// GreenBin Genius – On-Device TFLite Classifier Service
//
// Wraps the MobileNetV3 TFLite model for single-object waste classification.
// Runs entirely on-device — no internet required.
//
// Model:  assets/models/greenbin_mobilenetv3_dynamic.tflite
// Input:  [1, 224, 224, 3]  float32  RGB  normalised to [0.0, 1.0]
// Output: [1, 6]            float32  softmax probabilities
// Labels: e-waste, glass, metal, plastic, textile, wood

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Output of a single TFLite inference pass.
class TFLiteClassificationOutput {
  /// The winning label, e.g. "plastic"
  final String label;

  /// Softmax probability of the winning class, in [0.0 .. 1.0]
  final double confidence;

  /// Probabilities for all 6 classes, keyed by label name
  final Map<String, double> allScores;

  /// Wall-clock time for preprocessing + inference, in milliseconds
  final int inferenceMs;

  const TFLiteClassificationOutput({
    required this.label,
    required this.confidence,
    required this.allScores,
    required this.inferenceMs,
  });

  /// Confidence as a display string e.g. "94%"
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(0)}%';
}

/// Singleton service that loads and runs the on-device TFLite model.
class TFLiteClassifierService {
  TFLiteClassifierService._();
  static final TFLiteClassifierService instance = TFLiteClassifierService._();

  static const String _modelAsset  = 'assets/models/greenbin_mobilenetv3_dynamic.tflite';
  static const String _labelsAsset = 'assets/models/labels.txt';
  static const int    _inputSize   = 224;

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;
  bool _isLoading = false;

  // ─── Load ───────────────────────────────────────────────────────────────────

  /// Load model and labels from app bundle (idempotent).
  /// Safe to call multiple times — only loads once.
  Future<bool> load() async {
    if (_isLoaded) return true;
    if (_isLoading) {
      // Wait for the ongoing load to finish
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _isLoaded;
    }

    _isLoading = true;
    try {
      // 1. Load the TFLite model from assets
      final modelData = await rootBundle.load(_modelAsset);
      final modelBuffer = modelData.buffer.asUint8List(
        modelData.offsetInBytes,
        modelData.lengthInBytes,
      );

      _interpreter = Interpreter.fromBuffer(
        modelBuffer,
        options: InterpreterOptions()..threads = 2,
      );

      // 2. Load and parse labels
      final labelsRaw = await rootBundle.loadString(_labelsAsset);
      _labels = labelsRaw
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      _isLoaded = true;
      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      _isLoaded  = false;
      return false;
    }
  }

  // ─── Classify ───────────────────────────────────────────────────────────────

  /// Classify a [File] image on-device.
  ///
  /// Returns [TFLiteClassificationOutput] on success, or `null` if the model
  /// failed to load or the image could not be decoded.
  Future<TFLiteClassificationOutput?> classify(File imageFile) async {
    if (!_isLoaded && !await load()) return null;
    if (_interpreter == null || _labels.isEmpty) return null;

    try {
      final stopwatch = Stopwatch()..start();

      // 1. Decode image
      final bytes = await imageFile.readAsBytes();
      final rawImage = img.decodeImage(bytes);
      if (rawImage == null) return null;

      // 2. Resize to 224 × 224
      final resized = img.copyResize(
        rawImage,
        width:  _inputSize,
        height: _inputSize,
        interpolation: img.Interpolation.linear,
      );

      // 3. Build input tensor [1, 224, 224, 3] — normalise pixels to [0.0, 1.0]
      final input = List.generate(
        1,
        (_) => List.generate(
          _inputSize,
          (y) => List.generate(
            _inputSize,
            (x) {
              final pixel = resized.getPixel(x, y);
              return [
                pixel.r / 255.0,
                pixel.g / 255.0,
                pixel.b / 255.0,
              ];
            },
          ),
        ),
      );

      // 4. Prepare output tensor [1, numClasses]
      final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));

      // 5. Run inference
      _interpreter!.run(input, output);

      stopwatch.stop();
      final inferenceMs = stopwatch.elapsedMilliseconds;

      // 6. Parse output — find winning class
      final scores = output[0]; // List<double> of length 6
      int bestIdx = 0;
      double bestScore = scores[0];
      for (int i = 1; i < scores.length; i++) {
        if (scores[i] > bestScore) {
          bestScore = scores[i];
          bestIdx = i;
        }
      }

      // 7. Build allScores map
      final allScores = <String, double>{};
      for (int i = 0; i < _labels.length && i < scores.length; i++) {
        allScores[_labels[i]] = scores[i];
      }

      return TFLiteClassificationOutput(
        label:       _labels[bestIdx],
        confidence:  bestScore,
        allScores:   allScores,
        inferenceMs: inferenceMs,
      );
    } catch (e) {
      return null;
    }
  }

  // ─── Dispose ────────────────────────────────────────────────────────────────

  /// Release the interpreter. Call when the app exits or when memory is tight.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}

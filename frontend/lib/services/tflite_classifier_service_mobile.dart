import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'tflite_classifier_service_base.dart';

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

  Future<bool> load() async {
    if (_isLoaded) return true;
    if (_isLoading) {
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _isLoaded;
    }

    _isLoading = true;
    try {
      final modelData = await rootBundle.load(_modelAsset);
      final modelBuffer = modelData.buffer.asUint8List(
        modelData.offsetInBytes,
        modelData.lengthInBytes,
      );

      _interpreter = Interpreter.fromBuffer(
        modelBuffer,
        options: InterpreterOptions()..threads = 2,
      );

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

  Future<TFLiteClassificationOutput?> classify(File imageFile) async {
    if (!_isLoaded && !await load()) return null;
    if (_interpreter == null || _labels.isEmpty) return null;

    try {
      final stopwatch = Stopwatch()..start();

      final bytes = await imageFile.readAsBytes();
      final rawImage = img.decodeImage(bytes);
      if (rawImage == null) return null;

      final resized = img.copyResize(
        rawImage,
        width:  _inputSize,
        height: _inputSize,
        interpolation: img.Interpolation.linear,
      );

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

      final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));

      _interpreter!.run(input, output);

      stopwatch.stop();
      final inferenceMs = stopwatch.elapsedMilliseconds;

      final scores = output[0];
      int bestIdx = 0;
      double bestScore = scores[0];
      for (int i = 1; i < scores.length; i++) {
        if (scores[i] > bestScore) {
          bestScore = scores[i];
          bestIdx = i;
        }
      }

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

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}

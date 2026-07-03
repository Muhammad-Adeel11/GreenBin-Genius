// GreenBin Genius – TFLite Classifier base definitions

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

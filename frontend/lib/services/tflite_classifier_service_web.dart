import 'tflite_classifier_service_base.dart';

class TFLiteClassifierService {
  TFLiteClassifierService._();
  static final TFLiteClassifierService instance = TFLiteClassifierService._();

  Future<bool> load() async {
    return true;
  }

  Future<TFLiteClassificationOutput?> classify(dynamic imageFile) async {
    // Return mock classification for web runtime/UI layout debugging
    return const TFLiteClassificationOutput(
      label: 'plastic',
      confidence: 0.95,
      allScores: {
        'plastic': 0.95,
        'metal': 0.02,
        'glass': 0.01,
        'e-waste': 0.01,
        'textile': 0.005,
        'wood': 0.005,
      },
      inferenceMs: 45,
    );
  }

  void dispose() {}
}

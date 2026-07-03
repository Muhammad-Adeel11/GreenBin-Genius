export 'tflite_classifier_service_base.dart';
export 'tflite_classifier_service_mobile.dart'
    if (dart.library.js_interop) 'tflite_classifier_service_web.dart'
    if (dart.library.html) 'tflite_classifier_service_web.dart';

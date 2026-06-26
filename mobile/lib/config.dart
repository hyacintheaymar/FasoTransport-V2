import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _apiBaseUrlFromEnv = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_apiBaseUrlFromEnv.isNotEmpty) {
      return _apiBaseUrlFromEnv;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:4000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000';
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'http://127.0.0.1:4000';
    }

    return 'http://127.0.0.1:4000';
  }
}

import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _apiBaseUrlFromEnv = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_apiBaseUrlFromEnv.isNotEmpty) {
      return _apiBaseUrlFromEnv;
    }

    // URL du backend en production sur Render
    return 'https://fasotransport-v2.onrender.com';
  }
}

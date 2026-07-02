import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // Single origin via nginx: Laravel API at /api, storage at /storage,
  // Next.js at /. Debug and release builds both hit production so the app
  // works out of the box for testers on physical devices without needing
  // anyone to run a local Laravel server.
  static const String _productionUrl = 'https://medisasa.co.ke';

  static String get baseUrl {
    return '$_productionUrl/api';
  }

  static String get webUrl {
    return _productionUrl;
  }

  // Next.js web frontend (same origin as the backend)
  static String get webAppUrl {
    return _productionUrl;
  }

  // Get current configuration info for debugging
  static String get configInfo {
    return '''
🌐 Base URL: $baseUrl
🌐 Web URL: $webUrl
    ''';
  }

  static Future<Map<String, dynamic>?> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');
    if (userJson != null) {
      return jsonDecode(userJson) as Map<String, dynamic>;
    }
    return null;
  }
}

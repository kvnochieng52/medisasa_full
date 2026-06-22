import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // PRODUCTION CONFIGURATION
  // Using local network server for development

  static const String _productionUrl = 'http://192.168.0.15:8000';

  static String get baseUrl {
    return '$_productionUrl/api';
  }

  static String get webUrl {
    return _productionUrl;
  }

  // Next.js web frontend (separate port from Laravel backend)
  static const String _webFrontendUrl = 'http://192.168.0.15:3001';
  static String get webAppUrl {
    return _webFrontendUrl;
  }

  // Get current configuration info for debugging
  static String get configInfo {
    return '''
📱 Platform: ${kIsWeb ? 'Web' : Platform.operatingSystem}
🔧 Debug Mode: $kDebugMode
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

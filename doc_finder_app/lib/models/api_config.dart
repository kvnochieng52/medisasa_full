import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // In debug builds, point at the developer's workstation. Which host to use
  // depends on where the app is running:
  //   - Android emulator:  10.0.2.2         (special alias for the host machine)
  //   - iOS simulator:     127.0.0.1
  //   - Physical device:   the workstation's LAN IP  (see `_lanIp` below)
  //
  // Update `_lanIp` if your workstation gets a new DHCP lease.
  static const String _lanIp = '192.168.0.21';
  static const String _apiPort = '8000';   // php artisan serve
  static const String _webPort = '3001';   // next dev (see doc_finder_web/package.json)

  static const String _productionUrl = 'https://medisasa.co.ke';

  /// Debug host — chosen by platform. On web (flutter run -d chrome) we always
  /// hit localhost so the browser can talk to the local Laravel server.
  static String get _debugHost {
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2';
    if (Platform.isIOS || Platform.isMacOS) return _lanIp; // works for physical iPhones too
    return _lanIp;
  }

  static String get baseUrl {
    return kDebugMode
        ? 'http://$_debugHost:$_apiPort/api'
        : '$_productionUrl/api';
  }

  static String get webUrl {
    return kDebugMode
        ? 'http://$_debugHost:$_apiPort'
        : _productionUrl;
  }

  // Next.js web frontend
  static String get webAppUrl {
    return kDebugMode
        ? 'http://$_debugHost:$_webPort'
        : _productionUrl;
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

enum Environment { development, production }

class AppConfig {
  static const Environment currentEnvironment = Environment.production;

  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.development:
        return 'https://medisasa.co.ke/api';
      case Environment.production:
        return 'https://medisasa.co.ke/api';
    }
  }

  static String get webUrl {
    switch (currentEnvironment) {
      case Environment.development:
        return 'https://medisasa.co.ke';
      case Environment.production:
        return 'https://medisasa.co.ke';
    }
  }

  // For physical device testing against a local backend, set this to your
  // computer's LAN IP (e.g. 192.168.1.100). Leave null in production.
  static String? localDeviceIp;

  static String get deviceTestUrl {
    if (localDeviceIp != null) {
      return 'http://$localDeviceIp:8000/api';
    }
    return baseUrl;
  }

  static bool get isDevelopment => currentEnvironment == Environment.development;
  static bool get isProduction => currentEnvironment == Environment.production;
}
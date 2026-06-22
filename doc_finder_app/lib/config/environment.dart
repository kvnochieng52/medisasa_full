enum Environment { development, production }

class AppConfig {
  static const Environment currentEnvironment = Environment.development;

  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.development:
        return 'http://192.168.0.15:8000/api';
      case Environment.production:
        return 'http://192.168.0.15:8000/api';
    }
  }

  static String get webUrl {
    switch (currentEnvironment) {
      case Environment.development:
        return 'http://192.168.0.15:8000';
      case Environment.production:
        return 'http://192.168.0.15:8000';
    }
  }

  // For physical device testing, use your computer's IP address
  // You can find it by running 'ipconfig' in Command Prompt
  // Example: 192.168.1.100, 10.0.0.5, etc.
  static String? localDeviceIp; // Set this for physical device testing

  static String get deviceTestUrl {
    if (localDeviceIp != null) {
      return 'http://$localDeviceIp:8000/api';
    }
    return baseUrl;
  }

  static bool get isDevelopment => currentEnvironment == Environment.development;
  static bool get isProduction => currentEnvironment == Environment.production;
}
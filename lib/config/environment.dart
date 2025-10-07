// lib/config/environment.dart
// 🔹 Environment configuration for different deployment scenarios

class Environment {
  // 🔹 Environment types
  static const String development = 'development';
  static const String production = 'production';
  static const String local = 'local';
  
  // 🔹 Current environment (can be set via build arguments)
  static const String current = String.fromEnvironment('ENV', defaultValue: development);
  
  // 🔹 Environment-specific configurations
  static const Map<String, Map<String, String>> configs = {
    development: {
      'baseUrl': 'http://10.121.74.208:9001',
      'apiTimeout': '30000',
      'debugMode': 'true',
    },
    production: {
      'baseUrl': 'http://10.121.74.208:9001',
      'apiTimeout': '15000',
      'debugMode': 'false',
    },
    local: {
      'baseUrl': 'http://10.121.74.208:9001',
      'apiTimeout': '30000',
      'debugMode': 'true',
    },
  };
  
  // 🔹 Get configuration for current environment
  static Map<String, String> get currentConfig => configs[current] ?? configs[development]!;
  
  // 🔹 Helper methods
  static String get baseUrl => currentConfig['baseUrl']!;
  static int get apiTimeout => int.parse(currentConfig['apiTimeout']!);
  static bool get debugMode => currentConfig['debugMode'] == 'true';
  
  // 🔹 Environment info
  static bool get isDevelopment => current == development;
  static bool get isProduction => current == production;
  static bool get isLocal => current == local;
  
  // 🔹 Print current environment info
  static void printEnvironmentInfo() {
    print('🔧 Environment Configuration:');
    print('   Current Environment: $current');
    print('   Base URL: $baseUrl');
    print('   API Timeout: ${apiTimeout}ms');
    print('   Debug Mode: $debugMode');
  }
}

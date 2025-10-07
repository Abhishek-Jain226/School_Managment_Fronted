import 'environment.dart';

class AppConfig {
  // 🔹 Get current base URL based on environment
  static String get baseUrl => Environment.baseUrl;
  
  // 🔹 API Endpoints
  static String get authUrl => '$baseUrl/api/auth';
  static String get schoolsUrl => '$baseUrl/api/schools';
  static String get studentsUrl => '$baseUrl/api/students';
  static String get driversUrl => '$baseUrl/api/drivers';
  static String get vehicleOwnersUrl => '$baseUrl/api/vehicle-owners';
  static String get tripsUrl => '$baseUrl/api/trips';
  static String get vehiclesUrl => '$baseUrl/api';
  static String get pendingUsersUrl => '$baseUrl/api/pending-users';
  static String get masterDataUrl => '$baseUrl/api';
  static String get parentUrl => '$baseUrl/api';
  static String get activationUrl => '$baseUrl/activation';
  
  // 🔹 Environment info
  static String get environment => Environment.current;
  static bool get isDevelopment => Environment.isDevelopment;
  static bool get isProduction => Environment.isProduction;
  static bool get isLocal => Environment.isLocal;
  
  // 🔹 Debug info
  static void printConfig() {
    print('🔧 App Configuration:');
    print('   Environment: ${Environment.current}');
    print('   Base URL: $baseUrl');
    print('   Auth URL: $authUrl');
    print('   Schools URL: $schoolsUrl');
    print('   Debug Mode: ${Environment.debugMode}');
  }
}

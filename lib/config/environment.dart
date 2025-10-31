// lib/config/environment.dart
// 🔹 Environment configuration for different deployment scenarios

import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class Environment {
  // 🔹 Environment types
  static const String development = AppConstants.envDevelopment;
  static const String production = AppConstants.envProduction;
  static const String local = AppConstants.envLocal;
  
  // 🔹 Current environment (can be set via build arguments)
  static const String current = String.fromEnvironment('ENV', defaultValue: development);
  
  // 🔹 Environment-specific configurations
  static const Map<String, Map<String, String>> configs = {
    development: {
      AppConstants.configKeyBaseUrl: AppConstants.baseUrl,
      AppConstants.configKeyApiTimeout: AppConstants.configTimeoutDev,
      AppConstants.configKeyDebugMode: AppConstants.configValueTrue,
    },
    production: {
      AppConstants.configKeyBaseUrl: AppConstants.baseUrl,
      AppConstants.configKeyApiTimeout: AppConstants.configTimeoutProd,
      AppConstants.configKeyDebugMode: AppConstants.configValueFalse,
    },
    local: {
      AppConstants.configKeyBaseUrl: AppConstants.baseUrl,
      AppConstants.configKeyApiTimeout: AppConstants.configTimeoutDev,
      AppConstants.configKeyDebugMode: AppConstants.configValueTrue,
    },
  };
  
  // 🔹 Get configuration for current environment
  static Map<String, String> get currentConfig => configs[current] ?? configs[development]!;
  
  // 🔹 Helper methods
  static String get baseUrl => currentConfig[AppConstants.configKeyBaseUrl]!;
  static int get apiTimeout => int.parse(currentConfig[AppConstants.configKeyApiTimeout]!);
  static bool get debugMode => currentConfig[AppConstants.configKeyDebugMode] == AppConstants.configValueTrue;
  
  // 🔹 Environment info
  static bool get isDevelopment => current == development;
  static bool get isProduction => current == production;
  static bool get isLocal => current == local;
  
  // 🔹 Print current environment info
  static void printEnvironmentInfo() {
    debugPrint(AppConstants.logEnvironmentConfig);
    debugPrint('${AppConstants.logCurrentEnvironment}$current');
    debugPrint('${AppConstants.logBaseUrl}$baseUrl');
    debugPrint('${AppConstants.logApiTimeout}$apiTimeout${AppConstants.logApiTimeoutMs}');
    debugPrint('${AppConstants.logDebugMode}$debugMode');
  }
}

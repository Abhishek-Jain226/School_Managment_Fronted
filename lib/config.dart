// lib/config.dart
// 🔹 This file is deprecated - use lib/config/app_config.dart instead
// 🔹 Keeping this for backward compatibility

import 'config/app_config.dart' as new_config;

class AppConfig {
  // 🔹 Deprecated - use new_config.AppConfig.baseUrl instead
  static String get baseUrl => new_config.AppConfig.baseUrl;
}
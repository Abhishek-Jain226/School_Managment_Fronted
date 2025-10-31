import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../utils/constants.dart';


class AppAdminService {
  static String get _baseUrl => AppConfig.baseUrl;

  // Get auth token from shared preferences
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyJwtToken);
  }

  // Get all schools for AppAdmin
  static Future<Map<String, dynamic>> getAllSchools() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {AppConstants.keySuccess: false, AppConstants.keyMessage: 'No authentication token found'};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/app-admin/schools'),
        headers: {
          AppConstants.headerContentType: AppConstants.headerApplicationJson,
          AppConstants.headerAuthorization: '${AppConstants.headerBearer}$token',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          AppConstants.keySuccess: true,
          AppConstants.keyData: data[AppConstants.keyData],
          AppConstants.keyMessage: data[AppConstants.keyMessage],
        };
      } else {
        return {
          AppConstants.keySuccess: false,
          AppConstants.keyMessage: data[AppConstants.keyMessage] ?? 'Failed to fetch schools',
        };
      }
    } catch (e) {
      return {
        AppConstants.keySuccess: false,
        AppConstants.keyMessage: 'Error fetching schools: $e',
      };
    }
  }

  // Get App Admin Dashboard
  static Future<Map<String, dynamic>> getAppAdminDashboard() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {AppConstants.keySuccess: false, AppConstants.keyMessage: 'No authentication token found'};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/app-admin/dashboard'),
        headers: {
          AppConstants.headerContentType: AppConstants.headerApplicationJson,
          AppConstants.headerAuthorization: '${AppConstants.headerBearer}$token',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          AppConstants.keySuccess: true,
          AppConstants.keyData: data[AppConstants.keyData],
          AppConstants.keyMessage: data[AppConstants.keyMessage],
        };
      } else {
        return {
          AppConstants.keySuccess: false,
          AppConstants.keyMessage: data[AppConstants.keyMessage] ?? 'Failed to fetch dashboard',
        };
      }
    } catch (e) {
      return {
        AppConstants.keySuccess: false,
        AppConstants.keyMessage: 'Error fetching dashboard: $e',
      };
    }
  }

  // Get App Admin System Stats
  static Future<Map<String, dynamic>> getAppAdminSystemStats() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {AppConstants.keySuccess: false, AppConstants.keyMessage: 'No authentication token found'};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/app-admin/system-stats'),
        headers: {
          AppConstants.headerContentType: AppConstants.headerApplicationJson,
          AppConstants.headerAuthorization: '${AppConstants.headerBearer}$token',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          AppConstants.keySuccess: true,
          AppConstants.keyData: data[AppConstants.keyData],
          AppConstants.keyMessage: data[AppConstants.keyMessage],
        };
      } else {
        return {
          AppConstants.keySuccess: false,
          AppConstants.keyMessage: data[AppConstants.keyMessage] ?? 'Failed to fetch system stats',
        };
      }
    } catch (e) {
      return {
        AppConstants.keySuccess: false,
        AppConstants.keyMessage: 'Error fetching system stats: $e',
      };
    }
  }

  // Get school by ID
  static Future<Map<String, dynamic>> getSchoolById(int schoolId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {AppConstants.keySuccess: false, AppConstants.keyMessage: 'No authentication token found'};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/app-admin/schools/$schoolId'),
        headers: {
          AppConstants.headerContentType: AppConstants.headerApplicationJson,
          AppConstants.headerAuthorization: '${AppConstants.headerBearer}$token',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          AppConstants.keySuccess: true,
          AppConstants.keyData: data[AppConstants.keyData],
          AppConstants.keyMessage: data[AppConstants.keyMessage],
        };
      } else {
        return {
          AppConstants.keySuccess: false,
          AppConstants.keyMessage: data[AppConstants.keyMessage] ?? 'Failed to fetch school',
        };
      }
    } catch (e) {
      return {
        AppConstants.keySuccess: false,
        AppConstants.keyMessage: 'Error fetching school: $e',
      };
    }
  }

  // Update school status (activate/deactivate)
  static Future<Map<String, dynamic>> updateSchoolStatus(
    int schoolId,
    bool isActive,
    String updatedBy,
  ) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {AppConstants.keySuccess: false, AppConstants.keyMessage: 'No authentication token found'};
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/api/app-admin/schools/$schoolId/status?isActive=$isActive&updatedBy=$updatedBy'),
        headers: {
          AppConstants.headerContentType: AppConstants.headerApplicationJson,
          AppConstants.headerAuthorization: '${AppConstants.headerBearer}$token',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          AppConstants.keySuccess: true,
          AppConstants.keyData: data[AppConstants.keyData],
          AppConstants.keyMessage: data[AppConstants.keyMessage],
        };
      } else {
        return {
          AppConstants.keySuccess: false,
          AppConstants.keyMessage: data[AppConstants.keyMessage] ?? 'Failed to update school status',
        };
      }
    } catch (e) {
      return {
        AppConstants.keySuccess: false,
        AppConstants.keyMessage: 'Error updating school status: $e',
      };
    }
  }

  // Update school dates
  static Future<Map<String, dynamic>> updateSchoolDates(
    int schoolId,
    String? startDate,
    String? endDate,
    String updatedBy,
  ) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {AppConstants.keySuccess: false, AppConstants.keyMessage: 'No authentication token found'};
      }

      final requestBody = {
        AppConstants.keyStartDate: startDate,
        AppConstants.keyEndDate: endDate,
        AppConstants.keyUpdatedBy: updatedBy,
      };

      final response = await http.put(
        Uri.parse('$_baseUrl/api/app-admin/schools/$schoolId/dates'),
        headers: {
          AppConstants.headerContentType: AppConstants.headerApplicationJson,
          AppConstants.headerAuthorization: '${AppConstants.headerBearer}$token',
        },
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          AppConstants.keySuccess: true,
          AppConstants.keyData: data[AppConstants.keyData],
          AppConstants.keyMessage: data[AppConstants.keyMessage],
        };
      } else {
        return {
          AppConstants.keySuccess: false,
          AppConstants.keyMessage: data[AppConstants.keyMessage] ?? 'Failed to update school dates',
        };
      }
    } catch (e) {
      return {
        AppConstants.keySuccess: false,
        AppConstants.keyMessage: 'Error updating school dates: $e',
      };
    }
  }

  // Get school statistics
  static Future<Map<String, dynamic>> getSchoolStatistics() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {AppConstants.keySuccess: false, AppConstants.keyMessage: 'No authentication token found'};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/app-admin/schools/statistics'),
        headers: {
          AppConstants.headerContentType: AppConstants.headerApplicationJson,
          AppConstants.headerAuthorization: '${AppConstants.headerBearer}$token',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          AppConstants.keySuccess: true,
          AppConstants.keyData: data[AppConstants.keyData],
          AppConstants.keyMessage: data[AppConstants.keyMessage],
        };
      } else {
        return {
          AppConstants.keySuccess: false,
          AppConstants.keyMessage: data[AppConstants.keyMessage] ?? 'Failed to fetch statistics',
        };
      }
    } catch (e) {
      return {
        AppConstants.keySuccess: false,
        AppConstants.keyMessage: 'Error fetching statistics: $e',
      };
    }
  }

  // Search schools
  static Future<Map<String, dynamic>> searchSchools(String query) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {AppConstants.keySuccess: false, AppConstants.keyMessage: 'No authentication token found'};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/app-admin/schools/search?query=${Uri.encodeComponent(query)}'),
        headers: {
          AppConstants.headerContentType: AppConstants.headerApplicationJson,
          AppConstants.headerAuthorization: '${AppConstants.headerBearer}$token',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          AppConstants.keySuccess: true,
          AppConstants.keyData: data[AppConstants.keyData],
          AppConstants.keyMessage: data[AppConstants.keyMessage],
        };
      } else {
        return {
          AppConstants.keySuccess: false,
          AppConstants.keyMessage: data[AppConstants.keyMessage] ?? 'Failed to search schools',
        };
      }
    } catch (e) {
      return {
        AppConstants.keySuccess: false,
        AppConstants.keyMessage: 'Error searching schools: $e',
      };
    }
  }

  // Resend activation link for school admin
  static Future<Map<String, dynamic>> resendActivationLink(
    int schoolId,
    String updatedBy,
  ) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {AppConstants.keySuccess: false, AppConstants.keyMessage: 'No authentication token found'};
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/api/app-admin/schools/$schoolId/resend-activation?updatedBy=$updatedBy'),
        headers: {
          AppConstants.headerContentType: AppConstants.headerApplicationJson,
          AppConstants.headerAuthorization: '${AppConstants.headerBearer}$token',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          AppConstants.keySuccess: true,
          AppConstants.keyData: data[AppConstants.keyData],
          AppConstants.keyMessage: data[AppConstants.keyMessage],
        };
      } else {
        return {
          AppConstants.keySuccess: false,
          AppConstants.keyMessage: data[AppConstants.keyMessage] ?? 'Failed to resend activation link',
        };
      }
    } catch (e) {
      return {
        AppConstants.keySuccess: false,
        AppConstants.keyMessage: 'Error resending activation link: $e',
      };
    }
  }
}

// Instance wrappers used by BLoC (so BLoC can depend on an instance service)
extension AppAdminServiceInstance on AppAdminService {
  Future<Map<String, dynamic>> getAppAdminDashboard() async {
    return await AppAdminService.getAppAdminDashboard();
  }

  Future<List<dynamic>> getAppAdminSchools() async {
    final res = await AppAdminService.getAllSchools();
    print('🔍 getAllSchools raw response: $res');
    print('🔍 getAllSchools success: ${res[AppConstants.keySuccess]}');
    print('🔍 getAllSchools data type: ${res[AppConstants.keyData].runtimeType}');
    print('🔍 getAllSchools data: ${res[AppConstants.keyData]}');
    
    // Handle both formats:
    // 1. Direct array: [...]
    // 2. Nested object: {schools: [...], activeCount: X}
    if (res[AppConstants.keyData] is List) {
      return res[AppConstants.keyData] as List;
    } else if (res[AppConstants.keyData] is Map) {
      return (res[AppConstants.keyData][AppConstants.keySchools] as List?) ?? <dynamic>[];
    }
    return <dynamic>[];
  }

  Future<Map<String, dynamic>> getAppAdminSystemStats() async {
    return await AppAdminService.getAppAdminSystemStats();
  }

  Future<Map<String, dynamic>> getAppAdminProfile() async {
    final token = await AppAdminService._getAuthToken();
    if (token == null) {
      return {AppConstants.keySuccess: false, AppConstants.keyMessage: 'No authentication token found'};
    }
    final response = await http.get(
      Uri.parse('${AppAdminService._baseUrl}/api/app-admin/profile'),
      headers: {
        AppConstants.headerContentType: AppConstants.headerApplicationJson,
        AppConstants.headerAuthorization: '${AppConstants.headerBearer}$token',
      },
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {
        AppConstants.keySuccess: true,
        AppConstants.keyData: data[AppConstants.keyData],
        AppConstants.keyMessage: data[AppConstants.keyMessage],
      };
    }
    return {
      AppConstants.keySuccess: false,
      AppConstants.keyMessage: data[AppConstants.keyMessage] ?? 'Failed to fetch profile',
    };
  }

  Future<Map<String, dynamic>> updateAppAdminProfile(Map<String, dynamic> adminData) async {
    final token = await AppAdminService._getAuthToken();
    if (token == null) {
      return {AppConstants.keySuccess: false, AppConstants.keyMessage: 'No authentication token found'};
    }
    final response = await http.put(
      Uri.parse('${AppAdminService._baseUrl}/api/app-admin/profile'),
      headers: {
        AppConstants.headerContentType: AppConstants.headerApplicationJson,
        AppConstants.headerAuthorization: '${AppConstants.headerBearer}$token',
      },
      body: jsonEncode(adminData),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {
        AppConstants.keySuccess: true,
        AppConstants.keyData: data[AppConstants.keyData],
        AppConstants.keyMessage: data[AppConstants.keyMessage],
      };
    }
    return {
      AppConstants.keySuccess: false,
      AppConstants.keyMessage: data[AppConstants.keyMessage] ?? 'Failed to update profile',
    };
  }

  Future<Map<String, dynamic>> activateDeactivateSchool(int schoolId, bool isActive) async {
    // Default updatedBy; optionally fetch from stored username later
    return await AppAdminService.updateSchoolStatus(schoolId, isActive, 'AppAdmin');
  }

  Future<Map<String, dynamic>> setSchoolDates(int schoolId, String? startDate, String? endDate) async {
    return await AppAdminService.updateSchoolDates(schoolId, startDate, endDate, 'AppAdmin');
  }

  Future<Map<String, dynamic>> getAppAdminReports({String? startDate, String? endDate}) async {
    final token = await AppAdminService._getAuthToken();
    if (token == null) {
      return {AppConstants.keySuccess: false, AppConstants.keyMessage: 'No authentication token found'};
    }
    final query = <String, String>{};
    if (startDate != null) query['startDate'] = startDate;
    if (endDate != null) query['endDate'] = endDate;
    final uri = Uri.parse('${AppAdminService._baseUrl}/api/app-admin/reports').replace(queryParameters: query.isEmpty ? null : query);
    final response = await http.get(
      uri,
      headers: {
        AppConstants.headerContentType: AppConstants.headerApplicationJson,
        AppConstants.headerAuthorization: '${AppConstants.headerBearer}$token',
      },
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {
        AppConstants.keySuccess: true,
        AppConstants.keyData: data[AppConstants.keyData],
        AppConstants.keyMessage: data[AppConstants.keyMessage],
      };
    }
    return {
      AppConstants.keySuccess: false,
      AppConstants.keyMessage: data[AppConstants.keyMessage] ?? 'Failed to fetch reports',
    };
  }

  Future<Map<String, dynamic>> resendActivationLink(int schoolId) async {
    return await AppAdminService.resendActivationLink(schoolId, 'AppAdmin');
  }
}

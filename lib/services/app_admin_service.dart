import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';


class AppAdminService {
  static String get _baseUrl => AppConfig.baseUrl;

  // Get auth token from shared preferences
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Get all schools for AppAdmin
  static Future<Map<String, dynamic>> getAllSchools() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/app-admin/schools'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch schools',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching schools: $e',
      };
    }
  }

  // Get school by ID
  static Future<Map<String, dynamic>> getSchoolById(int schoolId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/app-admin/schools/$schoolId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch school',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching school: $e',
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
        return {'success': false, 'message': 'No authentication token found'};
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/api/app-admin/schools/$schoolId/status?isActive=$isActive&updatedBy=$updatedBy'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update school status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error updating school status: $e',
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
        return {'success': false, 'message': 'No authentication token found'};
      }

      final requestBody = {
        'startDate': startDate,
        'endDate': endDate,
        'updatedBy': updatedBy,
      };

      final response = await http.put(
        Uri.parse('$_baseUrl/api/app-admin/schools/$schoolId/dates'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update school dates',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error updating school dates: $e',
      };
    }
  }

  // Get school statistics
  static Future<Map<String, dynamic>> getSchoolStatistics() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/app-admin/schools/statistics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch statistics',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching statistics: $e',
      };
    }
  }

  // Search schools
  static Future<Map<String, dynamic>> searchSchools(String query) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/app-admin/schools/search?query=${Uri.encodeComponent(query)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to search schools',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error searching schools: $e',
      };
    }
  }
}

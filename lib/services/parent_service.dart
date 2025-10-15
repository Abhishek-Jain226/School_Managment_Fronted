import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/app_config.dart';
import '../data/models/parent_dashboard.dart';
import '../data/models/parent_notification.dart';
import '../data/models/attendance_history.dart';
import '../data/models/monthly_report.dart';

class ParentService {
  // 🔹 Using centralized configuration
  String get base => AppConfig.parentUrl;
  final AuthService _auth = AuthService();

  /// 🔹 Get Student linked with Parent (by parent userId)
  Future<Map<String, dynamic>> getStudentByParentUserId(int userId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/parents/user/$userId/student");
    final headers = _buildHeaders(token);

    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

  /// 🔹 Get Parent data by userId
  Future<Map<String, dynamic>> getParentByUserId(int userId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/parents/user/$userId");
    final headers = _buildHeaders(token);

    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

  /// 🔹 Get Student by studentId
  Future<Map<String, dynamic>> getStudentById(int studentId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/students/$studentId");
    final headers = _buildHeaders(token);

    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

  /// 🔹 Get Student trips by studentId
  Future<Map<String, dynamic>> getStudentTrips(int studentId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/students/$studentId/trips");
    final headers = _buildHeaders(token);

    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

  /// 🔹 Get Driver location by driverId
  Future<Map<String, dynamic>> getDriverLocation(int driverId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/drivers/$driverId/location");
    final headers = _buildHeaders(token);

    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

  /// 🔹 Update Student profile
  Future<Map<String, dynamic>> updateStudent(
      int studentId, Map<String, dynamic> req) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/students/$studentId");
    final headers = _buildHeaders(token);

    final resp = await http.put(
      url,
      headers: headers,
      body: jsonEncode(req),
    );
    return _handleResponse(resp);
  }

  // ================ PARENT DASHBOARD METHODS ================

  /// 🔹 Get Parent Dashboard
  Future<ParentDashboard> getParentDashboard(int userId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/parents/$userId/dashboard");
    print("🔍 ParentService: getParentDashboard URL: $url");
    print("🔍 ParentService: getParentDashboard userId: $userId");

    final headers = _buildHeaders(token);

    final resp = await http.get(url, headers: headers);
    print("🔍 ParentService: getParentDashboard response status: ${resp.statusCode}");
    print("🔍 ParentService: getParentDashboard response body: ${resp.body}");

    if (resp.statusCode == 200) {
      final responseData = jsonDecode(resp.body) as Map<String, dynamic>;
      print("🔍 ParentService: getParentDashboard responseData: $responseData");

      if (responseData['success'] == true && responseData['data'] != null) {
        return ParentDashboard.fromJson(responseData['data']);
      } else {
        throw Exception("Failed to get parent dashboard: ${responseData['message']}");
      }
    } else {
      throw Exception("Parent dashboard request failed: ${resp.statusCode} ${resp.body}");
    }
  }

  /// 🔹 Get Parent Notifications
  Future<List<ParentNotification>> getParentNotifications(int userId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/parents/$userId/notifications");
    print("🔍 ParentService: getParentNotifications URL: $url");

    final headers = _buildHeaders(token);

    final resp = await http.get(url, headers: headers);
    print("🔍 ParentService: getParentNotifications response status: ${resp.statusCode}");

    if (resp.statusCode == 200) {
      final responseData = jsonDecode(resp.body) as Map<String, dynamic>;
      if (responseData['success'] == true && responseData['data'] != null) {
        final List<dynamic> notificationsJson = responseData['data'];
        return notificationsJson.map((json) => ParentNotification.fromJson(json)).toList();
      } else {
        throw Exception("Failed to get parent notifications: ${responseData['message']}");
      }
    } else {
      throw Exception("Parent notifications request failed: ${resp.statusCode} ${resp.body}");
    }
  }

  /// 🔹 Get Attendance History
  Future<AttendanceHistory> getAttendanceHistory(int userId, {String? fromDate, String? toDate}) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/parents/$userId/attendance-history");
    print("🔍 ParentService: getAttendanceHistory URL: $url");

    // Add query parameters if provided
    final uri = Uri.parse(url.toString());
    final queryParams = <String, String>{};
    if (fromDate != null) queryParams['fromDate'] = fromDate;
    if (toDate != null) queryParams['toDate'] = toDate;
    
    final finalUrl = queryParams.isNotEmpty 
        ? uri.replace(queryParameters: queryParams)
        : uri;

    final headers = _buildHeaders(token);

    final resp = await http.get(finalUrl, headers: headers);
    print("🔍 ParentService: getAttendanceHistory response status: ${resp.statusCode}");

    if (resp.statusCode == 200) {
      final responseData = jsonDecode(resp.body) as Map<String, dynamic>;
      if (responseData['success'] == true && responseData['data'] != null) {
        return AttendanceHistory.fromJson(responseData['data']);
      } else {
        throw Exception("Failed to get attendance history: ${responseData['message']}");
      }
    } else {
      throw Exception("Attendance history request failed: ${resp.statusCode} ${resp.body}");
    }
  }

  /// 🔹 Get Monthly Report
  Future<MonthlyReport> getMonthlyReport(int userId, {int? year, int? month}) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/parents/$userId/monthly-report");
    print("🔍 ParentService: getMonthlyReport URL: $url");

    // Add query parameters if provided
    final uri = Uri.parse(url.toString());
    final queryParams = <String, String>{};
    if (year != null) queryParams['year'] = year.toString();
    if (month != null) queryParams['month'] = month.toString();
    
    final finalUrl = queryParams.isNotEmpty 
        ? uri.replace(queryParameters: queryParams)
        : uri;

    final headers = _buildHeaders(token);

    final resp = await http.get(finalUrl, headers: headers);
    print("🔍 ParentService: getMonthlyReport response status: ${resp.statusCode}");

    if (resp.statusCode == 200) {
      final responseData = jsonDecode(resp.body) as Map<String, dynamic>;
      if (responseData['success'] == true && responseData['data'] != null) {
        return MonthlyReport.fromJson(responseData['data']);
      } else {
        throw Exception("Failed to get monthly report: ${responseData['message']}");
      }
    } else {
      throw Exception("Monthly report request failed: ${resp.statusCode} ${resp.body}");
    }
  }

  /// 🔹 Update Parent Profile
  Future<Map<String, dynamic>> updateParentProfile(int userId, Map<String, dynamic> request) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/parents/$userId/profile");
    print("🔍 ParentService: updateParentProfile URL: $url");

    final headers = _buildHeaders(token);

    final resp = await http.put(
      url,
      headers: headers,
      body: jsonEncode(request),
    );
    print("🔍 ParentService: updateParentProfile response status: ${resp.statusCode}");

    return _handleResponse(resp);
  }

  /// ✅ Common Header Builder
  Map<String, String> _buildHeaders(String? token) {
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  /// ✅ Common Response Handler
  Map<String, dynamic> _handleResponse(http.Response resp) {
    try {
      final decoded = jsonDecode(resp.body);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return decoded;
      }
      return {
        "success": false,
        "message": decoded["message"] ?? "Error: ${resp.statusCode}",
        "data": null,
      };
    } catch (e) {
      return {
        "success": false,
        "message": "Invalid response format",
        "data": null,
      };
    }
  }
}

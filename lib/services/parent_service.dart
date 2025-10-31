import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
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

  /// 🔹 Get Parent Students
  Future<List<dynamic>> getParentStudents(int parentId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/parents/$parentId/students");
    final headers = _buildHeaders(token);

    final resp = await http.get(url, headers: headers);
    final data = _handleResponse(resp);
    return data[AppConstants.keyData] ?? [];
  }

  /// 🔹 Get Parent Trips
  Future<List<dynamic>> getParentTrips(int parentId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/parents/$parentId/trips");
    final headers = _buildHeaders(token);

    final resp = await http.get(url, headers: headers);
    final data = _handleResponse(resp);
    return data[AppConstants.keyData] ?? [];
  }

  /// 🔹 Get Parent Notifications (list of raw maps)
  Future<List<dynamic>> getParentNotifications(int parentId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/parents/$parentId/notifications");
    final headers = _buildHeaders(token);
    final resp = await http.get(url, headers: headers);
    final data = _handleResponse(resp);
    return data[AppConstants.keyData] ?? [];
  }

  /// 🔹 Get Parent Dashboard
  Future<ParentDashboard> getParentDashboard(int userId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/parents/$userId/dashboard");
    debugPrint("🔍 ParentService: getParentDashboard URL: $url");
    debugPrint("🔍 ParentService: getParentDashboard userId: $userId");

    final headers = _buildHeaders(token);

    final resp = await http.get(url, headers: headers);
    debugPrint("🔍 ParentService: getParentDashboard response status: ${resp.statusCode}");
    debugPrint("🔍 ParentService: getParentDashboard response body: ${resp.body}");

    if (resp.statusCode == 200) {
      final responseData = jsonDecode(resp.body) as Map<String, dynamic>;
      debugPrint("🔍 ParentService: getParentDashboard responseData: $responseData");

      if (responseData[AppConstants.keySuccess] == true && responseData[AppConstants.keyData] != null) {
        return ParentDashboard.fromJson(responseData[AppConstants.keyData]);
      } else {
        throw Exception("${AppConstants.errorFailedToGet} parent dashboard: ${responseData[AppConstants.keyMessage]}");
      }
    } else {
      throw Exception("Parent dashboard ${AppConstants.errorRequestFailedColon}: ${resp.statusCode} ${resp.body}");
    }
  }

  // -------- Additional endpoints used by ParentBloc --------
  Future<Map<String, dynamic>> getParentProfile(int parentId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/parents/$parentId/profile");
    final headers = _buildHeaders(token);
    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

  Future<Map<String, dynamic>> getParentAttendanceHistory(int parentId, {int? studentId, String? startDate, String? endDate}) async {
    final token = await _auth.getToken();
    final query = <String, String>{};
    if (studentId != null) query[AppConstants.keyStudentId] = studentId.toString();
    if (startDate != null) query[AppConstants.keyStartDate] = startDate;
    if (endDate != null) query[AppConstants.keyEndDate] = endDate;
    final uri = Uri.parse("$base/parents/$parentId/attendance").replace(queryParameters: query.isEmpty ? null : query);
    final headers = _buildHeaders(token);
    final resp = await http.get(uri, headers: headers);
    return _handleResponse(resp);
  }

  Future<Map<String, dynamic>> getParentMonthlyReport(int parentId, {int? studentId, int? month, int? year}) async {
    final token = await _auth.getToken();
    final query = <String, String>{};
    if (studentId != null) query[AppConstants.keyStudentId] = studentId.toString();
    if (month != null) query[AppConstants.keyMonth] = month.toString();
    if (year != null) query[AppConstants.keyYear] = year.toString();
    final uri = Uri.parse("$base/parents/$parentId/monthly-report").replace(queryParameters: query.isEmpty ? null : query);
    final headers = _buildHeaders(token);
    final resp = await http.get(uri, headers: headers);
    return _handleResponse(resp);
  }

  Future<Map<String, dynamic>> getParentVehicleTracking(int parentId, {int? studentId}) async {
    final token = await _auth.getToken();
    final query = <String, String>{};
    if (studentId != null) query[AppConstants.keyStudentId] = studentId.toString();
    final uri = Uri.parse("$base/parents/$parentId/vehicle-tracking").replace(queryParameters: query.isEmpty ? null : query);
    final headers = _buildHeaders(token);
    final resp = await http.get(uri, headers: headers);
    return _handleResponse(resp);
  }

  /// 🔹 Get Parent Notifications (typed models)
  Future<List<ParentNotification>> getParentNotificationsTyped(int userId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/parents/$userId/notifications");
    debugPrint("🔍 ParentService: getParentNotifications URL: $url");

    final headers = _buildHeaders(token);

    final resp = await http.get(url, headers: headers);
    debugPrint("🔍 ParentService: getParentNotifications response status: ${resp.statusCode}");

    if (resp.statusCode == 200) {
      final responseData = jsonDecode(resp.body) as Map<String, dynamic>;
      if (responseData[AppConstants.keySuccess] == true && responseData[AppConstants.keyData] != null) {
        final List<dynamic> notificationsJson = responseData[AppConstants.keyData];
        return notificationsJson.map((json) => ParentNotification.fromJson(json)).toList();
      } else {
        throw Exception("${AppConstants.errorFailedToGet} parent notifications: ${responseData[AppConstants.keyMessage]}");
      }
    } else {
      throw Exception("Parent notifications ${AppConstants.errorRequestFailedColon}: ${resp.statusCode} ${resp.body}");
    }
  }

  /// 🔹 Get Attendance History
  Future<AttendanceHistory> getAttendanceHistory(int userId, {String? fromDate, String? toDate}) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/parents/$userId/attendance-history");
    debugPrint("🔍 ParentService: getAttendanceHistory URL: $url");

    // Add query parameters if provided
    final uri = Uri.parse(url.toString());
    final queryParams = <String, String>{};
    if (fromDate != null) queryParams[AppConstants.keyFromDate] = fromDate;
    if (toDate != null) queryParams[AppConstants.keyToDate] = toDate;
    
    final finalUrl = queryParams.isNotEmpty 
        ? uri.replace(queryParameters: queryParams)
        : uri;

    final headers = _buildHeaders(token);

    final resp = await http.get(finalUrl, headers: headers);
    debugPrint("🔍 ParentService: getAttendanceHistory response status: ${resp.statusCode}");

    if (resp.statusCode == 200) {
      final responseData = jsonDecode(resp.body) as Map<String, dynamic>;
      if (responseData[AppConstants.keySuccess] == true && responseData[AppConstants.keyData] != null) {
        return AttendanceHistory.fromJson(responseData[AppConstants.keyData]);
      } else {
        throw Exception("${AppConstants.errorFailedToGet} attendance history: ${responseData[AppConstants.keyMessage]}");
      }
    } else {
      throw Exception("Attendance history ${AppConstants.errorRequestFailedColon}: ${resp.statusCode} ${resp.body}");
    }
  }

  /// 🔹 Get Monthly Report
  Future<MonthlyReport> getMonthlyReport(int userId, {int? year, int? month}) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/parents/$userId/monthly-report");
    debugPrint("🔍 ParentService: getMonthlyReport URL: $url");

    // Add query parameters if provided
    final uri = Uri.parse(url.toString());
    final queryParams = <String, String>{};
    if (year != null) queryParams[AppConstants.keyYear] = year.toString();
    if (month != null) queryParams[AppConstants.keyMonth] = month.toString();
    
    final finalUrl = queryParams.isNotEmpty 
        ? uri.replace(queryParameters: queryParams)
        : uri;

    final headers = _buildHeaders(token);

    final resp = await http.get(finalUrl, headers: headers);
    debugPrint("🔍 ParentService: getMonthlyReport response status: ${resp.statusCode}");

    if (resp.statusCode == 200) {
      final responseData = jsonDecode(resp.body) as Map<String, dynamic>;
      if (responseData[AppConstants.keySuccess] == true && responseData[AppConstants.keyData] != null) {
        return MonthlyReport.fromJson(responseData[AppConstants.keyData]);
      } else {
        throw Exception("${AppConstants.errorFailedToGet} monthly report: ${responseData[AppConstants.keyMessage]}");
      }
    } else {
      throw Exception("Monthly report ${AppConstants.errorRequestFailedColon}: ${resp.statusCode} ${resp.body}");
    }
  }

  /// 🔹 Update Parent Profile
  Future<Map<String, dynamic>> updateParentProfile(int userId, Map<String, dynamic> request) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/parents/$userId/profile");
    debugPrint("🔍 ParentService: updateParentProfile URL: $url");

    final headers = _buildHeaders(token);

    final resp = await http.put(
      url,
      headers: headers,
      body: jsonEncode(request),
    );
    debugPrint("🔍 ParentService: updateParentProfile response status: ${resp.statusCode}");

    return _handleResponse(resp);
  }

  /// ✅ Common Header Builder
  Map<String, String> _buildHeaders(String? token) {
    return {
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
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
        AppConstants.keySuccess: false,
        AppConstants.keyMessage: decoded[AppConstants.keyMessage] ?? "${AppConstants.errorPrefix}: ${resp.statusCode}",
        AppConstants.keyData: null,
      };
    } catch (e) {
      return {
        AppConstants.keySuccess: false,
        AppConstants.keyMessage: AppConstants.errorInvalidResponseFormat,
        AppConstants.keyData: null,
      };
    }
  }
}

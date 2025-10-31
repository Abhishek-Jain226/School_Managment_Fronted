import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';
import '../config/app_config.dart';

class GateStaffService {
  static String get base => AppConfig.baseUrl + AppConstants.endpointGateStaff;
  final AuthService _auth = AuthService();

  /// ---------------- Get Gate Staff Dashboard ----------------
  Future<Map<String, dynamic>> getGateStaffDashboard(int userId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$userId/dashboard");
    debugPrint("🔍 Frontend: getGateStaffDashboard URL: $url");
    debugPrint("🔍 Frontend: getGateStaffDashboard userId: $userId");

    final headers = {
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.get(url, headers: headers);
    debugPrint("🔍 Frontend: getGateStaffDashboard response status: ${resp.statusCode}");
    debugPrint("🔍 Frontend: getGateStaffDashboard response body: ${resp.body}");
    return _handleResponse(resp);
  }

  /// ---------------- Get Students by Trip ----------------
  Future<Map<String, dynamic>> getStudentsByTrip(int userId, int tripId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$userId/trips/$tripId/students");
    debugPrint("🔍 Frontend: getStudentsByTrip URL: $url");

    final headers = {
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.get(url, headers: headers);
    debugPrint("🔍 Frontend: getStudentsByTrip response status: ${resp.statusCode}");
    return _handleResponse(resp);
  }

  /// ---------------- Mark Gate Entry ----------------
  Future<Map<String, dynamic>> markGateEntry(int userId, int studentId, int tripId, String remarks) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$userId/gate-entry");
    debugPrint("🔍 Frontend: markGateEntry URL: $url");

    final requestData = {
      AppConstants.keyStudentId: studentId,
      AppConstants.keyTripId: tripId,
      AppConstants.keyRemarks: remarks,
    };

    final headers = {
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.post(url, headers: headers, body: jsonEncode(requestData));
    debugPrint("🔍 Frontend: markGateEntry response status: ${resp.statusCode}");
    return _handleResponse(resp);
  }

  /// ---------------- Mark Gate Exit ----------------
  Future<Map<String, dynamic>> markGateExit(int userId, int studentId, int tripId, String remarks) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$userId/gate-exit");
    debugPrint("🔍 Frontend: markGateExit URL: $url");

    final requestData = {
      AppConstants.keyStudentId: studentId,
      AppConstants.keyTripId: tripId,
      AppConstants.keyRemarks: remarks,
    };

    final headers = {
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.post(url, headers: headers, body: jsonEncode(requestData));
    debugPrint("🔍 Frontend: markGateExit response status: ${resp.statusCode}");
    return _handleResponse(resp);
  }

  /// ---------------- Get Recent Dispatch Logs ----------------
  Future<Map<String, dynamic>> getRecentDispatchLogs(int userId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$userId/recent-logs");
    debugPrint("🔍 Frontend: getRecentDispatchLogs URL: $url");

    final headers = {
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.get(url, headers: headers);
    debugPrint("🔍 Frontend: getRecentDispatchLogs response status: ${resp.statusCode}");
    return _handleResponse(resp);
  }

  /// ---------------- Get Gate Staff by User ID ----------------
  Future<Map<String, dynamic>> getGateStaffByUserId(int userId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/user/$userId");
    debugPrint("🔍 Frontend: getGateStaffByUserId URL: $url");

    final headers = {
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.get(url, headers: headers);
    debugPrint("🔍 Frontend: getGateStaffByUserId response status: ${resp.statusCode}");
    return _handleResponse(resp);
  }

  /// ---------------- Common Response Handler ----------------
  Map<String, dynamic> _handleResponse(http.Response resp) {
    debugPrint("🔍 Frontend: _handleResponse - Status: ${resp.statusCode}");
    debugPrint("🔍 Frontend: _handleResponse - Body: ${resp.body}");
    
    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data is Map<String, dynamic>) {
      debugPrint("🔍 Frontend: _handleResponse - Success: $data");
      return data;
    } else {
      debugPrint("🔍 Frontend: _handleResponse - Error: ${resp.statusCode} ${resp.body}");
      throw Exception("${AppConstants.errorApiError}: ${resp.statusCode} ${resp.body}");
    }
  }
}

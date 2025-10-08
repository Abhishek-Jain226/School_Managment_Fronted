import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/app_config.dart';

class GateStaffService {
  static String get base => AppConfig.baseUrl + '/api/gate-staff';
  final AuthService _auth = AuthService();

  /// ---------------- Get Gate Staff Dashboard ----------------
  Future<Map<String, dynamic>> getGateStaffDashboard(int userId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$userId/dashboard");
    print("🔍 Frontend: getGateStaffDashboard URL: $url");
    print("🔍 Frontend: getGateStaffDashboard userId: $userId");

    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    print("🔍 Frontend: getGateStaffDashboard response status: ${resp.statusCode}");
    print("🔍 Frontend: getGateStaffDashboard response body: ${resp.body}");
    return _handleResponse(resp);
  }

  /// ---------------- Get Students by Trip ----------------
  Future<Map<String, dynamic>> getStudentsByTrip(int userId, int tripId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$userId/trips/$tripId/students");
    print("🔍 Frontend: getStudentsByTrip URL: $url");

    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    print("🔍 Frontend: getStudentsByTrip response status: ${resp.statusCode}");
    return _handleResponse(resp);
  }

  /// ---------------- Mark Gate Entry ----------------
  Future<Map<String, dynamic>> markGateEntry(int userId, int studentId, int tripId, String remarks) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$userId/gate-entry");
    print("🔍 Frontend: markGateEntry URL: $url");

    final requestData = {
      "studentId": studentId,
      "tripId": tripId,
      "remarks": remarks,
    };

    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.post(url, headers: headers, body: jsonEncode(requestData));
    print("🔍 Frontend: markGateEntry response status: ${resp.statusCode}");
    return _handleResponse(resp);
  }

  /// ---------------- Mark Gate Exit ----------------
  Future<Map<String, dynamic>> markGateExit(int userId, int studentId, int tripId, String remarks) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$userId/gate-exit");
    print("🔍 Frontend: markGateExit URL: $url");

    final requestData = {
      "studentId": studentId,
      "tripId": tripId,
      "remarks": remarks,
    };

    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.post(url, headers: headers, body: jsonEncode(requestData));
    print("🔍 Frontend: markGateExit response status: ${resp.statusCode}");
    return _handleResponse(resp);
  }

  /// ---------------- Get Recent Dispatch Logs ----------------
  Future<Map<String, dynamic>> getRecentDispatchLogs(int userId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$userId/recent-logs");
    print("🔍 Frontend: getRecentDispatchLogs URL: $url");

    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    print("🔍 Frontend: getRecentDispatchLogs response status: ${resp.statusCode}");
    return _handleResponse(resp);
  }

  /// ---------------- Get Gate Staff by User ID ----------------
  Future<Map<String, dynamic>> getGateStaffByUserId(int userId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/user/$userId");
    print("🔍 Frontend: getGateStaffByUserId URL: $url");

    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    print("🔍 Frontend: getGateStaffByUserId response status: ${resp.statusCode}");
    return _handleResponse(resp);
  }

  /// ---------------- Common Response Handler ----------------
  Map<String, dynamic> _handleResponse(http.Response resp) {
    print("🔍 Frontend: _handleResponse - Status: ${resp.statusCode}");
    print("🔍 Frontend: _handleResponse - Body: ${resp.body}");
    
    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data is Map<String, dynamic>) {
      print("🔍 Frontend: _handleResponse - Success: $data");
      return data;
    } else {
      print("🔍 Frontend: _handleResponse - Error: ${resp.statusCode} ${resp.body}");
      throw Exception("API Error: ${resp.statusCode} ${resp.body}");
    }
  }
}

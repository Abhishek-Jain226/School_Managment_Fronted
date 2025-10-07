import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/app_config.dart';

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

  /// 🔹 Get Student by studentId
  Future<Map<String, dynamic>> getStudentById(int studentId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/students/$studentId");
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

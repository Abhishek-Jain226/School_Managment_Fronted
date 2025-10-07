import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/student_request.dart';
import 'auth_service.dart';
import '../config/app_config.dart';

class StudentService {
  // 🔹 Using centralized configuration
  static String get base => AppConfig.studentsUrl;
  final _auth = AuthService();

  Future<int> getStudentCount(String schoolId) async {
    try {
      final token = await _auth.getToken();
      final resp = await http.get(
        Uri.parse("$base/count/$schoolId"),
        headers: {"Authorization": "Bearer $token"},
      );
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return (data["data"] ?? 0) as int;
      } else {
        print("Error getting student count: ${resp.statusCode} - ${resp.body}");
        return 0;
      }
    } catch (e) {
      print("Exception getting student count: $e");
      return 0;
    }
  }
   /// Create student (POST /api/students/create)
  Future<Map<String, dynamic>> createStudent(StudentRequest req) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/create");
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.post(url, headers: headers, body: jsonEncode(req.toJson()));
    final body = resp.body;
    if (resp.statusCode == 200) {
      return jsonDecode(body) as Map<String, dynamic>;
    } else {
      // return error with server response for debugging
      throw Exception("Create student failed: ${resp.statusCode} ${resp.body}");
    }
  }

  /// Get students by school
  Future<Map<String, dynamic>> getStudentsBySchool(int schoolId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/school/$schoolId");
    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    return {"success": false, "message": "Failed to fetch students"};
  }

  /// Optionally: get student by id, update, delete etc. (not implemented here
}

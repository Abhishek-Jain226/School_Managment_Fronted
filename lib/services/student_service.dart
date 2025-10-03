import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/student_request.dart';
import 'auth_service.dart';

class StudentService {
  static const String base = "http://192.168.29.254:9001/api/students";
  final _auth = AuthService();

  Future<int> getStudentCount(String schoolId) async {
    final token = await _auth.getToken();
    final resp = await http.get(
      Uri.parse("$base/count?schoolId=$schoolId"),
      headers: {"Authorization": "Bearer $token"},
    );
    final data = jsonDecode(resp.body);
    return (data["data"] ?? 0) as int;
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

  /// Optionally: get student by id, update, delete etc. (not implemented here
}

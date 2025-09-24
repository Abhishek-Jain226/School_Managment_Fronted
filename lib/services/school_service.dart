import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../data/models/school_request.dart';
import 'auth_service.dart';

class SchoolService {
  final _auth = AuthService();
  static const String _base = "${AppConfig.baseUrl}/api/schools";

  // ---------------- Register School ----------------
  Future<Map<String, dynamic>> registerSchool(SchoolRequest request) async {
    final url = Uri.parse("$_base/register");
    final resp = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(request.toJson()),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      throw Exception("Failed to register school: ${resp.body}");
    }
  }

  // ---------------- Activate School ----------------
  Future<Map<String, dynamic>> activateSchool(int schoolId, String activationCode) async {
    final url = Uri.parse("$_base/$schoolId/activate?activationCode=$activationCode");
    final token = await _auth.getToken();
    final resp = await http.post(
      url,
      headers: {"Authorization": "Bearer $token"},
    );
    return jsonDecode(resp.body);
  }

  // ---------------- Update School ----------------
  Future<Map<String, dynamic>> updateSchool(int schoolId, SchoolRequest request) async {
    final url = Uri.parse("$_base/$schoolId");
    final token = await _auth.getToken();
    final resp = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(request.toJson()),
    );
    return jsonDecode(resp.body);
  }

  // ---------------- Delete School ----------------
  Future<Map<String, dynamic>> deleteSchool(int schoolId) async {
    final url = Uri.parse("$_base/$schoolId");
    final token = await _auth.getToken();
    final resp = await http.delete(
      url,
      headers: {"Authorization": "Bearer $token"},
    );
    return jsonDecode(resp.body);
  }

  // ---------------- Get School By Id ----------------
  Future<Map<String, dynamic>> getSchoolById(int schoolId) async {
    final url = Uri.parse("$_base/$schoolId");
    final token = await _auth.getToken();
    final resp = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );
    return jsonDecode(resp.body);
  }

  // ---------------- Get All Schools ----------------
  Future<List<dynamic>> getAllSchools() async {
    final url = Uri.parse(_base);
    final token = await _auth.getToken();
    final resp = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );
    final data = jsonDecode(resp.body);
    return data["data"] ?? [];
  }

  Future<void> saveSchoolToPrefs(Map<String, dynamic> school) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("school_info", jsonEncode(school));
  }

  Future<dynamic> getSchoolFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("school_info");
    if (data == null) return null;
    return jsonDecode(data);
  }
}

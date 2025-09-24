import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Update base URL if needed
  static const String base = "http://10.11.244.208:9001/api/auth";

  // ------------------ COMPLETE REGISTRATION ------------------
  Future<Map<String, dynamic>> completeRegistration({
    required String token,
    required String userName,
    required String password,
  }) async {
    final url = Uri.parse("$base/complete-registration");
    final resp = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "token": token,
        "userName": userName,
        "password": password,
      }),
    );

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("Activation failed: ${resp.statusCode} ${resp.body}");
    }
  }

  // ------------------ LOGIN ------------------
  Future<Map<String, dynamic>> login(String loginId, String password) async {
    final url = Uri.parse("$base/login");
    final resp = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"loginId": loginId, "password": password}),
    );

    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data["success"] == true) {
      final userData = data["data"];

      final prefs = await SharedPreferences.getInstance();


    
      await prefs.setString("jwt_token", userData["token"]);
      await prefs.setInt("userId", userData["userId"]);
      await prefs.setString("userName", userData["userName"] ?? "");
      await prefs.setString("email", userData["email"] ?? "");
      await prefs.setString("schoolName", userData["schoolName"] ?? "");
      await prefs.setInt("schoolId", userData["schoolId"] ?? 0);

      return data;
    } else {
      throw Exception(data["message"] ?? "Login failed");
    }
  }

  // ------------------ GET TOKEN ------------------
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("jwt_token");
  }

  // ------------------ LOGOUT ------------------
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ------------------ FORGOT PASSWORD ------------------
  Future<Map<String, dynamic>> forgotPassword(String loginId) async {
    final url = Uri.parse("$base/forgot-password");
    final resp = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"loginId": loginId}),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      throw Exception("Forgot password failed: ${resp.body}");
    }
  }

  // ------------------ RESET PASSWORD ------------------
  Future<Map<String, dynamic>> resetPassword(
      String loginId, String otp, String newPassword) async {
    final url = Uri.parse("$base/reset-password");
    final resp = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "loginId": loginId,
        "otp": otp,
        "newPassword": newPassword,
      }),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      throw Exception("Reset password failed: ${resp.body}");
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../utils/constants.dart';

class AuthService {
  // 🔹 Using centralized configuration
  static String get base => AppConfig.authUrl;

  // ------------------ COMPLETE REGISTRATION ------------------
  Future<Map<String, dynamic>> completeRegistration({
    required String token,
    required String userName,
    required String password,
  }) async {
    final url = Uri.parse("$base${AppConstants.endpointCompleteRegistration}");
    final resp = await http.post(
      url,
      headers: {
        AppConstants.headerContentType: AppConstants.headerApplicationJson,
      },
      body: jsonEncode({
        AppConstants.keyToken: token,
        AppConstants.keyUserName: userName,
        AppConstants.keyPassword: password,
      }),
    );

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("${AppConstants.errorActivationFailed}: ${resp.statusCode} ${resp.body}");
    }
  }

  // ------------------ LOGIN ------------------
  Future<Map<String, dynamic>> login(String loginId, String password) async {
    final url = Uri.parse("$base${AppConstants.endpointLogin}");
    final resp = await http.post(
      url,
      headers: {
        AppConstants.headerContentType: AppConstants.headerApplicationJson,
      },
      body: jsonEncode({
        AppConstants.keyLoginId: loginId,
        AppConstants.keyPassword: password,
      }),
    );

    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data[AppConstants.keySuccess] == true) {
      final userData = data[AppConstants.keyData];

      final prefs = await SharedPreferences.getInstance();
      
      // Only save the JWT token here
      // Other user data will be saved by AuthBloc._saveUserData()
      await prefs.setString(AppConstants.keyJwtToken, userData[AppConstants.keyToken]);

      return data;
    } else {
      throw Exception(data[AppConstants.keyMessage] ?? AppConstants.errorInvalidCredentials);
    }
  }

  // ------------------ GET TOKEN ------------------
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyJwtToken);
  }

  // ------------------ CHECK IF LOGGED IN ------------------
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyJwtToken);
    final userId = prefs.getInt(AppConstants.keyUserId);
    return token != null && userId != null;
  }

  // ------------------ GET USER ROLE ------------------
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyUserRole);
  }

  // ------------------ LOGOUT ------------------
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear all authentication related data
    await prefs.remove(AppConstants.keyJwtToken);
    await prefs.remove(AppConstants.keyToken);
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyUserName);
    await prefs.remove(AppConstants.keyEmail);
    await prefs.remove(AppConstants.keyUserRole);
    await prefs.remove(AppConstants.keySchoolId);
    await prefs.remove(AppConstants.keySchoolName);
    await prefs.remove(AppConstants.keyOwnerId);
    await prefs.remove(AppConstants.keyDriverId);
    await prefs.remove(AppConstants.keyParentId);
    
    // Clear all data to ensure complete logout
    await prefs.clear();
  }

  // ------------------ FORGOT PASSWORD ------------------
  Future<Map<String, dynamic>> forgotPassword(String loginId) async {
    final url = Uri.parse("$base${AppConstants.endpointForgotPassword}");
    final resp = await http.post(
      url,
      headers: {
        AppConstants.headerContentType: AppConstants.headerApplicationJson,
      },
      body: jsonEncode({
        AppConstants.keyLoginId: loginId,
      }),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      throw Exception("${AppConstants.errorForgotPasswordFailed}: ${resp.body}");
    }
  }

  // ------------------ RESET PASSWORD ------------------
  Future<Map<String, dynamic>> resetPassword(
      String loginId, String otp, String newPassword) async {
    final url = Uri.parse("$base${AppConstants.endpointResetPassword}");
    final resp = await http.post(
      url,
      headers: {
        AppConstants.headerContentType: AppConstants.headerApplicationJson,
      },
      body: jsonEncode({
        AppConstants.keyLoginId: loginId,
        AppConstants.keyOtp: otp,
        AppConstants.keyNewPassword: newPassword,
      }),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      throw Exception("${AppConstants.errorResetPasswordFailed}: ${resp.body}");
    }
  }
}

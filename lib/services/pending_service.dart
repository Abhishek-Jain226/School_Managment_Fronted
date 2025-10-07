import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class PendingService {
  // 🔹 Using centralized configuration
  static String get base => AppConfig.pendingUsersUrl;

  // assumes backend has GET /api/pending-users/verify?token=xxx
  Future<Map<String, dynamic>> verifyToken(String token) async {
    final url = Uri.parse("$base/verify?token=$token");
    final resp = await http.get(url, headers: {"Accept": "application/json"});
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("Verify token failed: ${resp.statusCode} ${resp.body}");
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class PendingService {
  static const String base = "http://10.11.244.208:9001/api/pending-users";

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

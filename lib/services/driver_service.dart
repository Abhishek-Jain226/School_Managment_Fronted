// lib/services/driver_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/driver_request.dart';
import 'auth_service.dart';

class DriverService {
  static const String base = "http://192.168.29.254:9001/api/drivers";
  final AuthService _auth = AuthService();

  Future<Map<String, dynamic>> createDriver(DriverRequest req) async {
    final prefs = await SharedPreferences.getInstance();
    final token = await _auth.getToken();

    final url = Uri.parse("$base/create");
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final body = jsonEncode(req.toJson());
    final resp = await http.post(url, headers: headers, body: body);

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("Driver create failed: ${resp.statusCode} ${resp.body}");
    }
  }
}

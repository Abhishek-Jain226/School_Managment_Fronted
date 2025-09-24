// lib/services/vehicle_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/New_vehicle_request.dart';
import 'auth_service.dart';

class VehicleService {
  static const String base = "http://10.11.244.208:9001/api/vehicles";
  final AuthService _auth = AuthService();

  Future<Map<String, dynamic>> registerVehicle(VehicleRequest req) async {
    final prefs = await SharedPreferences.getInstance();
    final token = await _auth.getToken();

    final url = Uri.parse("$base/register");
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token"
    };

    final resp =
        await http.post(url, headers: headers, body: jsonEncode(req.toJson()));

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      throw Exception("Vehicle register failed: ${resp.body}");
    }
  }

  Future<int> getVehicleCount(String schoolId) async {
    final url = Uri.parse("$base/count/$schoolId");
    final resp = await http.get(url);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data["data"] ?? 0;
    } else {
      throw Exception("Failed to get vehicle count");
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../data/models/trip_request.dart';
import '../data/models/trip_response.dart';
import '../config/app_config.dart';

class TripService {
  // 🔹 Using centralized configuration
  static String get baseUrl => AppConfig.tripsUrl;

  Future<bool> createTrip(TripRequest request) async {
    final url = Uri.parse("$baseUrl/create");
    final resp = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(request.toJson()),
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data["success"] == true;
    }
    return false;
  }

  Future<List<TripResponse>> getTripsBySchool(int schoolId) async {
    final url = Uri.parse("$baseUrl/school/$schoolId");
    final resp = await http.get(url);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data["success"] == true) {
        final List trips = data["data"];
        return trips.map((t) => TripResponse.fromJson(t)).toList();
      }
    }
    return [];
  }

  Future<Map<String, dynamic>> getTripsBySchoolMap(int schoolId) async {
    final url = Uri.parse("$baseUrl/school/$schoolId");
    final resp = await http.get(url);

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    return {"success": false, "message": "Failed to fetch trips"};
  }

  Future<bool> deleteTrip(int tripId) async {
    final url = Uri.parse("$baseUrl/$tripId");
    final resp = await http.delete(url);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data["success"] == true;
    }
    return false;
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../data/models/trip_request.dart';
import '../data/models/trip_response.dart';

class TripService {
  static const String baseUrl = "http://192.168.29.254:9001/api/trips"; // 🔹 replace with your backend URL

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

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/app_config.dart';

class TripStudentService {
  static String get base => AppConfig.baseUrl;
  final AuthService _auth = AuthService();

  /// ---------------- Assign Student to Trip ----------------
  Future<Map<String, dynamic>> assignStudentToTrip({
    required int tripId,
    required int studentId,
    required int pickupOrder,
    required String createdBy,
  }) async {
    final token = await _auth.getToken();
    
    final url = Uri.parse("$base/api/trip-students/assign");
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final body = {
      "tripId": tripId,
      "studentId": studentId,
      "pickupOrder": pickupOrder,
      "createdBy": createdBy,
    };

    print("🔍 TripStudentService: assignStudentToTrip URL: $url");
    print("🔍 TripStudentService: assignStudentToTrip body: $body");

    final resp = await http.post(url, headers: headers, body: jsonEncode(body));
    print("🔍 TripStudentService: assignStudentToTrip response status: ${resp.statusCode}");
    print("🔍 TripStudentService: assignStudentToTrip response body: ${resp.body}");

    return _handleResponse(resp);
  }

  /// ---------------- Update Trip Student Assignment ----------------
  Future<Map<String, dynamic>> updateTripStudent({
    required int tripStudentId,
    int? tripId,
    int? studentId,
    int? pickupOrder,
    String? updatedBy,
  }) async {
    final token = await _auth.getToken();
    
    final url = Uri.parse("$base/api/trip-students/$tripStudentId");
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final body = <String, dynamic>{};
    if (tripId != null) body["tripId"] = tripId;
    if (studentId != null) body["studentId"] = studentId;
    if (pickupOrder != null) body["pickupOrder"] = pickupOrder;
    if (updatedBy != null) body["updatedBy"] = updatedBy;

    print("🔍 TripStudentService: updateTripStudent URL: $url");
    print("🔍 TripStudentService: updateTripStudent body: $body");

    final resp = await http.put(url, headers: headers, body: jsonEncode(body));
    print("🔍 TripStudentService: updateTripStudent response status: ${resp.statusCode}");
    print("🔍 TripStudentService: updateTripStudent response body: ${resp.body}");

    return _handleResponse(resp);
  }

  /// ---------------- Remove Student from Trip ----------------
  Future<Map<String, dynamic>> removeStudentFromTrip(int tripStudentId) async {
    final token = await _auth.getToken();
    
    final url = Uri.parse("$base/api/trip-students/$tripStudentId");
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    print("🔍 TripStudentService: removeStudentFromTrip URL: $url");

    final resp = await http.delete(url, headers: headers);
    print("🔍 TripStudentService: removeStudentFromTrip response status: ${resp.statusCode}");
    print("🔍 TripStudentService: removeStudentFromTrip response body: ${resp.body}");

    return _handleResponse(resp);
  }

  /// ---------------- Get Students by Trip ----------------
  Future<Map<String, dynamic>> getStudentsByTrip(int tripId) async {
    final token = await _auth.getToken();
    
    final url = Uri.parse("$base/api/trip-students/trip/$tripId");
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    print("🔍 TripStudentService: getStudentsByTrip URL: $url");

    final resp = await http.get(url, headers: headers);
    print("🔍 TripStudentService: getStudentsByTrip response status: ${resp.statusCode}");
    print("🔍 TripStudentService: getStudentsByTrip response body: ${resp.body}");

    return _handleResponse(resp);
  }

  /// ---------------- Get All Trip-Student Assignments for a School ----------------
  Future<Map<String, dynamic>> getAllAssignmentsBySchool(int schoolId) async {
    final token = await _auth.getToken();
    
    // This endpoint might need to be created in the backend
    final url = Uri.parse("$base/api/trip-students/school/$schoolId");
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    print("🔍 TripStudentService: getAllAssignmentsBySchool URL: $url");

    final resp = await http.get(url, headers: headers);
    print("🔍 TripStudentService: getAllAssignmentsBySchool response status: ${resp.statusCode}");
    print("🔍 TripStudentService: getAllAssignmentsBySchool response body: ${resp.body}");

    return _handleResponse(resp);
  }

  /// ---------------- Helper method to handle responses ----------------
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("Request failed: ${response.statusCode} ${response.body}");
    }
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
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
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final body = {
      AppConstants.keyTripId: tripId,
      AppConstants.keyStudentId: studentId,
      AppConstants.keyPickupOrder: pickupOrder,
      AppConstants.keyCreatedBy: createdBy,
    };

    debugPrint("🔍 TripStudentService: assignStudentToTrip URL: $url");
    debugPrint("🔍 TripStudentService: assignStudentToTrip body: $body");

    final resp = await http.post(url, headers: headers, body: jsonEncode(body));
    debugPrint("🔍 TripStudentService: assignStudentToTrip response status: ${resp.statusCode}");
    debugPrint("🔍 TripStudentService: assignStudentToTrip response body: ${resp.body}");

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
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final body = <String, dynamic>{};
    if (tripId != null) body[AppConstants.keyTripId] = tripId;
    if (studentId != null) body[AppConstants.keyStudentId] = studentId;
    if (pickupOrder != null) body[AppConstants.keyPickupOrder] = pickupOrder;
    if (updatedBy != null) body[AppConstants.keyUpdatedBy] = updatedBy;

    debugPrint("🔍 TripStudentService: updateTripStudent URL: $url");
    debugPrint("🔍 TripStudentService: updateTripStudent body: $body");

    final resp = await http.put(url, headers: headers, body: jsonEncode(body));
    debugPrint("🔍 TripStudentService: updateTripStudent response status: ${resp.statusCode}");
    debugPrint("🔍 TripStudentService: updateTripStudent response body: ${resp.body}");

    return _handleResponse(resp);
  }

  /// ---------------- Remove Student from Trip ----------------
  Future<Map<String, dynamic>> removeStudentFromTrip(int tripStudentId) async {
    final token = await _auth.getToken();
    
    final url = Uri.parse("$base/api/trip-students/$tripStudentId");
    final headers = {
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    debugPrint("🔍 TripStudentService: removeStudentFromTrip URL: $url");

    final resp = await http.delete(url, headers: headers);
    debugPrint("🔍 TripStudentService: removeStudentFromTrip response status: ${resp.statusCode}");
    debugPrint("🔍 TripStudentService: removeStudentFromTrip response body: ${resp.body}");

    return _handleResponse(resp);
  }

  /// ---------------- Get Students by Trip ----------------
  Future<Map<String, dynamic>> getStudentsByTrip(int tripId) async {
    final token = await _auth.getToken();
    
    final url = Uri.parse("$base/api/trip-students/trip/$tripId");
    final headers = {
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    debugPrint("🔍 TripStudentService: getStudentsByTrip URL: $url");

    final resp = await http.get(url, headers: headers);
    debugPrint("🔍 TripStudentService: getStudentsByTrip response status: ${resp.statusCode}");
    debugPrint("🔍 TripStudentService: getStudentsByTrip response body: ${resp.body}");

    return _handleResponse(resp);
  }

  /// ---------------- Get All Trip-Student Assignments for a School ----------------
  Future<Map<String, dynamic>> getAllAssignmentsBySchool(int schoolId) async {
    final token = await _auth.getToken();
    
    // This endpoint might need to be created in the backend
    final url = Uri.parse("$base/api/trip-students/school/$schoolId");
    final headers = {
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    debugPrint("🔍 TripStudentService: getAllAssignmentsBySchool URL: $url");

    final resp = await http.get(url, headers: headers);
    debugPrint("🔍 TripStudentService: getAllAssignmentsBySchool response status: ${resp.statusCode}");
    debugPrint("🔍 TripStudentService: getAllAssignmentsBySchool response body: ${resp.body}");

    return _handleResponse(resp);
  }

  /// ---------------- Helper method to handle responses ----------------
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("${AppConstants.errorRequestFailed}: ${response.statusCode} ${response.body}");
    }
  }
}

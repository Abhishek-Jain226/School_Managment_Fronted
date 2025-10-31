// lib/services/vehicle_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/New_vehicle_request.dart';
import '../data/models/vehicle.dart';
import 'auth_service.dart';
import '../config/app_config.dart';
import '../utils/constants.dart';

class VehicleService {
  // 🔹 Using centralized configuration
  static String get base => AppConfig.vehiclesUrl;
  final AuthService _auth = AuthService();

  // 🔹 Get Auth Token from SharedPreferences
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyJwtToken);
  }

  Future<Map<String, dynamic>> registerVehicle(VehicleRequest req) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/vehicles/register");
    final headers = {
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token"
    };

    final resp =
        await http.post(url, headers: headers, body: jsonEncode(req.toJson()));

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      throw Exception("${AppConstants.errorVehicleRegisterFailed}: ${resp.body}");
    }
  }

  Future<int> getVehicleCount(String schoolId) async {
    try {
      final token = await _getAuthToken();
      final url = Uri.parse("$base/vehicles/count/$schoolId");
      
      debugPrint('🔍 VehicleService: getVehicleCount URL: $url');
      
      final headers = {
        AppConstants.headerContentType: AppConstants.headerApplicationJson,
        if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
      };
      
      final resp = await http.get(url, headers: headers);
      
      debugPrint('🔍 VehicleService: getVehicleCount response status: ${resp.statusCode}');
      debugPrint('🔍 VehicleService: getVehicleCount response body: ${resp.body}');
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data[AppConstants.keySuccess] == true) {
          return data[AppConstants.keyData] ?? 0;
        } else {
          debugPrint('❌ VehicleService: getVehicleCount failed - ${data[AppConstants.keyMessage]}');
          return 0;
        }
      } else {
        debugPrint('❌ VehicleService: getVehicleCount HTTP error ${resp.statusCode}');
        return 0;
      }
    } catch (e) {
      debugPrint('❌ VehicleService: getVehicleCount exception - $e');
      return 0;
    }
  }
  Future<List<Vehicle>> getVehiclesBySchool(int schoolId) async {
    try {
      final token = await _getAuthToken();
      final url = Uri.parse("$base/vehicles/school/$schoolId");
      
      debugPrint('🔹 VehicleService: getVehiclesBySchool URL: $url');
      
      final headers = {
        AppConstants.headerContentType: AppConstants.headerApplicationJson,
        if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
      };
      
      final resp = await http.get(url, headers: headers);
      
      debugPrint('🔹 VehicleService: getVehiclesBySchool response status: ${resp.statusCode}');
      debugPrint('🔹 VehicleService: getVehiclesBySchool response body: ${resp.body}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data[AppConstants.keySuccess] == true) {
          final List vehicles = data[AppConstants.keyData] ?? [];
          debugPrint('🔹 VehicleService: Found ${vehicles.length} vehicles for school $schoolId');
          return vehicles.map((v) => Vehicle.fromJson(v)).toList();
        } else {
          debugPrint('❌ VehicleService: getVehiclesBySchool failed - ${data[AppConstants.keyMessage]}');
        }
      } else {
        debugPrint('❌ VehicleService: getVehiclesBySchool HTTP error ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ VehicleService: getVehiclesBySchool exception - $e');
    }
    return [];
  }
  // 🔹 Get vehicles by Owner
  Future<Map<String, dynamic>> getVehiclesByOwner(int ownerId) async {
    try {
      final token = await _getAuthToken();
      final headers = {
        AppConstants.headerContentType: AppConstants.headerApplicationJson,
        if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
      };
      
      final resp = await http.get(
        Uri.parse("$base/vehicles/owner/$ownerId"),
        headers: headers,
      );

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body);
      }
      return {AppConstants.keySuccess: false, AppConstants.keyMessage: AppConstants.errorFailedToFetchData};
    } catch (e) {
      return {AppConstants.keySuccess: false, AppConstants.keyMessage: e.toString()};
    }
  }

  // 🔹 Get Pending Requests (Admin side)
Future<Map<String, dynamic>> getPendingRequests(int schoolId) async {
  try {
    final token = await _getAuthToken();
    final headers = {
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };
    
    final resp = await http.get(
      Uri.parse("$base/vehicle-assignments/school/$schoolId/pending"),
      headers: headers,
    );

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    return {AppConstants.keySuccess: false, AppConstants.keyMessage: AppConstants.errorFailedToFetchData};
  } catch (e) {
    return {AppConstants.keySuccess: false, AppConstants.keyMessage: e.toString()};
  }
}

// 🔹 Get ALL Requests for a School (PENDING + APPROVED + REJECTED) - for filtering vehicles
Future<Map<String, dynamic>> getAllRequestsBySchool(int schoolId) async {
  try {
    final token = await _getAuthToken();
    final headers = {
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };
    
    final resp = await http.get(
      Uri.parse("$base/vehicle-assignments/school/$schoolId/all"),
      headers: headers,
    );

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    return {AppConstants.keySuccess: false, AppConstants.keyMessage: AppConstants.errorFailedToFetchData};
  } catch (e) {
    return {AppConstants.keySuccess: false, AppConstants.keyMessage: e.toString()};
  }
}

// 🔹 Get vehicles by Owner Username
Future<Map<String, dynamic>> getVehiclesByCreatedBy(String username) async {
  try {
    final resp = await http.get(Uri.parse("$base/vehicles/owner/username/$username"));

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    return {AppConstants.keySuccess: false, AppConstants.keyMessage: AppConstants.errorFailedToFetchVehicles};
  } catch (e) {
    return {AppConstants.keySuccess: false, AppConstants.keyMessage: e.toString()};
  }
}

// 🔹 Vehicle Owner requests to assign vehicle to school (sends request to School Admin for approval)
Future<Map<String, dynamic>> assignVehicleRequest(Map<String, dynamic> body) async {
  try {
    final token = await _getAuthToken();
    final resp = await http.post(
      Uri.parse("$base/vehicle-assignments/request"),
      headers: {
        AppConstants.headerContentType: AppConstants.headerApplicationJson,
        AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
      },
      body: jsonEncode(body),
    );

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    return {AppConstants.keySuccess: false, AppConstants.keyMessage: AppConstants.errorFailedToSaveData};
  } catch (e) {
    return {AppConstants.keySuccess: false, AppConstants.keyMessage: e.toString()};
  }
}

// 🔹 Update Request Status (Approve/Reject)
Future<Map<String, dynamic>> updateRequestStatus(
    int requestId, String action, String updatedBy) async {
  try {
    final token = await _getAuthToken();
    final endpoint = action == AppConstants.actionApproveLC ? AppConstants.actionApproveLC : AppConstants.actionRejectLC;
    final url = Uri.parse("$base/vehicle-assignments/$requestId/$endpoint?${AppConstants.keyUpdatedBy}=$updatedBy");
    
    debugPrint("🔹 Updating request status: $action for requestId: $requestId");
    debugPrint("🔹 URL: $url");
    
    final resp = await http.put(
      url,
      headers: {
        AppConstants.headerContentType: AppConstants.headerApplicationJson,
        if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
      },
    );

    debugPrint("🔹 Response status: ${resp.statusCode}");
    debugPrint("🔹 Response body: ${resp.body}");

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data;
    }
    return {AppConstants.keySuccess: false, AppConstants.keyMessage: AppConstants.errorFailedToUpdateData};
  } catch (e) {
    debugPrint("❌ Error updating request status: $e");
    return {AppConstants.keySuccess: false, AppConstants.keyMessage: e.toString()};
  }
}

// 🔹 Get UNASSIGNED vehicles by Owner (vehicles not yet assigned to any school)
Future<Map<String, dynamic>> getUnassignedVehiclesByOwner(int ownerId) async {
  try {
    final token = await _getAuthToken();
    final url = Uri.parse("$base/vehicles/owner/$ownerId/unassigned");
    
    debugPrint("🔹 Fetching UNASSIGNED vehicles for ownerId: $ownerId");
    debugPrint("🔹 URL: $url");
    
    final resp = await http.get(
      url,
      headers: {
        AppConstants.headerContentType: AppConstants.headerApplicationJson,
        if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
      },
    );

    debugPrint("🔹 Response status: ${resp.statusCode}");
    debugPrint("🔹 Response body: ${resp.body}");

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data;
    }
    return {AppConstants.keySuccess: false, AppConstants.keyMessage: AppConstants.errorFailedToFetchData};
  } catch (e) {
    debugPrint("❌ Error fetching unassigned vehicles: $e");
    return {AppConstants.keySuccess: false, AppConstants.keyMessage: e.toString()};
  }
}
}

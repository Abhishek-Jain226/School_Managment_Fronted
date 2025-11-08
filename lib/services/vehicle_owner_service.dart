import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../data/models/vehicle_owner_request.dart';
import '../utils/constants.dart';
import 'auth_service.dart';
import '../config/app_config.dart';

class VehicleOwnerService {
  // 🔹 Using centralized configuration
  static String get baseUrl => AppConfig.vehicleOwnersUrl;
  final AuthService _auth = AuthService();
  /// ---------------- Dashboard/Profile/Reports (BLoC helpers) ----------------
  Future<Map<String, dynamic>> getVehicleOwnerDashboard(int ownerId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("${AppConfig.baseUrl}/api/vehicle-owners/$ownerId/dashboard");
    final headers = { if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token" };
    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

  Future<Map<String, dynamic>> getVehicleOwnerProfile(int ownerId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("${AppConfig.baseUrl}/api/vehicle-owners/$ownerId");
    final headers = { if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token" };
    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

  Future<Map<String, dynamic>> updateVehicleOwnerProfile(int ownerId, Map<String, dynamic> ownerData) async {
    final token = await _auth.getToken();
    final url = Uri.parse("${AppConfig.baseUrl}/api/vehicle-owners/$ownerId");
    final headers = {
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };
    final resp = await http.put(url, headers: headers, body: jsonEncode(ownerData));
    return _handleResponse(resp);
  }

  Future<Map<String, dynamic>> getVehicleOwnerReports(int ownerId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("${AppConfig.baseUrl}/api/vehicle-owners/$ownerId/recent-activity");
    final headers = { if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token" };
    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

  /// ---------------- Mutations used by BLoC ----------------
  Future<Map<String, dynamic>> addVehicle(int ownerId, Map<String, dynamic> vehicleData) async {
    final token = await _auth.getToken();
    final url = Uri.parse("${AppConfig.baseUrl}/api/vehicle-owners/$ownerId/vehicles");
    final headers = {
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };
    final resp = await http.post(url, headers: headers, body: jsonEncode(vehicleData));
    return _handleResponse(resp);
  }

  Future<Map<String, dynamic>> addDriver(int ownerId, Map<String, dynamic> driverData) async {
    final token = await _auth.getToken();
    final url = Uri.parse("${AppConfig.baseUrl}/api/vehicle-owners/$ownerId/drivers");
    final headers = {
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };
    final resp = await http.post(url, headers: headers, body: jsonEncode(driverData));
    return _handleResponse(resp);
  }

  Future<Map<String, dynamic>> assignDriver(int ownerId, Map<String, dynamic> payload) async {
    final token = await _auth.getToken();
    final url = Uri.parse("${AppConfig.baseUrl}/api/vehicle-owners/$ownerId/assign-driver");
    final headers = {
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };
    final resp = await http.post(url, headers: headers, body: jsonEncode(payload));
    return _handleResponse(resp);
  }

  /// ---------------- Register Vehicle Owner ----------------
  Future<Map<String, dynamic>> registerVehicleOwner(VehicleOwnerRequest req) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$baseUrl/register");
    final headers = {
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.post(url, headers: headers, body: jsonEncode(req.toJson()));
    return _handleResponse(resp);
  }

  /// ---------------- Activate Vehicle Owner ----------------
  Future<Map<String, dynamic>> activateOwner(int ownerId, String activationCode) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$baseUrl/$ownerId/activate?${AppConstants.keyActivationCode}=$activationCode");
    final headers = {
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.post(url, headers: headers);
    return _handleResponse(resp);
  }

  /// ---------------- Update Vehicle Owner ----------------
  Future<Map<String, dynamic>> updateOwner(int ownerId, VehicleOwnerRequest req) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$baseUrl/$ownerId");
    final headers = {
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.put(url, headers: headers, body: jsonEncode(req.toJson()));
    return _handleResponse(resp);
  }

  /// ---------------- Delete Vehicle Owner ----------------
  Future<Map<String, dynamic>> deleteOwner(int ownerId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$baseUrl/$ownerId");
    final headers = {
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.delete(url, headers: headers);
    return _handleResponse(resp);
  }

  /// ---------------- Get Vehicle Owner By Id ----------------
  Future<Map<String, dynamic>> getOwnerById(int ownerId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$baseUrl/$ownerId");
    final headers = {
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

  /// ---------------- Get All Vehicle Owners for a School ----------------
  Future<Map<String, dynamic>> getAllOwners(int schoolId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$baseUrl/school/$schoolId");
    final headers = {
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

  Future<Map<String, dynamic>> getOwnerByUserId(int userId) async {
  final token = await _auth.getToken();

  final url = Uri.parse("$baseUrl/user/$userId");
  final headers = {
    if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
  };

  final resp = await http.get(url, headers: headers);
  return _handleResponse(resp);
}

  /// ---------------- Get Vehicle Owner Notifications ----------------
  Future<Map<String, dynamic>> getVehicleOwnerNotifications(int userId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("${AppConfig.baseUrl}/api/vehicle-owners/user/$userId/notifications");
    final headers = {
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

  /// ---------------- Get Vehicle Owner Notifications by OwnerId ----------------
  Future<Map<String, dynamic>> getVehicleOwnerNotificationsByOwnerId(int ownerId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("${AppConfig.baseUrl}/api/vehicle-owners/$ownerId/notifications");
    final headers = {
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

/// ---------------- Get Vehicle Owner Dashboard ----------------
Future<Map<String, dynamic>> getVehicleOwnerDashboardLegacy(int ownerId) async {
  final token = await _auth.getToken();
  final url = Uri.parse("${AppConfig.baseUrl}/api/vehicle-owners/$ownerId/dashboard");
  final headers = { if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token" };
  final resp = await http.get(url, headers: headers);
  return _handleResponse(resp);
}

/// ---------------- Get Vehicle Owner Vehicles ----------------
Future<List<dynamic>> getVehicleOwnerVehicles(int ownerId) async {
  final token = await _auth.getToken();
  
  final url = Uri.parse("${AppConfig.baseUrl}/api/vehicle-owners/$ownerId/vehicles");
  final headers = {
    if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
  };

  final resp = await http.get(url, headers: headers);
  final data = _handleResponse(resp);
  
  // Backend returns: {data: {vehicles: [...]}}
  if (data[AppConstants.keyData] is Map && data[AppConstants.keyData][AppConstants.keyVehicles] is List) {
    return data[AppConstants.keyData][AppConstants.keyVehicles] as List<dynamic>;
  } else if (data[AppConstants.keyData] is List) {
    return data[AppConstants.keyData] as List<dynamic>;
  } else {
    return [];
  }
}

/// ---------------- Get Vehicle Owner Drivers ----------------
Future<List<dynamic>> getVehicleOwnerDrivers(int ownerId) async {
  final token = await _auth.getToken();
  
  final url = Uri.parse("${AppConfig.baseUrl}/api/vehicle-owners/$ownerId/drivers");
  final headers = {
    if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
  };

  final resp = await http.get(url, headers: headers);
  final data = _handleResponse(resp);
  
  // Backend returns: {data: {drivers: [...]}}
  if (data[AppConstants.keyData] is Map && data[AppConstants.keyData][AppConstants.keyDrivers] is List) {
    return data[AppConstants.keyData][AppConstants.keyDrivers] as List<dynamic>;
  } else if (data[AppConstants.keyData] is List) {
    return data[AppConstants.keyData] as List<dynamic>;
  } else {
    return [];
  }
}

/// ---------------- Get Vehicle Owner Trips ----------------
Future<List<dynamic>> getVehicleOwnerTrips(int ownerId) async {
  final token = await _auth.getToken();
  
  final url = Uri.parse("${AppConfig.baseUrl}/api/vehicle-owners/$ownerId/trips");
  final headers = {
    if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
  };

  final resp = await http.get(url, headers: headers);
  final data = _handleResponse(resp);
  
  // Backend returns: {data: [...]} (trips list directly)
  if (data[AppConstants.keyData] is List) {
    return data[AppConstants.keyData] as List<dynamic>;
  } else if (data[AppConstants.keyData] is Map && data[AppConstants.keyData][AppConstants.keyTrips] is List) {
    return data[AppConstants.keyData][AppConstants.keyTrips] as List<dynamic>;
  } else {
    return [];
  }
}

  /// ---------------- Associate Existing Vehicle Owner with School ----------------
  Future<Map<String, dynamic>> associateOwnerWithSchool(int ownerId, int schoolId, String createdBy) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$baseUrl/$ownerId/associate-school?${AppConstants.keySchoolId}=$schoolId&${AppConstants.keyCreatedBy}=$createdBy");
    final headers = {
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.post(url, headers: headers);
    return _handleResponse(resp);
  }

  /// ---------------- Get Schools Associated with Vehicle Owner ----------------
  Future<Map<String, dynamic>> getAssociatedSchools(int ownerId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$baseUrl/$ownerId/schools");
    final headers = {
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

  /// ---------------- Get Vehicles by Owner ----------------
  Future<Map<String, dynamic>> getVehiclesByOwner(int ownerId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$baseUrl/$ownerId/vehicles");
    debugPrint("🔍 Frontend: Calling URL: $url");
    final headers = {
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.get(url, headers: headers);
    debugPrint("🔍 Frontend: Response status: ${resp.statusCode}");
    debugPrint("🔍 Frontend: Response body: ${resp.body}");
    return _handleResponse(resp);
  }

  /// ---------------- Get Drivers by Owner ----------------
  Future<Map<String, dynamic>> getDriversByOwner(int ownerId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$baseUrl/$ownerId/drivers");
    debugPrint("🔍 Frontend: getDriversByOwner URL: $url");
    debugPrint("🔍 Frontend: getDriversByOwner ownerId: $ownerId");
    
    final headers = {
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.get(url, headers: headers);
    debugPrint("🔍 Frontend: getDriversByOwner response status: ${resp.statusCode}");
    debugPrint("🔍 Frontend: getDriversByOwner response body: ${resp.body}");
    return _handleResponse(resp);
  }

  /// ---------------- Get Vehicles in Transit by Owner ----------------
  Future<Map<String, dynamic>> getVehiclesInTransitByOwner(int ownerId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$baseUrl/$ownerId/vehicles-in-transit");
    final headers = {
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

  /// ---------------- Get Recent Activity by Owner ----------------
  Future<Map<String, dynamic>> getRecentActivityByOwner(int ownerId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$baseUrl/$ownerId/recent-activity");
    final headers = {
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

  /// ---------------- Get Total Assignments by Owner ----------------
  Future<Map<String, dynamic>> getTotalAssignmentsByOwner(int ownerId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$baseUrl/$ownerId/total-assignments");
    final headers = {
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

  /// ---------------- Get Pending Driver Registrations by Owner ----------------
  Future<Map<String, dynamic>> getPendingDriverRegistrations(int ownerId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$baseUrl/$ownerId/pending-driver-registrations");
    final headers = {
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

  /// ---------------- Assign Driver to Vehicle ----------------
  Future<Map<String, dynamic>> assignDriverToVehicle(Map<String, dynamic> assignmentData) async {
    final token = await _auth.getToken();

    final url = Uri.parse("${AppConfig.baseUrl}/api/vehicle-drivers/assign");
    debugPrint("🔍 Frontend: assignDriverToVehicle URL: $url");
    debugPrint("🔍 Frontend: assignDriverToVehicle data: $assignmentData");
    
    final headers = {
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.post(url, headers: headers, body: jsonEncode(assignmentData));
    debugPrint("🔍 Frontend: assignDriverToVehicle response status: ${resp.statusCode}");
    debugPrint("🔍 Frontend: assignDriverToVehicle response body: ${resp.body}");
    return _handleResponse(resp);
  }

  /// ---------------- Get Driver Assignments ----------------
  Future<Map<String, dynamic>> getDriverAssignments(int ownerId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("${AppConfig.baseUrl}/api/vehicle-drivers/owner/$ownerId/assignments");
    final headers = {
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

  /// ---------------- Remove Driver Assignment ----------------
  Future<Map<String, dynamic>> removeDriverAssignment(int assignmentId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("${AppConfig.baseUrl}/api/vehicle-drivers/$assignmentId");
    final headers = {
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.delete(url, headers: headers);
    return _handleResponse(resp);
  }

  // ================ STUDENT TRIP ASSIGNMENT METHODS ================

  // Note: Trip-Student assignment methods have been moved to TripStudentService
  // Use TripStudentService for all student-trip assignment operations

  /// ---------------- Common Response Handler ----------------
  // ========== TRIP ASSIGNMENT METHODS ==========
  
  /// Get all trips for a vehicle owner
  Future<Map<String, dynamic>> getTripsByOwner(int ownerId) async {
    debugPrint("🔍 Frontend: getTripsByOwner - Owner ID: $ownerId");
    
    final url = Uri.parse("$baseUrl/$ownerId/trips");
    final resp = await http.get(url);
    
    return _handleResponse(resp);
  }
  
  /// Get available vehicles for trip assignment
  Future<Map<String, dynamic>> getAvailableVehiclesForTrip(int ownerId, int schoolId) async {
    debugPrint("🔍 Frontend: getAvailableVehiclesForTrip - Owner ID: $ownerId, School ID: $schoolId");
    
    final url = Uri.parse("$baseUrl/$ownerId/available-vehicles/$schoolId");
    final resp = await http.get(url);
    
    return _handleResponse(resp);
  }
  
  /// Assign trip to vehicle
  Future<Map<String, dynamic>> assignTripToVehicle(int ownerId, int tripId, int vehicleId, String updatedBy) async {
    debugPrint("🔍 Frontend: assignTripToVehicle - Owner ID: $ownerId, Trip ID: $tripId, Vehicle ID: $vehicleId, Updated By: $updatedBy");
    
    final url = Uri.parse("$baseUrl/$ownerId/assign-trip/$tripId/vehicle/$vehicleId?${AppConstants.keyUpdatedBy}=$updatedBy");
    final resp = await http.put(url);
    
    return _handleResponse(resp);
  }

  Map<String, dynamic> _handleResponse(http.Response resp) {
    debugPrint("🔍 Frontend: _handleResponse - Status: ${resp.statusCode}");
    debugPrint("🔍 Frontend: _handleResponse - Body: ${resp.body}");
    
    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data is Map<String, dynamic>) {
      debugPrint("🔍 Frontend: _handleResponse - Success: $data");
      return data;
    } else {
      debugPrint("🔍 Frontend: _handleResponse - Error: ${resp.statusCode} ${resp.body}");
      throw Exception("${AppConstants.errorApiError}: ${resp.statusCode} ${resp.body}");
    }
  }
}

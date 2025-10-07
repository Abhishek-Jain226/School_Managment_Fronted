import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/vehicle_owner_request.dart';
import 'auth_service.dart';
import '../config/app_config.dart';

class VehicleOwnerService {
  // 🔹 Using centralized configuration
  static String get base => AppConfig.vehicleOwnersUrl;
  final AuthService _auth = AuthService();

  /// ---------------- Register Vehicle Owner ----------------
  Future<Map<String, dynamic>> registerVehicleOwner(VehicleOwnerRequest req) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/register");
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.post(url, headers: headers, body: jsonEncode(req.toJson()));
    return _handleResponse(resp);
  }

  /// ---------------- Activate Vehicle Owner ----------------
  Future<Map<String, dynamic>> activateOwner(int ownerId, String activationCode) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$ownerId/activate?activationCode=$activationCode");
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.post(url, headers: headers);
    return _handleResponse(resp);
  }

  /// ---------------- Update Vehicle Owner ----------------
  Future<Map<String, dynamic>> updateOwner(int ownerId, VehicleOwnerRequest req) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$ownerId");
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.put(url, headers: headers, body: jsonEncode(req.toJson()));
    return _handleResponse(resp);
  }

  /// ---------------- Delete Vehicle Owner ----------------
  Future<Map<String, dynamic>> deleteOwner(int ownerId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$ownerId");
    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.delete(url, headers: headers);
    return _handleResponse(resp);
  }

  /// ---------------- Get Vehicle Owner By Id ----------------
  Future<Map<String, dynamic>> getOwnerById(int ownerId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$ownerId");
    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

  /// ---------------- Get All Vehicle Owners for a School ----------------
  Future<Map<String, dynamic>> getAllOwners(int schoolId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/school/$schoolId");
    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

  Future<Map<String, dynamic>> getOwnerByUserId(int userId) async {
  final token = await _auth.getToken();

  final url = Uri.parse("$base/user/$userId");
  final headers = {
    if (token != null) "Authorization": "Bearer $token",
  };

  final resp = await http.get(url, headers: headers);
   print("🔹 Response Body: ${resp.body}");
  return _handleResponse(resp);
}

  /// ---------------- Associate Existing Vehicle Owner with School ----------------
  Future<Map<String, dynamic>> associateOwnerWithSchool(int ownerId, int schoolId, String createdBy) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$ownerId/associate-school?schoolId=$schoolId&createdBy=$createdBy");
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.post(url, headers: headers);
    return _handleResponse(resp);
  }

  /// ---------------- Get Schools Associated with Vehicle Owner ----------------
  Future<Map<String, dynamic>> getAssociatedSchools(int ownerId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$ownerId/schools");
    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

  /// ---------------- Get Vehicles by Owner ----------------
  Future<Map<String, dynamic>> getVehiclesByOwner(int ownerId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$ownerId/vehicles");
    print("🔍 Frontend: Calling URL: $url");
    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    print("🔍 Frontend: Response status: ${resp.statusCode}");
    print("🔍 Frontend: Response body: ${resp.body}");
    return _handleResponse(resp);
  }

  /// ---------------- Get Drivers by Owner ----------------
  Future<Map<String, dynamic>> getDriversByOwner(int ownerId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$ownerId/drivers");
    print("🔍 Frontend: getDriversByOwner URL: $url");
    print("🔍 Frontend: getDriversByOwner ownerId: $ownerId");
    
    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    print("🔍 Frontend: getDriversByOwner response status: ${resp.statusCode}");
    print("🔍 Frontend: getDriversByOwner response body: ${resp.body}");
    return _handleResponse(resp);
  }

  /// ---------------- Get Vehicles in Transit by Owner ----------------
  Future<Map<String, dynamic>> getVehiclesInTransitByOwner(int ownerId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$ownerId/vehicles-in-transit");
    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

  /// ---------------- Get Recent Activity by Owner ----------------
  Future<Map<String, dynamic>> getRecentActivityByOwner(int ownerId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$ownerId/recent-activity");
    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

  /// ---------------- Assign Driver to Vehicle ----------------
  Future<Map<String, dynamic>> assignDriverToVehicle(Map<String, dynamic> assignmentData) async {
    final token = await _auth.getToken();

    final url = Uri.parse("${AppConfig.baseUrl}/api/vehicle-drivers/assign");
    print("🔍 Frontend: assignDriverToVehicle URL: $url");
    print("🔍 Frontend: assignDriverToVehicle data: $assignmentData");
    
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.post(url, headers: headers, body: jsonEncode(assignmentData));
    print("🔍 Frontend: assignDriverToVehicle response status: ${resp.statusCode}");
    print("🔍 Frontend: assignDriverToVehicle response body: ${resp.body}");
    return _handleResponse(resp);
  }

  /// ---------------- Get Driver Assignments ----------------
  Future<Map<String, dynamic>> getDriverAssignments(int ownerId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("${AppConfig.baseUrl}/api/vehicle-drivers/owner/$ownerId/assignments");
    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    return _handleResponse(resp);
  }

  /// ---------------- Remove Driver Assignment ----------------
  Future<Map<String, dynamic>> removeDriverAssignment(int assignmentId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("${AppConfig.baseUrl}/api/vehicle-drivers/$assignmentId");
    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.delete(url, headers: headers);
    return _handleResponse(resp);
  }

  // ================ STUDENT TRIP ASSIGNMENT METHODS ================

  /// ---------------- Get Students for Trip Assignment ----------------
  Future<Map<String, dynamic>> getStudentsForTripAssignment(int ownerId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$ownerId/students");
    print("🔍 Frontend: getStudentsForTripAssignment URL: $url");
    print("🔍 Frontend: getStudentsForTripAssignment ownerId: $ownerId");

    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    print("🔍 Frontend: getStudentsForTripAssignment response status: ${resp.statusCode}");
    print("🔍 Frontend: getStudentsForTripAssignment response body: ${resp.body}");
    return _handleResponse(resp);
  }

  /// ---------------- Get Trips by Owner ----------------
  Future<Map<String, dynamic>> getTripsByOwner(int ownerId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$ownerId/trips");
    print("🔍 Frontend: getTripsByOwner URL: $url");
    print("🔍 Frontend: getTripsByOwner ownerId: $ownerId");

    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    print("🔍 Frontend: getTripsByOwner response status: ${resp.statusCode}");
    print("🔍 Frontend: getTripsByOwner response body: ${resp.body}");
    return _handleResponse(resp);
  }

  /// ---------------- Assign Student to Trip ----------------
  Future<Map<String, dynamic>> assignStudentToTrip(int ownerId, int tripId, int studentId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$ownerId/trips/$tripId/assign-student");
    print("🔍 Frontend: assignStudentToTrip URL: $url");
    print("🔍 Frontend: assignStudentToTrip ownerId: $ownerId, tripId: $tripId, studentId: $studentId");

    final assignmentData = {
      "studentId": studentId,
    };

    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.post(url, headers: headers, body: jsonEncode(assignmentData));
    print("🔍 Frontend: assignStudentToTrip response status: ${resp.statusCode}");
    print("🔍 Frontend: assignStudentToTrip response body: ${resp.body}");
    return _handleResponse(resp);
  }

  /// ---------------- Remove Student from Trip ----------------
  Future<Map<String, dynamic>> removeStudentFromTrip(int ownerId, int tripId, int studentId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$ownerId/trips/$tripId/students/$studentId");
    print("🔍 Frontend: removeStudentFromTrip URL: $url");
    print("🔍 Frontend: removeStudentFromTrip ownerId: $ownerId, tripId: $tripId, studentId: $studentId");

    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.delete(url, headers: headers);
    print("🔍 Frontend: removeStudentFromTrip response status: ${resp.statusCode}");
    print("🔍 Frontend: removeStudentFromTrip response body: ${resp.body}");
    return _handleResponse(resp);
  }

  /// ---------------- Get Trip Students ----------------
  Future<Map<String, dynamic>> getTripStudents(int ownerId, int tripId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/$ownerId/trips/$tripId/students");
    print("🔍 Frontend: getTripStudents URL: $url");
    print("🔍 Frontend: getTripStudents ownerId: $ownerId, tripId: $tripId");

    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    print("🔍 Frontend: getTripStudents response status: ${resp.statusCode}");
    print("🔍 Frontend: getTripStudents response body: ${resp.body}");
    return _handleResponse(resp);
  }

  /// ---------------- Common Response Handler ----------------
  Map<String, dynamic> _handleResponse(http.Response resp) {
    print("🔍 Frontend: _handleResponse - Status: ${resp.statusCode}");
    print("🔍 Frontend: _handleResponse - Body: ${resp.body}");
    
    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data is Map<String, dynamic>) {
      print("🔍 Frontend: _handleResponse - Success: $data");
      return data;
    } else {
      print("🔍 Frontend: _handleResponse - Error: ${resp.statusCode} ${resp.body}");
      throw Exception("API Error: ${resp.statusCode} ${resp.body}");
    }
  }
}

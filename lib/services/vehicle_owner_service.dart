import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/vehicle_owner_request.dart';
import 'auth_service.dart';

class VehicleOwnerService {
  static const String base = "http://192.168.29.254:9001/api/vehicle-owners";
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

  /// ---------------- Common Response Handler ----------------
  Map<String, dynamic> _handleResponse(http.Response resp) {
    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data is Map<String, dynamic>) {
      return data;
    } else {
      throw Exception("API Error: ${resp.statusCode} ${resp.body}");
    }
  }
}

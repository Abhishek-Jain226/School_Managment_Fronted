// lib/services/vehicle_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/New_vehicle_request.dart';
import '../data/models/vehicle.dart';
import 'auth_service.dart';

class VehicleService {
  static const String base = "http://192.168.29.254:9001/api";
  final AuthService _auth = AuthService();

  Future<Map<String, dynamic>> registerVehicle(VehicleRequest req) async {
    final prefs = await SharedPreferences.getInstance();
    final token = await _auth.getToken();

    final url = Uri.parse("$base/vehicles/register");
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
    final url = Uri.parse("$base/vehicles/count/$schoolId");
    final resp = await http.get(url);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data["data"] ?? 0;
    } else {
      throw Exception("Failed to get vehicle count");
    }
  }
  Future<List<Vehicle>> getVehiclesBySchool(int schoolId) async {
    final url = Uri.parse("$base/vehicles/school/$schoolId");
    final resp = await http.get(url);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data["success"] == true) {
        final List vehicles = data["data"];
        return vehicles.map((v) => Vehicle.fromJson(v)).toList();
      }
    }
    return [];
  }
  // 🔹 Get vehicles by Owner
  Future<Map<String, dynamic>> getVehiclesByOwner(int ownerId) async {
    try {
      final resp = await http.get(Uri.parse("$base/vehicles/owner/$ownerId"));

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body);
      }
      return {"success": false, "message": "Failed to fetch vehicles"};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // 🔹 Send Vehicle Assignment Request (Owner side)
Future<Map<String, dynamic>> assignVehicleRequest(Map<String, dynamic> body) async {
  try {
    final resp = await http.post(
      Uri.parse("$base/vehicle-assignments/request"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    return {"success": false, "message": "Failed to send request"};
  } catch (e) {
    return {"success": false, "message": e.toString()};
  }
}

  // 🔹 Get Pending Requests (Admin side)
Future<Map<String, dynamic>> getPendingRequests(int schoolId) async {
  try {
    final resp = await http.get(
      Uri.parse("$base/vehicle-assignments/school/$schoolId/pending"),
    );

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    return {"success": false, "message": "Failed to fetch requests"};
  } catch (e) {
    return {"success": false, "message": e.toString()};
  }
}
// 🔹 Approve / Reject (Admin side)
Future<Map<String, dynamic>> updateRequestStatus(
    int requestId, String action, String updatedBy) async {
  try {
    final resp = await http.put(
      Uri.parse("$base/vehicle-assignments/$requestId/$action?updatedBy=$updatedBy"),
    );

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    return {"success": false, "message": "Failed to update request"};
  } catch (e) {
    return {"success": false, "message": e.toString()};
  }

}
// 🔹 Get vehicles by Owner Username
Future<Map<String, dynamic>> getVehiclesByCreatedBy(String username) async {
  try {
    final resp = await http.get(Uri.parse("$base/vehicles/owner/username/$username"));

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    return {"success": false, "message": "Failed to fetch vehicles"};
  } catch (e) {
    return {"success": false, "message": e.toString()};
  }
}
// 🔹 Assign Vehicle to School
// Future<Map<String, dynamic>> assignVehicleToSchool(Map<String, dynamic> body) async {
//   try {
//     final resp = await http.post(
//       Uri.parse("$base/school-vehicles/assign"),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode(body),
//     );

//     if (resp.statusCode == 200) {
//       return jsonDecode(resp.body);
//     }
//     return {"success": false, "message": "Failed to assign vehicle"};
//   } catch (e) {
//     return {"success": false, "message": e.toString()};
//   }
// }
}

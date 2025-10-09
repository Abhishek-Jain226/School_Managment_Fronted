import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../data/models/api_response.dart';
import '../data/models/school_request.dart';
import '../data/models/staff_request.dart';
import 'auth_service.dart';

class SchoolService {
  final _auth = AuthService();
  // 🔹 Using centralized configuration
  static String get _base => AppConfig.schoolsUrl;

  // ---------------- Register School ----------------
  Future<Map<String, dynamic>> registerSchool(SchoolRequest request) async {
    final url = Uri.parse("$_base/register");
    final resp = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(request.toJson()),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      throw Exception("Failed to register school: ${resp.body}");
    }
  }

  // ---------------- Activate School ----------------
  Future<Map<String, dynamic>> activateSchool(int schoolId, String activationCode) async {
    final url = Uri.parse("$_base/$schoolId/activate?activationCode=$activationCode");
    final token = await _auth.getToken();
    final resp = await http.post(
      url,
      headers: {"Authorization": "Bearer $token"},
    );
    return jsonDecode(resp.body);
  }

  // ---------------- Update School ----------------
  Future<Map<String, dynamic>> updateSchool(int schoolId, SchoolRequest request) async {
    final url = Uri.parse("$_base/$schoolId");
    final token = await _auth.getToken();
    final resp = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(request.toJson()),
    );
    return jsonDecode(resp.body);
  }

  // ---------------- Delete School ----------------
  Future<Map<String, dynamic>> deleteSchool(int schoolId) async {
    final url = Uri.parse("$_base/$schoolId");
    final token = await _auth.getToken();
    final resp = await http.delete(
      url,
      headers: {"Authorization": "Bearer $token"},
    );
    return jsonDecode(resp.body);
  }

  // ---------------- Get School By Id ----------------
  // Future<Map<String, dynamic>> getSchoolById(int schoolId) async {
  //   final url = Uri.parse("$_base/$schoolId");
  //   final token = await _auth.getToken();
  //   final resp = await http.get(
  //     url,
  //     headers: {"Authorization": "Bearer $token"},
  //   );
  //   return jsonDecode(resp.body);
  // }

 // ---------------- Get All Schools ----------------
Future<Map<String, dynamic>> getAllSchools() async {
  final url = Uri.parse(_base);
  final token = await _auth.getToken();
  final resp = await http.get(
    url,
    headers: {"Authorization": "Bearer $token"},
  );

  if (resp.statusCode == 200) {
    return jsonDecode(resp.body); // ye ek Map hoga { success, message, data }
  } else {
    throw Exception("Failed to fetch schools: ${resp.body}");
  }
}
   // ---------------- ✅ Create Staff ----------------
  Future<ApiResponse> createStaff(StaffRequest request) async {
    final url = Uri.parse("${AppConfig.baseUrl}/api/school-admin/create-staff");
    final token = await _auth.getToken();

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return ApiResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to create staff: ${response.body}");
    }}
     // ---------------- Assign Vehicle to School ----------------
  Future<Map<String, dynamic>> assignVehicleToSchool(Map<String, dynamic> body) async {
    final url = Uri.parse("${AppConfig.baseUrl}/api/school-vehicles/assign");
    final token = await _auth.getToken();

    final resp = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      return {
        "success": false,
        "message": "Failed to assign vehicle",
        "error": resp.body,
      };
    }
    
  }

  Future<void> saveSchoolToPrefs(Map<String, dynamic> school) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("school_info", jsonEncode(school));
  }

  Future<dynamic> getSchoolFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("school_info");
    if (data == null) return null;
    return jsonDecode(data);
  }

  // ---------------- Get Vehicles in Transit ----------------
  Future<Map<String, dynamic>> getVehiclesInTransit(int schoolId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$_base/$schoolId/vehicles-in-transit");
    final resp = await http.get(
      url,
      headers: {
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      return {
        'success': false,
        'message': 'Failed to get vehicles in transit: ${resp.statusCode}',
        'data': 0
      };
    }
  }

  // ---------------- Get Today's Attendance ----------------
  Future<Map<String, dynamic>> getTodayAttendance(int schoolId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$_base/$schoolId/today-attendance");
    final resp = await http.get(
      url,
      headers: {
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      return {
        'success': false,
        'message': 'Failed to get today\'s attendance: ${resp.statusCode}',
        'data': {'studentsPresent': 0, 'totalStudents': 0, 'attendanceRate': 0.0}
      };
    }
  }

  // ---------------- Get School by ID ----------------
  Future<Map<String, dynamic>> getSchoolById(int schoolId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$_base/$schoolId");
    final resp = await http.get(
      url,
      headers: {
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      return {
        'success': false,
        'message': 'Failed to get school details: ${resp.statusCode}',
        'data': null
      };
    }
  }

  // ---------------- Get All Staff by School ----------------
  Future<Map<String, dynamic>> getAllStaffBySchool(int schoolId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("${AppConfig.baseUrl}/api/school-admin/school/$schoolId/staff");
    final resp = await http.get(
      url,
      headers: {
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      return {
        'success': false,
        'message': 'Failed to get staff list: ${resp.statusCode}',
        'data': null
      };
    }
  }

  // ---------------- Update Staff Status ----------------
  Future<Map<String, dynamic>> updateStaffStatus(int staffId, bool isActive, String updatedBy) async {
    final token = await _auth.getToken();
    final url = Uri.parse("${AppConfig.baseUrl}/api/school-admin/staff/$staffId/status?isActive=$isActive&updatedBy=$updatedBy");
    final resp = await http.put(
      url,
      headers: {
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      return {
        'success': false,
        'message': 'Failed to update staff status: ${resp.statusCode}',
        'data': null
      };
    }
  }

  // ---------------- Delete Staff ----------------
  Future<Map<String, dynamic>> deleteStaff(int staffId, String updatedBy) async {
    final token = await _auth.getToken();
    final url = Uri.parse("${AppConfig.baseUrl}/api/school-admin/staff/$staffId/delete?updatedBy=$updatedBy");
    final resp = await http.put(
      url,
      headers: {
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      return {
        'success': false,
        'message': 'Failed to delete staff: ${resp.statusCode}',
        'data': null
      };
    }
  }

  // ---------------- Debug: Get Staff by Name ----------------
  Future<Map<String, dynamic>> getStaffByName(int schoolId, String name) async {
    final token = await _auth.getToken();
    final url = Uri.parse("${AppConfig.baseUrl}/api/school-admin/school/$schoolId/staff/debug/$name");
    final resp = await http.get(
      url,
      headers: {
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      return {
        'success': false,
        'message': 'Failed to get staff by name: ${resp.statusCode}',
        'data': null
      };
    }
  }

  // ---------------- Update Staff Role ----------------
  Future<Map<String, dynamic>> updateStaffRole(int staffId, int newRoleId, String updatedBy) async {
    final token = await _auth.getToken();
    final url = Uri.parse("${AppConfig.baseUrl}/api/school-admin/staff/$staffId/role?newRoleId=$newRoleId&updatedBy=$updatedBy");
    final resp = await http.put(
      url,
      headers: {
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      return {
        'success': false,
        'message': 'Failed to update staff role: ${resp.statusCode}',
        'data': null
      };
    }
  }

  // ---------------- Get All Users (Including PARENT) ----------------
  Future<Map<String, dynamic>> getAllUsersBySchool(int schoolId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("${AppConfig.baseUrl}/api/school-admin/school/$schoolId/all-users");
    final resp = await http.get(
      url,
      headers: {
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      return {
        'success': false,
        'message': 'Failed to get all users: ${resp.statusCode}',
        'data': null
      };
    }
  }

  // ---------------- Get Dashboard Statistics ----------------
  Future<Map<String, dynamic>> getDashboardStats(int schoolId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("${AppConfig.baseUrl}/api/school-admin/dashboard/$schoolId");
    final resp = await http.get(
      url,
      headers: {
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      return {
        'success': false,
        'message': 'Failed to get dashboard stats: ${resp.statusCode}',
        'data': null
      };
    }
  }

}

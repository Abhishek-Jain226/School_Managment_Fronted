import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../data/models/api_response.dart';
import '../data/models/school_request.dart';
import '../data/models/staff_request.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class SchoolService {
  final _auth = AuthService();
  // 🔹 Using centralized configuration
  static String get _base => AppConfig.schoolsUrl;

  // ---------------- Register School ----------------
  Future<Map<String, dynamic>> registerSchool(SchoolRequest request) async {
    try {
    final url = Uri.parse("$_base/register");
      debugPrint('🔹 Registering school at URL: $url');
      
    final resp = await http.post(
      url,
        headers: {AppConstants.headerContentType: AppConstants.headerApplicationJson},
      body: jsonEncode(request.toJson()),
    );
      
      debugPrint('🔹 Response status code: ${resp.statusCode}');
      debugPrint('🔹 Response body: ${resp.body}');
      
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        
        // Check if backend returned success: false
        if (data[AppConstants.keySuccess] == false) {
          debugPrint('❌ Backend returned error: ${data[AppConstants.keyMessage]}');
          throw Exception("${AppConstants.errorRegistrationFailed}: ${data[AppConstants.keyMessage] ?? AppConstants.errorUnknown}");
        }
        
        return data;
    } else {
        debugPrint('❌ HTTP Error ${resp.statusCode}: ${resp.body}');
        throw Exception("${AppConstants.errorFailedToRegisterSchool}${resp.statusCode}): ${resp.body}");
      }
    } catch (e) {
      debugPrint('❌ Exception in registerSchool: $e');
      rethrow;
    }
  }

  // ---------------- Activate School ----------------
  Future<Map<String, dynamic>> activateSchool(int schoolId, String activationCode) async {
    final url = Uri.parse("$_base/$schoolId/activate?${AppConstants.keyActivationCode}=$activationCode");
    final token = await _auth.getToken();
    final resp = await http.post(
      url,
      headers: {AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token"},
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
        AppConstants.headerContentType: AppConstants.headerApplicationJson,
        AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
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
      headers: {AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token"},
    );
    return jsonDecode(resp.body);
  }

  // ---------------- Get School By Id ----------------
  // Future<Map<String, dynamic>> getSchoolById(int schoolId) async {
  //   final url = Uri.parse("$_base/$schoolId");
  //   final token = await _auth.getToken();
  //   final resp = await http.get(
  //     url,
  //     headers: {AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token"},
  //   );
  //   return jsonDecode(resp.body);
  // }

 // ---------------- Get All Schools ----------------
Future<Map<String, dynamic>> getAllSchools() async {
  final url = Uri.parse(_base);
  final token = await _auth.getToken();
  final resp = await http.get(
    url,
    headers: {AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token"},
  );

  if (resp.statusCode == 200) {
    return jsonDecode(resp.body); // ye ek Map hoga { success, message, data }
  } else {
    throw Exception("${AppConstants.errorFailedToFetchSchools}: ${resp.body}");
  }
}

// ---------------- Get School Dashboard ----------------
Future<Map<String, dynamic>> getSchoolDashboard(int schoolId) async {
  final url = Uri.parse("${AppConfig.baseUrl}/api/school-admin/dashboard/$schoolId");
  final token = await _auth.getToken();
  final resp = await http.get(
    url,
    headers: {AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token"},
  );

  if (resp.statusCode == 200) {
    return jsonDecode(resp.body);
  } else {
    throw Exception("${AppConstants.errorFailedToFetchSchoolDashboard}: ${resp.body}");
  }
}

// ---------------- Get School Students ----------------
Future<List<dynamic>> getSchoolStudents(int schoolId) async {
  final url = Uri.parse("${AppConfig.baseUrl}/api/students/school/$schoolId");
  final token = await _auth.getToken();
  final resp = await http.get(
    url,
    headers: {AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token"},
  );

  if (resp.statusCode == 200) {
    final data = jsonDecode(resp.body);
    return data[AppConstants.keyData] ?? [];
  } else {
    throw Exception("${AppConstants.errorFailedToFetchSchoolStudents}: ${resp.body}");
  }
}

// ---------------- Get School Staff ----------------
Future<List<dynamic>> getSchoolStaff(int schoolId) async {
  final url = Uri.parse("${AppConfig.baseUrl}/api/school-admin/school/$schoolId/staff");
  final token = await _auth.getToken();
  final resp = await http.get(
    url,
    headers: {AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token"},
  );

  if (resp.statusCode == 200) {
    final data = jsonDecode(resp.body);
    // Backend returns {data: {staffList: [...], totalCount: x, activeCount: y}}
    // We need to extract the staffList
    if (data[AppConstants.keyData] is Map) {
      return (data[AppConstants.keyData][AppConstants.keyStaffList] as List?) ?? [];
    }
    return data[AppConstants.keyData] ?? [];
  } else {
    throw Exception("${AppConstants.errorFailedToFetchSchoolStaff}: ${resp.body}");
  }
}

// ---------------- Get School Vehicles ----------------
Future<List<dynamic>> getSchoolVehicles(int schoolId) async {
  final url = Uri.parse("${AppConfig.baseUrl}/api/vehicles/school/$schoolId");
  final token = await _auth.getToken();
  final resp = await http.get(
    url,
    headers: {AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token"},
  );

  if (resp.statusCode == 200) {
    final data = jsonDecode(resp.body);
    return data[AppConstants.keyData] ?? [];
  } else {
    throw Exception("${AppConstants.errorFailedToFetchSchoolVehicles}: ${resp.body}");
  }
}

// ---------------- Get School Trips ----------------
Future<List<dynamic>> getSchoolTrips(int schoolId) async {
  final url = Uri.parse("${AppConfig.baseUrl}/api/trips/school/$schoolId");
  final token = await _auth.getToken();
  final resp = await http.get(
    url,
    headers: {AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token"},
  );

  if (resp.statusCode == 200) {
    final data = jsonDecode(resp.body);
    return data[AppConstants.keyData] ?? [];
  } else {
    throw Exception("${AppConstants.errorFailedToFetchSchoolTrips}: ${resp.body}");
  }
}

// ---------------- Get School Profile ----------------
Future<Map<String, dynamic>> getSchoolProfile(int schoolId) async {
  final url = Uri.parse("${AppConfig.baseUrl}/api/schools/$schoolId");
  final token = await _auth.getToken();
  final resp = await http.get(url, headers: {
    AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token"
  });
  if (resp.statusCode == 200) {
    return jsonDecode(resp.body);
  } else {
    throw Exception("${AppConstants.errorFailedToFetchSchoolProfile}: ${resp.body}");
  }
}

// ---------------- Update School Profile ----------------
Future<Map<String, dynamic>> updateSchoolProfile(int schoolId, Map<String, dynamic> schoolData) async {
  final url = Uri.parse("${AppConfig.baseUrl}/api/schools/$schoolId");
  final token = await _auth.getToken();
  final resp = await http.put(
    url,
    headers: {
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    },
    body: jsonEncode(schoolData),
  );
  if (resp.statusCode == 200) {
    return jsonDecode(resp.body);
  } else {
    throw Exception("${AppConstants.errorFailedToUpdateSchoolProfile}: ${resp.body}");
  }
}

// ---------------- Get School Reports ----------------
Future<Map<String, dynamic>> getSchoolReports(int schoolId) async {
    final url = Uri.parse("${AppConfig.baseUrl}/api/reports/attendance/$schoolId?${AppConstants.keyFilterType}=${AppConstants.keyFilterTypeAll}");
  final token = await _auth.getToken();
  final resp = await http.get(url, headers: {
    AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token"
  });
  if (resp.statusCode == 200) {
    return jsonDecode(resp.body);
  } else {
    throw Exception("${AppConstants.errorFailedToFetchSchoolReports}: ${resp.body}");
  }
}
   // ---------------- ✅ Create Staff ----------------
  Future<ApiResponse> createStaff(StaffRequest request) async {
    final url = Uri.parse("${AppConfig.baseUrl}/api/school-admin/create-staff");
    final token = await _auth.getToken();

    final response = await http.post(
      url,
      headers: {
        AppConstants.headerContentType: AppConstants.headerApplicationJson,
        AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return ApiResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("${AppConstants.errorFailedToCreateStaff}: ${response.body}");
    }}
     // ---------------- Assign Vehicle to School ----------------
  Future<Map<String, dynamic>> assignVehicleToSchool(Map<String, dynamic> body) async {
    final url = Uri.parse("${AppConfig.baseUrl}/api/school-vehicles/assign");
    final token = await _auth.getToken();

    final resp = await http.post(
      url,
      headers: {
        AppConstants.headerContentType: AppConstants.headerApplicationJson,
        AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
      },
      body: jsonEncode(body),
    );

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      return {
        AppConstants.keySuccess: false,
        AppConstants.keyMessage: AppConstants.errorFailedToAssignVehicle,
        AppConstants.keyError: resp.body,
      };
    }
    
  }

  Future<void> saveSchoolToPrefs(Map<String, dynamic> school) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keySchoolInfo, jsonEncode(school));
  }

  Future<dynamic> getSchoolFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(AppConstants.keySchoolInfo);
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
        if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
      },
    );
    
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      return {
        AppConstants.keySuccess: false,
        AppConstants.keyMessage: '${AppConstants.errorFailedToGetVehiclesInTransit}: ${resp.statusCode}',
        AppConstants.keyData: 0
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
        if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
      },
    );
    
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      return {
        AppConstants.keySuccess: false,
        AppConstants.keyMessage: '${AppConstants.errorFailedToGetTodayAttendance}: ${resp.statusCode}',
        AppConstants.keyData: {
          AppConstants.keyStudentsPresent: 0,
          AppConstants.keyTotalStudents: 0,
          AppConstants.keyAttendanceRate: 0.0
        }
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
        if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
      },
    );
    
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      return {
        AppConstants.keySuccess: false,
        AppConstants.keyMessage: '${AppConstants.errorFailedToGetSchoolDetails}: ${resp.statusCode}',
        AppConstants.keyData: null
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
        if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
      },
    );
    
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      return {
        AppConstants.keySuccess: false,
        AppConstants.keyMessage: '${AppConstants.errorFailedToGetStaffList}: ${resp.statusCode}',
        AppConstants.keyData: null
      };
    }
  }

  // ---------------- Update Staff Status ----------------
  Future<Map<String, dynamic>> updateStaffStatus(int staffId, bool isActive, String updatedBy) async {
    final token = await _auth.getToken();
    final url = Uri.parse("${AppConfig.baseUrl}/api/school-admin/staff/$staffId/status?${AppConstants.keyIsActive}=$isActive&${AppConstants.keyUpdatedBy}=$updatedBy");
    final resp = await http.put(
      url,
      headers: {
        if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
      },
    );
    
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      return {
        AppConstants.keySuccess: false,
        AppConstants.keyMessage: '${AppConstants.errorFailedToUpdateStaffStatus}: ${resp.statusCode}',
        AppConstants.keyData: null
      };
    }
  }

  // ---------------- Update Staff Details ----------------
  Future<Map<String, dynamic>> updateStaffDetails(
    int staffId,
    String name,
    String email,
    String contact,
    String role,
    String joinDate,
    bool isActive,
    String updatedBy,
  ) async {
    final token = await _auth.getToken();
    final url = Uri.parse("${AppConfig.baseUrl}/api/school-admin/staff/$staffId");
    
    final requestBody = {
      AppConstants.keyName: name,
      AppConstants.keyEmail: email,
      AppConstants.keyContact: contact,
      AppConstants.keyRole: role,
      AppConstants.keyJoinDate: joinDate,
      AppConstants.keyIsActive: isActive,
      AppConstants.keyUpdatedBy: updatedBy,
    };
    
    final resp = await http.put(
      url,
      headers: {
        AppConstants.headerContentType: AppConstants.headerApplicationJson,
        if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
      },
      body: jsonEncode(requestBody),
    );
    
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      return {
        AppConstants.keySuccess: false,
        AppConstants.keyMessage: '${AppConstants.errorFailedToUpdateStaffDetails}: ${resp.statusCode}',
        AppConstants.keyData: null
      };
    }
  }

  // ---------------- Delete Staff ----------------
  Future<Map<String, dynamic>> deleteStaff(int staffId, String updatedBy) async {
    final token = await _auth.getToken();
    final url = Uri.parse("${AppConfig.baseUrl}/api/school-admin/staff/$staffId/delete?${AppConstants.keyUpdatedBy}=$updatedBy");
    final resp = await http.put(
      url,
      headers: {
        if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
      },
    );
    
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      return {
        AppConstants.keySuccess: false,
        AppConstants.keyMessage: '${AppConstants.errorFailedToDeleteStaff}: ${resp.statusCode}',
        AppConstants.keyData: null
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
        if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
      },
    );
    
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      return {
        AppConstants.keySuccess: false,
        AppConstants.keyMessage: '${AppConstants.errorFailedToGetStaffByName}: ${resp.statusCode}',
        AppConstants.keyData: null
      };
    }
  }

  // ---------------- Update Staff Role ----------------
  Future<Map<String, dynamic>> updateStaffRole(int staffId, int newRoleId, String updatedBy) async {
    final token = await _auth.getToken();
    final url = Uri.parse("${AppConfig.baseUrl}/api/school-admin/staff/$staffId/role?${AppConstants.keyNewRoleId}=$newRoleId&${AppConstants.keyUpdatedBy}=$updatedBy");
    final resp = await http.put(
      url,
      headers: {
        if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
      },
    );
    
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      return {
        AppConstants.keySuccess: false,
        AppConstants.keyMessage: '${AppConstants.errorFailedToUpdateStaffRole}: ${resp.statusCode}',
        AppConstants.keyData: null
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
        if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
      },
    );
    
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      return {
        AppConstants.keySuccess: false,
        AppConstants.keyMessage: '${AppConstants.errorFailedToGetAllUsers}: ${resp.statusCode}',
        AppConstants.keyData: null
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
        if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
      },
    );
    
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      return {
        AppConstants.keySuccess: false,
        AppConstants.keyMessage: '${AppConstants.errorFailedToGetDashboardStats}: ${resp.statusCode}',
        AppConstants.keyData: null
      };
    }
  }

}

// // lib/services/school_admin_service.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../data/models/api_response.dart';
// import '../data/models/school_admin_request.dart';
// import '../data/models/login_request.dart';
// import '../config.dart';

// class SchoolAdminService {
//   final String base = kSchoolAdminBase; 
//   // e.g., http://localhost:9001/api/schoolAdmin

//   Map<String, String> get _headers => {
//         'Content-Type': 'application/json',
//         'Accept': 'application/json',
//       };

//   /// ---------------- AUTH ----------------
//   Future<ApiResponse> register(SchoolAdminRequest req) async {
//     final url = Uri.parse('$base/register');
//     try {
//       final r = await http.post(
//         url,
//         headers: _headers,
//         body: jsonEncode(req.toJson()),
//       );
//       return _parse(r);
//     } catch (e) {
//       return _error(e);
//     }
//   }
//   Future<ApiResponse> login(LoginRequest req) async {
//     final url = Uri.parse('$base/login');
//     try {
//       final r = await http.post(
//         url,
//         headers: _headers,
//         body: jsonEncode(req.toJson()),
//       );
//       final res = _parse(r);

//       // ✅ Save school data if login successful
//       if (res.success && res.data.isNotEmpty) {
//         final school = SchoolAdminRequest.fromJson(res.data);
//         await saveSchoolData(school);
//       }
//       return res;
//     } catch (e) {
//       return _error(e);
//     }
//   }

//   /// ---------------- CRUD ----------------
//   Future<ApiResponse> getAll() async {
//     try {
//       final r = await http.get(Uri.parse(base), headers: _headers);
//       return _parse(r);
//     } catch (e) {
//       return _error(e);
//     }
//   }

//   Future<ApiResponse> getByUserId(String userId) async {
//     try {
//       final r = await http.get(Uri.parse('$base/$userId'), headers: _headers);
//       return _parse(r);
//     } catch (e) {
//       return _error(e);
//     }
//   }

//   Future<bool> delete(String userId) async {
//     try {
//       final r = await http.delete(Uri.parse('$base/$userId'), headers: _headers);
//       if (r.statusCode == 200) {
//         final json = jsonDecode(r.body);
//         return json['success'] == true;
//       }
//     } catch (_) {}
//     return false;
//   }

//   Future<bool> updateSchool(SchoolAdminRequest req) async {
//     final userId = req.userId;
//     if (userId.isEmpty) return false;

//     final payload = req.toJson();
//     payload.remove('password');
//     payload.remove('confirmPassword');

//     final url = Uri.parse('$base/$userId');
//     try {
//       final r = await http.put(
//         url,
//         headers: _headers,
//         body: jsonEncode(payload),
//       );
//       if (r.statusCode == 200) {
//         final json = jsonDecode(r.body);
//         return json['success'] == true;
//       }
//     } catch (e) {
//       print('Update school error: $e');
//     }
//     return false;
//   }

//   /// ---------------- SCHOOL PROFILE ----------------
//   Future<SchoolAdminRequest?> fetchSchoolByUserId(String userId) async {
//     final url = Uri.parse('$base/byUserId/$userId');
//     try {
//       final r = await http.get(url, headers: _headers);
//       if (r.statusCode == 200) {
//         final json = jsonDecode(r.body);
//         if (json['success'] == true && json['data'] != null) {
//           return SchoolAdminRequest.fromJson(Map<String, dynamic>.from(json['data']));
//         }
//       }
//     } catch (e) {
//       print('Error in fetchSchoolByUserId: $e');
//     }
//     return null;
//   }

//   /// ---------------- STUDENT & VEHICLE COUNTS ----------------
//   // Future<int> getStudentCount(int schoolId) async {
//   //   final url = Uri.parse('$base/studentCount/$schoolId');
//   //   final r = await http.get(url, headers: _headers);
//   //   if (r.statusCode == 200) return int.tryParse(r.body) ?? 0;
//   //   return 0;
//   // }

//   // Future<int> getVehicleCount(int schoolId) async {
//   //   final url = Uri.parse('$base/vehicleCount/$schoolId');
//   //   final r = await http.get(url, headers: _headers);
//   //   if (r.statusCode == 200) return int.tryParse(r.body) ?? 0;
//   //   return 0;
//   // }

//   /// ---------------- LOCAL STORAGE ----------------
//   Future<void> saveSchoolData(SchoolAdminRequest req) async {
//     final prefs = await SharedPreferences.getInstance();
//     final data = req.toJson();
//     data.remove('password');
//     data.remove('confirmPassword');

//     await prefs.setString('schoolData', jsonEncode(data));
//     await prefs.setString('schoolName', req.schoolName);
//     await prefs.setString('userId', req.userId);
//     if (req.schoolId != null) await prefs.setInt('schoolId', req.schoolId!);
//   }

//   Future<SchoolAdminRequest?> getSchoolFromPrefs() async {
//     final prefs = await SharedPreferences.getInstance();
//     final raw = prefs.getString('schoolData');
//     if (raw != null && raw.isNotEmpty) {
//       final decoded = jsonDecode(raw) as Map<String, dynamic>;
//       return SchoolAdminRequest.fromJson(decoded);
//     }
//     return null;
//   }

//   /// ---------------- HELPERS ----------------
//   ApiResponse _parse(http.Response r) {
//     if (r.statusCode == 200 || r.statusCode == 201) {
//       return ApiResponse.fromJson(jsonDecode(r.body));
//     }
//     return ApiResponse(
//       success: false,
//       message: 'HTTP ${r.statusCode}: ${r.reasonPhrase}',
//       data: {}, // ✅ always non-null
//     );
//   }

//   ApiResponse _error(Object e) {
//     return ApiResponse(
//       success: false,
//       message: 'Network error: $e',
//       data: {}, // ✅ always non-null
//     );
//   }
// }

// lib/services/driver_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/driver_request.dart';
import '../data/models/driver_dashboard.dart';
import '../data/models/trip.dart';
import '../data/models/student_attendance.dart';
import '../data/models/notification_request.dart';
import 'auth_service.dart';
import '../config/app_config.dart';

class DriverService {
  // 🔹 Using centralized configuration
  static String get base => AppConfig.driversUrl;
  final AuthService _auth = AuthService();

  Future<Map<String, dynamic>> createDriver(DriverRequest req) async {
    final prefs = await SharedPreferences.getInstance();
    final token = await _auth.getToken();

    final url = Uri.parse("$base/create");
    print("🔍 DriverService: createDriver URL: $url");
    print("🔍 DriverService: createDriver request: ${req.toJson()}");
    
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final body = jsonEncode(req.toJson());
    final resp = await http.post(url, headers: headers, body: body);
    
    print("🔍 DriverService: createDriver response status: ${resp.statusCode}");
    print("🔍 DriverService: createDriver response body: ${resp.body}");

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("Driver create failed: ${resp.statusCode} ${resp.body}");
    }
  }

  // Get driver by userId
  Future<Map<String, dynamic>> getDriverByUserId(int userId) async {
    final token = await _auth.getToken();

    final url = Uri.parse("$base/user/$userId");
    print("🔍 DriverService: getDriverByUserId URL: $url");
    
    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    print("🔍 DriverService: getDriverByUserId response status: ${resp.statusCode}");
    print("🔍 DriverService: getDriverByUserId response body: ${resp.body}");

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("Failed to get driver by userId: ${resp.statusCode} ${resp.body}");
    }
  }

  // Get driver dashboard data
  Future<DriverDashboard> getDriverDashboard(int driverId) async {
    final token = await _auth.getToken();
    
    final url = Uri.parse("$base/dashboard/$driverId");
    print("🔍 DriverService: getDriverDashboard URL: $url");
    print("🔍 DriverService: getDriverDashboard driverId: $driverId");
    
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    print("🔍 DriverService: getDriverDashboard response status: ${resp.statusCode}");
    print("🔍 DriverService: getDriverDashboard response body: ${resp.body}");

    if (resp.statusCode == 200) {
      final responseData = jsonDecode(resp.body) as Map<String, dynamic>;
      print("🔍 DriverService: getDriverDashboard responseData: $responseData");
      
      if (responseData['success'] == true && responseData['data'] != null) {
        return DriverDashboard.fromJson(responseData['data']);
      } else {
        throw Exception("Failed to get driver dashboard: ${responseData['message']}");
      }
    } else {
      throw Exception("Driver dashboard request failed: ${resp.statusCode} ${resp.body}");
    }
  }

  // Get assigned trips for driver
  Future<List<Trip>> getAssignedTrips(int driverId) async {
    final token = await _auth.getToken();
    
    final url = Uri.parse("$base/$driverId/trips");
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);

    if (resp.statusCode == 200) {
      final responseData = jsonDecode(resp.body) as Map<String, dynamic>;
      if (responseData['success'] == true && responseData['data'] != null) {
        final List<dynamic> tripsJson = responseData['data'];
        return tripsJson.map((tripJson) => Trip.fromJson(tripJson)).toList();
      } else {
        throw Exception("Failed to get assigned trips: ${responseData['message']}");
      }
    } else {
      throw Exception("Assigned trips request failed: ${resp.statusCode} ${resp.body}");
    }
  }

  // Get students for a specific trip
  Future<Trip> getTripStudents(int driverId, int tripId) async {
    final token = await _auth.getToken();
    
    final url = Uri.parse("$base/$driverId/trip/$tripId/students");
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);

    if (resp.statusCode == 200) {
      final responseData = jsonDecode(resp.body) as Map<String, dynamic>;
      if (responseData['success'] == true && responseData['data'] != null) {
        return Trip.fromJson(responseData['data']);
      } else {
        throw Exception("Failed to get trip students: ${responseData['message']}");
      }
    } else {
      throw Exception("Trip students request failed: ${resp.statusCode} ${resp.body}");
    }
  }

  // Mark student attendance
  Future<StudentAttendanceResponse> markAttendance(int driverId, StudentAttendanceRequest attendanceData) async {
    final token = await _auth.getToken();
    
    final url = Uri.parse("$base/$driverId/attendance");
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final body = jsonEncode(attendanceData.toJson());
    final resp = await http.post(url, headers: headers, body: body);

    if (resp.statusCode == 200) {
      final responseData = jsonDecode(resp.body) as Map<String, dynamic>;
      return StudentAttendanceResponse.fromJson(responseData);
    } else {
      throw Exception("Mark attendance failed: ${resp.statusCode} ${resp.body}");
    }
  }

  // Send notification to parents
  Future<NotificationResponse> sendNotification(int driverId, NotificationRequest notificationData) async {
    final token = await _auth.getToken();
    
    final url = Uri.parse("$base/$driverId/notify-parents");
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final body = jsonEncode(notificationData.toJson());
    final resp = await http.post(url, headers: headers, body: body);

    if (resp.statusCode == 200) {
      final responseData = jsonDecode(resp.body) as Map<String, dynamic>;
      return NotificationResponse.fromJson(responseData);
    } else {
      throw Exception("Send notification failed: ${resp.statusCode} ${resp.body}");
    }
  }

  // Start trip
  Future<Map<String, dynamic>> startTrip(int driverId, int tripId) async {
    final token = await _auth.getToken();
    
    final url = Uri.parse("$base/$driverId/trip/$tripId/start");
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.post(url, headers: headers);

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("Start trip failed: ${resp.statusCode} ${resp.body}");
    }
  }

  // End trip
  Future<Map<String, dynamic>> endTrip(int driverId, int tripId) async {
    final token = await _auth.getToken();
    
    final url = Uri.parse("$base/$driverId/trip/$tripId/end");
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.post(url, headers: headers);

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("End trip failed: ${resp.statusCode} ${resp.body}");
    }
  }
}

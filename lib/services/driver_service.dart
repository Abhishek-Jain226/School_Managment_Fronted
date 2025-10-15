// lib/services/driver_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/driver_request.dart';
import '../data/models/driver_dashboard.dart';
import '../data/models/driver_profile.dart';
import '../data/models/driver_reports.dart';
import '../data/models/time_based_trips.dart';
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
    print("🔍 DriverService: getAssignedTrips URL: $url");
    print("🔍 DriverService: getAssignedTrips driverId: $driverId");
    
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    print("🔍 DriverService: getAssignedTrips response status: ${resp.statusCode}");
    print("🔍 DriverService: getAssignedTrips response body: ${resp.body}");

    if (resp.statusCode == 200) {
      final responseData = jsonDecode(resp.body) as Map<String, dynamic>;
      print("🔍 DriverService: getAssignedTrips responseData: $responseData");
      
      if (responseData['success'] == true && responseData['data'] != null) {
        final List<dynamic> tripsJson = responseData['data'];
        print("🔍 DriverService: getAssignedTrips tripsJson: $tripsJson");
        return tripsJson.map((tripJson) => Trip.fromJson(tripJson)).toList();
      } else {
        print("🔍 DriverService: getAssignedTrips failed: ${responseData['message']}");
        throw Exception("Failed to get assigned trips: ${responseData['message']}");
      }
    } else {
      print("🔍 DriverService: getAssignedTrips request failed: ${resp.statusCode} ${resp.body}");
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
    print("🔍 DriverService: markAttendance URL: $url");
    print("🔍 DriverService: markAttendance body: $body");
    
    final resp = await http.post(url, headers: headers, body: body);
    print("🔍 DriverService: markAttendance response status: ${resp.statusCode}");
    print("🔍 DriverService: markAttendance response body: ${resp.body}");

    if (resp.statusCode == 200) {
      final responseData = jsonDecode(resp.body) as Map<String, dynamic>;
      return StudentAttendanceResponse.fromJson(responseData);
    } else {
      throw Exception("Mark attendance failed: ${resp.statusCode} ${resp.body}");
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




  // Send notification to parents (CRITICAL FIX)
  Future<NotificationResponse> sendNotification(int driverId, NotificationRequest request) async {
    final token = await _auth.getToken();
    
    final url = Uri.parse("$base/$driverId/notify-parents");
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final body = jsonEncode(request.toJson());
    final resp = await http.post(url, headers: headers, body: body);

    if (resp.statusCode == 200) {
      final responseData = jsonDecode(resp.body) as Map<String, dynamic>;
      return NotificationResponse.fromJson(responseData);
    } else {
      throw Exception("Send notification failed: ${resp.statusCode} ${resp.body}");
    }
  }

  // ================ ENHANCED DRIVER DASHBOARD METHODS ================

  // Get time-based filtered trips
  Future<TimeBasedTrips> getTimeBasedTrips(int driverId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/$driverId/trips/time-based");
    
    print("🔍 DriverService: getTimeBasedTrips URL: $url");
    
    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    print("🔍 DriverService: getTimeBasedTrips response status: ${resp.statusCode}");
    print("🔍 DriverService: getTimeBasedTrips response body: ${resp.body}");

    if (resp.statusCode == 200) {
      final responseData = jsonDecode(resp.body) as Map<String, dynamic>;
      if (responseData['success'] == true && responseData['data'] != null) {
        return TimeBasedTrips.fromJson(responseData['data']);
      } else {
        throw Exception("Failed to get time-based trips: ${responseData['message']}");
      }
    } else {
      throw Exception("Get time-based trips failed: ${resp.statusCode} ${resp.body}");
    }
  }

  // Get driver profile
  Future<DriverProfile> getDriverProfile(int driverId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/$driverId/profile");
    
    print("🔍 DriverService: getDriverProfile URL: $url");
    
    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    print("🔍 DriverService: getDriverProfile response status: ${resp.statusCode}");
    print("🔍 DriverService: getDriverProfile response body: ${resp.body}");

    if (resp.statusCode == 200) {
      final responseData = jsonDecode(resp.body) as Map<String, dynamic>;
      if (responseData['success'] == true && responseData['data'] != null) {
        return DriverProfile.fromJson(responseData['data']);
      } else {
        throw Exception("Failed to get driver profile: ${responseData['message']}");
      }
    } else {
      throw Exception("Get driver profile failed: ${resp.statusCode} ${resp.body}");
    }
  }

  // Update driver profile
  Future<Map<String, dynamic>> updateDriverProfile(int driverId, DriverRequest request) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/$driverId/profile");
    
    print("🔍 DriverService: updateDriverProfile URL: $url");
    print("🔍 DriverService: updateDriverProfile request: ${request.toJson()}");
    
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final body = jsonEncode(request.toJson());
    final resp = await http.put(url, headers: headers, body: body);
    print("🔍 DriverService: updateDriverProfile response status: ${resp.statusCode}");
    print("🔍 DriverService: updateDriverProfile response body: ${resp.body}");

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("Update driver profile failed: ${resp.statusCode} ${resp.body}");
    }
  }

  // Get driver reports
  Future<DriverReports> getDriverReports(int driverId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/$driverId/reports");
    
    print("🔍 DriverService: getDriverReports URL: $url");
    
    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    print("🔍 DriverService: getDriverReports response status: ${resp.statusCode}");
    print("🔍 DriverService: getDriverReports response body: ${resp.body}");

    if (resp.statusCode == 200) {
      final responseData = jsonDecode(resp.body) as Map<String, dynamic>;
      if (responseData['success'] == true && responseData['data'] != null) {
        return DriverReports.fromJson(responseData['data']);
      } else {
        throw Exception("Failed to get driver reports: ${responseData['message']}");
      }
    } else {
      throw Exception("Get driver reports failed: ${resp.statusCode} ${resp.body}");
    }
  }

  // Send 5-minute alert
  Future<Map<String, dynamic>> send5MinuteAlert(int driverId, int tripId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/$driverId/trip/$tripId/alert-5min");
    
    print("🔍 DriverService: send5MinuteAlert URL: $url");
    
    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.post(url, headers: headers);
    print("🔍 DriverService: send5MinuteAlert response status: ${resp.statusCode}");
    print("🔍 DriverService: send5MinuteAlert response body: ${resp.body}");

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("Send 5-minute alert failed: ${resp.statusCode} ${resp.body}");
    }
  }

  // ================ CONTEXT-SENSITIVE STUDENT ACTIONS ================

  // Mark pickup from home (Morning Trip)
  Future<Map<String, dynamic>> markPickupFromHome(int driverId, int tripId, int studentId) async {
    return _markStudentAction(driverId, tripId, studentId, 'pickup-home');
  }

  // Mark drop to school (Morning Trip)
  Future<Map<String, dynamic>> markDropToSchool(int driverId, int tripId, int studentId) async {
    return _markStudentAction(driverId, tripId, studentId, 'drop-school');
  }

  // Mark pickup from school (Afternoon Trip)
  Future<Map<String, dynamic>> markPickupFromSchool(int driverId, int tripId, int studentId) async {
    return _markStudentAction(driverId, tripId, studentId, 'pickup-school');
  }

  // Mark drop to home (Afternoon Trip)
  Future<Map<String, dynamic>> markDropToHome(int driverId, int tripId, int studentId) async {
    return _markStudentAction(driverId, tripId, studentId, 'drop-home');
  }

  // Helper method for context-sensitive student actions
  Future<Map<String, dynamic>> _markStudentAction(int driverId, int tripId, int studentId, String action) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/$driverId/trip/$tripId/student/$studentId/$action");
    
    print("🔍 DriverService: _markStudentAction URL: $url");
    print("🔍 DriverService: _markStudentAction - driverId: $driverId, tripId: $tripId, studentId: $studentId, action: $action");
    
    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.post(url, headers: headers);
    print("🔍 DriverService: _markStudentAction response status: ${resp.statusCode}");
    print("🔍 DriverService: _markStudentAction response body: ${resp.body}");

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("Mark student action failed: ${resp.statusCode} ${resp.body}");
    }
  }

  // ================ TRIP MANAGEMENT METHODS ================

  // End trip
  Future<Map<String, dynamic>> endTrip(int driverId, int tripId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/$driverId/trip/$tripId/end");
    
    print("🔍 DriverService: endTrip URL: $url");
    print("🔍 DriverService: endTrip - driverId: $driverId, tripId: $tripId");
    
    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.post(url, headers: headers);
    print("🔍 DriverService: endTrip response status: ${resp.statusCode}");
    print("🔍 DriverService: endTrip response body: ${resp.body}");

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("End trip failed: ${resp.statusCode} ${resp.body}");
    }
  }

  // ================ LOCATION TRACKING METHODS ================

  // Update driver location
  Future<Map<String, dynamic>> updateDriverLocation(int driverId, double latitude, double longitude) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/$driverId/location");
    
    print("🔍 DriverService: updateDriverLocation URL: $url");
    print("🔍 DriverService: updateDriverLocation - driverId: $driverId, lat: $latitude, lng: $longitude");
    
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final body = jsonEncode({
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });

    final resp = await http.post(url, headers: headers, body: body);
    print("🔍 DriverService: updateDriverLocation response status: ${resp.statusCode}");
    print("🔍 DriverService: updateDriverLocation response body: ${resp.body}");

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("Update driver location failed: ${resp.statusCode} ${resp.body}");
    }
  }
}

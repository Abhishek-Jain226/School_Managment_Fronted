// lib/services/driver_service.dart
import 'package:flutter/foundation.dart';
import '../data/models/driver_request.dart';
import '../data/models/driver_dashboard.dart';
import '../data/models/driver_profile.dart';
import '../data/models/driver_reports.dart';
import '../data/models/trip.dart';
import '../data/models/student_attendance.dart';
import '../data/models/notification_request.dart';
import 'base_http_service.dart';
import '../config/app_config.dart';
import '../utils/constants.dart';

class DriverService extends BaseHttpService {
  // 🔹 Using centralized configuration
  static String get base => AppConfig.driversUrl;

  Future<Map<String, dynamic>> createDriver(DriverRequest req) async {
    try {
      final response = await post("$base/create", body: req.toJson());
      return handleResponse(response, operation: 'Create driver');
    } catch (e) {
      throw Exception(createErrorMessage('Create driver', e));
    }
  }

  // Get driver by userId
  Future<Map<String, dynamic>> getDriverByUserId(int userId) async {
    try {
      final response = await get("$base/user/$userId");
      return handleResponse(response, operation: 'Get driver by userId');
    } catch (e) {
      throw Exception(createErrorMessage('Get driver by userId', e));
    }
  }

  // Get driver dashboard data
  Future<DriverDashboard> getDriverDashboard(int driverId) async {
    try {
      final response = await get("$base/dashboard/$driverId");
      final data = handleResponse(response, operation: 'Get driver dashboard');
      return DriverDashboard.fromJson(data[AppConstants.keyData]);
    } catch (e) {
      throw Exception(createErrorMessage('Get driver dashboard', e));
    }
  }

  // Get assigned trips for driver
  Future<List<Trip>> getAssignedTrips(int driverId) async {
    try {
      final response = await get("$base/$driverId/trips");
      final data = handleResponse(response, operation: 'Get assigned trips');
      final tripsList = data[AppConstants.keyData] as List;
      return tripsList.map((trip) => Trip.fromJson(trip)).toList();
    } catch (e) {
      throw Exception(createErrorMessage('Get assigned trips', e));
    }
  }

  // Get students for a specific trip
  Future<Trip> getTripStudents(int driverId, int tripId) async {
    try {
      final response = await get("$base/$driverId/trip/$tripId/students");
      final data = handleResponse(response, operation: 'Get trip students');
      return Trip.fromJson(data[AppConstants.keyData]);
    } catch (e) {
      throw Exception(createErrorMessage('Get trip students', e));
    }
  }

  // Mark student attendance
  Future<StudentAttendanceResponse> markAttendance(int driverId, StudentAttendanceRequest attendanceData) async {
    try {
      final response = await post("$base/$driverId/attendance", body: attendanceData.toJson());
      final data = handleResponse(response, operation: 'Mark attendance');
      return StudentAttendanceResponse.fromJson(data);
    } catch (e) {
      throw Exception(createErrorMessage('Mark attendance', e));
    }
  }

  // Send notification to parents
  Future<Map<String, dynamic>> sendNotification(int driverId, NotificationRequest notificationData) async {
    try {
      final response = await post("$base/$driverId/notify-parents", body: notificationData.toJson());
      return handleResponse(response, operation: 'Send notification');
    } catch (e) {
      throw Exception(createErrorMessage('Send notification', e));
    }
  }

  // Get time-based trips
  Future<Map<String, dynamic>> getTimeBasedTrips(int driverId) async {
    try {
      final response = await get("$base/$driverId/trips/time-based");
      return handleResponse(response, operation: 'Get time-based trips');
    } catch (e) {
      throw Exception(createErrorMessage('Get time-based trips', e));
    }
  }

  // Get driver profile
  Future<DriverProfile?> getDriverProfile(int driverId) async {
    try {
      final response = await get("$base/$driverId/profile");
      final data = handleResponse(response, operation: 'Get driver profile');
      
      if (data[AppConstants.keyData] == null) {
        debugPrint('⚠️ Driver profile data is null - driver may not be activated or no vehicle assigned');
        return null;
      }
      
      return DriverProfile.fromJson(data[AppConstants.keyData]);
    } catch (e) {
      debugPrint('❌ Error getting driver profile: $e');
      throw Exception(createErrorMessage('Get driver profile', e));
    }
  }

  // Update driver profile
  Future<Map<String, dynamic>> updateDriverProfile(int driverId, DriverRequest profileData) async {
    try {
      final response = await put("$base/$driverId/profile", body: profileData.toJson());
      return handleResponse(response, operation: 'Update driver profile');
    } catch (e) {
      throw Exception(createErrorMessage('Update driver profile', e));
    }
  }

  // Get driver reports
  Future<DriverReports?> getDriverReports(int driverId) async {
    try {
      final response = await get("$base/$driverId/reports");
      final data = handleResponse(response, operation: 'Get driver reports');
      
      if (data[AppConstants.keyData] == null) {
        debugPrint('⚠️ Driver reports data is null - returning empty reports');
        return null;
      }
      
      return DriverReports.fromJson(data[AppConstants.keyData]);
    } catch (e) {
      debugPrint('❌ Error getting driver reports: $e');
      throw Exception(createErrorMessage('Get driver reports', e));
    }
  }

  // Send 5-minute alert
  Future<Map<String, dynamic>> send5MinuteAlert(int driverId, int tripId, int studentId) async {
    try {
      final response = await post("$base/$driverId/trip/$tripId/student/$studentId/alert-5min");
      return handleResponse(response, operation: 'Send 5-minute alert');
    } catch (e) {
      throw Exception(createErrorMessage('Send 5-minute alert', e));
    }
  }

  // Mark pickup from home
  Future<Map<String, dynamic>> markPickupFromHome(int driverId, int tripId, int studentId) async {
    try {
      final response = await post("$base/$driverId/trip/$tripId/student/$studentId/pickup-home");
      return handleResponse(response, operation: 'Mark pickup from home');
    } catch (e) {
      throw Exception(createErrorMessage('Mark pickup from home', e));
    }
  }

  // Mark drop to school
  Future<Map<String, dynamic>> markDropToSchool(int driverId, int tripId, int studentId) async {
    try {
      final response = await post("$base/$driverId/trip/$tripId/student/$studentId/drop-school");
      return handleResponse(response, operation: 'Mark drop to school');
    } catch (e) {
      throw Exception(createErrorMessage('Mark drop to school', e));
    }
  }

  // Mark pickup from school
  Future<Map<String, dynamic>> markPickupFromSchool(int driverId, int tripId, int studentId) async {
    try {
      final response = await post("$base/$driverId/trip/$tripId/student/$studentId/pickup-school");
      return handleResponse(response, operation: 'Mark pickup from school');
    } catch (e) {
      throw Exception(createErrorMessage('Mark pickup from school', e));
    }
  }

  // Mark drop to home
  Future<Map<String, dynamic>> markDropToHome(int driverId, int tripId, int studentId) async {
    try {
      final response = await post("$base/$driverId/trip/$tripId/student/$studentId/drop-home");
      return handleResponse(response, operation: 'Mark drop to home');
    } catch (e) {
      throw Exception(createErrorMessage('Mark drop to home', e));
    }
  }

  // Update driver location
  Future<Map<String, dynamic>> updateDriverLocation(int driverId, double latitude, double longitude) async {
    try {
      final body = {
        AppConstants.keyLatitude: latitude,
        AppConstants.keyLongitude: longitude,
      };
      final response = await post("$base/$driverId/location", body: body);
      return handleResponse(response, operation: 'Update driver location');
    } catch (e) {
      throw Exception(createErrorMessage('Update driver location', e));
    }
  }

  // Get driver location
  Future<Map<String, dynamic>> getDriverLocation(int driverId) async {
    try {
      final response = await get("$base/$driverId/location");
      return handleResponse(response, operation: 'Get driver location');
    } catch (e) {
      throw Exception(createErrorMessage('Get driver location', e));
    }
  }

  // Start trip
  Future<Map<String, dynamic>> startTrip(
    int driverId,
    int tripId,
    double latitude,
    double longitude,
  ) async {
    try {
      final body = {
        'latitude': latitude,
        'longitude': longitude,
      };
      final response = await post("$base/$driverId/trip/$tripId/start", body: body);
      return handleResponse(response, operation: 'Start trip');
    } catch (e) {
      throw Exception(createErrorMessage('Start trip', e));
    }
  }

  // End trip
  Future<Map<String, dynamic>> endTrip(int driverId, int tripId) async {
    try {
      final response = await post("$base/$driverId/trip/$tripId/end");
      return handleResponse(response, operation: 'End trip');
    } catch (e) {
      throw Exception(createErrorMessage('End trip', e));
    }
  }

  // Save location update for active trip
  Future<Map<String, dynamic>> saveLocationUpdate(
    int driverId,
    int tripId,
    double latitude,
    double longitude,
    String? address,
  ) async {
    try {
      final body = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      };
      if (address != null && address.isNotEmpty) {
        body['address'] = address;
      }
      final response = await post(
        "$base/$driverId/trip/$tripId/location",
        body: body,
      );
      return handleResponse(response, operation: 'Save location update');
    } catch (e) {
      throw Exception(createErrorMessage('Save location update', e));
    }
  }
}

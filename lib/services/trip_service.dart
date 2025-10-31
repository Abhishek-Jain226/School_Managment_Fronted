import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/trip_request.dart';
import '../data/models/trip_response.dart';
import '../config/app_config.dart';
import '../utils/constants.dart';

class TripService {
  // 🔹 Using centralized configuration
  static String get baseUrl => AppConfig.tripsUrl;

  // 🔹 Get Auth Token from SharedPreferences
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyJwtToken);
  }

  Future<bool> createTrip(TripRequest request) async {
    try {
      final token = await _getAuthToken();
      final url = Uri.parse("$baseUrl/create");
      
      debugPrint('🔹 TripService: createTrip URL: $url');
      debugPrint('🔹 TripService: Request data: ${jsonEncode(request.toJson())}');
      
      final headers = {
        AppConstants.headerContentType: AppConstants.headerApplicationJson,
        if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
      };
      
      final resp = await http.post(
        url,
        headers: headers,
        body: jsonEncode(request.toJson()),
      );
      
      debugPrint('🔹 TripService: createTrip response status: ${resp.statusCode}');
      debugPrint('🔹 TripService: createTrip response body: ${resp.body}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data[AppConstants.keySuccess] == true) {
          debugPrint('✅ TripService: Trip created successfully');
          return true;
        } else {
          debugPrint('❌ TripService: createTrip failed - ${data[AppConstants.keyMessage]}');
        }
      } else {
        debugPrint('❌ TripService: createTrip HTTP error ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ TripService: createTrip exception - $e');
    }
    return false;
  }

  Future<List<TripResponse>> getTripsBySchool(int schoolId) async {
    try {
      final token = await _getAuthToken();
      final url = Uri.parse("$baseUrl/school/$schoolId");
      
      debugPrint('🔹 TripService: getTripsBySchool URL: $url');
      
      final headers = {
        AppConstants.headerContentType: AppConstants.headerApplicationJson,
        if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
      };

      final resp = await http.get(url, headers: headers);
      
      debugPrint('🔹 TripService: getTripsBySchool response status: ${resp.statusCode}');
      debugPrint('🔹 TripService: getTripsBySchool response body: ${resp.body}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data[AppConstants.keySuccess] == true) {
          final List trips = data[AppConstants.keyData] ?? [];
          debugPrint('✅ TripService: Found ${trips.length} trips for school $schoolId');
          return trips.map((t) => TripResponse.fromJson(t)).toList();
        } else {
          debugPrint('❌ TripService: getTripsBySchool failed - ${data[AppConstants.keyMessage]}');
        }
      } else {
        debugPrint('❌ TripService: getTripsBySchool HTTP error ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ TripService: getTripsBySchool exception - $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> getTripsBySchoolMap(int schoolId) async {
    try {
      final token = await _getAuthToken();
      final url = Uri.parse("$baseUrl/school/$schoolId");
      
      final headers = {
        AppConstants.headerContentType: AppConstants.headerApplicationJson,
        if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
      };

      final resp = await http.get(url, headers: headers);

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('❌ TripService: getTripsBySchoolMap exception - $e');
    }
    return {AppConstants.keySuccess: false, AppConstants.keyMessage: AppConstants.errorFailedToFetchData};
  }

  Future<bool> deleteTrip(int tripId) async {
    try {
      final token = await _getAuthToken();
      final url = Uri.parse("$baseUrl/$tripId");
      
      debugPrint('🔹 TripService: deleteTrip URL: $url');
      
      final headers = {
        AppConstants.headerContentType: AppConstants.headerApplicationJson,
        if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
      };

      final resp = await http.delete(url, headers: headers);
      
      debugPrint('🔹 TripService: deleteTrip response status: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data[AppConstants.keySuccess] == true) {
          debugPrint('✅ TripService: Trip deleted successfully');
          return true;
        }
      }
    } catch (e) {
      debugPrint('❌ TripService: deleteTrip exception - $e');
    }
    return false;
  }
}

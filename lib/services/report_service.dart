// lib/services/report_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import '../config/app_config.dart';

class ReportService {
  static String get base => AppConfig.baseUrl;
  final AuthService _auth = AuthService();

  // Get attendance report
  Future<Map<String, dynamic>> getAttendanceReport(int schoolId, String filterType) async {
    final token = await _auth.getToken();
    
    final url = Uri.parse("$base/api/reports/attendance/$schoolId?filterType=$filterType");
    print("🔍 ReportService: getAttendanceReport URL: $url");
    
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    print("🔍 ReportService: getAttendanceReport response status: ${resp.statusCode}");
    print("🔍 ReportService: getAttendanceReport response body: ${resp.body}");

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("Attendance report request failed: ${resp.statusCode} ${resp.body}");
    }
  }

  // Get dispatch logs report
  Future<Map<String, dynamic>> getDispatchLogsReport(int schoolId, String filterType) async {
    final token = await _auth.getToken();
    
    final url = Uri.parse("$base/api/reports/dispatch-logs/$schoolId?filterType=$filterType");
    print("🔍 ReportService: getDispatchLogsReport URL: $url");
    
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    print("🔍 ReportService: getDispatchLogsReport response status: ${resp.statusCode}");
    print("🔍 ReportService: getDispatchLogsReport response body: ${resp.body}");

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("Dispatch logs report request failed: ${resp.statusCode} ${resp.body}");
    }
  }

  // Get notification logs report
  Future<Map<String, dynamic>> getNotificationLogsReport(int schoolId, String filterType) async {
    final token = await _auth.getToken();
    
    final url = Uri.parse("$base/api/reports/notifications/$schoolId?filterType=$filterType");
    print("🔍 ReportService: getNotificationLogsReport URL: $url");
    
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    print("🔍 ReportService: getNotificationLogsReport response status: ${resp.statusCode}");
    print("🔍 ReportService: getNotificationLogsReport response body: ${resp.body}");

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("Notification logs report request failed: ${resp.statusCode} ${resp.body}");
    }
  }

  // Export report
  Future<Map<String, dynamic>> exportReport(int schoolId, String type, String format) async {
    final token = await _auth.getToken();
    
    final url = Uri.parse("$base/api/reports/export/$schoolId?type=$type&format=$format");
    print("🔍 ReportService: exportReport URL: $url");
    
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final resp = await http.get(url, headers: headers);
    print("🔍 ReportService: exportReport response status: ${resp.statusCode}");
    print("🔍 ReportService: exportReport response body: ${resp.body}");

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("Export report request failed: ${resp.statusCode} ${resp.body}");
    }
  }
}

// lib/services/report_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';
import '../config/app_config.dart';

class ReportService {
  static String get base => AppConfig.baseUrl;
  final AuthService _auth = AuthService();

  // Get attendance report
  Future<Map<String, dynamic>> getAttendanceReport(int schoolId, String filterType) async {
    final token = await _auth.getToken();
    
    final url = Uri.parse("$base/api/reports/attendance/$schoolId?${AppConstants.keyFilterType}=$filterType");
    debugPrint("🔍 ReportService: getAttendanceReport URL: $url");
    
    final headers = {
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.get(url, headers: headers);
    debugPrint("🔍 ReportService: getAttendanceReport response status: ${resp.statusCode}");
    debugPrint("🔍 ReportService: getAttendanceReport response body: ${resp.body}");

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("${AppConstants.errorAttendanceReportFailed}: ${resp.statusCode} ${resp.body}");
    }
  }

  // Get dispatch logs report
  Future<Map<String, dynamic>> getDispatchLogsReport(int schoolId, String filterType) async {
    final token = await _auth.getToken();
    
    final url = Uri.parse("$base/api/reports/dispatch-logs/$schoolId?${AppConstants.keyFilterType}=$filterType");
    debugPrint("🔍 ReportService: getDispatchLogsReport URL: $url");
    
    final headers = {
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.get(url, headers: headers);
    debugPrint("🔍 ReportService: getDispatchLogsReport response status: ${resp.statusCode}");
    debugPrint("🔍 ReportService: getDispatchLogsReport response body: ${resp.body}");

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("${AppConstants.errorDispatchLogsReportFailed}: ${resp.statusCode} ${resp.body}");
    }
  }

  // Get notification logs report
  Future<Map<String, dynamic>> getNotificationLogsReport(int schoolId, String filterType) async {
    final token = await _auth.getToken();
    
    final url = Uri.parse("$base/api/reports/notifications/$schoolId?${AppConstants.keyFilterType}=$filterType");
    debugPrint("🔍 ReportService: getNotificationLogsReport URL: $url");
    
    final headers = {
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.get(url, headers: headers);
    debugPrint("🔍 ReportService: getNotificationLogsReport response status: ${resp.statusCode}");
    debugPrint("🔍 ReportService: getNotificationLogsReport response body: ${resp.body}");

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("${AppConstants.errorNotificationLogsReportFailed}: ${resp.statusCode} ${resp.body}");
    }
  }

  // Export report
  Future<Map<String, dynamic>> exportReport(int schoolId, String type, String format) async {
    final token = await _auth.getToken();
    
    final url = Uri.parse("$base/api/reports/export/$schoolId?${AppConstants.keyType}=$type&${AppConstants.keyFormat}=$format");
    debugPrint("🔍 ReportService: exportReport URL: $url");
    
    final headers = {
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.get(url, headers: headers);
    debugPrint("🔍 ReportService: exportReport response status: ${resp.statusCode}");
    debugPrint("🔍 ReportService: exportReport response body: ${resp.body}");

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("${AppConstants.errorExportReportFailed}: ${resp.statusCode} ${resp.body}");
    }
  }

  // Download report file
  Future<Uint8List> downloadReport(int schoolId, String type, String format) async {
    final token = await _auth.getToken();
    
    final url = Uri.parse("$base/api/reports/download/$schoolId?${AppConstants.keyType}=$type&${AppConstants.keyFormat}=$format");
    debugPrint("🔍 ReportService: downloadReport URL: $url");
    
    final headers = {
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };

    final resp = await http.get(url, headers: headers);
    debugPrint("🔍 ReportService: downloadReport response status: ${resp.statusCode}");

    if (resp.statusCode == 200) {
      return resp.bodyBytes;
    } else {
      throw Exception("${AppConstants.errorDownloadReportFailed}: ${resp.statusCode} ${resp.body}");
    }
  }
}

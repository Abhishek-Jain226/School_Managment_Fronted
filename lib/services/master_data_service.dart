// lib/services/master_data_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/class_master.dart';
import '../data/models/section_master.dart';
import 'auth_service.dart';
import '../config/app_config.dart';

class MasterDataService {
  // 🔹 Using centralized configuration
  static String get _baseUrl => AppConfig.masterDataUrl;
  final AuthService _auth = AuthService();

  // ================ CLASS MASTER APIs ================

  // Get all classes for a school
  Future<Map<String, dynamic>> getAllClasses(int schoolId) async {
    final token = await _auth.getToken();
    final resp = await http.get(
      Uri.parse("$_baseUrl/class-master/all?schoolId=$schoolId"),
      headers: {
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    return _handleResponse(resp);
  }

  // Get all active classes for a school
  Future<Map<String, dynamic>> getAllActiveClasses(int schoolId) async {
    final token = await _auth.getToken();
    final resp = await http.get(
      Uri.parse("$_baseUrl/class-master/active?schoolId=$schoolId"),
      headers: {
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    return _handleResponse(resp);
  }

  // Create class
  Future<Map<String, dynamic>> createClass(ClassMaster classMaster) async {
    final token = await _auth.getToken();
    final resp = await http.post(
      Uri.parse("$_baseUrl/class-master/create"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(classMaster.toJson()),
    );
    return _handleResponse(resp);
  }

  // Update class
  Future<Map<String, dynamic>> updateClass(int classId, ClassMaster classMaster) async {
    final token = await _auth.getToken();
    final resp = await http.put(
      Uri.parse("$_baseUrl/class-master/$classId"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(classMaster.toJson()),
    );
    return _handleResponse(resp);
  }

  // Delete class
  Future<Map<String, dynamic>> deleteClass(int classId) async {
    final token = await _auth.getToken();
    final resp = await http.delete(
      Uri.parse("$_baseUrl/class-master/$classId"),
      headers: {
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    return _handleResponse(resp);
  }

  // Toggle class status
  Future<Map<String, dynamic>> toggleClassStatus(int classId) async {
    final token = await _auth.getToken();
    final resp = await http.patch(
      Uri.parse("$_baseUrl/class-master/$classId/toggle-status"),
      headers: {
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    return _handleResponse(resp);
  }

  // ================ SECTION MASTER APIs ================

  // Get all sections for a school
  Future<Map<String, dynamic>> getAllSections(int schoolId) async {
    final token = await _auth.getToken();
    final resp = await http.get(
      Uri.parse("$_baseUrl/section-master/all?schoolId=$schoolId"),
      headers: {
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    return _handleResponse(resp);
  }

  // Get all active sections for a school
  Future<Map<String, dynamic>> getAllActiveSections(int schoolId) async {
    final token = await _auth.getToken();
    final resp = await http.get(
      Uri.parse("$_baseUrl/section-master/active?schoolId=$schoolId"),
      headers: {
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    return _handleResponse(resp);
  }


  // Create section
  Future<Map<String, dynamic>> createSection(SectionMaster sectionMaster) async {
    final token = await _auth.getToken();
    final resp = await http.post(
      Uri.parse("$_baseUrl/section-master/create"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(sectionMaster.toJson()),
    );
    return _handleResponse(resp);
  }

  // Update section
  Future<Map<String, dynamic>> updateSection(int sectionId, SectionMaster sectionMaster) async {
    final token = await _auth.getToken();
    final resp = await http.put(
      Uri.parse("$_baseUrl/section-master/$sectionId"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(sectionMaster.toJson()),
    );
    return _handleResponse(resp);
  }

  // Delete section
  Future<Map<String, dynamic>> deleteSection(int sectionId) async {
    final token = await _auth.getToken();
    final resp = await http.delete(
      Uri.parse("$_baseUrl/section-master/$sectionId"),
      headers: {
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    return _handleResponse(resp);
  }

  // Toggle section status
  Future<Map<String, dynamic>> toggleSectionStatus(int sectionId) async {
    final token = await _auth.getToken();
    final resp = await http.patch(
      Uri.parse("$_baseUrl/section-master/$sectionId/toggle-status"),
      headers: {
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    return _handleResponse(resp);
  }

  // ================ HELPER METHODS ================

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        'success': false,
        'message': 'Request failed with status: ${response.statusCode}',
        'data': null,
      };
    }
  }
}

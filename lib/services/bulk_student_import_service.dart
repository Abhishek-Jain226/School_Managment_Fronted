import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/bulk_student_import_request.dart';
import '../data/models/bulk_import_result.dart';
import 'auth_service.dart';
import '../config/app_config.dart';

class BulkStudentImportService {
  // 🔹 Using centralized configuration
  static String get base => AppConfig.studentsUrl;
  final AuthService _auth = AuthService();

  /// Import multiple students in bulk
  Future<BulkImportResult> importStudents(BulkStudentImportRequest request) async {
    try {
      // ✅ Pre-request validation
      if (request.students.isEmpty) {
        throw Exception("No students provided for import");
      }
      
      final token = await _auth.getToken();
      if (token == null || token.isEmpty) {
        throw Exception("Authentication token not available");
      }
      
      final response = await http.post(
        Uri.parse("$base/bulk-import"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return BulkImportResult.fromJson(data);
      } else if (response.statusCode == 400) {
        // Bad request - validation errors
        final errorData = jsonDecode(response.body);
        throw Exception("Validation failed: ${errorData['message'] ?? 'Invalid request data'}");
      } else if (response.statusCode == 401) {
        throw Exception("Authentication failed. Please login again.");
      } else if (response.statusCode == 403) {
        throw Exception("Access denied. You don't have permission to import students.");
      } else {
        throw Exception("Server error: ${response.statusCode}. Please try again later.");
      }
    } catch (e) {
      if (e.toString().contains("Exception:")) {
        rethrow; // Re-throw our custom exceptions
      }
      throw Exception("Network error: ${e.toString()}");
    }
  }

  /// Validate students data before import
  Future<BulkImportResult> validateStudents(BulkStudentImportRequest request) async {
    try {
      // ✅ Pre-request validation
      if (request.students.isEmpty) {
        throw Exception("No students provided for validation");
      }
      
      final token = await _auth.getToken();
      if (token == null || token.isEmpty) {
        throw Exception("Authentication token not available");
      }
      
      final response = await http.post(
        Uri.parse("$base/bulk-validate"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return BulkImportResult.fromJson(data);
      } else if (response.statusCode == 400) {
        // Bad request - validation errors
        final errorData = jsonDecode(response.body);
        throw Exception("Validation failed: ${errorData['message'] ?? 'Invalid request data'}");
      } else if (response.statusCode == 401) {
        throw Exception("Authentication failed. Please login again.");
      } else if (response.statusCode == 403) {
        throw Exception("Access denied. You don't have permission to validate students.");
      } else {
        throw Exception("Server error: ${response.statusCode}. Please try again later.");
      }
    } catch (e) {
      if (e.toString().contains("Exception:")) {
        rethrow; // Re-throw our custom exceptions
      }
      throw Exception("Network error: ${e.toString()}");
    }
  }
}

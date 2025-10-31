import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/bulk_student_import_request.dart';
import '../data/models/bulk_import_result.dart';
import '../utils/constants.dart';
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
        throw Exception("${AppConstants.errorNoStudentsProvided} for import");
      }
      
      final token = await _auth.getToken();
      if (token == null || token.isEmpty) {
        throw Exception(AppConstants.errorAuthTokenNotAvailable);
      }
      
      final response = await http.post(
        Uri.parse("$base${AppConstants.endpointBulkImport}"),
        headers: {
          AppConstants.headerContentType: AppConstants.headerApplicationJson,
          AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return BulkImportResult.fromJson(data);
      } else if (response.statusCode == 400) {
        // Bad request - validation errors
        final errorData = jsonDecode(response.body);
        throw Exception("${AppConstants.errorValidationFailed}: ${errorData[AppConstants.keyMessage] ?? AppConstants.errorInvalidRequestData}");
      } else if (response.statusCode == 401) {
        throw Exception(AppConstants.errorAuthenticationFailed);
      } else if (response.statusCode == 403) {
        throw Exception("${AppConstants.errorAccessDenied}. ${AppConstants.errorNoPermissionImport}.");
      } else {
        throw Exception("${AppConstants.errorServerError}: ${response.statusCode}. ${AppConstants.errorTryAgainLater}.");
      }
    } catch (e) {
      if (e.toString().contains("Exception:")) {
        rethrow; // Re-throw our custom exceptions
      }
      throw Exception("${AppConstants.errorNetworkError}: ${e.toString()}");
    }
  }

  /// Validate students data before import
  Future<BulkImportResult> validateStudents(BulkStudentImportRequest request) async {
    try {
      // ✅ Pre-request validation
      if (request.students.isEmpty) {
        throw Exception("${AppConstants.errorNoStudentsProvided} for validation");
      }
      
      final token = await _auth.getToken();
      if (token == null || token.isEmpty) {
        throw Exception(AppConstants.errorAuthTokenNotAvailable);
      }
      
      final response = await http.post(
        Uri.parse("$base${AppConstants.endpointBulkValidate}"),
        headers: {
          AppConstants.headerContentType: AppConstants.headerApplicationJson,
          AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return BulkImportResult.fromJson(data);
      } else if (response.statusCode == 400) {
        // Bad request - validation errors
        final errorData = jsonDecode(response.body);
        throw Exception("${AppConstants.errorValidationFailed}: ${errorData[AppConstants.keyMessage] ?? AppConstants.errorInvalidRequestData}");
      } else if (response.statusCode == 401) {
        throw Exception(AppConstants.errorAuthenticationFailed);
      } else if (response.statusCode == 403) {
        throw Exception("${AppConstants.errorAccessDenied}. ${AppConstants.errorNoPermissionValidate}.");
      } else {
        throw Exception("${AppConstants.errorServerError}: ${response.statusCode}. ${AppConstants.errorTryAgainLater}.");
      }
    } catch (e) {
      if (e.toString().contains("Exception:")) {
        rethrow; // Re-throw our custom exceptions
      }
      throw Exception("${AppConstants.errorNetworkError}: ${e.toString()}");
    }
  }
}

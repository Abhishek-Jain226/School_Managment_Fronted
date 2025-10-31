// lib/services/base_http_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../utils/constants.dart';

/// Base HTTP service class that provides common HTTP functionality
/// to reduce code duplication across all service classes
abstract class BaseHttpService {
  final AuthService _auth = AuthService();

  /// Get common headers for HTTP requests
  Future<Map<String, String>> getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      AppConstants.headerContentType: AppConstants.headerApplicationJson,
    };

    if (includeAuth) {
      final token = await _auth.getToken();
      if (token != null) {
        headers[AppConstants.headerAuthorization] = '${AppConstants.headerBearer}$token';
      }
    }

    return headers;
  }

  /// Make a GET request
  Future<http.Response> get(String url, {bool includeAuth = true}) async {
    final headers = await getHeaders(includeAuth: includeAuth);
    final uri = Uri.parse(url);
    
    try {
      final response = await http.get(uri, headers: headers);
      _logRequest(AppConstants.httpMethodGet, url, null, response.statusCode);
      return response;
    } catch (e) {
      _logError(AppConstants.httpMethodGet, url, e.toString());
      rethrow;
    }
  }

  /// Make a POST request
  Future<http.Response> post(String url, {Map<String, dynamic>? body, bool includeAuth = true}) async {
    final headers = await getHeaders(includeAuth: includeAuth);
    final uri = Uri.parse(url);
    final bodyString = body != null ? jsonEncode(body) : null;
    
    try {
      final response = await http.post(uri, headers: headers, body: bodyString);
      _logRequest(AppConstants.httpMethodPost, url, body, response.statusCode);
      return response;
    } catch (e) {
      _logError(AppConstants.httpMethodPost, url, e.toString());
      rethrow;
    }
  }

  /// Make a PUT request
  Future<http.Response> put(String url, {Map<String, dynamic>? body, bool includeAuth = true}) async {
    final headers = await getHeaders(includeAuth: includeAuth);
    final uri = Uri.parse(url);
    final bodyString = body != null ? jsonEncode(body) : null;
    
    try {
      final response = await http.put(uri, headers: headers, body: bodyString);
      _logRequest(AppConstants.httpMethodPut, url, body, response.statusCode);
      return response;
    } catch (e) {
      _logError(AppConstants.httpMethodPut, url, e.toString());
      rethrow;
    }
  }

  /// Make a DELETE request
  Future<http.Response> delete(String url, {bool includeAuth = true}) async {
    final headers = await getHeaders(includeAuth: includeAuth);
    final uri = Uri.parse(url);
    
    try {
      final response = await http.delete(uri, headers: headers);
      _logRequest(AppConstants.httpMethodDelete, url, null, response.statusCode);
      return response;
    } catch (e) {
      _logError(AppConstants.httpMethodDelete, url, e.toString());
      rethrow;
    }
  }

  /// Handle common response processing
  Map<String, dynamic> handleResponse(http.Response response, {String? operation}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw Exception('${AppConstants.errorFailedToParseResponse}: ${e.toString()}');
      }
    } else {
      String errorMessage = '${AppConstants.errorRequestFailedWithStatus} ${response.statusCode}';
      if (operation != null) {
        errorMessage = '$operation ${AppConstants.errorOperationFailed}: $errorMessage';
      }
      throw Exception('$errorMessage - ${response.body}');
    }
  }

  /// Handle common error responses
  void handleErrorResponse(http.Response response, {String? operation}) {
    try {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      final message = errorData[AppConstants.keyMessage] ?? AppConstants.msgError;
      final fullMessage = operation != null ? '$operation ${AppConstants.errorOperationFailed}: $message' : message;
      throw Exception(fullMessage);
    } catch (e) {
      if (e is Exception) rethrow;
      final fullMessage = operation != null ? '$operation ${AppConstants.errorOperationFailed}: ${response.body}' : response.body;
      throw Exception(fullMessage);
    }
  }

  /// Check if response is successful
  bool isSuccessResponse(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  /// Log HTTP requests for debugging
  void _logRequest(String method, String url, Map<String, dynamic>? body, int statusCode) {
    print('🌐 $method $url - ${AppConstants.logLabelStatus}: $statusCode');
    if (body != null) {
      print('📤 ${AppConstants.logLabelRequestBody}: ${jsonEncode(body)}');
    }
  }

  /// Log HTTP errors
  void _logError(String method, String url, String error) {
    print('❌ $method $url - ${AppConstants.logLabelError}: $error');
  }

  /// Create a standardized error message
  String createErrorMessage(String operation, dynamic error) {
    if (error is Exception) {
      return '$operation ${AppConstants.errorOperationFailed}: ${error.toString()}';
    }
    return '$operation ${AppConstants.errorOperationFailed}: $error';
  }

  /// Validate required fields in request body
  void validateRequiredFields(Map<String, dynamic> body, List<String> requiredFields) {
    for (final field in requiredFields) {
      if (!body.containsKey(field) || body[field] == null) {
        throw Exception('${AppConstants.errorRequiredFieldMissing}: $field');
      }
    }
  }

  /// Convert response to typed data
  T convertResponse<T>(Map<String, dynamic> response, T Function(Map<String, dynamic>) fromJson) {
    try {
      return fromJson(response);
    } catch (e) {
      throw Exception('${AppConstants.errorFailedToConvertResponse}: ${e.toString()}');
    }
  }
}

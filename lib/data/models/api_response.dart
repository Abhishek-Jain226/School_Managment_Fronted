import '../../utils/constants.dart';

class ApiResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic> data; // ✅ make non-nullable

  ApiResponse({required this.success, this.message, Map<String, dynamic>? data})
      : data = data ?? {}; // assign empty map if null

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json[AppConstants.keySuccess] ?? false,
      message: json[AppConstants.keyMessage],
      data: json[AppConstants.keyData] != null
          ? Map<String, dynamic>.from(json[AppConstants.keyData])
          : {}, // always non-null
    );
  }
}

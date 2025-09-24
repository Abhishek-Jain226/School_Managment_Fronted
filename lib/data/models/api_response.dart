class ApiResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic> data; // ✅ make non-nullable

  ApiResponse({required this.success, this.message, Map<String, dynamic>? data})
      : data = data ?? {}; // assign empty map if null

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : {}, // always non-null
    );
  }
}

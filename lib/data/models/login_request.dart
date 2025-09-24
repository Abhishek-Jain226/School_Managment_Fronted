/// lib/data/models/login_request.dart
class LoginRequest {
  final String loginId;   // ✅ username OR mobile number
  final String password;

  LoginRequest({required this.loginId, required this.password});

  Map<String, dynamic> toJson() => {
        'loginId': loginId,
        'password': password,
      };
}

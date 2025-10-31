/// lib/data/models/login_request.dart
import '../../utils/constants.dart';

class LoginRequest {
  final String loginId;   // ✅ username OR mobile number
  final String password;

  LoginRequest({required this.loginId, required this.password});

  Map<String, dynamic> toJson() => {
        AppConstants.keyLoginId: loginId,
        AppConstants.keyPassword: password,
      };
}

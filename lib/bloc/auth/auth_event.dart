import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String loginId;
  final String password;

  const AuthLoginRequested({
    required this.loginId,
    required this.password,
  });

  @override
  List<Object> get props => [loginId, password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthForgotPasswordRequested extends AuthEvent {
  final String loginId;

  const AuthForgotPasswordRequested({required this.loginId});

  @override
  List<Object> get props => [loginId];
}

class AuthResetPasswordRequested extends AuthEvent {
  final String loginId;
  final String otp;
  final String newPassword;

  const AuthResetPasswordRequested({
    required this.loginId,
    required this.otp,
    required this.newPassword,
  });

  @override
  List<Object> get props => [loginId, otp, newPassword];
}

class AuthCheckStatusRequested extends AuthEvent {
  const AuthCheckStatusRequested();
}

class AuthTokenRefreshRequested extends AuthEvent {
  const AuthTokenRefreshRequested();
}

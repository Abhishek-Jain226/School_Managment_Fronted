import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final Map<String, dynamic> userData;
  final String token;
  final List<String> roles;
  final int? userId;
  final int? driverId;
  final int? ownerId;
  final int? schoolId;

  const AuthAuthenticated({
    required this.userData,
    required this.token,
    required this.roles,
    this.userId,
    this.driverId,
    this.ownerId,
    this.schoolId,
  });

  @override
  List<Object?> get props => [
        userData,
        token,
        roles,
        userId,
        driverId,
        ownerId,
        schoolId,
      ];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  final String? errorCode;

  const AuthError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

class AuthForgotPasswordSuccess extends AuthState {
  final String message;

  const AuthForgotPasswordSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

class AuthResetPasswordSuccess extends AuthState {
  final String message;

  const AuthResetPasswordSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

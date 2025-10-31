import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import '../../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  StreamSubscription<Map<String, dynamic>>? _authSubscription;

  AuthBloc({required AuthService authService})
      : _authService = authService,
        super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthForgotPasswordRequested>(_onForgotPasswordRequested);
    on<AuthResetPasswordRequested>(_onResetPasswordRequested);
    on<AuthCheckStatusRequested>(_onCheckStatusRequested);
    on<AuthTokenRefreshRequested>(_onTokenRefreshRequested);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      final response = await _authService.login(
        event.loginId.trim(),
        event.password.trim(),
      );

      if (response[AppConstants.keySuccess] == true) {
        final data = response[AppConstants.keyData];
        final token = data[AppConstants.keyToken] as String;
        final roles = List<String>.from(data[AppConstants.keyRoles] ?? []);
        
        // Extract user information
        final userId = data[AppConstants.keyUserId] as int?;
        final driverId = data[AppConstants.keyDriverId] as int?;
        final ownerId = data[AppConstants.keyOwnerId] as int?;
        final schoolId = data[AppConstants.keySchoolId] as int?;

        // Save user data (token is already persisted by AuthService.login)
        await _saveUserData(data);

        emit(AuthAuthenticated(
          userData: data,
          token: token,
          roles: roles,
          userId: userId,
          driverId: driverId,
          ownerId: ownerId,
          schoolId: schoolId,
        ));
      } else {
        emit(AuthError(
          message: response[AppConstants.keyMessage] ?? AppConstants.errorLoginFailed,
          errorCode: response[AppConstants.keyCode],
        ));
      }
    } catch (e) {
      debugPrint('${AppConstants.errorLoginFailed}: ${e.toString()}');
      emit(AuthError(
        message: '${AppConstants.errorLoginFailed}: ${e.toString()}',
        errorCode: AppConstants.errorCodeLogin,
      ));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      await _authService.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      debugPrint('${AppConstants.errorLogoutFailed}: ${e.toString()}');
      emit(AuthError(
        message: '${AppConstants.errorLogoutFailed}: ${e.toString()}',
        errorCode: AppConstants.errorCodeLogout,
      ));
    }
  }

  Future<void> _onForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      final response = await _authService.forgotPassword(event.loginId);
      
      if (response[AppConstants.keySuccess] == true) {
        emit(AuthForgotPasswordSuccess(
          message: response[AppConstants.keyMessage] ?? AppConstants.msgOtpSentSuccessfully,
        ));
      } else {
        emit(AuthError(
          message: response[AppConstants.keyMessage] ?? AppConstants.errorFailedToSendOtp,
          errorCode: response[AppConstants.keyCode],
        ));
      }
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToSendOtp}: ${e.toString()}');
      emit(AuthError(
        message: '${AppConstants.errorFailedToSendOtp}: ${e.toString()}',
        errorCode: AppConstants.errorCodeForgotPassword,
      ));
    }
  }

  Future<void> _onResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      final response = await _authService.resetPassword(
        event.loginId,
        event.otp,
        event.newPassword,
      );
      
      if (response[AppConstants.keySuccess] == true) {
        emit(AuthResetPasswordSuccess(
          message: response[AppConstants.keyMessage] ?? AppConstants.msgPasswordResetSuccessfully,
        ));
      } else {
        emit(AuthError(
          message: response[AppConstants.keyMessage] ?? AppConstants.errorFailedToResetPassword,
          errorCode: response[AppConstants.keyCode],
        ));
      }
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToResetPassword}: ${e.toString()}');
      emit(AuthError(
        message: '${AppConstants.errorFailedToResetPassword}: ${e.toString()}',
        errorCode: AppConstants.errorCodeResetPassword,
      ));
    }
  }

  Future<void> _onCheckStatusRequested(
    AuthCheckStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final token = await _authService.getToken();
      if (token != null && token.isNotEmpty) {
        // Token exists, try to get user data
        final userData = await _getUserData();
        if (userData != null) {
          final roles = List<String>.from(userData[AppConstants.keyRoles] ?? []);
          final userId = userData[AppConstants.keyUserId] as int?;
          final driverId = userData[AppConstants.keyDriverId] as int?;
          final ownerId = userData[AppConstants.keyOwnerId] as int?;
          final schoolId = userData[AppConstants.keySchoolId] as int?;

          emit(AuthAuthenticated(
            userData: userData,
            token: token,
            roles: roles,
            userId: userId,
            driverId: driverId,
            ownerId: ownerId,
            schoolId: schoolId,
          ));
        } else {
          emit(const AuthUnauthenticated());
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      debugPrint('${AppConstants.errorCheckingAuthStatus}: ${e.toString()}');
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onTokenRefreshRequested(
    AuthTokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final token = await _authService.getToken();
      if (token != null && token.isNotEmpty) {
        // Token refresh logic can be implemented here
        // For now, just check if token is still valid
        emit(const AuthLoading());
        // Add token validation logic here
        add(const AuthCheckStatusRequested());
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      debugPrint('${AppConstants.errorTokenRefreshFailed}: ${e.toString()}');
      emit(AuthError(
        message: '${AppConstants.errorTokenRefreshFailed}: ${e.toString()}',
        errorCode: AppConstants.errorCodeTokenRefresh,
      ));
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save individual fields for easy access
    if (userData[AppConstants.keyUserId] != null) {
      await prefs.setInt(AppConstants.keyUserId, userData[AppConstants.keyUserId]);
    }
    if (userData[AppConstants.keyDriverId] != null) {
      await prefs.setInt(AppConstants.keyDriverId, userData[AppConstants.keyDriverId]);
    }
    if (userData[AppConstants.keyOwnerId] != null) {
      await prefs.setInt(AppConstants.keyOwnerId, userData[AppConstants.keyOwnerId]);
    }
    if (userData[AppConstants.keySchoolId] != null) {
      await prefs.setInt(AppConstants.keySchoolId, userData[AppConstants.keySchoolId]);
    }
    if (userData[AppConstants.keyUserName] != null) {
      await prefs.setString(AppConstants.keyUserName, userData[AppConstants.keyUserName]);
    }
    if (userData[AppConstants.keyEmail] != null) {
      await prefs.setString(AppConstants.keyEmail, userData[AppConstants.keyEmail]);
    }
    if (userData[AppConstants.keyRoles] != null) {
      final roles = List<String>.from(userData[AppConstants.keyRoles]);
      if (roles.isNotEmpty) {
        await prefs.setString(AppConstants.keyRole, roles.first);
      }
    }
    
    // Also save raw user data as JSON string for reference
    await prefs.setString(AppConstants.keyUserData, jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> _getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(AppConstants.keyUserData);
      if (userDataString != null) {
        // Parse user data from string
        // This is a simplified approach - in production, use proper serialization
        return {};
      }
    } catch (e) {
      debugPrint('${AppConstants.errorGettingUserData}: ${e.toString()}');
    }
    return null;
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}

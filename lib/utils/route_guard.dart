import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_routes.dart';
import '../services/auth_service.dart';

class RouteGuard {
  static Future<bool> checkAuthAndRedirect(BuildContext context) async {
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();
    
    if (!isLoggedIn) {
      // User is not logged in, redirect to login
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
      return false;
    }
    
    return true;
  }

  static Future<String?> getCurrentUserRole() async {
    final authService = AuthService();
    return await authService.getUserRole();
  }

  static Future<bool> isAuthorizedForRoute(String routeName) async {
    final userRole = await getCurrentUserRole();
    
    switch (routeName) {
      case AppRoutes.dashboard:
        return userRole == 'SCHOOL_ADMIN';
      case AppRoutes.vehicleOwnerDashboard:
        return userRole == 'VEHICLE_OWNER';
      case AppRoutes.parentDashboard:
        return userRole == 'PARENT';
      case AppRoutes.driverDashboard:
        return userRole == 'DRIVER';
      case AppRoutes.gateStaffDashboard:
        return userRole == 'GATE_STAFF';
      default:
        return true; // Allow access to other routes
    }
  }
}

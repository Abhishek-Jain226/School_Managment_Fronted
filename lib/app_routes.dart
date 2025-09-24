import 'package:flutter/widgets.dart';
import 'package:school_tracker/presentation/pages/activation_screen.dart';
import 'package:school_tracker/presentation/pages/driver_dashboard.dart';
import 'package:school_tracker/presentation/pages/forgot_password_screen.dart';
import 'package:school_tracker/presentation/pages/ownerdashboard.dart';
import 'package:school_tracker/presentation/pages/parent_dashboard_page.dart';
import 'package:school_tracker/presentation/pages/privacy_policy_screen.dart';
import 'package:school_tracker/presentation/pages/register_driver_screen.dart';
import 'package:school_tracker/presentation/pages/register_vehicle_owner_screen.dart';
import 'package:school_tracker/presentation/pages/register_vehicle_screen.dart';
import 'package:school_tracker/presentation/pages/school_profile_page.dart';
import 'package:school_tracker/presentation/pages/vehicle_owner_dashboard_page.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/login_screen.dart';
import 'presentation/pages/register_school_screen.dart';
import 'presentation/pages/register_student_screen.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/pages/add_vehicle_page.dart';

class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const login = '/login';
  static const registerSchool = '/register-school';
  static const dashboard = '/dashboard';
// static const driverDashboard = '/driver-dashboard'; // Driver
   static const ownerDashboard = '/owner-dashboard';
  //static const registerVehicle = '/register-vehicle';
  static const registerStudent = '/register-student';
  // Add this route constant
  static const activation = '/activation';
   static const privacyPolicy = '/privacy-policy'; 

   static const forgotPassword = '/forgot-password';

  // New
  static const schoolProfile = '/school-profile';
  static const editSchool = '/edit-school';

  static const String registerVehicleOwner = "/register-vehicle-owner";

  static const String vehicleOwnerDashboard = "/vehicle-owner-dashboard";

  static const String parentDashboard = '/parent-dashboard';

   static const String registerDriver = '/register-driver';

   static const String driverDashboard = '/driver-dashboard';

   static const String registerVehicle = '/register-vehicle';

  static Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashPage(),
    home: (_) => const HomePage(),
    login: (_) => const LoginScreen(),
    registerSchool: (_) => const RegisterSchoolScreen(),
    dashboard: (_) => const SchoolAdminDashboardPage(), // no argument needed
    //registerVehicle: (_) => const AddVehiclePage(), // no argument needed
   registerStudent: (_) => const RegisterStudentScreen(),
    //driverDashboard: (_) => const DriverDashboard(),
   // ownerDashboard: (_) => const OwnerDashboard(),
    schoolProfile: (context) => const SchoolProfilePage(),
    privacyPolicy: (_) => const PrivacyPolicyScreen(),

    forgotPassword: (_) => const ForgotPasswordScreen(),

    registerVehicleOwner: (_) => const RegisterVehicleOwnerScreen(),

    vehicleOwnerDashboard: (_) => const VehicleOwnerDashboardPage(),

    parentDashboard: (_) => const ParentDashboardPage(),

    registerDriver: (_) => const RegisterDriverScreen(),

    driverDashboard: (context) => const DriverDashboardPage(),

    registerVehicle: (context) => const RegisterVehicleScreen(),

    

    // Add this to the routes map
activation: (context) {
  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  final token = args?['token'] as String? ?? '';
  return ActivationScreen(token: token);
},
  };
}

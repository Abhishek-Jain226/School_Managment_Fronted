import 'package:flutter/widgets.dart';
import 'package:school_tracker/presentation/pages/StudentProfilePage.dart';
import 'package:school_tracker/presentation/pages/activation_screen.dart';
import 'package:school_tracker/presentation/pages/app_admin_dashboard.dart';
import 'package:school_tracker/presentation/pages/app_admin_school_management.dart';
import 'package:school_tracker/presentation/pages/app_admin_profile_page.dart';
import 'package:school_tracker/presentation/pages/create_trip_page.dart';
import 'package:school_tracker/presentation/pages/driver_dashboard.dart';
import 'package:school_tracker/presentation/pages/forgot_password_screen.dart';
import 'package:school_tracker/presentation/pages/gate_staff_dashboard.dart';
import 'package:school_tracker/presentation/pages/ownerdashboard.dart';
import 'package:school_tracker/presentation/pages/parent_dashboard_page.dart';
import 'package:school_tracker/presentation/pages/parent_profile_page.dart';
import 'package:school_tracker/presentation/pages/attendance_history_page.dart';
import 'package:school_tracker/presentation/pages/monthly_report_page.dart';
import 'package:school_tracker/presentation/pages/parent_profile_update_page.dart';
import 'package:school_tracker/presentation/pages/pending_vehicle_requests_page.dart';
import 'package:school_tracker/presentation/pages/privacy_policy_screen.dart';
import 'package:school_tracker/presentation/pages/register_driver_screen.dart';
import 'package:school_tracker/presentation/pages/register_gate_staff.dart';
import 'package:school_tracker/presentation/pages/register_vehicle_owner_screen.dart';
import 'package:school_tracker/presentation/pages/register_vehicle_screen.dart';
import 'package:school_tracker/presentation/pages/reports_screen.dart';
import 'package:school_tracker/presentation/pages/request_vehicle_assignment_page.dart';
import 'package:school_tracker/presentation/pages/school_profile_page.dart';
import 'package:school_tracker/presentation/pages/trips_list_page.dart';
import 'package:school_tracker/presentation/pages/vehicle_owner_dashboard_page.dart';
import 'package:school_tracker/presentation/pages/vehicle_owner_profile.dart';
import 'package:school_tracker/presentation/pages/vehicle_management_page.dart';
import 'package:school_tracker/presentation/pages/staff_management_page.dart';
import 'package:school_tracker/presentation/pages/vehicle_owner_vehicle_management.dart';
import 'package:school_tracker/presentation/pages/vehicle_owner_driver_management.dart';
import 'package:school_tracker/presentation/pages/vehicle_owner_driver_assignment.dart';
import 'package:school_tracker/presentation/pages/vehicle_owner_student_trip_assignment.dart';
import 'package:school_tracker/presentation/pages/vehicle_owner_trip_assignment.dart';
import 'package:school_tracker/presentation/pages/student_management_page.dart';
import 'package:school_tracker/presentation/pages/class_management_page.dart';
import 'package:school_tracker/presentation/pages/section_management_page.dart';
import 'package:school_tracker/presentation/pages/bulk_student_import_page.dart';
import 'package:school_tracker/presentation/pages/notification_page.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/login_screen.dart';
import 'presentation/pages/register_school_screen.dart';
import 'presentation/pages/register_student_screen.dart';
import 'presentation/pages/dashboard_page.dart';

class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const login = '/login';
  static const registerSchool = '/register-school';
  static const dashboard = '/dashboard';
  static const appAdminDashboard = '/app-admin-dashboard';
  static const appAdminSchoolManagement = '/app-admin-school-management';
  static const appAdminProfile = '/app-admin-profile';
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
  static const String attendanceHistory = '/attendance-history';
  static const String monthlyReport = '/monthly-report';
  static const String parentProfileUpdate = '/parent-profile-update';

   static const String registerDriver = '/register-driver';

   static const String driverDashboard = '/driver-dashboard';

     static const String registerVehicle = '/register-vehicle';
     static const String vehicleManagement = '/vehicle-management';

    static const String registerGateStaff = '/register-gate-staff';
    static const String staffManagement = '/staff-management';

     static const String gateStaffDashboard = '/gateStaffDashboard';

     static const String reports = '/reports';

     static const String vehicleOwnerProfile = '/vehicleOwnerProfile';

     //static const String parentProfile = '/parentProfile';

     static const String trips = '/trips';
static const String createTrip = '/createTrip';

    
 static const String studentProfile = '/studentProfile';

  static const requestVehicle = "/request-vehicle";
  static const pendingRequests = "/pending-requests";
  
  // Vehicle Owner Management Pages
  static const vehicleOwnerVehicleManagement = "/vehicle-owner-vehicle-management";
  static const vehicleOwnerDriverManagement = "/vehicle-owner-driver-management";
  static const vehicleOwnerAssignments = "/vehicle-owner-assignments";
  static const vehicleOwnerDriverAssignment = "/vehicle-owner-driver-assignment";
  static const vehicleOwnerStudentTripAssignment = "/vehicle-owner-student-trip-assignment";
  static const vehicleOwnerTripAssignment = "/vehicle-owner-trip-assignment";
  static const studentManagement = "/student-management";
  static const classManagement = "/class-management";
  static const sectionManagement = "/section-management";
  static const bulkStudentImport = "/bulk-student-import";
  static const notification = "/notifications";

  static Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashPage(),
    home: (_) => const HomePage(),
    login: (_) => const LoginScreen(),
    registerSchool: (_) => const RegisterSchoolScreen(),
    dashboard: (_) => const SchoolAdminDashboardPage(), // no argument needed
    appAdminDashboard: (_) => const AppAdminDashboardPage(),
    appAdminSchoolManagement: (_) => const AppAdminSchoolManagementPage(),
    appAdminProfile: (_) => const AppAdminProfilePage(),
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
    attendanceHistory: (_) => const AttendanceHistoryPage(),
    monthlyReport: (_) => const MonthlyReportPage(),
    parentProfileUpdate: (_) => const ParentProfileUpdatePage(),

    registerDriver: (_) => const RegisterDriverScreen(),

    driverDashboard: (context) => const DriverDashboardPage(),

    registerVehicle: (context) => const RegisterVehicleScreen(),
    vehicleManagement: (context) => const VehicleManagementPage(),

    registerGateStaff: (context) => RegisterGateStaffPage(),
    staffManagement: (context) => const StaffManagementPage(),

     gateStaffDashboard: (context) => GateStaffDashboardPage(),

      reports: (context) => ReportsScreen(),

       trips: (context) => TripsListPage(),
  createTrip: (context) => CreateTripPage(),

  pendingRequests: (context) => const PendingVehicleRequestsPage(),

  requestVehicle: (context) => const RequestVehicleAssignmentPage(),
  
  // Vehicle Owner Management Routes
  vehicleOwnerVehicleManagement: (context) => const VehicleOwnerVehicleManagementPage(),
  vehicleOwnerDriverManagement: (context) => const VehicleOwnerDriverManagementPage(),
  //vehicleOwnerAssignments: (context) => const VehicleOwnerAssignmentsPage(),
  vehicleOwnerDriverAssignment: (context) => const VehicleOwnerDriverAssignmentPage(),
  vehicleOwnerStudentTripAssignment: (context) => const VehicleOwnerStudentTripAssignmentPage(),
  vehicleOwnerTripAssignment: (context) => const VehicleOwnerTripAssignmentPage(),
  studentManagement: (context) => const StudentManagementPage(),

      vehicleOwnerProfile: (context) {
  final ownerId = ModalRoute.of(context)!.settings.arguments as int;
  return VehicleOwnerProfilePage(ownerId: ownerId);
},

// parentProfile: (context) {
//   final parentId = ModalRoute.of(context)!.settings.arguments as int;
//   return ParentProfilePage(parentId: parentId);
// },
studentProfile: (context) {
          final studentId = ModalRoute.of(context)!.settings.arguments as int;
          return StudentProfilePage(studentId: studentId);
    },

    

    // Add this to the routes map
activation: (context) {
  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  final token = args?['token'] as String? ?? '';
  return ActivationScreen(token: token);
},

    // Master Data Management Routes
    classManagement: (context) => const ClassManagementPage(),
    sectionManagement: (context) => const SectionManagementPage(),
    bulkStudentImport: (context) => const BulkStudentImportPage(),
    
    // Notification Route
    notification: (context) => const NotificationPage(),
    
  };
}

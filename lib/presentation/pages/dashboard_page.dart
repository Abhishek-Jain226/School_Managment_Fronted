import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:school_tracker/presentation/pages/school_profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_routes.dart';
import '../../services/school_service.dart';
import '../../services/student_service.dart';
import '../../services/vehicle_service.dart';
import '../../services/auth_service.dart';

class SchoolAdminDashboardPage extends StatefulWidget {
  const SchoolAdminDashboardPage({super.key});

  @override
  State<SchoolAdminDashboardPage> createState() =>
      _SchoolAdminDashboardPageState();
}

class _SchoolAdminDashboardPageState extends State<SchoolAdminDashboardPage> {
  int totalStudents = 0;
  int totalVehicles = 0;
  String todayAttendance = 'N/A';
  int vehiclesInTransit = 0;

  bool _isLoading = true;
  bool _hasError = false;

  // Admin & School info
  String adminName = '';
  String schoolName = '';
  String? schoolPhoto;
  int? schoolId;

  final SchoolService _schoolService = SchoolService();

  List<Map<String, String>> recentNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  /// Load data from SharedPreferences + services
  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final prefs = await SharedPreferences.getInstance();

      // ✅ Always load from prefs first
      adminName = prefs.getString("userName") ?? "";
      schoolName = prefs.getString("schoolName") ?? "";
      schoolId = prefs.getInt("schoolId");
      schoolPhoto = prefs.getString("schoolPhoto");

      // ✅ fallback to school service if available
      final school = await _schoolService.getSchoolFromPrefs();
      if (school != null) {
        schoolId ??= school.schoolId;
        schoolPhoto ??= school.schoolPhoto;
      }
      
      // ✅ If still no photo, try to load from school profile
      if (schoolPhoto == null || schoolPhoto!.isEmpty) {
        try {
          final schoolProfile = await _schoolService.getSchoolById(schoolId!);
          if (schoolProfile['success'] == true && schoolProfile['data'] != null) {
            final schoolData = schoolProfile['data'];
            if (schoolData['schoolPhoto'] != null && schoolData['schoolPhoto'].toString().isNotEmpty) {
              schoolPhoto = schoolData['schoolPhoto'];
              // Save to SharedPreferences for future use
              await prefs.setString("schoolPhoto", schoolPhoto!);
            }
          }
        } catch (e) {
          debugPrint("Error loading school photo: $e");
        }
      }

      // ✅ Load counts if we have schoolId
      if (schoolId != null) {
        final studentCount =
            await StudentService().getStudentCount(schoolId!.toString());
        final vehicleCount =
            await VehicleService().getVehicleCount(schoolId!.toString());

        // Get real attendance data from API
        final attendanceData = await _getTodayAttendanceFromAPI();
        final todayPresent = attendanceData['studentsPresent'] ?? 0;
        
        // Get real vehicles in transit count from API
        final vehiclesInTransitCount = await _getVehiclesInTransitFromAPI();
        
        // Generate recent notifications
        await _generateRecentNotifications(studentCount, vehicleCount, todayPresent);
        setState(() {
          totalStudents = studentCount;
          totalVehicles = vehicleCount;
          todayAttendance = "$todayPresent/$studentCount";
          vehiclesInTransit = vehiclesInTransitCount;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
      });
      debugPrint("Error loading dashboard data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Calculate today's attendance (mock implementation)
  Future<int> _calculateTodayAttendance(int totalStudents) async {
    if (totalStudents == 0) return 0;
    
    // Mock logic: 85-95% attendance rate
    final attendanceRate = 0.85 + (DateTime.now().day % 10) * 0.01; // Varies by day
    return (totalStudents * attendanceRate).round();
  }

  /// Get vehicles in transit from real API
  Future<int> _getVehiclesInTransitFromAPI() async {
    if (schoolId == null) return 0;
    
    try {
      final response = await _schoolService.getVehiclesInTransit(schoolId!);
      if (response['success'] == true) {
        return (response['data'] ?? 0) as int;
      } else {
        debugPrint("Error getting vehicles in transit: ${response['message']}");
        return 0;
      }
    } catch (e) {
      debugPrint("Exception getting vehicles in transit: $e");
      return 0;
    }
  }

  /// Get today's attendance from real API
  Future<Map<String, dynamic>> _getTodayAttendanceFromAPI() async {
    if (schoolId == null) return {'studentsPresent': 0, 'totalStudents': 0, 'attendanceRate': 0.0};
    
    try {
      final response = await _schoolService.getTodayAttendance(schoolId!);
      if (response['success'] == true) {
        return response['data'] ?? {'studentsPresent': 0, 'totalStudents': 0, 'attendanceRate': 0.0};
      } else {
        debugPrint("Error getting today's attendance: ${response['message']}");
        return {'studentsPresent': 0, 'totalStudents': 0, 'attendanceRate': 0.0};
      }
    } catch (e) {
      debugPrint("Exception getting today's attendance: $e");
      return {'studentsPresent': 0, 'totalStudents': 0, 'attendanceRate': 0.0};
    }
  }

  /// Calculate vehicles in transit (mock implementation) - DEPRECATED
  Future<int> _calculateVehiclesInTransit(int totalVehicles) async {
    if (totalVehicles == 0) return 0;
    
    // Mock logic: 30-70% of vehicles are in transit during school hours
    final currentHour = DateTime.now().hour;
    if (currentHour >= 7 && currentHour <= 9) {
      // Morning pickup time
      return (totalVehicles * 0.7).round();
    } else if (currentHour >= 14 && currentHour <= 16) {
      // Afternoon drop time
      return (totalVehicles * 0.6).round();
    } else {
      // Other times
      return (totalVehicles * 0.3).round();
    }
  }

  /// Generate recent notifications based on current data
  Future<void> _generateRecentNotifications(int studentCount, int vehicleCount, int todayPresent) async {
    final now = DateTime.now();
    final notifications = <Map<String, String>>[];

    // Add login notification
    notifications.add({
      'message': 'School Admin logged in',
      'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'
    });

    // Add attendance notification with insights
    final attendanceRate = studentCount > 0 ? (todayPresent / studentCount * 100).round() : 0;
    String attendanceMessage = 'Today\'s attendance: $attendanceRate% ($todayPresent/$studentCount)';
    if (attendanceRate >= 90) {
      attendanceMessage += ' - Excellent!';
    } else if (attendanceRate >= 80) {
      attendanceMessage += ' - Good';
    } else if (attendanceRate >= 70) {
      attendanceMessage += ' - Needs improvement';
    } else {
      attendanceMessage += ' - Low attendance';
    }
    
    notifications.add({
      'message': attendanceMessage,
      'time': '${(now.hour - 1).toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'
    });

    // Add vehicle status notification with insights
    if (vehicleCount > 0) {
      final inTransit = await _calculateVehiclesInTransit(vehicleCount);
      String vehicleMessage = '$inTransit out of $vehicleCount vehicles in transit';
      if (inTransit > vehicleCount * 0.7) {
        vehicleMessage += ' - High activity';
      } else if (inTransit < vehicleCount * 0.3) {
        vehicleMessage += ' - Low activity';
      }
      
      notifications.add({
        'message': vehicleMessage,
        'time': '${(now.hour - 2).toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'
      });
    }

    // Add system insights
    final currentHour = now.hour;
    String systemMessage = 'System running smoothly';
    if (currentHour >= 7 && currentHour <= 9) {
      systemMessage = 'Morning pickup time - High activity expected';
    } else if (currentHour >= 14 && currentHour <= 16) {
      systemMessage = 'Afternoon drop time - High activity expected';
    } else if (currentHour >= 17) {
      systemMessage = 'School day ended - Low activity expected';
    }
    
    notifications.add({
      'message': systemMessage,
      'time': '${(now.hour - 3).toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'
    });

    recentNotifications = notifications;
  }

  /// Logout
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final authService = AuthService();
                await authService.logout();
                if (!mounted) return;
                Navigator.pop(ctx);
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.login, (route) => false);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logout failed: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  /// Info card
  Widget _buildInfoCard(String label, String value, {IconData? icon}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Icon(icon, color: Colors.blueGrey, size: 20),
            Text(label,
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 8),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                    ? Center(
                        child: Text(
                          "Error",
                          style: TextStyle(
                              color: Colors.red[400],
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    : Text(value,
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  /// Quick Action button
  Widget _buildQuickAction(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          minimumSize: const Size.fromHeight(48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  /// Build insight item
  Widget _buildInsightItem(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Get current time context
  String _getCurrentTimeContext() {
    final now = DateTime.now();
    final hour = now.hour;
    
    if (hour >= 6 && hour < 9) {
      return 'Morning Pickup';
    } else if (hour >= 9 && hour < 12) {
      return 'School Hours';
    } else if (hour >= 12 && hour < 14) {
      return 'Lunch Break';
    } else if (hour >= 14 && hour < 17) {
      return 'Afternoon Drop';
    } else if (hour >= 17 && hour < 20) {
      return 'Evening';
    } else {
      return 'Off Hours';
    }
  }

  /// Drawer
  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              height: 100,
              width: double.infinity,
              color: const Color(0xFF1E3A8A),
              padding: const EdgeInsets.all(16),
              alignment: Alignment.centerLeft,
              child: const Text(
                'ADMIN PANEL',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Dashboard
                  ListTile(
                      leading: const Icon(Icons.dashboard),
                      title: const Text('Dashboard'),
                      onTap: () => Navigator.pop(context)),
                  
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('MANAGEMENT', 
                        style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: Colors.grey,
                            fontSize: 12)),
                  ),
                  
                  // Students Management
                  ExpansionTile(
                    leading: const Icon(Icons.group),
                    title: const Text('Students'),
                    subtitle: const Text('Manage students & parents'),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_add),
                        title: const Text('Add Student'),
                        subtitle: const Text('Register new student'),
                        onTap: () => Navigator.pushNamed(context, AppRoutes.studentManagement),
                      ),
                      ListTile(
                        leading: const Icon(Icons.upload_file),
                        title: const Text('Bulk Import'),
                        subtitle: const Text('Import students from Excel'),
                        onTap: () => Navigator.pushNamed(context, AppRoutes.bulkStudentImport),
                      ),
                    ],
                  ),
                  
                  // Vehicle Management
                  ListTile(
                      leading: const Icon(Icons.directions_bus),
                      title: const Text('Vehicles'),
                      subtitle: const Text('View vehicles & reports'),
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.vehicleManagement)),
                  
                  // Staff Management
                  ListTile(
                      leading: const Icon(Icons.people),
                      title: const Text('Staff'),
                      subtitle: const Text('Manage teachers & gate staff'),
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.staffManagement)),
                  
                  // Trip Management
                  ListTile(
                      leading: const Icon(Icons.alt_route),
                      title: const Text('Trips'),
                      subtitle: const Text('Manage routes & schedules'),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.trips)),
                  
                  // Master Data Management
                  ExpansionTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Master Data'),
                    subtitle: const Text('Manage classes & sections'),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.class_),
                        title: const Text('Classes'),
                        subtitle: const Text('Manage class names'),
                        onTap: () => Navigator.pushNamed(context, AppRoutes.classManagement),
                      ),
                      ListTile(
                        leading: const Icon(Icons.category),
                        title: const Text('Sections'),
                        subtitle: const Text('Manage section names'),
                        onTap: () => Navigator.pushNamed(context, AppRoutes.sectionManagement),
                      ),
                    ],
                  ),
                  
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('REPORTS & ANALYTICS', 
                        style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: Colors.grey,
                            fontSize: 12)),
                  ),
                  
                  // Reports
                  ListTile(
                      leading: const Icon(Icons.bar_chart),
                      title: const Text('Reports'),
                      subtitle: const Text('Attendance, dispatch logs'),
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.reports)),
                  
                  // Pending Requests
                  ListTile(
                      leading: const Icon(Icons.pending_actions),
                      title: const Text('Pending Requests'),
                      subtitle: const Text('Vehicle assignment requests'),
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.pendingRequests)),
                  
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('ACCOUNT', 
                        style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: Colors.grey,
                            fontSize: 12)),
                  ),
                  
                  // Profile
                  ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Profile'),
                      subtitle: const Text('School profile settings'),
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.schoolProfile)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout',
                  style: TextStyle(color: Colors.red)),
              onTap: _showLogoutDialog,
            ),
          ],
        ),
      ),
    );
  }

  /// UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: const [
          Icon(Icons.school, size: 28),
          SizedBox(width: 8),
          Text('School Admin'),
        ]),
        actions: [
  Padding(
    padding: const EdgeInsets.only(right: 12.0),
    child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SchoolProfilePage()),
        );
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blueGrey,
            backgroundImage: schoolPhoto != null && schoolPhoto!.isNotEmpty
                ? MemoryImage(base64Decode(schoolPhoto!))
                : null,
            child: schoolPhoto == null || schoolPhoto!.isEmpty
                ? const Icon(Icons.school, color: Colors.white, size: 20)
                : null,
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(adminName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              Text(schoolName, style: const TextStyle(fontSize: 12)),
            ],
          )
        ],
      ),
    ),
  ),
],

      ),
      drawer: _buildDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Info Cards
                  isWide
                      ? Row(
                          children: [
                            Expanded(
                                child: _buildInfoCard('Total Students',
                                    totalStudents.toString(),
                                    icon: Icons.group)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildInfoCard('Total Vehicles',
                                    totalVehicles.toString(),
                                    icon: Icons.directions_bus)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildInfoCard("Today's Attendance",
                                    todayAttendance,
                                    icon: Icons.calendar_today)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildInfoCard(
                                    'Vehicles in Transit',
                                    vehiclesInTransit.toString(),
                                    icon: Icons.local_shipping)),
                          ],
                        )
                      : Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: _buildInfoCard('Total Students',
                                        totalStudents.toString(),
                                        icon: Icons.group)),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: _buildInfoCard('Total Vehicles',
                                        totalVehicles.toString(),
                                        icon: Icons.directions_bus)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                    child: _buildInfoCard("Today's Attendance",
                                        todayAttendance,
                                        icon: Icons.calendar_today)),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: _buildInfoCard(
                                        'Vehicles in Transit',
                                        vehiclesInTransit.toString(),
                                        icon: Icons.local_shipping)),
                              ],
                            ),
                          ],
                        ),

                  const SizedBox(height: 16),

                  // Insights Card
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Today\'s Insights',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInsightItem(
                            Icons.trending_up,
                            'Attendance Rate',
                            totalStudents > 0 
                                ? '${((int.parse(todayAttendance.split('/')[0]) / totalStudents) * 100).round()}%'
                                : '0%',
                            totalStudents > 0 && (int.parse(todayAttendance.split('/')[0]) / totalStudents) >= 0.8
                                ? Colors.green
                                : Colors.orange,
                          ),
                          _buildInsightItem(
                            Icons.local_shipping,
                            'Vehicle Utilization',
                            totalVehicles > 0
                                ? '${((vehiclesInTransit / totalVehicles) * 100).round()}%'
                                : '0%',
                            totalVehicles > 0 && (vehiclesInTransit / totalVehicles) >= 0.5
                                ? Colors.green
                                : Colors.blue,
                          ),
                          _buildInsightItem(
                            Icons.schedule,
                            'Current Time',
                            _getCurrentTimeContext(),
                            Colors.purple,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Notifications + Quick Actions
                  isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Recent Notifications',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 12),
                                      ...recentNotifications.map((n) => ListTile(
                                            dense: true,
                                            title:
                                                Text(n['message'] ?? ''),
                                            trailing:
                                                Text(n['time'] ?? ''),
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Text('Quick Actions',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 12),
                                      _buildQuickAction(
                                          'Add Student',
                                          Icons.person_add,
                                          () => Navigator.pushNamed(
                                              context,
                                              AppRoutes.registerStudent)),
                                      _buildQuickAction(
                                          'Add Vehicle Owner',
                                          Icons.business,
                                          () => Navigator.pushNamed(
                                              context,
                                              AppRoutes.registerVehicleOwner)),
                                      _buildQuickAction(
                                          'Add Staff',
                                          Icons.person_add_alt_1,
                                          () => Navigator.pushNamed(
                                              context,
                                              AppRoutes.registerGateStaff)),
                                      _buildQuickAction(
                                          'Create Trip',
                                          Icons.alt_route,
                                          () => Navigator.pushNamed(
                                              context,
                                              AppRoutes.createTrip)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('Recent Notifications',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    ...recentNotifications.map((n) =>
                                        ListTile(
                                          dense: true,
                                          title: Text(n['message'] ?? ''),
                                          trailing: Text(n['time'] ?? ''),
                                        )),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text('Quick Actions',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 12),
                                    _buildQuickAction(
                                        'Add Student', 
                                        Icons.person_add, 
                                        () => Navigator.pushNamed(context, AppRoutes.registerStudent)),
                                    _buildQuickAction(
                                        'Add Vehicle Owner',
                                        Icons.business,
                                        () => Navigator.pushNamed(
                                            context,
                                            AppRoutes.registerVehicleOwner)),
                                    _buildQuickAction(
                                        'Add Staff',
                                        Icons.person_add_alt_1,
                                        () => Navigator.pushNamed(
                                            context,
                                            AppRoutes.registerGateStaff)),
                                    _buildQuickAction(
                                        'Create Trip',
                                        Icons.alt_route,
                                        () => Navigator.pushNamed(context, AppRoutes.createTrip)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                  if (_hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        "Failed to load counts. Pull down to retry.",
                        style: TextStyle(
                            color: Colors.red[400],
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:school_tracker/presentation/pages/school_profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_routes.dart';
import '../../services/school_service.dart';
import '../../services/student_service.dart';
import '../../services/vehicle_service.dart';

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
  int? schoolId;

  final SchoolService _schoolService = SchoolService();

  final List<Map<String, String>> recentNotifications = [
    {'message': 'School Admin logged in', 'time': '09:00 AM'},
    {'message': 'New student registered', 'time': '09:15 AM'},
    {'message': 'New vehicle added', 'time': '10:00 AM'},
    {'message': 'Attendance updated', 'time': '11:30 AM'},
  ];

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

      // ✅ fallback to school service if available
      final school = await _schoolService.getSchoolFromPrefs();
      if (school != null) {
        schoolId ??= school.schoolId;
      }

      // ✅ Load counts if we have schoolId
      if (schoolId != null) {
        final studentCount =
            await StudentService().getStudentCount(schoolId!.toString());
        final vehicleCount =
            await VehicleService().getVehicleCount(schoolId!.toString());

        setState(() {
          totalStudents = studentCount;
          totalVehicles = vehicleCount;
          todayAttendance = studentCount > 0
              ? "${(studentCount * 0.85).round()}/$studentCount"
              : "0/$studentCount";
          vehiclesInTransit = vehicleCount ~/ 2;
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
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.home, (route) => false);
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
                  ListTile(
                      leading: const Icon(Icons.dashboard),
                      title: const Text('Dashboard'),
                      onTap: () => Navigator.pop(context)),
                  ListTile(
                      leading: const Icon(Icons.group),
                      title: const Text('Students'),
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.registerStudent)),
                  ListTile(
                      leading: const Icon(Icons.directions_bus),
                      title: const Text('Vehicles'),
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.registerVehicle)),
                  ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Drivers'),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Drivers page not implemented')))),
                              ListTile(
  leading: const Icon(Icons.security),
  title: const Text('Add Gate Staff'),
  onTap: () => Navigator.pushNamed(
      context, AppRoutes.registerGateStaff),
),
ListTile(
  leading: const Icon(Icons.alt_route),
  title: const Text('Trips'),
  onTap: () => Navigator.pushNamed(context, AppRoutes.trips),
),
ListTile(
  leading: const Icon(Icons.pending_actions),
  title: const Text('Pending Vehicle Requests'),
  onTap: () => Navigator.pushNamed(
    context,
    AppRoutes.pendingRequests,
  ),
),

                  ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Attendance / Logs'),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Attendance page not implemented')))),
                  ListTile(
                      leading: const Icon(Icons.bar_chart),
                      title: const Text('Reports'),
                      onTap: () =>Navigator.pushNamed(
      context, AppRoutes.reports),),
                  ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Settings'),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Settings page not implemented')))),
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
          const CircleAvatar(
              child: Icon(Icons.person, color: Colors.white),
              backgroundColor: Colors.blueGrey),
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
                                          'Add Vehicle',
                                          Icons.directions_bus,
                                          () => Navigator.pushNamed(
                                              context,
                                              AppRoutes.registerVehicle)),
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
                                   _buildQuickAction('Add Student', Icons.person_add, () => Navigator.pushNamed(context, AppRoutes.registerStudent)),

                                    _buildQuickAction(
                                        'Add Vehicle Owner',
                                        Icons.directions_bus,
                                        () => Navigator.pushNamed(
                                            context,
                                            AppRoutes.registerVehicleOwner)),
                                            _buildQuickAction(
  'Create Trip',
  Icons.alt_route,
  () => Navigator.pushNamed(context, AppRoutes.createTrip),
),
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../app_routes.dart';
import '../../services/parent_service.dart';
import '../../services/auth_service.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/parent_dashboard.dart';
import '../../data/models/websocket_notification.dart';

class ParentDashboardPage extends StatefulWidget {
  const ParentDashboardPage({super.key});

  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  final ParentService _parentService = ParentService();
  final AuthService _authService = AuthService();
  final WebSocketNotificationService _webSocketService = WebSocketNotificationService();
  
  int? _userId;
  bool _isLoading = true;
  ParentDashboard? _dashboardData;
  String _error = '';
  
  // Real-time updates
  bool _isConnected = false;
  StreamSubscription<WebSocketNotification>? _notificationSubscription;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _initializeWebSocket() {
    _webSocketService.initialize().then((_) {
      setState(() {
        _isConnected = _webSocketService.isConnected;
      });
      _notificationSubscription = _webSocketService.notificationStream.listen(
        _handleWebSocketNotification,
        onError: (error) {
          print('WebSocket error: $error');
          setState(() {
            _isConnected = false;
          });
        },
      );
      _startAutoRefresh();
    });
  }

  void _handleWebSocketNotification(WebSocketNotification notification) {
    print('🔔 Parent - Received notification: ${notification.type} - ${notification.message}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${notification.title}: ${notification.message}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.blue,
        ),
      );
    }
    if (_isRelevantNotification(notification)) {
      _loadDashboardData();
    }
  }

  bool _isRelevantNotification(WebSocketNotification notification) {
    return notification.type == NotificationType.arrivalNotification ||
           notification.type == NotificationType.attendanceUpdate ||
           notification.type == NotificationType.tripUpdate ||
           notification.type == NotificationType.vehicleAssignmentRequest;
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId');
    });
    
    if (_userId != null) {
      _loadDashboardData();
    } else {
      setState(() {
        _error = 'User ID not found. Please login again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDashboardData() async {
    if (_userId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final dashboard = await _parentService.getParentDashboard(_userId!);
      print('🔍 Dashboard loaded: $dashboard');
      
      setState(() {
        _dashboardData = dashboard;
        _error = '';
      });
    } catch (e) {
      print('🔍 Error loading dashboard: $e');
      setState(() {
        _error = 'Error loading dashboard: $e';
      });
      
      // Show error snackbar with more helpful message
      if (mounted) {
        String errorMessage = 'Failed to load dashboard';
        if (e.toString().contains('No student linked')) {
          errorMessage = 'No student linked to this parent account. Please contact school admin.';
        } else if (e.toString().contains('Parent user not found')) {
          errorMessage = 'Parent account not found. Please login again.';
        } else {
          errorMessage = 'Failed to load dashboard: $e';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadDashboardData,
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        // Clear all stored data
        await _authService.logout();
        
        // Navigate to login screen and clear navigation stack
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove back button
        title: Row(
          children: const [
            Icon(Icons.family_restroom, size: 28),
            SizedBox(width: 8),
            Text("Parent Dashboard"),
          ],
        ),
        actions: [
          // WebSocket connection status
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh Data',
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: FutureBuilder<Map<String, dynamic>>(
              future: SharedPreferences.getInstance().then((prefs) async {
                final userId = prefs.getInt("userId");
                if (userId == null) return {"success": false};
                final service = ParentService();
                // ✅ API: student data by parent userId
                return await service.getStudentByParentUserId(userId);
              }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2);
                }

                if (!snapshot.hasData || snapshot.data!['success'] != true) {
                  return const Text(
                    "Parent",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  );
                }

                final data = snapshot.data!['data'];
                final studentName =
                    "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}"
                        .trim();
                final studentId = data['studentId'];
                final studentPhoto = data['studentPhoto'];

                return InkWell(
                  onTap: () {
                    // ✅ Navigate to Student Profile Page
                    Navigator.pushNamed(
                      context,
                      AppRoutes.studentProfile,
                      arguments: studentId,
                    );
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blueGrey,
                        backgroundImage: studentPhoto != null && studentPhoto.isNotEmpty
                            ? MemoryImage(base64Decode(studentPhoto))
                            : null,
                        child: studentPhoto == null || studentPhoto.isEmpty
                            ? const Icon(Icons.person, color: Colors.white, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        studentName.isNotEmpty ? studentName : "Student",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Unable to Load Dashboard',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error,
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadDashboardData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                    children: [
                      // ✅ Welcome Section
                      Text(
                        'Welcome, ${_dashboardData?.userName ?? 'Parent'}!',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'School: ${_dashboardData?.schoolName ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      // ✅ Dashboard Summary Cards
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard(
                            "Present Days",
                            (_dashboardData?.totalPresentDays ?? 0).toString(),
                            Colors.green,
                          ),
                          _buildStatCard(
                            "Absent Days",
                            (_dashboardData?.totalAbsentDays ?? 0).toString(),
                            Colors.red,
                          ),
                          _buildStatCard(
                            "Attendance %",
                            "${(_dashboardData?.attendancePercentage ?? 0.0).toStringAsFixed(1)}%",
                            Colors.blue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ✅ Child Info Card (dynamic data)
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Child Information",
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blueAccent,
                                  backgroundImage: _dashboardData?.studentPhoto != null
                                      ? MemoryImage(base64Decode(_dashboardData!.studentPhoto!))
                                      : null,
                                  child: _dashboardData?.studentPhoto == null
                                      ? const Icon(Icons.person, color: Colors.white)
                                      : null,
                                ),
                                title: Text("Name: ${_dashboardData?.studentName ?? 'N/A'}"),
                                subtitle: Text(
                                    "Class: ${_dashboardData?.className ?? 'N/A'} - Section ${_dashboardData?.sectionName ?? 'N/A'}"),
                              ),
                              ListTile(
                                leading: const Icon(Icons.school),
                                title: Text("School: ${_dashboardData?.schoolName ?? 'N/A'}"),
                                subtitle: Text("Student ID: ${_dashboardData?.studentId ?? 'N/A'}"),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ✅ Today's Attendance
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Today's Attendance",
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ListTile(
                                leading: Icon(
                                  _getAttendanceIcon(_dashboardData?.todayAttendanceStatus),
                                  color: _getAttendanceColor(_dashboardData?.todayAttendanceStatus),
                                ),
                                title: Text("Status: ${_dashboardData?.todayAttendanceStatus ?? 'Not Marked'}"),
                                subtitle: Text(
                                  "Arrival: ${_dashboardData?.todayArrivalTime ?? 'N/A'} | "
                                  "Departure: ${_dashboardData?.todayDepartureTime ?? 'N/A'}",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ✅ Recent Notifications
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Recent Notifications",
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              if (_dashboardData?.recentNotifications.isEmpty ?? true)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('No recent notifications'),
                                )
                              else
                                ...(_dashboardData?.recentNotifications.take(3).map((notification) => 
                                  ListTile(
                                    leading: const Icon(Icons.notifications),
                                    title: Text(notification['title'] ?? 'Notification'),
                                    subtitle: Text(notification['message'] ?? ''),
                                    trailing: Text(
                                      _formatDateTime(notification['notificationTime']),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ).toList() ?? []),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ✅ Quick Actions
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text("Quick Actions",
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, AppRoutes.attendanceHistory);
                                },
                                icon: const Icon(Icons.history),
                                label: const Text("View Attendance History"),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, AppRoutes.monthlyReport);
                                },
                                icon: const Icon(Icons.assessment),
                                label: const Text("View Monthly Reports"),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, AppRoutes.parentProfileUpdate);
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text("Update Profile"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  // ================ HELPER METHODS ================

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: MediaQuery.of(context).size.width / 3.5,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAttendanceIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.schedule;
      default:
        return Icons.help_outline;
    }
  }

  Color _getAttendanceColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final DateTime dt = DateTime.parse(dateTime.toString());
      return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }
}

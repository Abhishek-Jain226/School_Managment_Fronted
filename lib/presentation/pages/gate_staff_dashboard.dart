import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../services/auth_service.dart';
import '../../services/gate_staff_service.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart';
import '../../app_routes.dart';

class GateStaffDashboardPage extends StatefulWidget {
  const GateStaffDashboardPage({Key? key}) : super(key: key);

  @override
  State<GateStaffDashboardPage> createState() => _GateStaffDashboardPageState();
}

class _GateStaffDashboardPageState extends State<GateStaffDashboardPage> {
  final GateStaffService _gateStaffService = GateStaffService();
  final AuthService _authService = AuthService();
  final WebSocketNotificationService _webSocketService = WebSocketNotificationService();
  
  int? _userId;
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
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
    print('🔔 Gate Staff - Received notification: ${notification.type} - ${notification.message}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${notification.title}: ${notification.message}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    if (_isRelevantNotification(notification)) {
      _loadDashboardData();
    }
  }

  bool _isRelevantNotification(WebSocketNotification notification) {
    return notification.type == NotificationType.attendanceUpdate ||
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
      final response = await _gateStaffService.getGateStaffDashboard(_userId!);
      print('🔍 Dashboard response: $response');
      
      if (response['success'] == true) {
        setState(() {
          _dashboardData = response['data'];
          _error = '';
        });
        print('🔍 Dashboard data loaded successfully');
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load dashboard data';
        });
      }
    } catch (e) {
      print('🔍 Error loading dashboard: $e');
      setState(() {
        _error = 'Error loading dashboard: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markGateEvent(int studentId, int tripId, String eventType, String remarks) async {
    if (_userId == null) return;
    
    try {
      Map<String, dynamic> response;
      if (eventType == 'entry') {
        response = await _gateStaffService.markGateEntry(_userId!, studentId, tripId, remarks);
      } else {
        response = await _gateStaffService.markGateExit(_userId!, studentId, tripId, remarks);
      }
      
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gate $eventType marked successfully!')),
        );
        // Reload dashboard data
        _loadDashboardData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response['message']}')),
        );
      }
    } catch (e) {
      print('🔍 Error marking gate event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking gate $eventType: $e')),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _logout(context);
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gate Staff Dashboard"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Error',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _error,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDashboardData,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _dashboardData == null
                  ? const Center(child: Text('No data available'))
                  : _buildDashboardContent(),
    );
  }

  Widget _buildDashboardContent() {
    final data = _dashboardData!;
    final gateStaffName = data['gateStaffName'] ?? 'Gate Staff';
    final schoolName = data['schoolName'] ?? 'School';
    final totalStudents = data['totalStudents'] ?? 0;
    final studentsWithGateEntry = data['studentsWithGateEntry'] ?? 0;
    final studentsWithGateExit = data['studentsWithGateExit'] ?? 0;
    final studentsByTrip = data['studentsByTrip'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $gateStaffName!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  schoolName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Statistics Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Total Students",
                  totalStudents.toString(),
                  Colors.blue,
                  Icons.people,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  "Gate Entry",
                  studentsWithGateEntry.toString(),
                  Colors.green,
                  Icons.login,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  "Gate Exit",
                  studentsWithGateExit.toString(),
                  Colors.orange,
                  Icons.logout,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Students by Trip Section
          Text(
            "Students by Trip",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          if (studentsByTrip.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No trips scheduled for today',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else
            ...studentsByTrip.map((tripData) => _buildTripCard(tripData)).toList(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> tripData) {
    final tripName = tripData['tripName'] ?? 'Unknown Trip';
    final vehicleNumber = tripData['vehicleNumber'] ?? 'Unknown Vehicle';
    final driverName = tripData['driverName'] ?? 'No Driver';
    final students = tripData['students'] as List<dynamic>? ?? [];
    final studentCount = tripData['studentCount'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_bus, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tripName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$studentCount students',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Vehicle: $vehicleNumber',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (driverName != 'No Driver')
              Text(
                'Driver: $driverName',
                style: TextStyle(color: Colors.grey[600]),
              ),
            const SizedBox(height: 12),
            
            if (students.isEmpty)
              const Text(
                'No students assigned to this trip',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...students.map((student) => _buildStudentCard(student)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> studentData) {
    final studentId = studentData['studentId'];
    final tripId = studentData['tripId'] ?? _dashboardData?['studentsByTrip']?.first?['tripId'];
    final firstName = studentData['firstName'] ?? '';
    final middleName = studentData['middleName'] ?? '';
    final lastName = studentData['lastName'] ?? '';
    final grade = studentData['grade'] ?? '';
    final section = studentData['section'] ?? '';
    final hasGateEntry = studentData['hasGateEntry'] ?? false;
    final hasGateExit = studentData['hasGateExit'] ?? false;
    
    final studentName = '$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName'.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: hasGateEntry && hasGateExit ? Colors.green.shade50 : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: hasGateEntry && hasGateExit ? Colors.green : Colors.blue,
          child: Icon(
            hasGateEntry && hasGateExit ? Icons.check : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(studentName),
        subtitle: Text('$grade - $section'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!hasGateEntry)
              ElevatedButton(
                onPressed: () => _showRemarksDialog(studentId, tripId, 'entry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text("Entry"),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "✓ Entry",
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(width: 8),
            if (!hasGateExit)
              ElevatedButton(
                onPressed: () => _showRemarksDialog(studentId, tripId, 'exit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text("Exit"),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "✓ Exit",
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showRemarksDialog(int studentId, int tripId, String eventType) {
    final TextEditingController remarksController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark Gate ${eventType.toUpperCase()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add remarks (optional):'),
            const SizedBox(height: 8),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                hintText: 'Enter remarks...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _markGateEvent(studentId, tripId, eventType, remarksController.text);
            },
            child: Text('Mark ${eventType.toUpperCase()}'),
          ),
        ],
      ),
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/driver_dashboard.dart';
import '../../data/models/trip.dart';
import '../../data/models/trip_type.dart';
import '../../services/driver_service.dart';
import '../../services/auth_service.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart';
import '../../app_routes.dart';
import 'trip_management_page.dart';
import 'student_attendance_page.dart';
import 'notification_page.dart';

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  
  final DriverService _driverService = DriverService();
  final WebSocketNotificationService _webSocketService = WebSocketNotificationService();
  DriverDashboard? _dashboard;
  List<Trip> _assignedTrips = [];
  bool _isLoading = true;
  String? _error;
  int? _driverId;
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  
  // Real-time updates
  bool _isConnected = false;
  StreamSubscription<WebSocketNotification>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
    _startPeriodicRefresh();
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  /// Initialize WebSocket connection
  void _initializeWebSocket() {
    _webSocketService.initialize().then((_) {
      setState(() {
        _isConnected = _webSocketService.isConnected;
      });
      
      // Listen to notifications
      _notificationSubscription = _webSocketService.notificationStream.listen(
        _handleWebSocketNotification,
        onError: (error) {
          print('WebSocket error: $error');
          setState(() {
            _isConnected = false;
          });
        },
      );
      
      print('🔌 WebSocket initialized for Driver Dashboard');
    });
  }

  /// Handle WebSocket notifications
  void _handleWebSocketNotification(WebSocketNotification notification) {
    print('🔔 Received notification: ${notification.type} - ${notification.message}');
    
    // Show notification using SnackBar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${notification.title}: ${notification.message}'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => _handleNotificationTap(notification),
          ),
        ),
      );
    }
    
    // Refresh dashboard data for relevant notifications
    if (_isRelevantNotification(notification)) {
      _refreshDataSilently();
    }
  }

  /// Check if notification is relevant for dashboard refresh
  bool _isRelevantNotification(WebSocketNotification notification) {
    return notification.type == NotificationType.tripUpdate ||
           notification.type == NotificationType.arrivalNotification ||
           notification.type == NotificationType.attendanceUpdate ||
           notification.type == NotificationType.vehicleStatusUpdate;
  }

  /// Handle notification tap
  void _handleNotificationTap(WebSocketNotification notification) {
    if (notification.type == NotificationType.tripUpdate) {
      // Navigate to trip management
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TripManagementPage(),
        ),
      );
    } else {
      // Refresh dashboard data for other notifications
      _refreshDataSilently();
    }
  }

  void _startPeriodicRefresh() {
    // Refresh data every 30 seconds for real-time updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_isRefreshing) {
        _refreshDataSilently();
      }
    });
  }

  Future<void> _refreshDataSilently() async {
    if (_driverId == null || _isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    
    try {
      final results = await Future.wait([
        _driverService.getDriverDashboard(_driverId!),
        _driverService.getAssignedTrips(_driverId!),
      ]);

      if (mounted && results.length >= 2 && results[0] != null && results[1] != null) {
        setState(() {
          _dashboard = results[0] as DriverDashboard;
          _assignedTrips = results[1] as List<Trip>;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      print('🔍 Silent refresh error: $e');
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _loadDriverData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get driver ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _driverId = prefs.getInt('driverId');
      
      print('🔍 Driver ID loaded from preferences: $_driverId');
      
      // If driverId is null, try to get it from userId
      if (_driverId == null) {
        print('⚠️ Driver ID is null! Trying to fetch from userId...');
        
        final userId = prefs.getInt('userId');
        final role = prefs.getString('role');
        
        if (userId != null && role == 'DRIVER') {
            try {
              // Call backend to get driverId from userId
              final driverResponse = await _driverService.getDriverByUserId(userId);
              if (driverResponse['success'] == true && driverResponse['data'] != null) {
                final driverData = driverResponse['data'];
                _driverId = driverData['driverId'];
                print('🔍 Found driverId from userId: $_driverId');
                
                // Save driverId for future use
                await prefs.setInt('driverId', _driverId!);
                print('🔍 Saved driverId to preferences');
              } else {
              throw Exception('Driver record not found');
              }
            } catch (e) {
              print('🔍 Error fetching driverId from userId: $e');
            setState(() {
              _error = 'Driver record not found. Please contact support or register as driver again.';
              _isLoading = false;
            });
            return;
          }
        } else {
          setState(() {
            _error = 'Driver ID not found. Please login again.';
            _isLoading = false;
          });
          return;
        }
      }

               // Load dashboard data and assigned trips in parallel
               final results = await Future.wait([
                 _driverService.getDriverDashboard(_driverId!),
                 _driverService.getAssignedTrips(_driverId!),
               ]);

      // Validate results before setting state
      if (results.length >= 2 && results[0] != null && results[1] != null) {
        print('🔍 Dashboard data type: ${results[0].runtimeType}');
        print('🔍 Trips data type: ${results[1].runtimeType}');
        
        setState(() {
          _dashboard = results[0] as DriverDashboard;
          _assignedTrips = results[1] as List<Trip>;
          _isLoading = false;
        });
      } else {
        print('🔍 Invalid results: length=${results.length}, [0]=${results[0]}, [1]=${results[1]}');
        throw Exception('Invalid response from server');
      }
      
      print('🔍 Dashboard loaded successfully');
    } catch (e) {
      print('🔍 Error loading driver data: $e');
      setState(() {
        _error = 'Failed to load driver data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadDriverData();
  }


  Widget _buildTripCard(Trip trip) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.schedule;
    
    switch (trip.tripStatus) {
      case 'NOT_STARTED':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'IN_PROGRESS':
        statusColor = Colors.blue;
        statusIcon = Icons.play_circle;
        break;
      case 'COMPLETED':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: () => _navigateToTripDetails(trip),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                        Text(
                          trip.tripName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${trip.tripType} - ${trip.scheduledTime ?? 'No time set'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Text(
          trip.tripStatus ?? 'Unknown',
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStudentStatChip('Total', trip.totalStudents, Colors.blue),
                  const SizedBox(width: 8),
                  _buildStudentStatChip('Picked', trip.studentsPickedUp, Colors.green),
                  const SizedBox(width: 8),
                  _buildStudentStatChip('Dropped', trip.studentsDropped, Colors.purple),
                  const SizedBox(width: 8),
                  _buildStudentStatChip('Absent', trip.studentsAbsent, Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _navigateToTripDetails(Trip trip) {
    _showTripDetailsDialog(trip);
  }

  void _showTripDetailsDialog(Trip trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.route, color: _getStatusColor(trip.tripStatus)),
            const SizedBox(width: 8),
            Expanded(child: Text(trip.tripName)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTripDetailRow('Type', trip.tripType ?? 'N/A'),
            _buildTripDetailRow('Time', trip.scheduledTime ?? 'Not set'),
            _buildTripDetailRow('Status', trip.tripStatus ?? 'Unknown'),
            _buildTripDetailRow('Students', '${trip.totalStudents} total'),
            _buildTripDetailRow('Picked Up', '${trip.studentsPickedUp}'),
            _buildTripDetailRow('Dropped', '${trip.studentsDropped}'),
            _buildTripDetailRow('Absent', '${trip.studentsAbsent}'),
            const SizedBox(height: 16),
            Text(
              'Students:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...trip.students.take(3).map((student) => 
              ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue,
                  child: Text(
                    student.studentName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                title: Text(student.studentName),
                subtitle: Text('${student.className} - ${student.sectionName}'),
                trailing: _getAttendanceStatusChip(student.attendanceStatus),
                dense: true,
              ),
            ),
            if (trip.students.length > 3)
              Text(
                '... and ${trip.students.length - 3} more students',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToStudentAttendance(trip);
            },
            child: const Text('View Students'),
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _getAttendanceStatusChip(String status) {
    Color color;
    switch (status) {
      case 'PENDING':
        color = Colors.orange;
        break;
      case 'PICKED_UP':
        color = Colors.blue;
        break;
      case 'DROPPED':
        color = Colors.green;
        break;
      case 'ABSENT':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _navigateToTripManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TripManagementPage(),
      ),
    ).then((_) {
      // Refresh data when returning from trip management
      _refreshData();
    });
  }

  void _navigateToStudentAttendance(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentAttendancePage(trip: trip),
      ),
    ).then((_) {
      // Refresh data when returning from attendance
      _refreshData();
    });
  }

  void _navigateToNotification(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationPage(),
      ),
    );
  }

  /// Show notification options for trip
  void _showNotificationOptions(Trip trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Trip Started - ${trip.tripName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Trip has been started successfully!'),
            const SizedBox(height: 16),
            const Text('You can now:'),
            const SizedBox(height: 8),
            const Text('• Send 5-minute arrival notification'),
            const Text('• View student list with pickup order'),
            const Text('• Mark attendance for each student'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendArrivalNotification(trip);
            },
            child: const Text('Send Notification'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToStudentAttendance(trip);
            },
            child: const Text('Manage Students'),
          ),
        ],
      ),
    );
  }

  /// Send 5-minute arrival notification
  Future<void> _sendArrivalNotification(Trip trip) async {
    try {
      final message = "🚌 Your child's school bus will arrive in approximately 5 minutes. Please be ready for pickup.";
      
      final response = await _driverService.sendArrivalNotification(
        _driverId!, 
        trip.tripId, 
        message
      );
      
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arrival notification sent to all parents!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send notification: ${response['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startTrip(Trip trip) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Starting trip...'),
            ],
          ),
        ),
      );

      await _driverService.startTrip(_driverId!, trip.tripId);
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Trip "${trip.tripName}" started successfully!')),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Show notification options
      _showNotificationOptions(trip);
      
      // Refresh data
      _refreshData();
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Failed to start trip: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _startTrip(trip),
          ),
        ),
      );
    }
  }

  Future<void> _endTrip(Trip trip) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('End Trip'),
          content: Text('Are you sure you want to end trip "${trip.tripName}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('End Trip'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Ending trip...'),
            ],
          ),
        ),
      );

      await _driverService.endTrip(_driverId!, trip.tripId);
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Trip "${trip.tripName}" ended successfully!')),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Refresh data
      _refreshData();
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Failed to end trip: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _endTrip(trip),
          ),
        ),
      );
    }
  }

  void _showLogoutDialog() {
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
      final authService = AuthService();
      await authService.logout();
      
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
        automaticallyImplyLeading: false, // Remove back button
        title: Row(
          children: [
            const Icon(Icons.local_taxi, size: 28),
            const SizedBox(width: 8),
            Text(_dashboard?.driverName ?? "Driver Dashboard"),
          ],
        ),
        actions: [
          // 🔹 Connection Status
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          
          // Real-time indicator
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // ✅ Welcome Section
                        Text(
                          'Welcome, ${_dashboard?.driverName ?? 'Driver'}!',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'School: ${_dashboard?.schoolName ?? 'N/A'}',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),

                        // ✅ Dashboard Summary Cards
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCard(
                              "Total Trips",
                              (_dashboard?.totalTripsToday ?? 0).toString(),
                              Colors.blue,
                            ),
                            _buildStatCard(
                              "Completed",
                              (_dashboard?.completedTrips ?? 0).toString(),
                              Colors.green,
                            ),
                            _buildStatCard(
                              "Pending",
                              (_dashboard?.pendingTrips ?? 0).toString(),
                              Colors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ✅ Driver & Vehicle Info Card
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Driver & Vehicle Information",
                                    style: TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.blueAccent,
                                    child: Icon(Icons.person, color: Colors.white),
                                  ),
                                  title: Text("Driver: ${_dashboard?.driverName ?? 'N/A'}"),
                                  subtitle: Text("Contact: ${_dashboard?.driverContactNumber ?? 'N/A'}"),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.directions_bus),
                                  title: Text("Vehicle: ${_dashboard?.vehicleNumber ?? 'N/A'}"),
                                  subtitle: Text("Type: ${_dashboard?.vehicleType ?? 'N/A'} | Capacity: ${_dashboard?.vehicleCapacity ?? 'Not Set'} students"),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.school),
                                  title: Text("School: ${_dashboard?.schoolName ?? 'N/A'}"),
                                ),
                              ],
                            ),
                          ),
                        ),
                          const SizedBox(height: 16),
                          
                        // ✅ Student Statistics Card
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Today's Student Statistics",
                                    style: TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildStatCard(
                                      "Total Students",
                                      (_dashboard?.totalStudentsToday ?? 0).toString(),
                                      Colors.purple,
                                    ),
                                    _buildStatCard(
                                      "Picked Up",
                                      (_dashboard?.studentsPickedUp ?? 0).toString(),
                                      Colors.blue,
                                    ),
                                    _buildStatCard(
                                      "Dropped",
                                      (_dashboard?.studentsDropped ?? 0).toString(),
                                      Colors.green,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                          const SizedBox(height: 16),
                          
                        // ✅ Trip Selection Card
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Select Trip",
                                    style: TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                if (_assignedTrips.isNotEmpty) ...[
                                  // Morning Trips
                                  if (_assignedTrips.any((trip) => _isMorningTrip(trip))) ...[
                                    const Text("Morning Trips", 
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                    const SizedBox(height: 8),
                                    ..._assignedTrips
                                        .where((trip) => _isMorningTrip(trip))
                                        .map((trip) => _buildTripSelectionCard(trip)),
                                    const SizedBox(height: 16),
                                  ],
                                  
                                  // Afternoon Trips
                                  if (_assignedTrips.any((trip) => _isAfternoonTrip(trip))) ...[
                                    const Text("Afternoon Trips", 
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                    const SizedBox(height: 8),
                                    ..._assignedTrips
                                        .where((trip) => _isAfternoonTrip(trip))
                                        .map((trip) => _buildTripSelectionCard(trip)),
                                  ],
                                ] else ...[
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: Text(
                                        "No trips assigned for today",
                                        style: TextStyle(color: Colors.grey, fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ✅ Current Trip Info Card
                        if (_dashboard?.currentTripId != null) ...[
                          Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Current Trip",
                                      style: TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  ListTile(
                                    leading: Icon(
                                      Icons.route,
                                      color: _getStatusColor(_dashboard!.currentTripStatus),
                                    ),
                                    title: Text(_dashboard!.currentTripName ?? "Unknown Trip"),
                                    subtitle: Text("Status: ${_dashboard!.currentTripStatus ?? 'Unknown'}"),
                                    trailing: Text(
                                      "${_dashboard!.currentTripStudentCount} students",
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ✅ Assigned Trips Card
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                          const Text("Assigned Trips",
                                    style: TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          if (_assignedTrips.isEmpty)
                                  const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text("No trips assigned for today"),
                            )
                          else
                            ..._assignedTrips.map((trip) => _buildTripCard(trip)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ✅ Quick Actions Card
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
                          
                                // Trip Management Actions
                                ElevatedButton.icon(
                                  onPressed: () => _navigateToTripManagement(),
                                  icon: const Icon(Icons.route),
                                  label: const Text("Trip Management"),
                                ),
                                const SizedBox(height: 8),
                                
                                // Current Trip Actions
                                if (_dashboard?.currentTripId != null) ...[
                                  _buildCurrentTripActions(),
                                ] else if (_assignedTrips.isNotEmpty) ...[
                                  _buildTripSelectionActions(),
                                ],
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

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'NOT_STARTED':
        return Colors.orange;
      case 'IN_PROGRESS':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
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

  Widget _buildCurrentTripActions() {
    final currentTrip = _assignedTrips.firstWhere(
      (trip) => trip.tripId == _dashboard!.currentTripId,
      orElse: () => _assignedTrips.first,
    );

    return Column(
      children: [
        // Trip Status Info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getStatusColor(_dashboard!.currentTripStatus).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getStatusColor(_dashboard!.currentTripStatus),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: _getStatusColor(_dashboard!.currentTripStatus),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Current Trip: ${_dashboard!.currentTripName} (${_dashboard!.currentTripStatus})',
                  style: TextStyle(
                    color: _getStatusColor(_dashboard!.currentTripStatus),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Action Buttons
        ElevatedButton.icon(
          onPressed: _dashboard!.currentTripStatus == 'NOT_STARTED' ? () => _startTrip(currentTrip) : null,
          icon: const Icon(Icons.play_arrow),
          label: const Text("Start Trip"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        
        ElevatedButton.icon(
          onPressed: _dashboard!.currentTripStatus == 'IN_PROGRESS' ? () => _endTrip(currentTrip) : null,
          icon: const Icon(Icons.stop),
          label: const Text("End Trip"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        
        ElevatedButton.icon(
          onPressed: () => _navigateToStudentAttendance(currentTrip),
          icon: const Icon(Icons.checklist),
          label: const Text("Mark Attendance"),
        ),
        const SizedBox(height: 8),
        
        ElevatedButton.icon(
          onPressed: () => _navigateToNotification(currentTrip),
          icon: const Icon(Icons.notifications),
          label: const Text("Send Notification"),
        ),
      ],
    );
  }

  Widget _buildTripSelectionActions() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue, width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No active trip. Select a trip to start:',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        ElevatedButton.icon(
          onPressed: () => _showTripSelectionDialog(),
          icon: const Icon(Icons.route),
          label: const Text("Select Trip"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Check if trip is morning trip (before 12 PM)
  bool _isMorningTrip(Trip trip) {
    final timeString = trip.scheduledTime;
    if (timeString == null) return false;
    
    try {
      final time = DateTime.parse('2024-01-01 $timeString');
      final hour = time.hour;
      return hour < 12;
    } catch (e) {
      return false;
    }
  }

  /// Check if trip is afternoon trip (12 PM or after)
  bool _isAfternoonTrip(Trip trip) {
    final timeString = trip.scheduledTime;
    if (timeString == null) return false;
    
    try {
      final time = DateTime.parse('2024-01-01 $timeString');
      final hour = time.hour;
      return hour >= 12;
    } catch (e) {
      return false;
    }
  }

  /// Build trip selection card
  Widget _buildTripSelectionCard(Trip trip) {
    final isCurrentTrip = _dashboard?.currentTripId == trip.tripId;
    final canStart = trip.tripStatus == 'NOT_STARTED' || trip.tripStatus == 'SCHEDULED';
    
    return Card(
      elevation: isCurrentTrip ? 4 : 2,
      color: isCurrentTrip ? Colors.blue.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isCurrentTrip ? const BorderSide(color: Colors.blue, width: 2) : BorderSide.none,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _isMorningTrip(trip) ? Colors.orange : Colors.blue,
          child: Icon(
            _isMorningTrip(trip) ? Icons.wb_sunny : Icons.wb_twilight,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          trip.tripName,
          style: TextStyle(
            fontWeight: isCurrentTrip ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${_getTripTypeDisplayName(trip.tripType)}'),
            Text('Time: ${trip.scheduledTime ?? 'N/A'}'),
            Text('Students: ${trip.students.length}'),
            Text('Status: ${trip.tripStatus}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canStart && !isCurrentTrip)
              ElevatedButton(
                onPressed: () => _startTrip(trip),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('Start', style: TextStyle(fontSize: 12)),
              ),
            if (isCurrentTrip)
              ElevatedButton(
                onPressed: () => _viewTripDetails(trip),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('Active', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        onTap: () => _viewTripDetails(trip),
      ),
    );
  }

  /// Format time for display
  String _formatTime(DateTime? time) {
    if (time == null) return 'N/A';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Get trip type display name
  String _getTripTypeDisplayName(String? tripType) {
    if (tripType == null) return 'Unknown';
    try {
      return TripType.fromValue(tripType).displayName;
    } catch (e) {
      return tripType; // Fallback to original value
    }
  }

  /// View trip details with student list
  void _viewTripDetails(Trip trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Trip Details - ${trip.tripName}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trip Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Time: ${trip.scheduledTime ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Status: ${trip.tripStatus}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Students: ${trip.students.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Student List
              const Text('Students (Pickup Order):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                height: 200,
                child: ListView.builder(
                  itemCount: trip.students.length,
                  itemBuilder: (context, index) {
                    final student = trip.students[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.blue,
                        child: Text(
                          student.studentName[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      title: Text(student.studentName),
                      subtitle: Text('${student.className} - ${student.sectionName}'),
                      trailing: _getAttendanceStatusChip(student.attendanceStatus),
                      dense: true,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToStudentAttendance(trip);
            },
            child: const Text('Manage Students'),
          ),
        ],
      ),
    );
  }

  void _showTripSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Trip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _assignedTrips.map((trip) => 
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Icon(
                  Icons.route,
                  color: _getStatusColor(trip.tripStatus),
                ),
                title: Text(trip.tripName),
                subtitle: Text('${_getTripTypeDisplayName(trip.tripType)} - ${trip.scheduledTime ?? 'No time set'}'),
                trailing: Text(
                  trip.tripStatus ?? 'Unknown',
                  style: TextStyle(
                    color: _getStatusColor(trip.tripStatus),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToStudentAttendance(trip);
                },
              ),
            ),
          ).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

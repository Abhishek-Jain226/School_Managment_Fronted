import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/models/driver_profile.dart';
import '../../data/models/driver_reports.dart';
import '../../data/models/trip.dart';
import '../../services/driver_service.dart';
import '../../services/auth_service.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart' as websocket;
import '../../app_routes.dart';
import 'driver_profile_page.dart';
import 'driver_reports_page.dart';
import 'simplified_student_management_page.dart';

class SimplifiedDriverDashboardPage extends StatefulWidget {
  const SimplifiedDriverDashboardPage({super.key});

  @override
  State<SimplifiedDriverDashboardPage> createState() => _SimplifiedDriverDashboardPageState();
}

class _SimplifiedDriverDashboardPageState extends State<SimplifiedDriverDashboardPage> {
  
  final DriverService _driverService = DriverService();
  final WebSocketNotificationService _webSocketService = WebSocketNotificationService();
  
  // Data
  DriverProfile? _driverProfile;
  DriverReports? _driverReports;
  Trip? _selectedTrip;
  
  // Trip type selection
  String _selectedTripType = 'MORNING_PICKUP'; // Default to morning
  List<Trip> _morningTrips = [];
  List<Trip> _afternoonTrips = [];
  
  // State
  bool _isLoading = true;
  String? _error;
  int? _driverId;
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  bool _isConnected = false;
  StreamSubscription<websocket.WebSocketNotification>? _notificationSubscription;
  
  // Location tracking
  bool _isTripActive = false;
  Timer? _locationTimer;

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
    _locationTimer?.cancel();
    super.dispose();
  }

  /// Initialize WebSocket connection
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
      
      print('🔌 WebSocket initialized for Simplified Driver Dashboard');
    });
  }

  /// Handle WebSocket notifications
  void _handleWebSocketNotification(websocket.WebSocketNotification notification) {
    print('🔔 Received notification: ${notification.type} - ${notification.message}');
    
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
    
    if (_isRelevantNotification(notification)) {
      _refreshDataSilently();
    }
  }

  /// Check if notification is relevant for dashboard refresh
  bool _isRelevantNotification(websocket.WebSocketNotification notification) {
    return notification.type == websocket.NotificationType.tripUpdate ||
           notification.type == websocket.NotificationType.arrivalNotification ||
           notification.type == websocket.NotificationType.attendanceUpdate ||
           notification.type == websocket.NotificationType.vehicleStatusUpdate;
  }

  /// Handle notification tap
  void _handleNotificationTap(websocket.WebSocketNotification notification) {
    if (notification.type == websocket.NotificationType.tripUpdate) {
      _refreshData();
    } else {
      _refreshDataSilently();
    }
  }

  void _startPeriodicRefresh() {
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
        _driverService.getAssignedTrips(_driverId!),
        _driverService.getDriverReports(_driverId!),
      ]);

      if (mounted && results.length >= 2 && results[0] != null && results[1] != null) {
        setState(() {
          _driverReports = results[1] as DriverReports;
          _isRefreshing = false;
        });
        
        // Process trips and separate by type
        final List<Trip> allTrips = results[0] as List<Trip>;
        _morningTrips = allTrips
            .where((trip) => trip.tripType == 'MORNING_PICKUP')
            .toList();
        _afternoonTrips = allTrips
            .where((trip) => trip.tripType == 'AFTERNOON_DROP')
            .toList();
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
      
      if (_driverId == null) {
        final userId = prefs.getInt('userId');
        final role = prefs.getString('role');
        
        if (userId != null && role == 'DRIVER') {
          try {
            final driverResponse = await _driverService.getDriverByUserId(userId);
            if (driverResponse['success'] == true && driverResponse['data'] != null) {
              final driverData = driverResponse['data'];
              _driverId = driverData['driverId'];
              print('🔍 Found driverId from userId: $_driverId');
              await prefs.setInt('driverId', _driverId!);
            } else {
              throw Exception('Driver record not found');
            }
          } catch (e) {
            print('🔍 Error fetching driverId from userId: $e');
            setState(() {
              _error = 'Driver record not found. Please contact support.';
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

      // Load all data in parallel
      final results = await Future.wait([
        _driverService.getDriverProfile(_driverId!),
        _driverService.getAssignedTrips(_driverId!),
        _driverService.getDriverReports(_driverId!),
      ]);

      if (results.length >= 3 && results[0] != null && results[1] != null && results[2] != null) {
        setState(() {
          _driverProfile = results[0] as DriverProfile;
          _driverReports = results[2] as DriverReports;
          _isLoading = false;
        });
        
        // Process trips and separate by type
        final List<Trip> allTrips = results[1] as List<Trip>;
        _morningTrips = allTrips
            .where((trip) => trip.tripType == 'MORNING_PICKUP')
            .toList();
        _afternoonTrips = allTrips
            .where((trip) => trip.tripType == 'AFTERNOON_DROP')
            .toList();
        
        print('🔍 Simplified dashboard loaded successfully');
        print('🔍 Total trips: ${allTrips.length}');
        print('🔍 Morning trips: ${_morningTrips.length}');
        print('🔍 Afternoon trips: ${_afternoonTrips.length}');
        
        // Debug driver reports data
        if (_driverReports != null) {
          print('🔍 Driver Reports Data:');
          print('🔍 Today Trips: ${_driverReports!.todayTrips}');
          print('🔍 Today Students: ${_driverReports!.todayStudents}');
          print('🔍 Today Pickups: ${_driverReports!.todayPickups}');
          print('🔍 Today Drops: ${_driverReports!.todayDrops}');
          print('🔍 Total Trips Completed: ${_driverReports!.totalTripsCompleted}');
          print('🔍 Total Students Transported: ${_driverReports!.totalStudentsTransported}');
        }
      } else {
        throw Exception('Invalid response from server');
      }
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

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverProfilePage(profile: _driverProfile!),
      ),
    ).then((_) {
      _refreshData();
    });
  }

  void _navigateToReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverReportsPage(reports: _driverReports!),
      ),
    );
  }

  void _navigateToStudentManagement(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimplifiedStudentManagementPage(
          trip: trip,
          driverId: _driverId!,
        ),
      ),
    ).then((_) {
      _refreshData();
    });
  }

  Future<void> _send5MinuteAlert(Trip trip) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Sending 5-minute alert...'),
            ],
          ),
        ),
      );

      final response = await _driverService.send5MinuteAlert(_driverId!, trip.tripId);
      
      Navigator.pop(context); // Close loading dialog
      
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? '5-minute alert sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to send alert'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send alert: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.local_taxi, size: 28),
            const SizedBox(width: 8),
            Text(_driverProfile?.driverName ?? "Driver Dashboard"),
          ],
        ),
        actions: [
          // Connection Status
          Icon(
            _isConnected ? Icons.wifi : Icons.wifi_off,
            color: _isConnected ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          // Profile Photo
          GestureDetector(
            onTap: _navigateToProfile,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              backgroundImage: _driverProfile?.driverPhoto != null 
                ? MemoryImage(base64Decode(_driverProfile!.driverPhoto!))
                : null,
              child: _driverProfile?.driverPhoto == null 
                ? const Icon(Icons.person, size: 20, color: Colors.white)
                : null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: _buildDrawer(),
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
                        // Trip Type Selection
                        _buildTripTypeSelection(),
                        const SizedBox(height: 20),

                        // Selected Trip Actions
                        if (_selectedTrip != null) ...[
                          _buildSelectedTripCard(),
                          const SizedBox(height: 20),
                        ],

                        // Today's Summary
                        _buildTodaySummaryCard(),
                        const SizedBox(height: 20),

                        // Quick Actions
                        _buildQuickActionsCard(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: _driverProfile?.driverPhoto != null 
                    ? MemoryImage(base64Decode(_driverProfile!.driverPhoto!))
                    : null,
                  child: _driverProfile?.driverPhoto == null 
                    ? const Icon(Icons.person, size: 40, color: Colors.blue)
                    : null,
                ),
                const SizedBox(height: 12),
                Text(
                  _driverProfile?.driverName ?? 'Driver',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _driverProfile?.schoolName ?? 'School',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              _navigateToProfile();
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Reports'),
            onTap: () {
              Navigator.pop(context);
              _navigateToReports();
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.pop(context);
              _showHelpDialog();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: _showLogoutDialog,
          ),
        ],
      ),
    );
  }


  Widget _buildTripTypeSelection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Trip Type:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Radio buttons for trip type selection
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Morning Pickup'),
                    subtitle: Text('${_morningTrips.length} trips available'),
                    value: 'MORNING_PICKUP',
                    groupValue: _selectedTripType,
                    onChanged: (String? value) {
                      setState(() {
                        _selectedTripType = value!;
                        _selectedTrip = null; // Reset selected trip
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Afternoon Drop'),
                    subtitle: Text('${_afternoonTrips.length} trips available'),
                    value: 'AFTERNOON_DROP',
                    groupValue: _selectedTripType,
                    onChanged: (String? value) {
                      setState(() {
                        _selectedTripType = value!;
                        _selectedTrip = null; // Reset selected trip
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Trip selection dropdown based on selected type
            if (_getAvailableTrips().isNotEmpty) ...[
              const Text(
                'Select Your Trip:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedTrip?.tripId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('Choose a trip...'),
                items: _getAvailableTrips().map((trip) {
                  return DropdownMenuItem<int>(
                    value: trip.tripId,
                    child: Text('${trip.tripName} - ${trip.scheduledTime ?? 'No time'}'),
                  );
                }).toList(),
                onChanged: (int? tripId) {
                  if (tripId != null) {
                    setState(() {
                      try {
                        _selectedTrip = _getAvailableTrips().firstWhere(
                          (trip) => trip.tripId == tripId,
                        );
                      } catch (e) {
                        // If trip not found, select the first available trip
                        _selectedTrip = _getAvailableTrips().isNotEmpty 
                            ? _getAvailableTrips().first 
                            : null;
                      }
                    });
                  }
                },
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No ${_selectedTripType == 'MORNING_PICKUP' ? 'morning pickup' : 'afternoon drop'} trips available',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  List<Trip> _getAvailableTrips() {
    return _selectedTripType == 'MORNING_PICKUP' ? _morningTrips : _afternoonTrips;
  }

  Widget _buildSelectedTripCard() {
    if (_selectedTrip == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      color: Colors.blue.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.blue, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                const Text(
                  "Selected Trip",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _selectedTrip!.tripName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text("Time: ${_selectedTrip!.scheduledTime ?? 'Not set'}"),
            Text("Students: ${_selectedTrip!.students.length}"),
            const SizedBox(height: 16),
            
            // Trip Status Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isTripActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isTripActive ? Colors.green : Colors.grey,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isTripActive ? Icons.location_on : Icons.location_off,
                    color: _isTripActive ? Colors.green : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isTripActive ? 'Trip Active - Location Tracking' : 'Trip Inactive',
                    style: TextStyle(
                      color: _isTripActive ? Colors.green : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: !_isTripActive ? _startTrip : null,
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Start Trip'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isTripActive ? Colors.green : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTripActive ? _stopTrip : null,
                    icon: const Icon(Icons.stop, size: 16),
                    label: const Text('Stop Trip'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTripActive ? Colors.red : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTripActive ? () => _navigateToStudentManagement(_selectedTrip!) : null,
                    icon: const Icon(Icons.people, size: 16),
                    label: const Text('View Students'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTripActive ? Colors.blue : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySummaryCard() {
    if (_driverReports == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    print('🔍 Building Today Summary Card with data:');
    print('🔍 Today Trips: ${_driverReports!.todayTrips}');
    print('🔍 Today Students: ${_driverReports!.todayStudents}');
    print('🔍 Today Pickups: ${_driverReports!.todayPickups}');
    print('🔍 Today Drops: ${_driverReports!.todayDrops}');
    print('🔍 Total Trips Completed: ${_driverReports!.totalTripsCompleted}');
    print('🔍 Total Students Transported: ${_driverReports!.totalStudentsTransported}');
    print('🔍 Month Pickups: ${_driverReports!.monthPickups}');
    print('🔍 Month Drops: ${_driverReports!.monthDrops}');

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Driver Performance Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSimpleStatCard("Total Trips", _driverReports!.totalTripsCompleted.toString(), Colors.blue),
                _buildSimpleStatCard("Total Students", _driverReports!.totalStudentsTransported.toString(), Colors.green),
                _buildSimpleStatCard("Students Picked Up", _driverReports!.monthPickups.toString(), Colors.orange),
                _buildSimpleStatCard("Students Dropped", _driverReports!.monthDrops.toString(), Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 3,
      color: Colors.green.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.green, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                const Text(
                  "Driver Instructions",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "1. Select a trip from the dropdown above\n"
              "2. Click 'View Students' to see pickup order\n"
              "3. Click 'Send Alert' to notify parents\n"
              "4. Mark pickup/drop for each student",
              style: TextStyle(fontSize: 14, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'For any issues or questions:\n\n'
          '• Contact your school administrator\n'
          '• Check your internet connection\n'
          '• Make sure you\'re in the correct time slot\n'
          '• Refresh the app if data seems outdated',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ================ LOCATION TRACKING METHODS ================

  Future<void> _startTrip() async {
    if (_selectedTrip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a trip first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate directly to student management form
    _navigateToStudentManagement(_selectedTrip!);
  }


  Future<bool> _requestLocationPermission() async {
    // Check current permission status
    var status = await Permission.location.status;
    
    print('🔍 Current location permission status: $status');
    
    // If permission is already granted, return true
    if (status == PermissionStatus.granted) {
      return true;
    }
    
    // If permission is denied permanently, show dialog to open settings
    if (status == PermissionStatus.permanentlyDenied) {
      _showPermissionDeniedDialog();
      return false;
    }
    
    // If permission is denied or restricted, request it
    if (status == PermissionStatus.denied || status == PermissionStatus.restricted) {
      status = await Permission.location.request();
      print('🔍 Location permission request result: $status');
      
      if (status == PermissionStatus.granted) {
        return true;
      } else if (status == PermissionStatus.permanentlyDenied) {
        _showPermissionDeniedDialog();
        return false;
      } else {
        _showPermissionDeniedDialog();
        return false;
      }
    }
    
    return false;
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs location permission to track your trip and share your location with parents. Please grant location permission in the app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showLocationSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Location services are disabled. Please enable them in your device settings to start trip tracking.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _stopTrip() async {
    if (_selectedTrip == null) return;
    
    try {
      setState(() {
        _isLoading = true;
      });

      // Stop location tracking
      _locationTimer?.cancel();
      _locationTimer = null;

      // Call backend to end trip
      final response = await _driverService.endTrip(_driverId!, _selectedTrip!.tripId);
      
      if (response['success'] == true) {
        setState(() {
          _isTripActive = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip stopped successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to stop trip'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error stopping trip: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startLocationTracking() {
    // Use live location tracking instead of periodic updates
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) async {
      if (_isTripActive && _selectedTrip != null) {
        // Send location update to backend
        await _sendLocationUpdate(position);
      }
    }, onError: (error) {
      print('Error in location stream: $error');
    });
  }

  Future<void> _sendLocationUpdate(Position position) async {
    try {
      print('📍 Location Update: ${position.latitude}, ${position.longitude}');
      
      // Send location update to backend
      await _driverService.updateDriverLocation(_driverId!, position.latitude, position.longitude);
      
    } catch (e) {
      print('Error sending location update: $e');
    }
  }
}

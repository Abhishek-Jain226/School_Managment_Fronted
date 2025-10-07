import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/driver_dashboard.dart';
import '../../data/models/trip.dart';
import '../../services/driver_service.dart';
import '../../services/auth_service.dart';
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
  DriverDashboard? _dashboard;
  List<Trip> _assignedTrips = [];
  bool _isLoading = true;
  String? _error;
  int? _driverId;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
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
      
      // Debug: Print all stored preferences
      final allKeys = prefs.getKeys();
      print('🔍 All stored preferences: $allKeys');
      for (String key in allKeys) {
        print('🔍 $key: ${prefs.get(key)}');
      }
      
      if (_driverId == null) {
        print('⚠️ Driver ID is null! Checking if user has DRIVER role...');
        
        // Check if user has DRIVER role but driverId is missing
        final role = prefs.getString('role');
        print('🔍 User role: $role');
        
        if (role == 'DRIVER') {
          print('🔍 User has DRIVER role but driverId is null. Trying to fetch driverId from userId...');
          
          // Try to get driverId from userId
          final userId = prefs.getInt('userId');
          if (userId != null) {
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
                
                // Continue with dashboard loading
              } else {
                setState(() {
                  _error = 'Driver record not found for this user. Please register as driver again.';
                  _isLoading = false;
                });
                return;
              }
            } catch (e) {
              print('🔍 Error fetching driverId from userId: $e');
              setState(() {
                _error = 'Driver ID not found but user has DRIVER role. Please contact support or register as driver again.';
                _isLoading = false;
              });
              return;
            }
          } else {
            setState(() {
              _error = 'Driver ID not found but user has DRIVER role. Please contact support or register as driver again.';
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

      // Load dashboard data and assigned trips
      final dashboard = await _driverService.getDriverDashboard(_driverId!);
      final trips = await _driverService.getAssignedTrips(_driverId!);

      setState(() {
        _dashboard = dashboard;
        _assignedTrips = trips;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load driver data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadDriverData();
  }

  /// Info card widget
  Widget _buildInfoCard(String label, String value, {IconData? icon, Color? valueColor}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
        child: Row(
          children: [
            if (icon != null) Icon(icon, color: Colors.blueGrey, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 6),
                Text(value,
                    style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: valueColor ?? Colors.black)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Quick Action button
  Widget _buildQuickAction(String label, IconData icon, VoidCallback onTap, {bool isEnabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ElevatedButton.icon(
        onPressed: isEnabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: isEnabled ? null : Colors.grey[300],
        ),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
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
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(trip.tripName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${trip.tripType} - ${trip.scheduledTime ?? 'No time set'}'),
            Text('Students: ${trip.totalStudents} | Picked: ${trip.studentsPickedUp} | Dropped: ${trip.studentsDropped}'),
          ],
        ),
        trailing: Text(
          trip.tripStatus ?? 'Unknown',
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () => _navigateToTripDetails(trip),
      ),
    );
  }

  void _navigateToTripDetails(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripDetailsPage(trip: trip),
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
        builder: (context) => NotificationPage(trip: trip),
      ),
    );
  }

  Future<void> _startTrip(Trip trip) async {
    try {
      await _driverService.startTrip(_driverId!, trip.tripId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trip "${trip.tripName}" started successfully!')),
      );
      _refreshData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start trip: $e')),
      );
    }
  }

  Future<void> _endTrip(Trip trip) async {
    try {
      await _driverService.endTrip(_driverId!, trip.tripId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trip "${trip.tripName}" ended successfully!')),
      );
      _refreshData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to end trip: $e')),
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
        title: Row(
          children: [
            const Icon(Icons.local_taxi, size: 28),
            const SizedBox(width: 8),
            Text(_dashboard?.driverName ?? "Driver Dashboard"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Driver Info
                        if (_dashboard != null) ...[
                          _buildInfoCard("Driver Name", _dashboard!.driverName,
                              icon: Icons.person),
                          _buildInfoCard("Contact", _dashboard!.driverContactNumber,
                              icon: Icons.phone),
                          
                          const SizedBox(height: 16),
                          
                          // Vehicle Info
                          _buildInfoCard("Assigned Vehicle", _dashboard!.vehicleNumber,
                              icon: Icons.directions_bus),
                          _buildInfoCard("Vehicle Type", _dashboard!.vehicleType,
                              icon: Icons.local_taxi),
                          _buildInfoCard("Capacity", "${_dashboard!.vehicleCapacity} students",
                              icon: Icons.group),
                          
                          const SizedBox(height: 16),
                          
                          // School Info
                          _buildInfoCard("School", _dashboard!.schoolName,
                              icon: Icons.school),
                          
                          const SizedBox(height: 16),
                          
                          // Trip Statistics
                          _buildInfoCard("Total Trips Today", "${_dashboard!.totalTripsToday}",
                              icon: Icons.route),
                          _buildInfoCard("Completed Trips", "${_dashboard!.completedTrips}",
                              icon: Icons.check_circle, valueColor: Colors.green),
                          _buildInfoCard("Pending Trips", "${_dashboard!.pendingTrips}",
                              icon: Icons.schedule, valueColor: Colors.orange),
                          
                          const SizedBox(height: 16),
                          
                          // Student Statistics
                          _buildInfoCard("Total Students Today", "${_dashboard!.totalStudentsToday}",
                              icon: Icons.group),
                          _buildInfoCard("Students Picked Up", "${_dashboard!.studentsPickedUp}",
                              icon: Icons.person_add, valueColor: Colors.blue),
                          _buildInfoCard("Students Dropped", "${_dashboard!.studentsDropped}",
                              icon: Icons.person_remove, valueColor: Colors.green),
                          
                          const SizedBox(height: 20),
                          const Divider(),
                          
                          // Current Trip Info
                          if (_dashboard!.currentTripId != null) ...[
                            const Text("Current Trip",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            _buildInfoCard("Trip Name", _dashboard!.currentTripName ?? "Unknown",
                                icon: Icons.route),
                            _buildInfoCard("Status", _dashboard!.currentTripStatus ?? "Unknown",
                                icon: Icons.info, valueColor: _getStatusColor(_dashboard!.currentTripStatus)),
                            _buildInfoCard("Students", "${_dashboard!.currentTripStudentCount}",
                                icon: Icons.group),
                          ],
                          
                          const SizedBox(height: 20),
                          const Divider(),
                          
                          // Assigned Trips
                          const Text("Assigned Trips",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          
                          if (_assignedTrips.isEmpty)
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text("No trips assigned for today"),
                              ),
                            )
                          else
                            ..._assignedTrips.map((trip) => _buildTripCard(trip)),
                          
                          const SizedBox(height: 20),
                          const Divider(),
                          
                          // Quick Actions
                          const Text("Quick Actions",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          
                          // Find current trip for actions
                          if (_dashboard!.currentTripId != null) ...[
                            _buildQuickAction("Start Trip", Icons.play_arrow, () {
                              final currentTrip = _assignedTrips.firstWhere(
                                (trip) => trip.tripId == _dashboard!.currentTripId,
                                orElse: () => _assignedTrips.first,
                              );
                              _startTrip(currentTrip);
                            }, isEnabled: _dashboard!.currentTripStatus == 'NOT_STARTED'),
                            
                            _buildQuickAction("End Trip", Icons.stop, () {
                              final currentTrip = _assignedTrips.firstWhere(
                                (trip) => trip.tripId == _dashboard!.currentTripId,
                                orElse: () => _assignedTrips.first,
                              );
                              _endTrip(currentTrip);
                            }, isEnabled: _dashboard!.currentTripStatus == 'IN_PROGRESS'),
                          ],
                          
                          _buildQuickAction("Trip Management", Icons.route, () {
                            _navigateToTripManagement();
                          }),
                          
                          if (_dashboard!.currentTripId != null) ...[
                            _buildQuickAction("Mark Attendance", Icons.checklist, () {
                              final currentTrip = _assignedTrips.firstWhere(
                                (trip) => trip.tripId == _dashboard!.currentTripId,
                                orElse: () => _assignedTrips.first,
                              );
                              _navigateToStudentAttendance(currentTrip);
                            }),
                            
                            _buildQuickAction("Send Notification", Icons.notifications, () {
                              final currentTrip = _assignedTrips.firstWhere(
                                (trip) => trip.tripId == _dashboard!.currentTripId,
                                orElse: () => _assignedTrips.first,
                              );
                              _navigateToNotification(currentTrip);
                            }),
                          ],
                        ],
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
}

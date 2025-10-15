import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/parent_service.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart' as websocket;
import '../../data/models/trip.dart';

class VehicleTrackingPage extends StatefulWidget {
  const VehicleTrackingPage({super.key});

  @override
  State<VehicleTrackingPage> createState() => _VehicleTrackingPageState();
}

class _VehicleTrackingPageState extends State<VehicleTrackingPage> {
  final ParentService _parentService = ParentService();
  final WebSocketNotificationService _webSocketService = WebSocketNotificationService();
  
  // State
  bool _isLoading = true;
  String? _error;
  int? _userId;
  bool _isConnected = false;
  
  // Location tracking data
  Map<String, dynamic>? _currentLocation;
  Trip? _activeTrip;
  String? _driverName;
  String? _vehicleNumber;
  DateTime? _lastLocationUpdate;
  Timer? _locationTimer;
  
  // WebSocket subscription
  StreamSubscription<websocket.WebSocketNotification>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId');
    });
    _loadActiveTrip();
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
      
      print('🔌 WebSocket initialized for Vehicle Tracking');
    });
  }

  void _handleWebSocketNotification(websocket.WebSocketNotification notification) {
    print('🔔 Vehicle Tracking - Received notification: ${notification.type} - ${notification.message}');
    
    if (notification.type == websocket.NotificationType.locationUpdate) {
      _handleLocationUpdate(notification);
    } else if (notification.type == websocket.NotificationType.tripUpdate) {
      _loadActiveTrip();
    }
  }

  void _handleLocationUpdate(websocket.WebSocketNotification notification) {
    if (notification.data != null) {
      setState(() {
        _currentLocation = notification.data;
        _lastLocationUpdate = DateTime.now();
      });
    }
  }

  Future<void> _loadActiveTrip() async {
    if (_userId == null) return;
    
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get student data for this parent
      final studentResponse = await _parentService.getStudentByParentUserId(_userId!);
      
      if (studentResponse['success'] == true && studentResponse['data'] != null) {
        final studentData = studentResponse['data'];
        final studentId = studentData['studentId'];
        
        // Get active trips for this student
        final tripsResponse = await _parentService.getStudentTrips(studentId);
        
        if (tripsResponse['success'] == true && tripsResponse['data'] != null) {
          final trips = tripsResponse['data'] as List;
          
          // Find active trip (you might need to adjust this logic based on your trip status)
          final activeTrip = trips.firstWhere(
            (trip) => trip['tripStatus'] == 'IN_PROGRESS' || trip['tripStatus'] == 'STARTED',
            orElse: () => null,
          );
          
          if (activeTrip != null) {
            setState(() {
              _activeTrip = Trip.fromJson(activeTrip);
              _driverName = activeTrip['driverName'];
              _vehicleNumber = activeTrip['vehicleNumber'];
            });
          }
        }
      }
      
      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error loading active trip: $e');
      setState(() {
        _error = 'Failed to load trip data: $e';
        _isLoading = false;
      });
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  Color _getLocationStatusColor() {
    if (_lastLocationUpdate == null) return Colors.grey;
    
    final now = DateTime.now();
    final difference = now.difference(_lastLocationUpdate!);
    
    if (difference.inMinutes < 2) {
      return Colors.green; // Live
    } else if (difference.inMinutes < 5) {
      return Colors.orange; // Recent
    } else {
      return Colors.red; // Stale
    }
  }

  String _getLocationStatusText() {
    if (_lastLocationUpdate == null) return 'No location data';
    
    final now = DateTime.now();
    final difference = now.difference(_lastLocationUpdate!);
    
    if (difference.inMinutes < 2) {
      return 'Live tracking';
    } else if (difference.inMinutes < 5) {
      return 'Recent update';
    } else {
      return 'Location may be outdated';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.location_on, size: 24),
            SizedBox(width: 8),
            Text('Vehicle Tracking'),
          ],
        ),
        actions: [
          // Connection status
          Icon(
            _isConnected ? Icons.wifi : Icons.wifi_off,
            color: _isConnected ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActiveTrip,
            tooltip: 'Refresh',
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
                        onPressed: _loadActiveTrip,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _activeTrip == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_taxi, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'No Active Trip',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your child is not currently on any trip.',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Trip Information Card
                          _buildTripInfoCard(),
                          const SizedBox(height: 20),
                          
                          // Location Status Card
                          _buildLocationStatusCard(),
                          const SizedBox(height: 20),
                          
                          // Map Placeholder (you can integrate Google Maps here)
                          _buildMapPlaceholder(),
                          const SizedBox(height: 20),
                          
                          // Trip Progress Card
                          _buildTripProgressCard(),
                          const SizedBox(height: 20),
                          
                          // Driver Information Card
                          _buildDriverInfoCard(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildTripInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _activeTrip!.tripType == 'MORNING_PICKUP' ? Icons.wb_sunny : Icons.wb_twilight,
                  color: _activeTrip!.tripType == 'MORNING_PICKUP' ? Colors.orange : Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Trip Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Trip Name', _activeTrip!.tripName),
            _buildInfoRow('Type', _activeTrip!.tripType == 'MORNING_PICKUP' ? 'Morning Pickup' : 'Afternoon Drop'),
            _buildInfoRow('Scheduled Time', _activeTrip!.scheduledTime ?? 'Not set'),
            _buildInfoRow('Status', _activeTrip!.tripStatus ?? 'Unknown'),
            _buildInfoRow('Students', '${_activeTrip!.students.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getLocationStatusColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Location Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Status', _getLocationStatusText()),
            _buildInfoRow('Last Update', _getTimeAgo(_lastLocationUpdate)),
            if (_currentLocation != null) ...[
              _buildInfoRow('Latitude', _currentLocation!['latitude']?.toString() ?? 'N/A'),
              _buildInfoRow('Longitude', _currentLocation!['longitude']?.toString() ?? 'N/A'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[100],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Map View',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Real-time vehicle location will be shown here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            if (_currentLocation != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '📍 ${_currentLocation!['latitude']?.toStringAsFixed(6)}, ${_currentLocation!['longitude']?.toStringAsFixed(6)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTripProgressCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trip Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Progress indicators
            _buildProgressStep(
              'Trip Started',
              true,
              Icons.play_circle,
              Colors.green,
            ),
            _buildProgressStep(
              'In Progress',
              _currentLocation != null,
              Icons.location_on,
              _currentLocation != null ? Colors.blue : Colors.grey,
            ),
            _buildProgressStep(
              'Arriving Soon',
              false,
              Icons.schedule,
              Colors.grey,
            ),
            _buildProgressStep(
              'Trip Completed',
              false,
              Icons.check_circle,
              Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStep(String title, bool isActive, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? Colors.black : Colors.grey,
              ),
            ),
          ),
          if (isActive)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDriverInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Driver Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Driver Name', _driverName ?? 'Unknown'),
            _buildInfoRow('Vehicle Number', _vehicleNumber ?? 'Unknown'),
            _buildInfoRow('Vehicle Type', _activeTrip?.vehicleType ?? 'Unknown'),
            _buildInfoRow('School', _activeTrip?.schoolName ?? 'Unknown'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

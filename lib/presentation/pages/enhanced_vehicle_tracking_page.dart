import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/parent_service.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart' as websocket;
import '../../data/models/trip.dart';

class EnhancedVehicleTrackingPage extends StatefulWidget {
  const EnhancedVehicleTrackingPage({super.key});

  @override
  State<EnhancedVehicleTrackingPage> createState() => _EnhancedVehicleTrackingPageState();
}

class _EnhancedVehicleTrackingPageState extends State<EnhancedVehicleTrackingPage> {
  final ParentService _parentService = ParentService();
  final WebSocketNotificationService _webSocketService = WebSocketNotificationService();
  
  // Google Maps
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  // State
  bool _isLoading = true;
  String? _error;
  int? _userId;
  bool _isConnected = false;
  
  // Location tracking data
  LatLng? _driverLocation;
  LatLng? _destinationLocation;
  Trip? _activeTrip;
  String? _driverName;
  String? _vehicleNumber;
  DateTime? _lastLocationUpdate;
  String? _estimatedArrivalTime;
  String? _currentAddress;
  
  // WebSocket subscription
  StreamSubscription<websocket.WebSocketNotification>? _notificationSubscription;
  Timer? _etaUpdateTimer;

  // Map settings
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(28.6139, 77.2090), // Delhi coordinates as default
    zoom: 15,
  );

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _etaUpdateTimer?.cancel();
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
      
      print('🔌 WebSocket initialized for Enhanced Vehicle Tracking');
    });
  }

  void _handleWebSocketNotification(websocket.WebSocketNotification notification) {
    print('🔔 Enhanced Vehicle Tracking - Received notification: ${notification.type} - ${notification.message}');
    
    if (notification.type == websocket.NotificationType.locationUpdate) {
      _handleLocationUpdate(notification);
    } else if (notification.type == websocket.NotificationType.tripUpdate) {
      _loadActiveTrip();
    }
  }

  void _handleLocationUpdate(websocket.WebSocketNotification notification) {
    if (notification.data != null) {
      final lat = notification.data!['latitude'] as double?;
      final lng = notification.data!['longitude'] as double?;
      
      if (lat != null && lng != null) {
        setState(() {
          _driverLocation = LatLng(lat, lng);
          _lastLocationUpdate = DateTime.now();
        });
        
        _updateMapMarkers();
        _updateETA();
        _getAddressFromCoordinates(lat, lng);
      }
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
          
          // Find active trip
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
            
            // Set destination based on trip type
            _setDestinationLocation();
            _startETAUpdates();
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

  void _setDestinationLocation() {
    if (_activeTrip == null) return;
    
    // For demo purposes, using Delhi coordinates
    // In real implementation, you would get actual school/home coordinates
    if (_activeTrip!.tripType == 'MORNING_PICKUP') {
      // Going to school
      _destinationLocation = const LatLng(28.6139, 77.2090); // School location
    } else {
      // Going home
      _destinationLocation = const LatLng(28.6141, 77.2092); // Home location
    }
  }

  void _startETAUpdates() {
    _etaUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateETA();
    });
  }

  void _updateETA() {
    if (_driverLocation == null || _destinationLocation == null) return;
    
    // Calculate distance and estimated time
    final distance = Geolocator.distanceBetween(
      _driverLocation!.latitude,
      _driverLocation!.longitude,
      _destinationLocation!.latitude,
      _destinationLocation!.longitude,
    );
    
    // Assume average speed of 30 km/h in city traffic
    final estimatedMinutes = (distance / 1000) / 30 * 60;
    
    final arrivalTime = DateTime.now().add(Duration(minutes: estimatedMinutes.round()));
    
    setState(() {
      _estimatedArrivalTime = _formatTime(arrivalTime);
    });
  }

  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        setState(() {
          _currentAddress = '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}';
        });
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  void _updateMapMarkers() {
    _markers.clear();
    
    if (_driverLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Driver Location',
            snippet: _currentAddress ?? 'Current location',
          ),
        ),
      );
    }
    
    if (_destinationLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: _activeTrip?.tripType == 'MORNING_PICKUP' ? 'School' : 'Home',
            snippet: 'Destination',
          ),
        ),
      );
    }
    
    // Add route polyline if both locations are available
    if (_driverLocation != null && _destinationLocation != null) {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_driverLocation!, _destinationLocation!],
          color: Colors.blue,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    }
    
    setState(() {});
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateMapMarkers();
  }

  String _formatTime(DateTime dateTime) {
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
            Text('Live Vehicle Tracking'),
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
                  : Column(
                      children: [
                        // ETA and Status Bar
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          color: Colors.blue[50],
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildETAInfo(),
                                  _buildLocationStatus(),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_currentAddress != null)
                                Text(
                                  _currentAddress!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        ),
                        
                        // Google Map
                        Expanded(
                          child: GoogleMap(
                            onMapCreated: _onMapCreated,
                            initialCameraPosition: _initialPosition,
                            markers: _markers,
                            polylines: _polylines,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            zoomControlsEnabled: true,
                            mapType: MapType.normal,
                            onTap: (LatLng position) {
                              // Handle map tap if needed
                            },
                          ),
                        ),
                        
                        // Trip Information Panel
                        Container(
                          height: 120,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _activeTrip!.tripType == 'MORNING_PICKUP' ? Icons.wb_sunny : Icons.wb_twilight,
                                    color: _activeTrip!.tripType == 'MORNING_PICKUP' ? Colors.orange : Colors.blue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _activeTrip!.tripType == 'MORNING_PICKUP' ? 'Morning Pickup' : 'Afternoon Drop',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Driver: ${_driverName ?? 'Unknown'}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        'Vehicle: ${_vehicleNumber ?? 'Unknown'}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Status: ${_activeTrip!.tripStatus ?? 'Unknown'}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        'Students: ${_activeTrip!.students.length}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildETAInfo() {
    return Column(
      children: [
        const Icon(Icons.access_time, color: Colors.blue, size: 24),
        const SizedBox(height: 4),
        Text(
          'ETA',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Text(
          _estimatedArrivalTime ?? 'Calculating...',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      ],
    );
  }

  Widget _buildLocationStatus() {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _getLocationStatusColor(),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Status',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Text(
          _getLocationStatusText(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _getLocationStatusColor(),
          ),
        ),
      ],
    );
  }
}

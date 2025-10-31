import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/parent_service.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart' as websocket;
import '../../data/models/trip.dart';
import '../../utils/constants.dart';

class EnhancedVehicleTrackingPage extends StatefulWidget {
  const EnhancedVehicleTrackingPage({super.key});

  @override
  State<EnhancedVehicleTrackingPage> createState() => _EnhancedVehicleTrackingPageState();
}

class _EnhancedVehicleTrackingPageState extends State<EnhancedVehicleTrackingPage> {
  final ParentService _parentService = ParentService();
  final WebSocketNotificationService _webSocketService = WebSocketNotificationService();
  
  // Google Maps
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  
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
    target: LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude),
    zoom: AppSizes.vehicleTrackingZoom,
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
      _userId = prefs.getInt(AppConstants.keyUserId);
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
          debugPrint('${AppConstants.msgWebSocketError}$error');
          setState(() {
            _isConnected = false;
          });
        },
      );
      
      debugPrint(AppConstants.msgWebSocketInitializedVehicleTracking);
    });
  }

  void _handleWebSocketNotification(websocket.WebSocketNotification notification) {
    debugPrint('${AppConstants.msgReceivedNotificationVehicleTracking}${notification.type} - ${notification.message}');
    
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
      debugPrint('${AppConstants.msgErrorLoadingTrip}$e');
      setState(() {
        _error = '${AppConstants.msgFailedToLoadTripData}$e';
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
      _destinationLocation = const LatLng(AppConstants.schoolLatitude, AppConstants.schoolLongitude);
    } else {
      // Going home
      _destinationLocation = const LatLng(AppConstants.homeLatitude, AppConstants.homeLongitude);
    }
  }

  void _startETAUpdates() {
    _etaUpdateTimer = Timer.periodic(const Duration(seconds: AppConstants.etaUpdateSeconds), (timer) {
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
    final estimatedMinutes = (distance / 1000) / AppConstants.averageSpeedKmh * 60;
    
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
      debugPrint('${AppConstants.msgErrorGettingAddress}$e');
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
            title: AppConstants.labelDriverLocation,
            snippet: _currentAddress ?? AppConstants.labelCurrentLocation,
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
            title: _activeTrip?.tripType == 'MORNING_PICKUP' ? AppConstants.labelSchool : AppConstants.labelHome,
            snippet: AppConstants.labelDestination,
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
          color: AppColors.vehicleTrackingBlueColor,
          width: AppSizes.vehicleTrackingPolylineWidth,
          patterns: [
            PatternItem.dash(AppSizes.vehicleTrackingPolylineDash),
            PatternItem.gap(AppSizes.vehicleTrackingPolylineGap),
          ],
        ),
      );
    }
    
    setState(() {});
  }

  void _onMapCreated(GoogleMapController controller) {
    _updateMapMarkers();
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return AppConstants.labelUnknown;
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return AppConstants.labelJustNow;
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}${AppConstants.labelMinutesAgo}';
    } else {
      return '${difference.inHours}${AppConstants.labelHoursAgo}';
    }
  }

  Color _getLocationStatusColor() {
    if (_lastLocationUpdate == null) return AppColors.vehicleTrackingGreyColor;
    
    final now = DateTime.now();
    final difference = now.difference(_lastLocationUpdate!);
    
    if (difference.inMinutes < AppConstants.locationLiveMinutes) {
      return AppColors.vehicleTrackingGreenColor; // Live
    } else if (difference.inMinutes < AppConstants.locationRecentMinutes) {
      return AppColors.vehicleTrackingOrangeColor; // Recent
    } else {
      return AppColors.vehicleTrackingRedColor; // Stale
    }
  }

  String _getLocationStatusText() {
    if (_lastLocationUpdate == null) return AppConstants.labelNoLocationData;
    
    final now = DateTime.now();
    final difference = now.difference(_lastLocationUpdate!);
    
    if (difference.inMinutes < AppConstants.locationLiveMinutes) {
      return AppConstants.labelLiveTracking;
    } else if (difference.inMinutes < AppConstants.locationRecentMinutes) {
      return AppConstants.labelRecentUpdate;
    } else {
      return AppConstants.labelLocationOutdated;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.location_on, size: AppSizes.vehicleTrackingAppBarIconSize),
            SizedBox(width: AppSizes.vehicleTrackingAppBarSpacing),
            Text(AppConstants.labelLiveVehicleTracking),
          ],
        ),
        actions: [
          // Connection status
          Icon(
            _isConnected ? Icons.wifi : Icons.wifi_off,
            color: _isConnected ? AppColors.vehicleTrackingGreenColor : AppColors.vehicleTrackingRedColor,
            size: AppSizes.vehicleTrackingWifiIconSize,
          ),
          const SizedBox(width: AppSizes.vehicleTrackingAppBarSpacing),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActiveTrip,
            tooltip: AppConstants.labelRefresh,
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
                      Icon(Icons.error, size: AppSizes.vehicleTrackingErrorIconSize, color: AppColors.vehicleTrackingRedColor),
                      const SizedBox(height: AppSizes.vehicleTrackingErrorSpacing),
                      Text(
                        _error!,
                        style: const TextStyle(fontSize: AppSizes.vehicleTrackingErrorFontSize),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizes.vehicleTrackingErrorSpacing),
                      ElevatedButton(
                        onPressed: _loadActiveTrip,
                        child: const Text(AppConstants.labelRetry),
                      ),
                    ],
                  ),
                )
              : _activeTrip == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_taxi, size: AppSizes.vehicleTrackingNoTripIconSize, color: AppColors.vehicleTrackingGreyColor),
                          const SizedBox(height: AppSizes.vehicleTrackingNoTripSpacing),
                          const Text(
                            AppConstants.labelNoActiveTrip,
                            style: TextStyle(fontSize: AppSizes.vehicleTrackingNoTripTitleFontSize, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: AppSizes.vehicleTrackingAppBarSpacing),
                          const Text(
                            AppConstants.labelChildNotOnTrip,
                            style: TextStyle(fontSize: AppSizes.vehicleTrackingNoTripMsgFontSize, color: AppColors.vehicleTrackingGreyColor),
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
                          padding: const EdgeInsets.all(AppSizes.vehicleTrackingBarPadding),
                          color: AppColors.vehicleTrackingBlueColor.withValues(alpha: 0.1),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildETAInfo(),
                                  _buildLocationStatus(),
                                ],
                              ),
                              const SizedBox(height: AppSizes.vehicleTrackingBarSpacing),
                              if (_currentAddress != null)
                                Text(
                                  _currentAddress!,
                                  style: const TextStyle(
                                    fontSize: AppSizes.vehicleTrackingAddressFontSize,
                                    color: AppColors.vehicleTrackingGreyColor,
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
                          height: AppSizes.vehicleTrackingPanelHeight,
                          padding: const EdgeInsets.all(AppSizes.vehicleTrackingPanelPadding),
                          decoration: BoxDecoration(
                            color: AppColors.vehicleTrackingWhiteColor,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.vehicleTrackingGreyColor.withValues(alpha: AppConstants.locationOpacity),
                                spreadRadius: AppSizes.vehicleTrackingPanelSpreadRadius,
                                blurRadius: AppSizes.vehicleTrackingPanelBlurRadius,
                                offset: const Offset(0, AppSizes.vehicleTrackingPanelOffsetY),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _activeTrip!.tripType == 'MORNING_PICKUP' ? Icons.wb_sunny : Icons.wb_twilight,
                                    color: _activeTrip!.tripType == 'MORNING_PICKUP' ? AppColors.vehicleTrackingOrangeColor : AppColors.vehicleTrackingBlueColor,
                                    size: AppSizes.vehicleTrackingTripIconSize,
                                  ),
                                  const SizedBox(width: AppSizes.vehicleTrackingTripIconSpacing),
                                  Text(
                                    _activeTrip!.tripType == 'MORNING_PICKUP' ? AppConstants.labelMorningPickup : AppConstants.labelAfternoonDrop,
                                    style: const TextStyle(fontSize: AppSizes.vehicleTrackingTripTitleFontSize, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.vehicleTrackingTripInfoSpacing),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${AppConstants.labelDriver}${_driverName ?? AppConstants.labelUnknown}',
                                        style: const TextStyle(fontSize: AppSizes.vehicleTrackingTripInfoFontSize),
                                      ),
                                      Text(
                                        '${AppConstants.labelVehicle}${_vehicleNumber ?? AppConstants.labelUnknown}',
                                        style: const TextStyle(fontSize: AppSizes.vehicleTrackingTripInfoFontSize),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${AppConstants.labelStatus}${_activeTrip!.tripStatus ?? AppConstants.labelUnknown}',
                                        style: const TextStyle(fontSize: AppSizes.vehicleTrackingTripInfoFontSize),
                                      ),
                                      Text(
                                        '${AppConstants.labelStudentsCount}${_activeTrip!.students.length}',
                                        style: const TextStyle(fontSize: AppSizes.vehicleTrackingTripInfoFontSize),
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
        const Icon(Icons.access_time, color: AppColors.vehicleTrackingBlueColor, size: AppSizes.vehicleTrackingETAIconSize),
        const SizedBox(height: AppSizes.vehicleTrackingETASpacing),
        const Text(
          AppConstants.labelETA,
          style: TextStyle(fontSize: AppSizes.vehicleTrackingETALabelFontSize, color: AppColors.vehicleTrackingGreyColor),
        ),
        Text(
          _estimatedArrivalTime ?? AppConstants.labelCalculating,
          style: const TextStyle(fontSize: AppSizes.vehicleTrackingETAValueFontSize, fontWeight: FontWeight.bold, color: AppColors.vehicleTrackingBlueColor),
        ),
      ],
    );
  }

  Widget _buildLocationStatus() {
    return Column(
      children: [
        Container(
          width: AppSizes.vehicleTrackingStatusDotSize,
          height: AppSizes.vehicleTrackingStatusDotSize,
          decoration: BoxDecoration(
            color: _getLocationStatusColor(),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: AppSizes.vehicleTrackingETASpacing),
        const Text(
          AppConstants.labelStatus,
          style: TextStyle(fontSize: AppSizes.vehicleTrackingStatusFontSize, color: AppColors.vehicleTrackingGreyColor),
        ),
        Text(
          _getLocationStatusText(),
          style: TextStyle(
            fontSize: AppSizes.vehicleTrackingStatusFontSize,
            fontWeight: FontWeight.w500,
            color: _getLocationStatusColor(),
          ),
        ),
      ],
    );
  }
}

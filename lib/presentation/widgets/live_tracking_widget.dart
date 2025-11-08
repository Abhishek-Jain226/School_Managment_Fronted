import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart' as websocket;
import '../../utils/constants.dart';

enum TrackingViewState {
  hidden,
  embedded,
  expanded,
}

class LiveTrackingWidget extends StatefulWidget {
  final int? tripId;
  final int? studentId;
  final VoidCallback? onTripCompleted;

  const LiveTrackingWidget({
    super.key,
    this.tripId,
    this.studentId,
    this.onTripCompleted,
  });

  @override
  State<LiveTrackingWidget> createState() => _LiveTrackingWidgetState();
}

class _LiveTrackingWidgetState extends State<LiveTrackingWidget> {
  final WebSocketNotificationService _webSocketService = WebSocketNotificationService();
  StreamSubscription<websocket.WebSocketNotification>? _notificationSubscription;

  TrackingViewState _viewState = TrackingViewState.hidden;
  LatLng? _driverLocation;
  String? _driverName;
  String? _vehicleNumber;
  DateTime? _lastLocationUpdate;
  bool _hasActiveTrip = false;
  bool _isTripCompleted = false;
  String? _tripCompletedMessage;

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final List<LatLng> _routeHistory = [];

  // Embedded map size
  static const double _embeddedWidth = 300.0;
  static const double _embeddedHeight = 200.0;

  // Initial camera position
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude),
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
    _checkActiveTrip();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _initializeWebSocket() {
    _webSocketService.initialize().then((_) {
      _notificationSubscription = _webSocketService.notificationStream.listen(
        _handleWebSocketNotification,
        onError: (error) {
          debugPrint('LiveTrackingWidget: WebSocket error: $error');
        },
      );
    });
  }

  void _handleWebSocketNotification(websocket.WebSocketNotification notification) {
    if (!mounted) return;

    // Handle location updates
    if (notification.type == websocket.NotificationType.locationUpdate) {
      if (widget.tripId != null && notification.tripId == widget.tripId) {
        _handleLocationUpdate(notification);
      }
    }
    // Handle trip completion
    else if (notification.type == AppConstants.notificationTypeTripCompleted ||
             notification.type == websocket.NotificationType.tripUpdate) {
      // Check if this is a trip completion notification
      if (notification.message.toLowerCase().contains('completed') ||
          notification.message.toLowerCase().contains('ended')) {
        if (widget.tripId != null && notification.tripId == widget.tripId) {
          _handleTripCompleted(notification);
        }
      }
    }
    // Handle trip started notification - show widget if hidden
    else if (notification.type == AppConstants.notificationTypeTripStarted ||
             notification.type == websocket.NotificationType.tripUpdate) {
      // Check if this is a trip started notification
      if (notification.message.toLowerCase().contains('started') ||
          notification.message.toLowerCase().contains('begin')) {
        if (widget.tripId != null && notification.tripId == widget.tripId) {
          setState(() {
            _hasActiveTrip = true;
            _isTripCompleted = false;
            if (_viewState == TrackingViewState.hidden) {
              _viewState = TrackingViewState.embedded;
            }
          });
        }
      }
    }
  }

  void _handleLocationUpdate(websocket.WebSocketNotification notification) {
    if (notification.data != null) {
      final lat = notification.data!['latitude'] as double?;
      final lng = notification.data!['longitude'] as double?;

      if (lat != null && lng != null) {
        final newLocation = LatLng(lat, lng);
        setState(() {
          _driverLocation = newLocation;
          _lastLocationUpdate = DateTime.now();
          _driverName = notification.data!['driverName'] as String?;
          _vehicleNumber = notification.data!['vehicleNumber'] as String?;
          
          // Add to route history for polyline
          _routeHistory.add(newLocation);
        });

        _updateMapMarkers();
        _updateRoutePolyline();
        _updateCameraPosition();
      }
    }
  }

  void _handleTripCompleted(websocket.WebSocketNotification notification) {
    setState(() {
      _hasActiveTrip = false;
      _isTripCompleted = true;
      _tripCompletedMessage = notification.message;
      // Clear route history when trip completes
      _routeHistory.clear();
      _polylines.clear();
    });

    // Show trip completed message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tripCompletedMessage ?? 'Trip has been completed'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    }

    // Callback if provided
    widget.onTripCompleted?.call();

    // Auto-hide after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _viewState = TrackingViewState.hidden;
        });
      }
    });
  }

  void _checkActiveTrip() {
    // This would ideally check with backend if trip is active
    // For now, we'll rely on WebSocket notifications
    setState(() {
      _hasActiveTrip = widget.tripId != null;
    });
  }

  void _updateMapMarkers() {
    if (_driverLocation == null) return;

    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('driver_location'),
          position: _driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Driver Location',
            snippet: _driverName != null
                ? 'Driver: $_driverName\nVehicle: ${_vehicleNumber ?? "N/A"}'
                : 'Vehicle: ${_vehicleNumber ?? "N/A"}',
          ),
        ),
      );
    });
  }

  void _updateRoutePolyline() {
    if (_routeHistory.length < 2) return;
    
    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route_path'),
          points: _routeHistory,
          color: Colors.blue,
          width: 4,
          patterns: [],
        ),
      );
    });
  }

  void _updateCameraPosition() {
    if (_driverLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_driverLocation!),
      );
    }
  }

  void _expandMap() {
    setState(() {
      _viewState = TrackingViewState.expanded;
    });
  }

  void _minimizeMap() {
    setState(() {
      _viewState = TrackingViewState.embedded;
    });
  }

  void _closeMap() {
    setState(() {
      _viewState = TrackingViewState.hidden;
    });
  }

  Widget _buildEmbeddedMap() {
    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        width: _embeddedWidth,
        height: _embeddedHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildMap(),
            ),
            Positioned(
              top: 5,
              right: 5,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.fullscreen, size: 18),
                    onPressed: _expandMap,
                    tooltip: 'Expand',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      shape: const CircleBorder(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _closeMap,
                    tooltip: 'Close',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
            ),
            if (_isTripCompleted)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    _tripCompletedMessage ?? 'Trip Completed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedMap() {
    return Container(
      color: Colors.black87,
      child: Stack(
        children: [
          _buildMap(),
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.minimize, size: 24),
              onPressed: _minimizeMap,
              tooltip: 'Minimize',
              color: Colors.white,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                shape: const CircleBorder(),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.close, size: 24),
              onPressed: _closeMap,
              tooltip: 'Close',
              color: Colors.white,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                shape: const CircleBorder(),
              ),
            ),
          ),
          if (_isTripCompleted)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _tripCompletedMessage ?? 'Trip Completed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: _initialPosition,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        if (_driverLocation != null) {
          _updateCameraPosition();
        }
      },
      markers: _markers,
      polylines: _polylines,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapType: MapType.normal,
      compassEnabled: false,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: false,
      zoomGesturesEnabled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_viewState == TrackingViewState.hidden) {
      return const SizedBox.shrink();
    }

    if (_viewState == TrackingViewState.expanded) {
      return _buildExpandedMap();
    }

    // Embedded view - return as Positioned widget for Stack
    return _buildEmbeddedMap();
  }
}


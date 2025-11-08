import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import 'driver_service.dart';
import '../utils/constants.dart';

/// Service for tracking driver location in the background during active trips
class LocationTrackingService {
  static final LocationTrackingService _instance = LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  final DriverService _driverService = DriverService();
  Timer? _locationUpdateTimer;
  bool _isTracking = false;
  bool _isInitializing = false; // Prevent concurrent initialization
  int? _currentDriverId;
  int? _currentTripId;
  DateTime? _lastLocationUpdateTime; // Track last update time to prevent duplicates
  
  /// Callback to notify when location tracking status changes
  Function(bool)? onTrackingStatusChanged;
  
  /// Callback to notify when location update fails
  Function(String)? onError;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('⚠️ Location services are disabled');
      return LocationPermission.denied;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('⚠️ Location permissions are denied');
        return LocationPermission.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('⚠️ Location permissions are permanently denied');
      return LocationPermission.deniedForever;
    }

    debugPrint('✅ Location permission granted');
    return permission;
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      LocationPermission permission = await requestLocationPermission();
      
      if (permission != LocationPermission.whileInUse && 
          permission != LocationPermission.always) {
        debugPrint('❌ Location permission not granted');
        onError?.call('Location permission not granted');
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      debugPrint('📍 Current location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('❌ Error getting current location: $e');
      onError?.call('Failed to get current location: ${e.toString()}');
      return null;
    }
  }

  /// Get address from coordinates (optional, can be implemented with geocoding)
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      // Using placemark for address
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');
        return address.isNotEmpty ? address : null;
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ Error getting address: $e');
      return null;
    }
  }

  /// Start location tracking for an active trip
  /// Updates location every [updateInterval] seconds (default: 15 seconds)
  Future<bool> startLocationTracking({
    required int driverId,
    required int tripId,
    Duration updateInterval = const Duration(seconds: 15),
  }) async {
    // Prevent concurrent calls - check both tracking state and initialization flag
    if (_isTracking || _isInitializing) {
      debugPrint('⚠️ Location tracking is already active or initializing');
      debugPrint('   Current state: _isTracking=$_isTracking, _isInitializing=$_isInitializing');
      debugPrint('   Current driver: $_currentDriverId, trip: $_currentTripId');
      debugPrint('   Requested driver: $driverId, trip: $tripId');
      return false;
    }

    // Cancel any existing timer (safety check)
    if (_locationUpdateTimer != null) {
      debugPrint('⚠️ Found existing timer, cancelling it before starting new tracking');
      _locationUpdateTimer?.cancel();
      _locationUpdateTimer = null;
    }

    // Set initialization flag to prevent concurrent calls
    _isInitializing = true;

    try {
      // Request permission first
      LocationPermission permission = await requestLocationPermission();
      if (permission != LocationPermission.whileInUse && 
          permission != LocationPermission.always) {
        debugPrint('❌ Cannot start tracking: Location permission not granted');
        onError?.call('Location permission not granted. Please enable location permissions.');
        _isInitializing = false;
        return false;
      }

      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Cannot start tracking: Location services are disabled');
        onError?.call('Location services are disabled. Please enable location services.');
        _isInitializing = false;
        return false;
      }

      // Set tracking state BEFORE creating timer to prevent race conditions
      _currentDriverId = driverId;
      _currentTripId = tripId;
      _isTracking = true;
      _lastLocationUpdateTime = null; // Reset last update time
      onTrackingStatusChanged?.call(true);

      debugPrint('🚀 Starting location tracking for driver $driverId, trip $tripId');
      debugPrint('⏱️ Update interval: ${updateInterval.inSeconds} seconds');

      // Send initial location update immediately (only once)
      await _sendLocationUpdate();

      // Set up periodic location updates (only one timer)
      _locationUpdateTimer = Timer.periodic(updateInterval, (timer) async {
        if (!_isTracking) {
          debugPrint('🛑 Timer cancelled: Tracking stopped');
          timer.cancel();
          return;
        }

        await _sendLocationUpdate();
      });

      debugPrint('✅ Location tracking started successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error starting location tracking: $e');
      // Reset state on error
      _isTracking = false;
      _locationUpdateTimer?.cancel();
      _locationUpdateTimer = null;
      _currentDriverId = null;
      _currentTripId = null;
      return false;
    } finally {
      // Always clear initialization flag
      _isInitializing = false;
    }
  }

  /// Send location update to backend
  Future<void> _sendLocationUpdate() async {
    if (!_isTracking || _currentDriverId == null || _currentTripId == null) {
      debugPrint('⚠️ Cannot send location update: Tracking not active or missing IDs');
      return;
    }

    // Prevent duplicate updates within 5 seconds (debouncing)
    if (_lastLocationUpdateTime != null) {
      final timeSinceLastUpdate = DateTime.now().difference(_lastLocationUpdateTime!);
      if (timeSinceLastUpdate.inSeconds < 5) {
        debugPrint('⏸️ Skipping location update: Only ${timeSinceLastUpdate.inSeconds}s since last update (minimum 5s)');
        return;
      }
    }

    try {
      debugPrint('📍 Getting current location for driver $_currentDriverId, trip $_currentTripId...');
      
      // Get current location
      Position? position = await getCurrentLocation();
      if (position == null) {
        debugPrint('⚠️ Failed to get position, skipping location update');
        return;
      }

      debugPrint('📍 Location obtained: ${position.latitude}, ${position.longitude}');

      // Get address (optional, can be null)
      String? address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      debugPrint('📤 Sending location update to backend...');
      
      // Call saveLocationUpdate API
      final response = await _driverService.saveLocationUpdate(
        _currentDriverId!,
        _currentTripId!,
        position.latitude,
        position.longitude,
        address,
      );

      // Update last update time only on success
      if (response[AppConstants.keySuccess] == true) {
        _lastLocationUpdateTime = DateTime.now();
        debugPrint('✅ Location update sent successfully: ${position.latitude}, ${position.longitude}');
        debugPrint('   Time: ${_lastLocationUpdateTime}');
      } else {
        String errorMessage = response[AppConstants.keyMessage] ?? 'Unknown error';
        debugPrint('❌ Location update failed: $errorMessage');
        onError?.call(errorMessage);
        
        // If trip is not in progress, stop tracking
        if (errorMessage.contains('not in progress') || 
            errorMessage.contains('IN_PROGRESS')) {
          debugPrint('🛑 Stopping location tracking: Trip is not in progress');
          stopLocationTracking();
        }
      }
    } catch (e) {
      debugPrint('❌ Error sending location update: $e');
      onError?.call('Failed to send location update: ${e.toString()}');
    }
  }

  /// Stop location tracking
  void stopLocationTracking() {
    if (!_isTracking && !_isInitializing) {
      debugPrint('⚠️ stopLocationTracking called but tracking is not active');
      return;
    }

    debugPrint('🛑 Stopping location tracking');
    debugPrint('   Driver: $_currentDriverId, Trip: $_currentTripId');
    
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _isTracking = false;
    _isInitializing = false;
    _currentDriverId = null;
    _currentTripId = null;
    _lastLocationUpdateTime = null;
    
    onTrackingStatusChanged?.call(false);
    
    debugPrint('✅ Location tracking stopped');
  }

  /// Check if location tracking is currently active
  bool get isTracking => _isTracking;

  /// Get current driver ID being tracked
  int? get currentDriverId => _currentDriverId;

  /// Get current trip ID being tracked
  int? get currentTripId => _currentTripId;

  /// Dispose resources
  void dispose() {
    stopLocationTracking();
  }
}


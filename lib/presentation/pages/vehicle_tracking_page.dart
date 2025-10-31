import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/parent_service.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart' as websocket;
import '../../data/models/trip.dart';
import '../../utils/constants.dart';

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
          debugPrint('WebSocket error: $error');
          setState(() {
            _isConnected = false;
          });
        },
      );
      
      debugPrint('🔌 WebSocket initialized for Vehicle Tracking');
    });
  }

  void _handleWebSocketNotification(websocket.WebSocketNotification notification) {
    debugPrint('🔔 Vehicle Tracking - Received notification: ${notification.type} - ${notification.message}');
    
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
      
      if (studentResponse[AppConstants.keySuccess] == true && studentResponse[AppConstants.keyData] != null) {
        final studentData = studentResponse[AppConstants.keyData];
        final studentId = studentData[AppConstants.keyStudentId];
        
        // Get active trips for this student
        final tripsResponse = await _parentService.getStudentTrips(studentId);
        
        if (tripsResponse[AppConstants.keySuccess] == true && tripsResponse[AppConstants.keyData] != null) {
          final trips = tripsResponse[AppConstants.keyData] as List;
          
          // Find active trip (you might need to adjust this logic based on your trip status)
          final activeTrip = trips.firstWhere(
            (trip) => trip[AppConstants.keyTripStatus] == 'IN_PROGRESS' || trip[AppConstants.keyTripStatus] == 'STARTED',
            orElse: () => null,
          );
          
          if (activeTrip != null) {
            setState(() {
              _activeTrip = Trip.fromJson(activeTrip);
              _driverName = activeTrip[AppConstants.keyDriverName];
              _vehicleNumber = activeTrip[AppConstants.keyVehicleNumber];
            });
          }
        }
      }
      
      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      debugPrint('Error loading active trip: $e');
      setState(() {
        _error = '${AppConstants.msgFailedToLoadTripData}$e';
        _isLoading = false;
      });
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return AppConstants.labelNA;
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return AppConstants.labelUnknownDate;
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return AppConstants.labelJustNow;
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}${AppConstants.labelMinutesAgoSuffix}';
    } else {
      return '${difference.inHours}${AppConstants.labelHoursAgoSuffix}';
    }
  }

  Color _getLocationStatusColor() {
    if (_lastLocationUpdate == null) return AppColors.textSecondary;
    
    final now = DateTime.now();
    final difference = now.difference(_lastLocationUpdate!);
    
    if (difference.inMinutes < 2) {
      return AppColors.successColor; // Live
    } else if (difference.inMinutes < 5) {
      return AppColors.warningColor; // Recent
    } else {
      return AppColors.errorColor; // Stale
    }
  }

  String _getLocationStatusText() {
    if (_lastLocationUpdate == null) return AppConstants.labelNoLocationData;
    
    final now = DateTime.now();
    final difference = now.difference(_lastLocationUpdate!);
    
    if (difference.inMinutes < 2) {
      return AppConstants.labelLiveTracking;
    } else if (difference.inMinutes < 5) {
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
            Icon(Icons.location_on, size: AppSizes.iconMD),
            SizedBox(width: AppSizes.marginSM),
            Text(AppConstants.labelVehicleTracking),
          ],
        ),
        actions: [
          // Connection status
          Icon(
            _isConnected ? Icons.wifi : Icons.wifi_off,
            color: _isConnected ? AppColors.successColor : AppColors.errorColor,
            size: AppSizes.iconSM,
          ),
          const SizedBox(width: AppSizes.marginSM),
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
                      Icon(Icons.error, size: AppSizes.iconXL, color: AppColors.errorColor),
                      const SizedBox(height: AppSizes.marginMD),
                      Text(
                        _error!,
                        style: const TextStyle(fontSize: AppSizes.textMD),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizes.marginMD),
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
                          Icon(Icons.local_taxi, size: AppSizes.iconXL, color: AppColors.grey200),
                          const SizedBox(height: AppSizes.marginMD),
                          const Text(AppConstants.labelNoActiveTrip, style: TextStyle(fontSize: AppSizes.textXXL, fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppSizes.marginSM),
                          Text(
                            AppConstants.labelChildNotOnTrip,
                            style: TextStyle(fontSize: AppSizes.textMD, color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSizes.paddingMD),
                      child: Column(
                        children: [
                          // Trip Information Card
                          _buildTripInfoCard(),
                          const SizedBox(height: AppSizes.marginLG),
                          
                          // Location Status Card
                          _buildLocationStatusCard(),
                          const SizedBox(height: AppSizes.marginLG),
                          
                          // Map Placeholder (you can integrate Google Maps here)
                          _buildMapPlaceholder(),
                          const SizedBox(height: AppSizes.marginLG),
                          
                          // Trip Progress Card
                          _buildTripProgressCard(),
                          const SizedBox(height: AppSizes.marginLG),
                          
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMD)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _activeTrip!.tripType == 'MORNING_PICKUP' ? Icons.wb_sunny : Icons.wb_twilight,
                  color: _activeTrip!.tripType == 'MORNING_PICKUP' ? AppColors.warningColor : AppColors.infoColor,
                  size: AppSizes.iconMD,
                ),
                const SizedBox(width: AppSizes.marginSM),
                const Text(AppConstants.labelTripInformation, style: TextStyle(fontSize: AppSizes.textXL, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: AppSizes.marginSM),
            _buildInfoRow(AppConstants.labelTripName, _activeTrip!.tripName),
            _buildInfoRow(AppConstants.labelType, _activeTrip!.tripType == 'MORNING_PICKUP' ? AppConstants.labelMorningPickup : AppConstants.labelAfternoonDrop),
            _buildInfoRow(AppConstants.labelScheduledTime, _activeTrip!.scheduledTime ?? AppConstants.labelNotSet),
            _buildInfoRow(AppConstants.labelStatus, _activeTrip!.tripStatus ?? AppConstants.labelUnknown),
            _buildInfoRow(AppConstants.labelStudents, '${_activeTrip!.students.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMD)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: AppSizes.iconXS,
                  height: AppSizes.iconXS,
                  decoration: BoxDecoration(
                    color: _getLocationStatusColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSizes.marginSM),
                const Text(AppConstants.labelLocationStatus, style: TextStyle(fontSize: AppSizes.textXL, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: AppSizes.marginSM),
            _buildInfoRow(AppConstants.labelStatus, _getLocationStatusText()),
            _buildInfoRow(AppConstants.labelLastUpdate, _getTimeAgo(_lastLocationUpdate)),
            if (_currentLocation != null) ...[
              _buildInfoRow(AppConstants.labelLatitude, _currentLocation![AppConstants.keyLatitude]?.toString() ?? AppConstants.labelNA),
              _buildInfoRow(AppConstants.labelLongitude, _currentLocation![AppConstants.keyLongitude]?.toString() ?? AppConstants.labelNA),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMD)),
      child: Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          color: AppColors.grey200,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              size: AppSizes.iconXL,
              color: AppColors.grey200,
            ),
            const SizedBox(height: AppSizes.marginMD),
            const Text(AppConstants.labelMapView, style: TextStyle(fontSize: AppSizes.textXL, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: AppSizes.marginSM),
            const Text(AppConstants.labelRealtimeLocationHint, style: TextStyle(fontSize: AppSizes.textSM, color: AppColors.textSecondary), textAlign: TextAlign.center),
            if (_currentLocation != null) ...[
              const SizedBox(height: AppSizes.marginMD),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingSM, vertical: AppSizes.paddingXS),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                ),
                child: Text(
                  '📍 ${_currentLocation![AppConstants.keyLatitude]?.toStringAsFixed(6)}, ${_currentLocation![AppConstants.keyLongitude]?.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: AppSizes.textXS, color: AppColors.primaryDark, fontWeight: FontWeight.w500),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMD)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppConstants.labelTripProgress, style: TextStyle(fontSize: AppSizes.textXL, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSizes.marginSM),
            
            // Progress indicators
            _buildProgressStep(
              AppConstants.labelTripStarted,
              true,
              Icons.play_circle,
              AppColors.successColor,
            ),
            _buildProgressStep(
              AppConstants.labelInProgress,
              _currentLocation != null,
              Icons.location_on,
              _currentLocation != null ? AppColors.infoColor : AppColors.textSecondary,
            ),
            _buildProgressStep(
              AppConstants.labelArrivingSoon,
              false,
              Icons.schedule,
              AppColors.textSecondary,
            ),
            _buildProgressStep(
              AppConstants.labelTripCompleted,
              false,
              Icons.check_circle,
              AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStep(String title, bool isActive, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.marginSM),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: AppSizes.iconSM,
          ),
          const SizedBox(width: AppSizes.marginMD),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: AppSizes.textMD,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppColors.textBlack : AppColors.textSecondary,
              ),
            ),
          ),
          if (isActive)
            Container(
              width: AppSizes.iconXS,
              height: AppSizes.iconXS,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMD)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppConstants.labelDriverInformation, style: TextStyle(fontSize: AppSizes.textXL, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSizes.marginSM),
            _buildInfoRow(AppConstants.labelDriverName, _driverName ?? AppConstants.labelUnknown),
            _buildInfoRow(AppConstants.labelVehicleNumber, _vehicleNumber ?? AppConstants.labelUnknown),
            _buildInfoRow(AppConstants.labelVehicleType, _activeTrip?.vehicleType ?? AppConstants.labelUnknown),
            _buildInfoRow(AppConstants.labelSchool, _activeTrip?.schoolName ?? AppConstants.labelUnknown),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.marginXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
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

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/constants.dart';
import '../../services/vehicle_owner_service.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart';
import 'vehicle_owner_event.dart';
import 'vehicle_owner_state.dart';

class VehicleOwnerBloc extends Bloc<VehicleOwnerEvent, VehicleOwnerState> {
  final VehicleOwnerService _vehicleOwnerService;
  final WebSocketNotificationService _webSocketService;
  StreamSubscription<WebSocketNotification>? _notificationSubscription;
  StreamSubscription<WebSocketNotification>? _tripUpdateSubscription;
  StreamSubscription<WebSocketNotification>? _systemAlertSubscription;
  int? _currentOwnerId;
  int? _currentUserId;
  final Set<int> _trackedVehicleIds = <int>{};
  final Set<int> _trackedTripIds = <int>{};
  final Set<int> _trackedDriverIds = <int>{};
  bool _isRealtimeRefreshInProgress = false;

  Map<String, dynamic>? _lastDashboard;
  List<dynamic> _lastVehicles = <dynamic>[];
  List<dynamic> _lastDrivers = <dynamic>[];
  List<dynamic> _lastTrips = <dynamic>[];
  List<dynamic> _lastNotifications = <dynamic>[];

  VehicleOwnerBloc({
    required VehicleOwnerService vehicleOwnerService,
    required WebSocketNotificationService webSocketService,
  })  : _vehicleOwnerService = vehicleOwnerService,
        _webSocketService = webSocketService,
        super(const VehicleOwnerInitial()) {
    on<VehicleOwnerDashboardRequested>(_onDashboardRequested);
    on<VehicleOwnerProfileRequested>(_onProfileRequested);
    on<VehicleOwnerUpdateRequested>(_onUpdateRequested);
    on<VehicleOwnerVehiclesRequested>(_onVehiclesRequested);
    on<VehicleOwnerDriversRequested>(_onDriversRequested);
    on<VehicleOwnerTripsRequested>(_onTripsRequested);
    on<VehicleOwnerNotificationsRequested>(_onNotificationsRequested);
    on<VehicleOwnerReportsRequested>(_onReportsRequested);
    on<VehicleOwnerAddVehicleRequested>(_onAddVehicleRequested);
    on<VehicleOwnerAddDriverRequested>(_onAddDriverRequested);
    on<VehicleOwnerAssignDriverRequested>(_onAssignDriverRequested);
    on<VehicleOwnerRefreshRequested>(_onRefreshRequested);
    on<VehicleOwnerRealtimeNotificationReceived>(_onRealtimeNotificationReceived);

    unawaited(_webSocketService.initialize());
    _subscribeToRealtimeStreams();
  }

  Future<void> _onDashboardRequested(
    VehicleOwnerDashboardRequested event,
    Emitter<VehicleOwnerState> emit,
  ) async {
    emit(const VehicleOwnerLoading());

    await _refreshDashboardData(
      ownerId: event.ownerId,
      emit: emit,
      emitRefreshingState: false,
    );
  }

  Future<void> _onProfileRequested(
    VehicleOwnerProfileRequested event,
    Emitter<VehicleOwnerState> emit,
  ) async {
    try {
      final profile = await _vehicleOwnerService.getVehicleOwnerProfile(event.ownerId);
      emit(VehicleOwnerProfileLoaded(profile: profile));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadVehicleOwnerProfile}: ${e.toString()}');
      emit(VehicleOwnerError(
        message: '${AppConstants.errorFailedToLoadVehicleOwnerProfile}: ${e.toString()}',
        errorCode: AppConstants.errorCodeVehicleOwnerProfile,
        actionType: AppConstants.actionTypeLoadProfile,
      ));
    }
  }

  Future<void> _onUpdateRequested(
    VehicleOwnerUpdateRequested event,
    Emitter<VehicleOwnerState> emit,
  ) async {
    try {
      final response = await _vehicleOwnerService.updateVehicleOwnerProfile(
        event.ownerId,
        event.ownerData,
      );

      emit(VehicleOwnerActionSuccess(
        message: response[AppConstants.keyMessage] ?? AppConstants.msgProfileUpdated,
        actionType: AppConstants.actionTypeUpdateProfile,
      ));

      add(VehicleOwnerProfileRequested(ownerId: event.ownerId));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToUpdateVehicleOwnerProfile}: ${e.toString()}');
      emit(VehicleOwnerError(
        message: '${AppConstants.errorFailedToUpdateVehicleOwnerProfile}: ${e.toString()}',
        errorCode: AppConstants.errorCodeVehicleOwnerUpdate,
        actionType: AppConstants.actionTypeUpdateProfile,
      ));
    }
  }

  Future<void> _onVehiclesRequested(
    VehicleOwnerVehiclesRequested event,
    Emitter<VehicleOwnerState> emit,
  ) async {
    try {
      final vehicles = await _vehicleOwnerService.getVehicleOwnerVehicles(event.ownerId);
      emit(VehicleOwnerVehiclesLoaded(vehicles: vehicles));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadVehicleOwnerVehicles}: ${e.toString()}');
      emit(VehicleOwnerError(
        message: '${AppConstants.errorFailedToLoadVehicleOwnerVehicles}: ${e.toString()}',
        errorCode: AppConstants.errorCodeVehicleOwnerVehicles,
        actionType: AppConstants.actionTypeLoadVehicles,
      ));
    }
  }

  Future<void> _onDriversRequested(
    VehicleOwnerDriversRequested event,
    Emitter<VehicleOwnerState> emit,
  ) async {
    try {
      final drivers = await _vehicleOwnerService.getVehicleOwnerDrivers(event.ownerId);
      emit(VehicleOwnerDriversLoaded(drivers: drivers));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadVehicleOwnerDrivers}: ${e.toString()}');
      emit(VehicleOwnerError(
        message: '${AppConstants.errorFailedToLoadVehicleOwnerDrivers}: ${e.toString()}',
        errorCode: AppConstants.errorCodeVehicleOwnerDrivers,
        actionType: AppConstants.actionTypeLoadDrivers,
      ));
    }
  }

  Future<void> _onTripsRequested(
    VehicleOwnerTripsRequested event,
    Emitter<VehicleOwnerState> emit,
  ) async {
    try {
      final trips = await _vehicleOwnerService.getVehicleOwnerTrips(event.ownerId);
      emit(VehicleOwnerTripsLoaded(trips: trips));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadVehicleOwnerTrips}: ${e.toString()}');
      emit(VehicleOwnerError(
        message: '${AppConstants.errorFailedToLoadVehicleOwnerTrips}: ${e.toString()}',
        errorCode: AppConstants.errorCodeVehicleOwnerTrips,
        actionType: AppConstants.actionTypeLoadTrips,
      ));
    }
  }

  Future<void> _onNotificationsRequested(
    VehicleOwnerNotificationsRequested event,
    Emitter<VehicleOwnerState> emit,
  ) async {
    try {
      final notificationsResponse = await _vehicleOwnerService.getVehicleOwnerNotifications(event.userId);
      final notifications = notificationsResponse[AppConstants.keyData] ?? [];
      emit(VehicleOwnerNotificationsLoaded(notifications: notifications));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToFetchVehicleOwnerNotifications}: ${e.toString()}');
      emit(VehicleOwnerError(
        message: '${AppConstants.errorFailedToFetchVehicleOwnerNotifications}: ${e.toString()}',
        errorCode: AppConstants.errorCodeVehicleOwnerNotifications,
        actionType: AppConstants.actionTypeLoadNotifications,
      ));
    }
  }

  Future<void> _onReportsRequested(
    VehicleOwnerReportsRequested event,
    Emitter<VehicleOwnerState> emit,
  ) async {
    try {
      final reports = await _vehicleOwnerService.getVehicleOwnerReports(event.ownerId);
      emit(VehicleOwnerReportsLoaded(reports: reports));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadVehicleOwnerReports}: ${e.toString()}');
      emit(VehicleOwnerError(
        message: '${AppConstants.errorFailedToLoadVehicleOwnerReports}: ${e.toString()}',
        errorCode: AppConstants.errorCodeVehicleOwnerReports,
        actionType: AppConstants.actionTypeLoadReports,
      ));
    }
  }

  Future<void> _onAddVehicleRequested(
    VehicleOwnerAddVehicleRequested event,
    Emitter<VehicleOwnerState> emit,
  ) async {
    try {
      final response = await _vehicleOwnerService.addVehicle(
        event.ownerId,
        event.vehicleData,
      );

      emit(VehicleOwnerActionSuccess(
        message: response[AppConstants.keyMessage] ?? AppConstants.msgVehicleAdded,
        actionType: AppConstants.actionTypeAddVehicle,
      ));

      add(VehicleOwnerVehiclesRequested(ownerId: event.ownerId));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToAddVehicle}: ${e.toString()}');
      emit(VehicleOwnerError(
        message: '${AppConstants.errorFailedToAddVehicle}: ${e.toString()}',
        errorCode: AppConstants.errorCodeAddVehicle,
        actionType: AppConstants.actionTypeAddVehicle,
      ));
    }
  }

  Future<void> _onAddDriverRequested(
    VehicleOwnerAddDriverRequested event,
    Emitter<VehicleOwnerState> emit,
  ) async {
    try {
      final response = await _vehicleOwnerService.addDriver(
        event.ownerId,
        event.driverData,
      );

      emit(VehicleOwnerActionSuccess(
        message: response[AppConstants.keyMessage] ?? AppConstants.msgDriverAdded,
        actionType: AppConstants.actionTypeAddDriver,
      ));

      add(VehicleOwnerDriversRequested(ownerId: event.ownerId));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToAddDriver}: ${e.toString()}');
      emit(VehicleOwnerError(
        message: '${AppConstants.errorFailedToAddDriver}: ${e.toString()}',
        errorCode: AppConstants.errorCodeAddDriver,
        actionType: AppConstants.actionTypeAddDriver,
      ));
    }
  }

  Future<void> _onAssignDriverRequested(
    VehicleOwnerAssignDriverRequested event,
    Emitter<VehicleOwnerState> emit,
  ) async {
    try {
      final response = await _vehicleOwnerService.assignDriver(
        event.ownerId,
        {
          AppConstants.keyVehicleId: event.vehicleId,
          AppConstants.keyDriverId: event.driverId,
        },
      );

      emit(VehicleOwnerActionSuccess(
        message: response[AppConstants.keyMessage] ?? AppConstants.msgDriverAssigned,
        actionType: AppConstants.actionTypeAssignDriver,
      ));

      add(VehicleOwnerRefreshRequested(ownerId: event.ownerId));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToAssignDriver}: ${e.toString()}');
      emit(VehicleOwnerError(
        message: '${AppConstants.errorFailedToAssignDriver}: ${e.toString()}',
        errorCode: AppConstants.errorCodeAssignDriver,
        actionType: AppConstants.actionTypeAssignDriver,
      ));
    }
  }

  Future<void> _onRefreshRequested(
    VehicleOwnerRefreshRequested event,
    Emitter<VehicleOwnerState> emit,
  ) async {
    await _refreshDashboardData(
      ownerId: event.ownerId,
      emit: emit,
      emitRefreshingState: true,
    );
  }

  Future<void> _onRealtimeNotificationReceived(
    VehicleOwnerRealtimeNotificationReceived event,
    Emitter<VehicleOwnerState> emit,
  ) async {
    if (_currentOwnerId == null) return;
    if (_isRealtimeRefreshInProgress) return;

    _isRealtimeRefreshInProgress = true;
    try {
      await _refreshDashboardData(
        ownerId: _currentOwnerId!,
        emit: emit,
        emitRefreshingState: false,
      );
    } finally {
      _isRealtimeRefreshInProgress = false;
    }
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    _tripUpdateSubscription?.cancel();
    _systemAlertSubscription?.cancel();
    return super.close();
  }

  void _subscribeToRealtimeStreams() {
    _notificationSubscription ??=
        _webSocketService.notificationStream.listen(_handleNotification, onError: _handleStreamError);
    _tripUpdateSubscription ??=
        _webSocketService.tripUpdateStream.listen(_handleNotification, onError: _handleStreamError);
    _systemAlertSubscription ??=
        _webSocketService.systemAlertStream.listen(_handleNotification, onError: _handleStreamError);
  }

  void _handleNotification(WebSocketNotification notification) {
    if (!_isNotificationRelevant(notification)) return;
    add(VehicleOwnerRealtimeNotificationReceived(notification: notification));
  }

  void _handleStreamError(Object error) {
    debugPrint('${AppConstants.msgNotificationStreamError}$error');
  }

  bool _isNotificationRelevant(WebSocketNotification notification) {
    if (_currentOwnerId == null) return false;

    if (_matchesOwnerId(notification.targetUser)) {
      return true;
    }

    final targetRole = notification.targetRole?.toUpperCase();
    if (targetRole == AppConstants.roleVehicleOwner || targetRole == UserRole.vehicleOwner) {
      return true;
    }

    if (_matchesOwnerId(notification.data?[AppConstants.keyOwnerId])) {
      return true;
    }
    if (_matchesOwnerId(notification.data?['vehicleOwnerId'])) {
      return true;
    }

    if (notification.vehicleId != null && _trackedVehicleIds.contains(notification.vehicleId)) {
      return true;
    }
    if (_matchesVehicleId(notification.data?[AppConstants.keyVehicleId])) {
      return true;
    }

    if (notification.tripId != null && _trackedTripIds.contains(notification.tripId)) {
      return true;
    }
    if (_matchesTripId(notification.data?[AppConstants.keyTripId])) {
      return true;
    }

    if (_matchesDriverId(notification.data?[AppConstants.keyDriverId])) {
      return true;
    }
    if (_matchesDriverId(notification.data?['assignedDriverId'])) {
      return true;
    }

    switch (notification.type.toUpperCase()) {
      case NotificationType.vehicleAssignmentApproved:
      case NotificationType.vehicleAssignmentRejected:
      case NotificationType.vehicleAssignmentRequest:
      case NotificationType.vehicleStatusUpdate:
      case NotificationType.systemAlert:
      case NotificationType.tripUpdate:
        return true;
    }

    return false;
  }

  bool _matchesOwnerId(dynamic value) {
    if (value == null || _currentOwnerId == null) return false;
    if (value is int) return value == _currentOwnerId;
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed != null && parsed == _currentOwnerId;
    }
    return false;
  }

  bool _matchesVehicleId(dynamic value) {
    final parsed = _extractInt(value);
    return parsed != null && _trackedVehicleIds.contains(parsed);
  }

  bool _matchesTripId(dynamic value) {
    final parsed = _extractInt(value);
    return parsed != null && _trackedTripIds.contains(parsed);
  }

  bool _matchesDriverId(dynamic value) {
    final parsed = _extractInt(value);
    return parsed != null && _trackedDriverIds.contains(parsed);
  }

  void _updateTrackedIds({
    required Map<String, dynamic> dashboard,
    required List<dynamic> vehicles,
    required List<dynamic> drivers,
    required List<dynamic> trips,
  }) {
    final dashboardVehicles = _extractDashboardList(dashboard, AppConstants.keyVehicles);
    final dashboardDrivers = _extractDashboardList(dashboard, AppConstants.keyDrivers);
    final dashboardTrips = _extractDashboardList(dashboard, AppConstants.keyTrips);

    final combinedVehicles = <dynamic>[...vehicles, ...dashboardVehicles];
    final combinedDrivers = <dynamic>[...drivers, ...dashboardDrivers];
    final combinedTrips = <dynamic>[...trips, ...dashboardTrips];

    _trackedVehicleIds
      ..clear()
      ..addAll(_extractIdsFromCollection(combinedVehicles, const [
        AppConstants.keyVehicleId,
        AppConstants.keyId,
        'vehicleID',
      ]));

    _trackedDriverIds
      ..clear()
      ..addAll(_extractIdsFromCollection(combinedDrivers, const [
        AppConstants.keyDriverId,
        AppConstants.keyId,
        'driverID',
      ]));

    _trackedTripIds
      ..clear()
      ..addAll(_extractIdsFromCollection(combinedTrips, const [
        AppConstants.keyTripId,
        AppConstants.keyId,
        'tripID',
      ]));
  }

  List<dynamic> _extractDashboardList(Map<String, dynamic> dashboard, String key) {
    final dataSection = dashboard[AppConstants.keyData];
    if (dataSection is Map<String, dynamic>) {
      final value = dataSection[key];
      if (value is List) {
        return List<dynamic>.from(value);
      }
    }

    final directValue = dashboard[key];
    if (directValue is List) {
      return List<dynamic>.from(directValue);
    }

    return const <dynamic>[];
  }

  Iterable<int> _extractIdsFromCollection(List<dynamic> collection, List<String> candidateKeys) sync* {
    for (final item in collection) {
      final id = _extractIdFromItem(item, candidateKeys);
      if (id != null) {
        yield id;
      }
    }
  }

  int? _extractIdFromItem(dynamic item, List<String> candidateKeys) {
    if (item is Map<String, dynamic>) {
      for (final key in candidateKeys) {
        if (!item.containsKey(key)) {
          continue;
        }
        final parsed = _extractInt(item[key]);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  int? _extractInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  int? _extractUserIdFromDashboard(Map<String, dynamic> dashboard) {
    // Try multiple possible paths for userId
    final dataSection = dashboard[AppConstants.keyData];
    if (dataSection is Map<String, dynamic>) {
      final userId = _extractInt(dataSection['userId']);
      if (userId != null) return userId;
      
      final userIdFromOwner = _extractInt(dataSection['ownerId']);
      if (userIdFromOwner != null) return userIdFromOwner;
    }
    
    final directUserId = _extractInt(dashboard['userId']);
    if (directUserId != null) return directUserId;
    
    final directOwnerId = _extractInt(dashboard['ownerId']);
    if (directOwnerId != null) return directOwnerId;
    
    return null;
  }

  Future<void> _refreshDashboardData({
    required int ownerId,
    required Emitter<VehicleOwnerState> emit,
    required bool emitRefreshingState,
  }) async {
    VehicleOwnerDashboardLoaded? previousState;

    if (state is VehicleOwnerDashboardLoaded) {
      previousState = state as VehicleOwnerDashboardLoaded;
      if (emitRefreshingState) {
        emit(VehicleOwnerRefreshing(
          dashboard: previousState.dashboard,
          vehicles: previousState.vehicles,
          drivers: previousState.drivers,
          trips: previousState.trips,
          notifications: previousState.notifications,
        ));
      }
    } else if (state is VehicleOwnerRefreshing &&
        _lastDashboard != null) {
      previousState = VehicleOwnerDashboardLoaded(
        dashboard: _lastDashboard!,
        vehicles: _lastVehicles,
        drivers: _lastDrivers,
        trips: _lastTrips,
        notifications: _lastNotifications,
      );
    }

          try {
        final dashboard = await _vehicleOwnerService.getVehicleOwnerDashboard(ownerId);
        final vehicles = await _vehicleOwnerService.getVehicleOwnerVehicles(ownerId);
        final drivers = await _vehicleOwnerService.getVehicleOwnerDrivers(ownerId);
        final trips = await _vehicleOwnerService.getVehicleOwnerTrips(ownerId); 

        // Fetch notifications using ownerId directly (no need to extract userId)
        List<dynamic> notifications = <dynamic>[];
        try {
          final notificationsResponse = await _vehicleOwnerService.getVehicleOwnerNotificationsByOwnerId(ownerId);
          notifications = notificationsResponse[AppConstants.keyData] ?? [];
          debugPrint('🔍 Fetched ${notifications.length} notifications for ownerId: $ownerId');
        } catch (e) {
          debugPrint('❌ Error fetching notifications for ownerId $ownerId: ${e.toString()}');
          // Continue with empty notifications list rather than failing entire dashboard load
          notifications = <dynamic>[];
        }

        // Extract userId from dashboard for tracking purposes (optional)
        final userId = _extractUserIdFromDashboard(dashboard);
        _currentOwnerId = ownerId;
        _currentUserId = userId;
      _updateTrackedIds(
        dashboard: dashboard,
        vehicles: vehicles,
        drivers: drivers,
        trips: trips,
      );

      _lastDashboard = dashboard;
      _lastVehicles = List<dynamic>.from(vehicles);
      _lastDrivers = List<dynamic>.from(drivers);
      _lastTrips = List<dynamic>.from(trips);
      _lastNotifications = List<dynamic>.from(notifications);

      emit(VehicleOwnerDashboardLoaded(
        dashboard: dashboard,
        vehicles: vehicles,
        drivers: drivers,
        trips: trips,
        notifications: notifications,
      ));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadVehicleOwnerDashboard}: ${e.toString()}');
      if (previousState != null) {
        emit(previousState);
      } else {
        emit(VehicleOwnerError(
          message: '${AppConstants.errorFailedToLoadVehicleOwnerDashboard}: ${e.toString()}',
          errorCode: AppConstants.errorCodeVehicleOwnerDashboard,
          actionType: AppConstants.actionTypeLoadDashboard,
        ));
      }
    }
  }
}


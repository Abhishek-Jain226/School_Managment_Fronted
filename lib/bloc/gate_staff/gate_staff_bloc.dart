import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/constants.dart';
import '../../services/gate_staff_service.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart';
import 'gate_staff_event.dart';
import 'gate_staff_state.dart';

class GateStaffBloc extends Bloc<GateStaffEvent, GateStaffState> {
  final GateStaffService _gateStaffService;
  final WebSocketNotificationService _webSocketService;
  StreamSubscription<WebSocketNotification>? _notificationSubscription;
  StreamSubscription<WebSocketNotification>? _arrivalSubscription;
  StreamSubscription<WebSocketNotification>? _tripUpdateSubscription;
  int? _currentUserId;
  final Set<int> _trackedTripIds = <int>{};
  final Set<int> _trackedStudentIds = <int>{};
  bool _isRealtimeRefreshInProgress = false;

  GateStaffBloc({
    required GateStaffService gateStaffService,
    required WebSocketNotificationService webSocketService,
  })  : _gateStaffService = gateStaffService,
        _webSocketService = webSocketService,
        super(const GateStaffInitial()) {
    on<GateStaffDashboardRequested>(_onDashboardRequested);
    on<GateStaffMarkEntryRequested>(_onMarkEntryRequested);
    on<GateStaffMarkExitRequested>(_onMarkExitRequested);
    on<GateStaffRefreshRequested>(_onRefreshRequested);
    on<GateStaffRealtimeNotificationReceived>(_onRealtimeNotificationReceived);

    unawaited(_webSocketService.initialize());
    _subscribeToRealtimeStreams();
  }

  Future<void> _onDashboardRequested(
    GateStaffDashboardRequested event,
    Emitter<GateStaffState> emit,
  ) async {
    emit(const GateStaffLoading());

    try {
      final dashboard = await _gateStaffService.getGateStaffDashboard(event.userId);

      if (dashboard[AppConstants.keySuccess] == true) {
        final dashboardData = dashboard[AppConstants.keyData] ?? dashboard;
        _currentUserId = event.userId;
        _updateTrackedIds(dashboardData);
        emit(GateStaffDashboardLoaded(dashboard: dashboardData));
      } else {
        emit(GateStaffError(
          message: dashboard[AppConstants.keyMessage] ?? AppConstants.msgFailedToLoadDashboard,
          errorCode: AppConstants.errorCodeDashboardLoad,
          actionType: AppConstants.actionTypeLoadDashboard,
        ));
      }
    } catch (e) {
      debugPrint('${AppConstants.msgErrorLoadingDashboard}: ${e.toString()}');
      emit(GateStaffError(
        message: '${AppConstants.msgErrorLoadingDashboard}: ${e.toString()}',
        errorCode: AppConstants.errorCodeDashboardLoad,
        actionType: AppConstants.actionTypeLoadDashboard,
      ));
    }
  }

  Future<void> _onMarkEntryRequested(
    GateStaffMarkEntryRequested event,
    Emitter<GateStaffState> emit,
  ) async {
    try {
      final response = await _gateStaffService.markGateEntry(
        event.userId,
        event.studentId,
        event.tripId,
        event.remarks,
      );

      if (response[AppConstants.keySuccess] == true) {
        emit(GateStaffActionSuccess(
          message: response[AppConstants.keyMessage] ??
              '${AppConstants.msgGateEventMarkedSuccess}${AppConstants.labelEntry.toLowerCase()}${AppConstants.msgMarkedSuccessfully}',
          actionType: AppConstants.actionTypeMarkGateEntry,
        ));

        add(GateStaffRefreshRequested(userId: event.userId));
      } else {
        emit(GateStaffError(
          message: response[AppConstants.keyMessage] ?? AppConstants.msgFailedToMarkGateEvent,
          errorCode: AppConstants.errorCodeGateEntry,
          actionType: AppConstants.actionTypeMarkGateEntry,
        ));
      }
    } catch (e) {
      debugPrint('${AppConstants.msgErrorMarkingGateEvent}: ${e.toString()}');
      emit(GateStaffError(
        message: '${AppConstants.msgErrorMarkingGateEvent}${AppConstants.labelEntry.toLowerCase()}: ${e.toString()}',
        errorCode: AppConstants.errorCodeGateEntry,
        actionType: AppConstants.actionTypeMarkGateEntry,
      ));
    }
  }

  Future<void> _onMarkExitRequested(
    GateStaffMarkExitRequested event,
    Emitter<GateStaffState> emit,
  ) async {
    try {
      final response = await _gateStaffService.markGateExit(
        event.userId,
        event.studentId,
        event.tripId,
        event.remarks,
      );

      if (response[AppConstants.keySuccess] == true) {
        emit(GateStaffActionSuccess(
          message: response[AppConstants.keyMessage] ??
              '${AppConstants.msgGateEventMarkedSuccess}${AppConstants.labelExit.toLowerCase()}${AppConstants.msgMarkedSuccessfully}',
          actionType: AppConstants.actionTypeMarkGateExit,
        ));

        add(GateStaffRefreshRequested(userId: event.userId));
      } else {
        emit(GateStaffError(
          message: response[AppConstants.keyMessage] ?? AppConstants.msgFailedToMarkGateEvent,
          errorCode: AppConstants.errorCodeGateExit,
          actionType: AppConstants.actionTypeMarkGateExit,
        ));
      }
    } catch (e) {
      debugPrint('${AppConstants.msgErrorMarkingGateEvent}: ${e.toString()}');
      emit(GateStaffError(
        message: '${AppConstants.msgErrorMarkingGateEvent}${AppConstants.labelExit.toLowerCase()}: ${e.toString()}',
        errorCode: AppConstants.errorCodeGateExit,
        actionType: AppConstants.actionTypeMarkGateExit,
      ));
    }
  }

  Future<void> _onRefreshRequested(
    GateStaffRefreshRequested event,
    Emitter<GateStaffState> emit,
  ) async {
    await _refreshDashboardData(
      userId: event.userId,
      emit: emit,
      emitRefreshingState: true,
    );
  }

  Future<void> _onRealtimeNotificationReceived(
    GateStaffRealtimeNotificationReceived event,
    Emitter<GateStaffState> emit,
  ) async {
    if (_currentUserId == null) return;
    if (_isRealtimeRefreshInProgress) return;

    _isRealtimeRefreshInProgress = true;
    try {
      await _refreshDashboardData(
        userId: _currentUserId!,
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
    _arrivalSubscription?.cancel();
    _tripUpdateSubscription?.cancel();
    return super.close();
  }

  void _subscribeToRealtimeStreams() {
    _notificationSubscription ??=
        _webSocketService.notificationStream.listen(_handleNotification, onError: _handleStreamError);
    _arrivalSubscription ??=
        _webSocketService.arrivalStream.listen(_handleNotification, onError: _handleStreamError);
    _tripUpdateSubscription ??=
        _webSocketService.tripUpdateStream.listen(_handleNotification, onError: _handleStreamError);
  }

  void _handleNotification(WebSocketNotification notification) {
    if (!_isNotificationRelevant(notification)) return;
    add(GateStaffRealtimeNotificationReceived(notification: notification));
  }

  void _handleStreamError(Object error) {
    debugPrint('${AppConstants.msgGateNotificationError}$error');
  }

  bool _isNotificationRelevant(WebSocketNotification notification) {
    if (_currentUserId == null) return false;

    if (_matchesUserId(notification.targetUser)) {
      return true;
    }

    final targetRole = notification.targetRole?.toUpperCase();
    if (targetRole == AppConstants.roleGateStaff) {
      return true;
    }

    if (_matchesUserId(notification.data?[AppConstants.keyUserId])) {
      return true;
    }
    if (_matchesUserId(notification.data?['gateStaffId'])) {
      return true;
    }
    if (_matchesUserId(notification.data?['gateStaffUserId'])) {
      return true;
    }

    if (notification.tripId != null && _trackedTripIds.contains(notification.tripId)) {
      return true;
    }
    if (_matchesTripId(notification.data?[AppConstants.keyTripId])) {
      return true;
    }

    if (notification.studentId != null && _trackedStudentIds.contains(notification.studentId)) {
      return true;
    }
    if (_matchesStudentId(notification.data?[AppConstants.keyStudentId])) {
      return true;
    }

    return false;
  }

  bool _matchesUserId(dynamic value) {
    if (value == null || _currentUserId == null) return false;
    if (value is int) return value == _currentUserId;
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed != null && parsed == _currentUserId;
    }
    return false;
  }

  bool _matchesTripId(dynamic value) {
    if (value == null) return false;
    if (value is int) return _trackedTripIds.contains(value);
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed != null && _trackedTripIds.contains(parsed);
    }
    return false;
  }

  bool _matchesStudentId(dynamic value) {
    if (value == null) return false;
    if (value is int) return _trackedStudentIds.contains(value);
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed != null && _trackedStudentIds.contains(parsed);
    }
    return false;
  }

  void _updateTrackedIds(Map<String, dynamic> dashboard) {
    _trackedTripIds.clear();
    _trackedStudentIds.clear();

    final studentsByTrip = dashboard['studentsByTrip'] as List<dynamic>? ?? [];
    for (final trip in studentsByTrip) {
      if (trip is Map<String, dynamic>) {
        final tripId = _extractInt(trip['tripId']);
        if (tripId != null) {
          _trackedTripIds.add(tripId);
        }

        final students = trip['students'] as List<dynamic>? ?? [];
        for (final student in students) {
          final studentId = _extractInt(student is Map<String, dynamic> ? student['studentId'] : null);
          if (studentId != null) {
            _trackedStudentIds.add(studentId);
          }
        }
      }
    }
  }

  int? _extractInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<void> _refreshDashboardData({
    required int userId,
    required Emitter<GateStaffState> emit,
    required bool emitRefreshingState,
  }) async {
    GateStaffDashboardLoaded? previousState;

    if (state is GateStaffDashboardLoaded) {
      previousState = state as GateStaffDashboardLoaded;
      if (emitRefreshingState) {
        emit(GateStaffRefreshing(dashboard: previousState.dashboard));
      }
    }

    try {
      final dashboard = await _gateStaffService.getGateStaffDashboard(userId);

      if (dashboard[AppConstants.keySuccess] == true) {
        final dashboardData = dashboard[AppConstants.keyData] ?? dashboard;
        _currentUserId = userId;
        _updateTrackedIds(dashboardData);
        emit(GateStaffDashboardLoaded(dashboard: dashboardData));
      } else {
        if (previousState != null) {
          emit(previousState);
        } else {
          emit(GateStaffError(
            message: dashboard[AppConstants.keyMessage] ?? AppConstants.msgFailedToLoadDashboard,
            errorCode: AppConstants.errorCodeDashboardLoad,
            actionType: AppConstants.actionTypeLoadDashboard,
          ));
        }
      }
    } catch (e) {
      debugPrint('${AppConstants.msgErrorLoadingDashboard}: ${e.toString()}');
      if (previousState != null) {
        emit(previousState);
      } else {
        emit(GateStaffError(
          message: '${AppConstants.msgErrorLoadingDashboard}: ${e.toString()}',
          errorCode: AppConstants.errorCodeDashboardLoad,
          actionType: AppConstants.actionTypeLoadDashboard,
        ));
      }
    }
  }
}


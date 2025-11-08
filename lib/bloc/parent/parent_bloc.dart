import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/constants.dart';
import '../../services/parent_service.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart';
import '../../data/models/parent_dashboard.dart';
import 'parent_event.dart';
import 'parent_state.dart';

class ParentBloc extends Bloc<ParentEvent, ParentState> {
  final ParentService _parentService;
  final WebSocketNotificationService _webSocketService;
  StreamSubscription<WebSocketNotification>? _notificationSubscription;
  StreamSubscription<WebSocketNotification>? _pickupSubscription;
  StreamSubscription<WebSocketNotification>? _dropSubscription;
  StreamSubscription<WebSocketNotification>? _tripUpdateSubscription;
  StreamSubscription<WebSocketNotification>? _arrivalSubscription;
  int? _currentParentId;
  final Set<int> _studentIds = <int>{};
  bool _isRealtimeRefreshInProgress = false;

  ParentBloc({
    required ParentService parentService,
    required WebSocketNotificationService webSocketService,
  })  : _parentService = parentService,
        _webSocketService = webSocketService,
        super(const ParentInitial()) {
    on<ParentDashboardRequested>(_onDashboardRequested);
    on<ParentProfileRequested>(_onProfileRequested);
    on<ParentUpdateRequested>(_onUpdateRequested);
    on<ParentStudentsRequested>(_onStudentsRequested);
    on<ParentTripsRequested>(_onTripsRequested);
    on<ParentNotificationsRequested>(_onNotificationsRequested);
    on<ParentAttendanceHistoryRequested>(_onAttendanceHistoryRequested);
    on<ParentMonthlyReportRequested>(_onMonthlyReportRequested);
    on<ParentVehicleTrackingRequested>(_onVehicleTrackingRequested);
    on<ParentDriverLocationRequested>(_onDriverLocationRequested);
    on<ParentRefreshRequested>(_onRefreshRequested);
    on<ParentRealtimeNotificationReceived>(_onRealtimeNotificationReceived);

    unawaited(_webSocketService.initialize());
    _subscribeToRealtimeStreams();
  }

  Future<void> _onDashboardRequested(
    ParentDashboardRequested event,
    Emitter<ParentState> emit,
  ) async {
    emit(const ParentLoading());
    
    try {
      // Load dashboard data
      final dashboard = await _parentService.getParentDashboard(event.parentId);
      
      // Load related data
      final students = await _parentService.getParentStudents(event.parentId);
      final trips = await _parentService.getParentTrips(event.parentId);
      final notifications = await _parentService.getParentNotifications(event.parentId);
      
      emit(ParentDashboardLoaded(
        dashboard: dashboard,
        students: students,
        trips: trips,
        notifications: notifications,
      ));
      _currentParentId = event.parentId;
      _updateStudentIds(dashboard: dashboard, students: students);
      
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadParentDashboard}: ${e.toString()}');
      emit(ParentError(
        message: '${AppConstants.errorFailedToLoadParentDashboard}: ${e.toString()}',
        errorCode: AppConstants.errorCodeParentDashboard,
        actionType: AppConstants.actionTypeLoadDashboard,
      ));
    }
  }

  Future<void> _onProfileRequested(
    ParentProfileRequested event,
    Emitter<ParentState> emit,
  ) async {
    // Don't emit loading state to preserve dashboard UI
    try {
      final profile = await _parentService.getParentProfile(event.parentId);
      emit(ParentProfileLoaded(profile: profile));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadParentProfile}: ${e.toString()}');
      emit(ParentError(
        message: '${AppConstants.errorFailedToLoadParentProfile}: ${e.toString()}',
        errorCode: AppConstants.errorCodeParentProfile,
        actionType: AppConstants.actionTypeLoadProfile,
      ));
    }
  }

  Future<void> _onUpdateRequested(
    ParentUpdateRequested event,
    Emitter<ParentState> emit,
  ) async {
    try {
      final response = await _parentService.updateParentProfile(
        event.parentId,
        event.parentData,
      );
      
      emit(ParentActionSuccess(
        message: response[AppConstants.keyMessage] ?? AppConstants.msgProfileUpdated,
        actionType: AppConstants.actionTypeUpdateProfile,
      ));
      
      // Refresh profile after update
      add(ParentProfileRequested(parentId: event.parentId));
      
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToUpdateParentProfile}: ${e.toString()}');
      emit(ParentError(
        message: '${AppConstants.errorFailedToUpdateParentProfile}: ${e.toString()}',
        errorCode: AppConstants.errorCodeParentUpdate,
        actionType: AppConstants.actionTypeUpdateProfile,
      ));
    }
  }

  Future<void> _onStudentsRequested(
    ParentStudentsRequested event,
    Emitter<ParentState> emit,
  ) async {
    try {
      final students = await _parentService.getParentStudents(event.parentId);
      emit(ParentStudentsLoaded(students: students));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadParentStudents}: ${e.toString()}');
      emit(ParentError(
        message: '${AppConstants.errorFailedToLoadParentStudents}: ${e.toString()}',
        errorCode: AppConstants.errorCodeParentStudents,
        actionType: AppConstants.actionTypeLoadStudents,
      ));
    }
  }

  Future<void> _onTripsRequested(
    ParentTripsRequested event,
    Emitter<ParentState> emit,
  ) async {
    try {
      final trips = await _parentService.getParentTrips(event.parentId);
      emit(ParentTripsLoaded(trips: trips));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadParentTrips}: ${e.toString()}');
      emit(ParentError(
        message: '${AppConstants.errorFailedToLoadParentTrips}: ${e.toString()}',
        errorCode: AppConstants.errorCodeParentTrips,
        actionType: AppConstants.actionTypeLoadTrips,
      ));
    }
  }

  Future<void> _onNotificationsRequested(
    ParentNotificationsRequested event,
    Emitter<ParentState> emit,
  ) async {
    try {
      final notifications = await _parentService.getParentNotifications(event.parentId);
      emit(ParentNotificationsLoaded(notifications: notifications));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadParentNotifications}: ${e.toString()}');
      emit(ParentError(
        message: '${AppConstants.errorFailedToLoadParentNotifications}: ${e.toString()}',
        errorCode: AppConstants.errorCodeParentNotifications,
        actionType: AppConstants.actionTypeLoadNotifications,
      ));
    }
  }

  Future<void> _onAttendanceHistoryRequested(
    ParentAttendanceHistoryRequested event,
    Emitter<ParentState> emit,
  ) async {
    try {
      final attendanceHistory = await _parentService.getParentAttendanceHistory(
        event.parentId,
        studentId: event.studentId,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      final historyList = (attendanceHistory[AppConstants.keyData] as List?) ?? <dynamic>[];
      emit(ParentAttendanceHistoryLoaded(attendanceHistory: historyList));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadAttendanceHistory}: ${e.toString()}');
      emit(ParentError(
        message: '${AppConstants.errorFailedToLoadAttendanceHistory}: ${e.toString()}',
        errorCode: AppConstants.errorCodeParentAttendanceHistory,
        actionType: AppConstants.actionTypeLoadAttendanceHistory,
      ));
    }
  }

  Future<void> _onMonthlyReportRequested(
    ParentMonthlyReportRequested event,
    Emitter<ParentState> emit,
  ) async {
    try {
      final parsedMonth = event.month != null ? int.tryParse(event.month!) : null;
      final parsedYear = event.year != null ? int.tryParse(event.year!) : null;
      final monthlyReport = await _parentService.getParentMonthlyReport(
        event.parentId,
        studentId: event.studentId,
        month: parsedMonth,
        year: parsedYear,
      );
      emit(ParentMonthlyReportLoaded(monthlyReport: monthlyReport));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadMonthlyReport}: ${e.toString()}');
      emit(ParentError(
        message: '${AppConstants.errorFailedToLoadMonthlyReport}: ${e.toString()}',
        errorCode: AppConstants.errorCodeParentMonthlyReport,
        actionType: AppConstants.actionTypeLoadMonthlyReport,
      ));
    }
  }

  Future<void> _onVehicleTrackingRequested(
    ParentVehicleTrackingRequested event,
    Emitter<ParentState> emit,
  ) async {
    try {
      final vehicleTracking = await _parentService.getParentVehicleTracking(
        event.parentId,
        studentId: event.studentId,
      );
      emit(ParentVehicleTrackingLoaded(vehicleTracking: vehicleTracking));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadVehicleTracking}: ${e.toString()}');
      emit(ParentError(
        message: '${AppConstants.errorFailedToLoadVehicleTracking}: ${e.toString()}',
        errorCode: AppConstants.errorCodeParentVehicleTracking,
        actionType: AppConstants.actionTypeLoadVehicleTracking,
      ));
    }
  }

  Future<void> _onDriverLocationRequested(
    ParentDriverLocationRequested event,
    Emitter<ParentState> emit,
  ) async {
    try {
      final driverLocation = await _parentService.getDriverLocation(event.driverId);
      emit(ParentDriverLocationLoaded(driverLocation: driverLocation));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadDriverLocation}: ${e.toString()}');
      emit(ParentError(
        message: '${AppConstants.errorFailedToLoadDriverLocation}: ${e.toString()}',
        errorCode: AppConstants.errorCodeParentDriverLocation,
        actionType: AppConstants.actionTypeLoadDriverLocation,
      ));
    }
  }

  Future<void> _onRefreshRequested(
    ParentRefreshRequested event,
    Emitter<ParentState> emit,
  ) async {
    await _refreshDashboardData(
      parentId: event.parentId,
      emit: emit,
      emitRefreshingState: true,
    );
  }

  Future<void> _onRealtimeNotificationReceived(
    ParentRealtimeNotificationReceived event,
    Emitter<ParentState> emit,
  ) async {
    if (_currentParentId == null) return;
    if (_isRealtimeRefreshInProgress) return;

    _isRealtimeRefreshInProgress = true;
    try {
      await _refreshDashboardData(
        parentId: _currentParentId!,
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
    _pickupSubscription?.cancel();
    _dropSubscription?.cancel();
    _tripUpdateSubscription?.cancel();
    _arrivalSubscription?.cancel();
    return super.close();
  }

  void _subscribeToRealtimeStreams() {
    _notificationSubscription ??=
        _webSocketService.notificationStream.listen(_handleNotification, onError: _handleStreamError);
    _pickupSubscription ??=
        _webSocketService.pickupStream.listen(_handleNotification, onError: _handleStreamError);
    _dropSubscription ??=
        _webSocketService.dropStream.listen(_handleNotification, onError: _handleStreamError);
    _tripUpdateSubscription ??=
        _webSocketService.tripUpdateStream.listen(_handleNotification, onError: _handleStreamError);
    _arrivalSubscription ??=
        _webSocketService.arrivalStream.listen(_handleNotification, onError: _handleStreamError);
  }

  void _handleNotification(WebSocketNotification notification) {
    if (!_isNotificationRelevant(notification)) return;
    add(ParentRealtimeNotificationReceived(notification: notification));
  }

  void _handleStreamError(Object error) {
    debugPrint('${AppConstants.msgNotificationStreamError}$error');
  }

  bool _isNotificationRelevant(WebSocketNotification notification) {
    if (_currentParentId == null) return false;

    final targetUserRaw = notification.targetUser;
    if (targetUserRaw != null) {
      final targetUserId = int.tryParse(targetUserRaw);
      if (targetUserId != null && targetUserId == _currentParentId) {
        return true;
      }
      if (targetUserRaw == _currentParentId.toString()) {
        return true;
      }
    }

    final targetRole = notification.targetRole?.toUpperCase();
    if (targetRole == AppConstants.roleParent && _matchesParentId(notification.targetUser)) {
      return true;
    }

    if (_matchesParentId(notification.data?[AppConstants.keyParentId])) {
      return true;
    }

    if (notification.studentId != null && _studentIds.contains(notification.studentId)) {
      return true;
    }

    final dataStudentId = notification.data?[AppConstants.keyStudentId];
    if (_matchesStudentId(dataStudentId)) {
      return true;
    }

    return false;
  }

  bool _matchesParentId(dynamic value) {
    if (value == null || _currentParentId == null) return false;
    if (value is int) {
      return value == _currentParentId;
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed != null && parsed == _currentParentId;
    }
    return false;
  }

  bool _matchesStudentId(dynamic value) {
    if (value == null) return false;
    if (value is int) {
      return _studentIds.contains(value);
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed != null && _studentIds.contains(parsed);
    }
    return false;
  }

  void _updateStudentIds({
    required ParentDashboard dashboard,
    required List<dynamic> students,
  }) {
    _studentIds
      ..clear()
      ..add(dashboard.studentId);

    for (final student in students) {
      final studentId = _extractStudentId(student);
      if (studentId != null) {
        _studentIds.add(studentId);
      }
    }
  }

  int? _extractStudentId(dynamic student) {
    if (student is Map<String, dynamic>) {
      final value = student[AppConstants.keyStudentId] ?? student['studentId'];
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
    }
    return null;
  }

  Future<void> _refreshDashboardData({
    required int parentId,
    required Emitter<ParentState> emit,
    required bool emitRefreshingState,
  }) async {
    ParentDashboardLoaded? previousState;

    if (state is ParentDashboardLoaded) {
      previousState = state as ParentDashboardLoaded;
      if (emitRefreshingState) {
        emit(ParentRefreshing(
          dashboard: previousState.dashboard,
          students: previousState.students,
          trips: previousState.trips,
          notifications: previousState.notifications,
        ));
      }
    }

    try {
      final dashboard = await _parentService.getParentDashboard(parentId);
      final students = await _parentService.getParentStudents(parentId);
      final trips = await _parentService.getParentTrips(parentId);
      final notifications = await _parentService.getParentNotifications(parentId);

      _currentParentId = parentId;
      _updateStudentIds(dashboard: dashboard, students: students);

      emit(ParentDashboardLoaded(
        dashboard: dashboard,
        students: students,
        trips: trips,
        notifications: notifications,
      ));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadParentDashboard}: ${e.toString()}');
      if (previousState != null) {
        emit(previousState);
      } else {
        emit(ParentError(
          message: '${AppConstants.errorFailedToLoadParentDashboard}: ${e.toString()}',
          errorCode: AppConstants.errorCodeParentDashboard,
          actionType: AppConstants.actionTypeLoadDashboard,
        ));
      }
    }
  }
}

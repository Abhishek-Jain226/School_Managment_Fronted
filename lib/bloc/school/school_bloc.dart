import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/constants.dart';
import '../../services/school_service.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart';
import 'school_event.dart';
import 'school_state.dart';

class SchoolBloc extends Bloc<SchoolEvent, SchoolState> {
  final SchoolService _schoolService;
  final WebSocketNotificationService _webSocketService;
  StreamSubscription<WebSocketNotification>? _notificationSubscription;
  StreamSubscription<WebSocketNotification>? _tripUpdateSubscription;
  int? _currentSchoolId;
  bool _isRealtimeRefreshInProgress = false;

  SchoolBloc({
    required SchoolService schoolService,
    required WebSocketNotificationService webSocketService,
  })  : _schoolService = schoolService,
        _webSocketService = webSocketService,
        super(const SchoolInitial()) {
    on<SchoolDashboardRequested>(_onDashboardRequested);
    on<SchoolProfileRequested>(_onProfileRequested);
    on<SchoolUpdateRequested>(_onUpdateRequested);
    on<SchoolStudentsRequested>(_onStudentsRequested);
    on<SchoolStaffRequested>(_onStaffRequested);
    on<SchoolVehiclesRequested>(_onVehiclesRequested);
    on<SchoolTripsRequested>(_onTripsRequested);
    on<SchoolNotificationsRequested>(_onNotificationsRequested);
    on<SchoolReportsRequested>(_onReportsRequested);
    on<SchoolRefreshRequested>(_onRefreshRequested);
    on<SchoolRealtimeNotificationReceived>(_onRealtimeNotificationReceived);

    unawaited(_webSocketService.initialize());
    _subscribeToRealtimeStreams();
  }

  Future<void> _onDashboardRequested(
    SchoolDashboardRequested event,
    Emitter<SchoolState> emit,
  ) async {
    emit(const SchoolLoading());
    
    try {
      // Load dashboard data
      final dashboardResponse = await _schoolService.getSchoolDashboard(event.schoolId);
      
      // Load related data
      final students = await _schoolService.getSchoolStudents(event.schoolId);
      final staff = await _schoolService.getSchoolStaff(event.schoolId);
      final vehicles = await _schoolService.getSchoolVehicles(event.schoolId);
      final trips = await _schoolService.getSchoolTrips(event.schoolId);
      final notificationsResponse = await _schoolService.getSchoolNotifications(event.schoolId);
      final notifications = notificationsResponse[AppConstants.keyData] ?? [];
      
      emit(SchoolDashboardLoaded(
        dashboard: dashboardResponse,
        students: students,
        staff: staff,
        vehicles: vehicles,
        trips: trips,
        notifications: notifications,
      ));
      _currentSchoolId = event.schoolId;
      
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadSchoolDashboard}: ${e.toString()}');
      emit(SchoolError(
        message: '${AppConstants.errorFailedToLoadSchoolDashboard}: ${e.toString()}',
        errorCode: AppConstants.errorCodeSchoolDashboard,
        actionType: AppConstants.actionTypeLoadDashboard,
      ));
    }
  }

  Future<void> _onProfileRequested(
    SchoolProfileRequested event,
    Emitter<SchoolState> emit,
  ) async {
    // Don't emit loading state to preserve dashboard UI
    try {
      final profile = await _schoolService.getSchoolProfile(event.schoolId);
      emit(SchoolProfileLoaded(profile: profile));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadSchoolProfile}: ${e.toString()}');
      emit(SchoolError(
        message: '${AppConstants.errorFailedToLoadSchoolProfile}: ${e.toString()}',
        errorCode: AppConstants.errorCodeSchoolProfile,
        actionType: AppConstants.actionTypeLoadProfile,
      ));
    }
  }

  Future<void> _onUpdateRequested(
    SchoolUpdateRequested event,
    Emitter<SchoolState> emit,
  ) async {
    try {
      final response = await _schoolService.updateSchoolProfile(
        event.schoolId,
        event.schoolData,
      );
      
      emit(SchoolActionSuccess(
        message: response[AppConstants.keyMessage] ?? AppConstants.msgSchoolProfileUpdated,
        actionType: AppConstants.actionTypeUpdateProfile,
      ));
      
      // Refresh profile after update
      add(SchoolProfileRequested(schoolId: event.schoolId));
      
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToUpdateSchoolProfile}: ${e.toString()}');
      emit(SchoolError(
        message: '${AppConstants.errorFailedToUpdateSchoolProfile}: ${e.toString()}',
        errorCode: AppConstants.errorCodeSchoolUpdate,
        actionType: AppConstants.actionTypeUpdateProfile,
      ));
    }
  }

  Future<void> _onStudentsRequested(
    SchoolStudentsRequested event,
    Emitter<SchoolState> emit,
  ) async {
    try {
      final students = await _schoolService.getSchoolStudents(event.schoolId);
      emit(SchoolStudentsLoaded(students: students));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadSchoolStudents}: ${e.toString()}');
      emit(SchoolError(
        message: '${AppConstants.errorFailedToLoadSchoolStudents}: ${e.toString()}',
        errorCode: AppConstants.errorCodeSchoolStudents,
        actionType: AppConstants.actionTypeLoadStudents,
      ));
    }
  }

  Future<void> _onStaffRequested(
    SchoolStaffRequested event,
    Emitter<SchoolState> emit,
  ) async {
    try {
      final staff = await _schoolService.getSchoolStaff(event.schoolId);
      emit(SchoolStaffLoaded(staff: staff));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadSchoolStaff}: ${e.toString()}');
      emit(SchoolError(
        message: '${AppConstants.errorFailedToLoadSchoolStaff}: ${e.toString()}',
        errorCode: AppConstants.errorCodeSchoolStaff,
        actionType: AppConstants.actionTypeLoadStaff,
      ));
    }
  }

  Future<void> _onVehiclesRequested(
    SchoolVehiclesRequested event,
    Emitter<SchoolState> emit,
  ) async {
    try {
      final vehicles = await _schoolService.getSchoolVehicles(event.schoolId);
      emit(SchoolVehiclesLoaded(vehicles: vehicles));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadSchoolVehicles}: ${e.toString()}');
      emit(SchoolError(
        message: '${AppConstants.errorFailedToLoadSchoolVehicles}: ${e.toString()}',
        errorCode: AppConstants.errorCodeSchoolVehicles,
        actionType: AppConstants.actionTypeLoadVehicles,
      ));
    }
  }

  Future<void> _onTripsRequested(
    SchoolTripsRequested event,
    Emitter<SchoolState> emit,
  ) async {
    try {
      final trips = await _schoolService.getSchoolTrips(event.schoolId);
      emit(SchoolTripsLoaded(trips: trips));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadSchoolTrips}: ${e.toString()}');
      emit(SchoolError(
        message: '${AppConstants.errorFailedToLoadSchoolTrips}: ${e.toString()}',
        errorCode: AppConstants.errorCodeSchoolTrips,
        actionType: AppConstants.actionTypeLoadTrips,
      ));
    }
  }

  Future<void> _onNotificationsRequested(
    SchoolNotificationsRequested event,
    Emitter<SchoolState> emit,
  ) async {
    try {
      final notificationsResponse = await _schoolService.getSchoolNotifications(event.schoolId);
      final notifications = notificationsResponse[AppConstants.keyData] ?? [];
      emit(SchoolNotificationsLoaded(notifications: notifications));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToFetchSchoolNotifications}: ${e.toString()}');
      emit(SchoolError(
        message: '${AppConstants.errorFailedToFetchSchoolNotifications}: ${e.toString()}',
        errorCode: AppConstants.errorCodeSchoolNotifications,
        actionType: AppConstants.actionTypeLoadNotifications,
      ));
    }
  }

  Future<void> _onReportsRequested(
    SchoolReportsRequested event,
    Emitter<SchoolState> emit,
  ) async {
    try {
      final reports = await _schoolService.getSchoolReports(event.schoolId);
      emit(SchoolReportsLoaded(reports: reports));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadSchoolReports}: ${e.toString()}');
      emit(SchoolError(
        message: '${AppConstants.errorFailedToLoadSchoolReports}: ${e.toString()}',
        errorCode: AppConstants.errorCodeSchoolReports,
        actionType: AppConstants.actionTypeLoadReports,
      ));
    }
  }

  Future<void> _onRefreshRequested(
    SchoolRefreshRequested event,
    Emitter<SchoolState> emit,
  ) async {
    await _refreshDashboardData(
      schoolId: event.schoolId,
      emit: emit,
      emitRefreshingState: true,
    );
  }

  Future<void> _onRealtimeNotificationReceived(
    SchoolRealtimeNotificationReceived event,
    Emitter<SchoolState> emit,
  ) async {
    if (_currentSchoolId == null) return;
    if (_isRealtimeRefreshInProgress) return;

    _isRealtimeRefreshInProgress = true;
    try {
      await _refreshDashboardData(
        schoolId: _currentSchoolId!,
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
    return super.close();
  }

  void _subscribeToRealtimeStreams() {
    _notificationSubscription ??=
        _webSocketService.notificationStream.listen(_handleNotification, onError: _handleStreamError);
    _tripUpdateSubscription ??=
        _webSocketService.tripUpdateStream.listen(_handleNotification, onError: _handleStreamError);
  }

  void _handleNotification(WebSocketNotification notification) {
    if (!_isNotificationRelevant(notification)) return;
    add(SchoolRealtimeNotificationReceived(notification: notification));
  }

  void _handleStreamError(Object error) {
    debugPrint('${AppConstants.msgNotificationStreamError}$error');
  }

  bool _isNotificationRelevant(WebSocketNotification notification) {
    if (_currentSchoolId == null) return false;

    if (notification.schoolId != null && notification.schoolId == _currentSchoolId) {
      return true;
    }

    final targetRole = notification.targetRole?.toUpperCase();
    if (targetRole == AppConstants.roleSchoolAdmin) {
      return true;
    }

    final dataSchoolId = notification.data != null
        ? notification.data![AppConstants.keySchoolId]
        : null;
    if (dataSchoolId != null) {
      if (dataSchoolId is int && dataSchoolId == _currentSchoolId) {
        return true;
      }
      if (dataSchoolId is String) {
        final parsed = int.tryParse(dataSchoolId);
        if (parsed != null && parsed == _currentSchoolId) {
          return true;
        }
      }
    }

    return false;
  }

  Future<void> _refreshDashboardData({
    required int schoolId,
    required Emitter<SchoolState> emit,
    required bool emitRefreshingState,
  }) async {
    SchoolDashboardLoaded? previousState;

    if (state is SchoolDashboardLoaded) {
      previousState = state as SchoolDashboardLoaded;
      if (emitRefreshingState) {
        emit(SchoolRefreshing(
          dashboard: previousState.dashboard,
          students: previousState.students,
          staff: previousState.staff,
          vehicles: previousState.vehicles,
          trips: previousState.trips,
          notifications: previousState.notifications,
        ));
      }
    }

    try {
      final dashboardResponse = await _schoolService.getSchoolDashboard(schoolId);
      final students = await _schoolService.getSchoolStudents(schoolId);
      final staff = await _schoolService.getSchoolStaff(schoolId);
      final vehicles = await _schoolService.getSchoolVehicles(schoolId);
      final trips = await _schoolService.getSchoolTrips(schoolId);
      final notificationsResponse = await _schoolService.getSchoolNotifications(schoolId);
      final notifications = notificationsResponse[AppConstants.keyData] ?? [];

      _currentSchoolId = schoolId;

      emit(SchoolDashboardLoaded(
        dashboard: dashboardResponse,
        students: students,
        staff: staff,
        vehicles: vehicles,
        trips: trips,
        notifications: notifications,
      ));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadSchoolDashboard}: ${e.toString()}');
      if (previousState != null) {
        emit(previousState);
      } else {
        emit(SchoolError(
          message: '${AppConstants.errorFailedToLoadSchoolDashboard}: ${e.toString()}',
          errorCode: AppConstants.errorCodeSchoolDashboard,
          actionType: AppConstants.actionTypeLoadDashboard,
        ));
      }
    }
  }
}

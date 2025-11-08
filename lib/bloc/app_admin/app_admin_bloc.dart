import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/constants.dart';
import '../../services/app_admin_service.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart';
import 'app_admin_event.dart';
import 'app_admin_state.dart';

class AppAdminBloc extends Bloc<AppAdminEvent, AppAdminState> {
  final AppAdminService _appAdminService;
  final WebSocketNotificationService _webSocketService;
  StreamSubscription<WebSocketNotification>? _notificationSubscription;
  StreamSubscription<WebSocketNotification>? _systemAlertSubscription;

  Map<String, dynamic>? _lastDashboard;
  List<dynamic> _lastSchools = <dynamic>[];
  Map<String, dynamic>? _lastSystemStats;
  bool _isRealtimeRefreshInProgress = false;

  AppAdminBloc({
    required AppAdminService appAdminService,
    required WebSocketNotificationService webSocketService,
  })  : _appAdminService = appAdminService,
        _webSocketService = webSocketService,
        super(const AppAdminInitial()) {
    on<AppAdminDashboardRequested>(_onDashboardRequested);
    on<AppAdminProfileRequested>(_onProfileRequested);
    on<AppAdminUpdateRequested>(_onUpdateRequested);
    on<AppAdminSchoolsRequested>(_onSchoolsRequested);
    on<AppAdminSchoolActivationRequested>(_onSchoolActivationRequested);
    on<AppAdminSchoolDatesRequested>(_onSchoolDatesRequested);
    on<AppAdminResendActivationLinkRequested>(_onResendActivationLinkRequested);
    on<AppAdminReportsRequested>(_onReportsRequested);
    on<AppAdminSystemStatsRequested>(_onSystemStatsRequested);
    on<AppAdminRefreshRequested>(_onRefreshRequested);
    on<AppAdminRealtimeNotificationReceived>(_onRealtimeNotificationReceived);

    unawaited(_webSocketService.initialize());
    _subscribeToRealtimeStreams();
  }

  Future<void> _onDashboardRequested(
    AppAdminDashboardRequested event,
    Emitter<AppAdminState> emit,
  ) async {
    emit(const AppAdminLoading());

    await _refreshDashboardData(
      emit: emit,
      emitRefreshingState: false,
    );
  }

  Future<void> _onProfileRequested(
    AppAdminProfileRequested event,
    Emitter<AppAdminState> emit,
  ) async {
    try {
      final profile = await _appAdminService.getAppAdminProfile();
      emit(AppAdminProfileLoaded(profile: profile));
    } catch (e) {
      emit(AppAdminError(
        message: '${AppConstants.errorFailedToGetStaffList}: ${e.toString()}',
        errorCode: AppConstants.errorCodeProfileLoad,
        actionType: AppConstants.actionTypeLoadProfile,
      ));
    }
  }

  Future<void> _onUpdateRequested(
    AppAdminUpdateRequested event,
    Emitter<AppAdminState> emit,
  ) async {
    try {
      final response = await _appAdminService.updateAppAdminProfile(event.adminData);

      emit(AppAdminActionSuccess(
        message: response[AppConstants.keyMessage] ?? AppConstants.msgProfileUpdated,
        actionType: AppConstants.actionTypeUpdateProfile,
      ));

      add(const AppAdminProfileRequested());
    } catch (e) {
      emit(AppAdminError(
        message: '${AppConstants.errorFailedToUpdateData}: ${e.toString()}',
        errorCode: AppConstants.errorCodeUpdate,
        actionType: AppConstants.actionTypeUpdateProfile,
      ));
    }
  }

  Future<void> _onSchoolsRequested(
    AppAdminSchoolsRequested event,
    Emitter<AppAdminState> emit,
  ) async {
    try {
      final schools = await _appAdminService.getAppAdminSchools();
      emit(AppAdminSchoolsLoaded(schools: schools));
    } catch (e) {
      emit(AppAdminError(
        message: '${AppConstants.errorFailedToFetchSchools}: ${e.toString()}',
        errorCode: AppConstants.errorCodeSchoolsLoad,
        actionType: AppConstants.actionTypeLoadSchools,
      ));
    }
  }

  Future<void> _onSchoolActivationRequested(
    AppAdminSchoolActivationRequested event,
    Emitter<AppAdminState> emit,
  ) async {
    try {
      final response = await _appAdminService.activateDeactivateSchool(
        event.schoolId,
        event.isActive,
      );

      emit(AppAdminActionSuccess(
        message: response[AppConstants.keyMessage] ?? AppConstants.msgSchoolStatusUpdated,
        actionType: AppConstants.actionTypeSchoolActivation,
      ));

      add(const AppAdminSchoolsRequested());
    } catch (e) {
      emit(AppAdminError(
        message: '${AppConstants.errorFailedToUpdateStaffStatus}: ${e.toString()}',
        errorCode: AppConstants.errorCodeSchoolActivation,
        actionType: AppConstants.actionTypeSchoolActivation,
      ));
    }
  }

  Future<void> _onSchoolDatesRequested(
    AppAdminSchoolDatesRequested event,
    Emitter<AppAdminState> emit,
  ) async {
    try {
      final response = await _appAdminService.setSchoolDates(
        event.schoolId,
        event.startDate,
        event.endDate,
      );

      emit(AppAdminActionSuccess(
        message: response[AppConstants.keyMessage] ?? AppConstants.msgSchoolDatesUpdated,
        actionType: AppConstants.actionTypeSchoolDates,
      ));

      add(const AppAdminSchoolsRequested());
    } catch (e) {
      emit(AppAdminError(
        message: '${AppConstants.errorFailedToUpdateData}: ${e.toString()}',
        errorCode: AppConstants.errorCodeSchoolDates,
        actionType: AppConstants.actionTypeSchoolDates,
      ));
    }
  }

  Future<void> _onResendActivationLinkRequested(
    AppAdminResendActivationLinkRequested event,
    Emitter<AppAdminState> emit,
  ) async {
    try {
      final response = await _appAdminService.resendActivationLink(event.schoolId);

      emit(AppAdminActionSuccess(
        message: response[AppConstants.keyMessage] ?? AppConstants.msgActivationLinkSent,
        actionType: AppConstants.actionTypeResendActivationLink,
      ));
    } catch (e) {
      emit(AppAdminError(
        message: '${AppConstants.errorFailedToSaveData}: ${e.toString()}',
        errorCode: AppConstants.errorCodeResendActivationLink,
        actionType: AppConstants.actionTypeResendActivationLink,
      ));
    }
  }

  Future<void> _onReportsRequested(
    AppAdminReportsRequested event,
    Emitter<AppAdminState> emit,
  ) async {
    try {
      final reports = await _appAdminService.getAppAdminReports(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(AppAdminReportsLoaded(reports: reports));
    } catch (e) {
      emit(AppAdminError(
        message: '${AppConstants.errorFailedToFetchData}: ${e.toString()}',
        errorCode: AppConstants.errorCodeReportsLoad,
        actionType: AppConstants.actionTypeLoadReports,
      ));
    }
  }

  Future<void> _onSystemStatsRequested(
    AppAdminSystemStatsRequested event,
    Emitter<AppAdminState> emit,
  ) async {
    try {
      final systemStats = await _appAdminService.getAppAdminSystemStats();
      emit(AppAdminSystemStatsLoaded(systemStats: systemStats));
    } catch (e) {
      emit(AppAdminError(
        message: '${AppConstants.errorFailedToGetDashboardStats}: ${e.toString()}',
        errorCode: AppConstants.errorCodeSystemStatsLoad,
        actionType: AppConstants.actionTypeLoadSystemStats,
      ));
    }
  }

  Future<void> _onRefreshRequested(
    AppAdminRefreshRequested event,
    Emitter<AppAdminState> emit,
  ) async {
    await _refreshDashboardData(
      emit: emit,
      emitRefreshingState: true,
    );
  }

  Future<void> _onRealtimeNotificationReceived(
    AppAdminRealtimeNotificationReceived event,
    Emitter<AppAdminState> emit,
  ) async {
    if (_isRealtimeRefreshInProgress) return;

    _isRealtimeRefreshInProgress = true;
    try {
      await _refreshDashboardData(
        emit: emit,
        emitRefreshingState: false,
      );
    } finally {
      _isRealtimeRefreshInProgress = false;
    }
  }

  void _subscribeToRealtimeStreams() {
    _notificationSubscription ??=
        _webSocketService.notificationStream.listen(_handleNotification, onError: _handleStreamError);
    _systemAlertSubscription ??=
        _webSocketService.systemAlertStream.listen(_handleNotification, onError: _handleStreamError);
  }

  void _handleNotification(WebSocketNotification notification) {
    if (!_isNotificationRelevant(notification)) return;
    add(AppAdminRealtimeNotificationReceived(notification: notification));
  }

  void _handleStreamError(Object error) {
    debugPrint('${AppConstants.msgNotificationStreamError}$error');
  }

  bool _isNotificationRelevant(WebSocketNotification notification) {
    final targetRole = notification.targetRole?.toUpperCase();
    if (targetRole == AppConstants.roleAppAdmin) {
      return true;
    }

    final typeUpper = notification.type.toUpperCase();
    final relevantTypes = <String>{
      AppConstants.notifTypeNewSchoolRegistration.toUpperCase(),
      AppConstants.notifTypeSystemError.toUpperCase(),
      AppConstants.notifTypeSystemAlert.toUpperCase(),
      AppConstants.notifTypeEmergencyAlert.toUpperCase(),
      AppConstants.notifTypeDatabaseBackup.toUpperCase(),
      AppConstants.notifTypeInfo.toUpperCase(),
      AppConstants.notifTypeAlert.toUpperCase(),
      AppConstants.notifTypeSuccess.toUpperCase(),
      NotificationType.systemAlert.toUpperCase(),
    };

    if (relevantTypes.contains(typeUpper)) {
      return true;
    }

    return notification.targetRole == null && notification.targetUser == null;
  }

  Future<void> _refreshDashboardData({
    required Emitter<AppAdminState> emit,
    required bool emitRefreshingState,
  }) async {
    AppAdminDashboardLoaded? previousState;

    if (state is AppAdminDashboardLoaded) {
      previousState = state as AppAdminDashboardLoaded;
      if (emitRefreshingState) {
        emit(AppAdminRefreshing(
          dashboard: previousState.dashboard,
          schools: previousState.schools,
          systemStats: previousState.systemStats,
        ));
      }
    } else if (state is AppAdminRefreshing &&
        _lastDashboard != null &&
        _lastSystemStats != null) {
      previousState = AppAdminDashboardLoaded(
        dashboard: _lastDashboard!,
        schools: _lastSchools,
        systemStats: _lastSystemStats!,
      );
    }

    try {
      final dashboard = await _appAdminService.getAppAdminDashboard();
      final schools = await _appAdminService.getAppAdminSchools();
      final systemStats = await _appAdminService.getAppAdminSystemStats();

      _lastDashboard = dashboard;
      _lastSchools = List<dynamic>.from(schools);
      _lastSystemStats = systemStats;

      emit(AppAdminDashboardLoaded(
        dashboard: dashboard,
        schools: schools,
        systemStats: systemStats,
      ));
    } catch (e) {
      debugPrint('❌ Dashboard Error: $e');
      if (previousState != null) {
        emit(previousState);
      } else {
        emit(AppAdminError(
          message: '${AppConstants.errorFailedToGetDashboardStats}: ${e.toString()}',
          errorCode: AppConstants.errorCodeDashboardLoad,
          actionType: AppConstants.actionTypeLoadDashboard,
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    _systemAlertSubscription?.cancel();
    return super.close();
  }
}


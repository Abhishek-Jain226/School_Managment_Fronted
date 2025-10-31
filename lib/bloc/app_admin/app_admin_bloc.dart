import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/constants.dart';
import '../../services/app_admin_service.dart';
import 'app_admin_event.dart';
import 'app_admin_state.dart';

class AppAdminBloc extends Bloc<AppAdminEvent, AppAdminState> {
  final AppAdminService _appAdminService;
  Timer? _refreshTimer;

  AppAdminBloc({required AppAdminService appAdminService})
      : _appAdminService = appAdminService,
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
  }

  Future<void> _onDashboardRequested(
    AppAdminDashboardRequested event,
    Emitter<AppAdminState> emit,
  ) async {
    emit(const AppAdminLoading());
    
    try {
      // Load dashboard data
      final dashboard = await _appAdminService.getAppAdminDashboard();
      debugPrint('📊 Dashboard Response: $dashboard');
      
      // Load related data
      final schools = await _appAdminService.getAppAdminSchools();
      debugPrint('🏫 Schools Response: $schools');
      debugPrint('🏫 Schools Count: ${schools.length}');
      
      final systemStats = await _appAdminService.getAppAdminSystemStats();
      debugPrint('📈 System Stats Response: $systemStats');
      
      emit(AppAdminDashboardLoaded(
        dashboard: dashboard,
        schools: schools,
        systemStats: systemStats,
      ));
      
      // Start auto-refresh timer
      _startRefreshTimer();
      
    } catch (e) {
      debugPrint('❌ Dashboard Error: $e');
      emit(AppAdminError(
        message: '${AppConstants.errorFailedToGetDashboardStats}: ${e.toString()}',
        errorCode: AppConstants.errorCodeDashboardLoad,
        actionType: AppConstants.actionTypeLoadDashboard,
      ));
    }
  }

  Future<void> _onProfileRequested(
    AppAdminProfileRequested event,
    Emitter<AppAdminState> emit,
  ) async {
    // Don't emit loading state to preserve dashboard UI
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
      
      // Refresh profile after update
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
      
      // Refresh schools after activation/deactivation
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
      
      // Refresh schools after date update
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
    // Emit refreshing state to show loading indicator
    if (state is AppAdminDashboardLoaded) {
      final currentState = state as AppAdminDashboardLoaded;
      emit(AppAdminRefreshing(
        dashboard: currentState.dashboard,
        schools: currentState.schools,
        systemStats: currentState.systemStats,
      ));
    }
    
    // Refresh dashboard data
    add(const AppAdminDashboardRequested());
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(AppDurations.autoRefreshDashboard, (timer) {
      add(const AppAdminRefreshRequested());
    });
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }
}

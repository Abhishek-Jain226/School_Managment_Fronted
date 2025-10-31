import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/constants.dart';
import '../../services/parent_service.dart';
import 'parent_event.dart';
import 'parent_state.dart';

class ParentBloc extends Bloc<ParentEvent, ParentState> {
  final ParentService _parentService;
  Timer? _refreshTimer;

  ParentBloc({required ParentService parentService})
      : _parentService = parentService,
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
        dashboard: dashboard.toJson(),
        students: students,
        trips: trips,
        notifications: notifications,
      ));
      
      // Start auto-refresh timer
      _startRefreshTimer(event.parentId);
      
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
    // Emit refreshing state to show loading indicator
    if (state is ParentDashboardLoaded) {
      final currentState = state as ParentDashboardLoaded;
      emit(ParentRefreshing(
        dashboard: currentState.dashboard,
        students: currentState.students,
        trips: currentState.trips,
        notifications: currentState.notifications,
      ));
    }
    
    // Refresh dashboard data
    add(ParentDashboardRequested(parentId: event.parentId));
  }

  void _startRefreshTimer(int parentId) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(AppDurations.autoRefreshParent, (timer) {
      add(ParentRefreshRequested(parentId: parentId));
    });
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }
}

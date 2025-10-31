import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/constants.dart';
import '../../services/school_service.dart';
import 'school_event.dart';
import 'school_state.dart';

class SchoolBloc extends Bloc<SchoolEvent, SchoolState> {
  final SchoolService _schoolService;
  Timer? _refreshTimer;

  SchoolBloc({required SchoolService schoolService})
      : _schoolService = schoolService,
        super(const SchoolInitial()) {
    on<SchoolDashboardRequested>(_onDashboardRequested);
    on<SchoolProfileRequested>(_onProfileRequested);
    on<SchoolUpdateRequested>(_onUpdateRequested);
    on<SchoolStudentsRequested>(_onStudentsRequested);
    on<SchoolStaffRequested>(_onStaffRequested);
    on<SchoolVehiclesRequested>(_onVehiclesRequested);
    on<SchoolTripsRequested>(_onTripsRequested);
    on<SchoolReportsRequested>(_onReportsRequested);
    on<SchoolRefreshRequested>(_onRefreshRequested);
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
      
      emit(SchoolDashboardLoaded(
        dashboard: dashboardResponse,
        students: students,
        staff: staff,
        vehicles: vehicles,
        trips: trips,
      ));
      
      // Start auto-refresh timer
      _startRefreshTimer(event.schoolId);
      
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
    // Emit refreshing state to show loading indicator
    if (state is SchoolDashboardLoaded) {
      final currentState = state as SchoolDashboardLoaded;
      emit(SchoolRefreshing(
        dashboard: currentState.dashboard,
        students: currentState.students,
        staff: currentState.staff,
        vehicles: currentState.vehicles,
        trips: currentState.trips,
      ));
    }
    
    // Refresh dashboard data
    add(SchoolDashboardRequested(schoolId: event.schoolId));
  }

  void _startRefreshTimer(int schoolId) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(AppDurations.autoRefreshSchool, (timer) {
      add(SchoolRefreshRequested(schoolId: schoolId));
    });
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }
}

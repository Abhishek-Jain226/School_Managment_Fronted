import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/driver_service.dart';
import '../../utils/constants.dart';
import 'driver_event.dart';
import 'driver_state.dart';

class DriverBloc extends Bloc<DriverEvent, DriverState> {
  final DriverService _driverService;
  Timer? _refreshTimer;

  DriverBloc({required DriverService driverService})
      : _driverService = driverService,
        super(const DriverInitial()) {
    on<DriverDashboardRequested>(_onDashboardRequested);
    on<DriverTripsRequested>(_onTripsRequested);
    on<DriverProfileRequested>(_onProfileRequested);
    on<DriverReportsRequested>(_onReportsRequested);
    on<DriverTripStudentsRequested>(_onTripStudentsRequested);
    on<DriverMarkAttendanceRequested>(_onMarkAttendanceRequested);
    on<DriverSendNotificationRequested>(_onSendNotificationRequested);
    on<DriverUpdateLocationRequested>(_onUpdateLocationRequested);
    on<DriverEndTripRequested>(_onEndTripRequested);
    on<DriverSend5MinuteAlertRequested>(_onSend5MinuteAlertRequested);
    on<DriverMarkPickupFromHomeRequested>(_onMarkPickupFromHomeRequested);
    on<DriverMarkDropToSchoolRequested>(_onMarkDropToSchoolRequested);
    on<DriverMarkPickupFromSchoolRequested>(_onMarkPickupFromSchoolRequested);
    on<DriverMarkDropToHomeRequested>(_onMarkDropToHomeRequested);
    on<DriverRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onDashboardRequested(
    DriverDashboardRequested event,
    Emitter<DriverState> emit,
  ) async {
    emit(const DriverLoading());
    
    try {
      // Load dashboard data
      final dashboard = await _driverService.getDriverDashboard(event.driverId);
      
      // Load reports
      final reports = await _driverService.getDriverReports(event.driverId);
      
      // Load trips
      final trips = await _driverService.getAssignedTrips(event.driverId);
      
      // Separate morning and afternoon trips
      final morningTrips = trips.where((trip) => trip.tripType == AppConstants.tripTypeMorningPickup).toList();
      final afternoonTrips = trips.where((trip) => trip.tripType == AppConstants.tripTypeAfternoonDrop).toList();
      
      emit(DriverDashboardLoaded(
        dashboard: dashboard,
        reports: reports,
        morningTrips: morningTrips,
        afternoonTrips: afternoonTrips,
      ));
      
      // Start auto-refresh timer
      _startRefreshTimer(event.driverId);
      
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadDriverDashboard}: ${e.toString()}');
      emit(DriverError(
        message: '${AppConstants.errorFailedToLoadDriverDashboard}: ${e.toString()}',
        errorCode: AppConstants.errorCodeDriverDashboard,
        actionType: AppConstants.actionTypeLoadDashboard,
      ));
    }
  }

  Future<void> _onTripsRequested(
    DriverTripsRequested event,
    Emitter<DriverState> emit,
  ) async {
    try {
      final trips = await _driverService.getAssignedTrips(event.driverId);
      final morningTrips = trips.where((trip) => trip.tripType == AppConstants.tripTypeMorningPickup).toList();
      final afternoonTrips = trips.where((trip) => trip.tripType == AppConstants.tripTypeAfternoonDrop).toList();
      
      emit(DriverTripsLoaded(
        trips: trips,
        morningTrips: morningTrips,
        afternoonTrips: afternoonTrips,
      ));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadTrips}: ${e.toString()}');
      emit(DriverError(
        message: '${AppConstants.errorFailedToLoadTrips}: ${e.toString()}',
        errorCode: AppConstants.errorCodeDriverTrips,
        actionType: AppConstants.actionTypeLoadTrips,
      ));
    }
  }

  Future<void> _onProfileRequested(
    DriverProfileRequested event,
    Emitter<DriverState> emit,
  ) async {
    // Don't emit loading state to preserve dashboard UI
    try {
      final profile = await _driverService.getDriverProfile(event.driverId);
      
      if (profile == null) {
        emit(DriverError(
          message: AppConstants.errorDriverProfileNotFound,
          errorCode: AppConstants.errorCodeDriverProfileNotFound,
          actionType: AppConstants.actionTypeLoadProfile,
        ));
        return;
      }
      
      emit(DriverProfileLoaded(profile: profile));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadDriverProfile}: ${e.toString()}');
      emit(DriverError(
        message: '${AppConstants.errorFailedToLoadDriverProfile}: ${e.toString()}',
        errorCode: AppConstants.errorCodeDriverProfile,
        actionType: AppConstants.actionTypeLoadProfile,
      ));
    }
  }

  Future<void> _onReportsRequested(
    DriverReportsRequested event,
    Emitter<DriverState> emit,
  ) async {
    try {
      final reports = await _driverService.getDriverReports(event.driverId);
      
      if (reports == null) {
        emit(const DriverError(
          message: AppConstants.errorDriverReportsNotFound,
          errorCode: AppConstants.errorCodeDriverReportsNotFound,
          actionType: AppConstants.actionTypeLoadReports,
        ));
        return;
      }
      
      emit(DriverReportsLoaded(reports: reports));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadDriverReports}: ${e.toString()}');
      emit(DriverError(
        message: '${AppConstants.errorFailedToLoadDriverReports}: ${e.toString()}',
        errorCode: AppConstants.errorCodeDriverReports,
        actionType: AppConstants.actionTypeLoadReports,
      ));
    }
  }

  Future<void> _onTripStudentsRequested(
    DriverTripStudentsRequested event,
    Emitter<DriverState> emit,
  ) async {
    try {
      final trip = await _driverService.getTripStudents(event.driverId, event.tripId);
      emit(DriverTripStudentsLoaded(
        tripId: event.tripId,
        students: trip.students,
      ));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadTripStudents}: ${e.toString()}');
      emit(DriverError(
        message: '${AppConstants.errorFailedToLoadTripStudents}: ${e.toString()}',
        errorCode: AppConstants.errorCodeTripStudents,
        actionType: AppConstants.actionTypeLoadTripStudents,
      ));
    }
  }

  Future<void> _onMarkAttendanceRequested(
    DriverMarkAttendanceRequested event,
    Emitter<DriverState> emit,
  ) async {
    try {
      final response = await _driverService.markAttendance(
        event.driverId,
        event.attendanceRequest,
      );
      
      emit(DriverActionSuccess(
        message: response.message,
        actionType: AppConstants.actionTypeMarkAttendance,
      ));
      
      // Refresh dashboard after marking attendance
      add(DriverDashboardRequested(driverId: event.driverId));
      
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToMarkAttendance}: ${e.toString()}');
      emit(DriverError(
        message: '${AppConstants.errorFailedToMarkAttendance}: ${e.toString()}',
        errorCode: AppConstants.errorCodeAttendance,
        actionType: AppConstants.actionTypeMarkAttendance,
      ));
    }
  }

  Future<void> _onSendNotificationRequested(
    DriverSendNotificationRequested event,
    Emitter<DriverState> emit,
  ) async {
    try {
      final response = await _driverService.sendNotification(
        event.driverId,
        event.notificationRequest,
      );
      
      emit(DriverActionSuccess(
        message: response[AppConstants.keyMessage] ?? AppConstants.msgNotificationSent,
        actionType: AppConstants.actionTypeSendNotification,
      ));
      
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToSendNotification}: ${e.toString()}');
      emit(DriverError(
        message: '${AppConstants.errorFailedToSendNotification}: ${e.toString()}',
        errorCode: AppConstants.errorCodeNotification,
        actionType: AppConstants.actionTypeSendNotification,
      ));
    }
  }

  Future<void> _onUpdateLocationRequested(
    DriverUpdateLocationRequested event,
    Emitter<DriverState> emit,
  ) async {
    try {
      await _driverService.updateDriverLocation(
        event.driverId,
        event.latitude,
        event.longitude,
      );
      
      emit(DriverLocationUpdated(
        latitude: event.latitude,
        longitude: event.longitude,
      ));
      
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToUpdateLocation}: ${e.toString()}');
      emit(DriverError(
        message: '${AppConstants.errorFailedToUpdateLocation}: ${e.toString()}',
        errorCode: AppConstants.errorCodeLocationUpdate,
        actionType: AppConstants.actionTypeUpdateLocation,
      ));
    }
  }

  Future<void> _onEndTripRequested(
    DriverEndTripRequested event,
    Emitter<DriverState> emit,
  ) async {
    try {
      final response = await _driverService.endTrip(event.driverId, event.tripId);
      
      emit(DriverActionSuccess(
        message: response[AppConstants.keyMessage] ?? AppConstants.msgTripEnded,
        actionType: AppConstants.actionTypeEndTrip,
      ));
      
      // Refresh dashboard after ending trip
      add(DriverDashboardRequested(driverId: event.driverId));
      
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToEndTrip}: ${e.toString()}');
      emit(DriverError(
        message: '${AppConstants.errorFailedToEndTrip}: ${e.toString()}',
        errorCode: AppConstants.errorCodeEndTrip,
        actionType: AppConstants.actionTypeEndTrip,
      ));
    }
  }

  Future<void> _onSend5MinuteAlertRequested(
    DriverSend5MinuteAlertRequested event,
    Emitter<DriverState> emit,
  ) async {
    try {
      final response = await _driverService.send5MinuteAlert(event.driverId, event.tripId);
      
      emit(DriverActionSuccess(
        message: response[AppConstants.keyMessage] ?? AppConstants.msg5MinuteAlert,
        actionType: AppConstants.actionTypeSend5MinAlert,
      ));
      
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToSend5MinAlert}: ${e.toString()}');
      emit(DriverError(
        message: '${AppConstants.errorFailedToSend5MinAlert}: ${e.toString()}',
        errorCode: AppConstants.errorCode5MinAlert,
        actionType: AppConstants.actionTypeSend5MinAlert,
      ));
    }
  }

  Future<void> _onMarkPickupFromHomeRequested(
    DriverMarkPickupFromHomeRequested event,
    Emitter<DriverState> emit,
  ) async {
    try {
      final response = await _driverService.markPickupFromHome(
        event.driverId,
        event.tripId,
        event.studentId,
      );
      
      emit(DriverActionSuccess(
        message: response[AppConstants.keyMessage] ?? AppConstants.msgPickupFromHome,
        actionType: AppConstants.actionTypeMarkPickupHome,
      ));
      
      // Refresh dashboard
      add(DriverDashboardRequested(driverId: event.driverId));
      
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToMarkPickupHome}: ${e.toString()}');
      emit(DriverError(
        message: '${AppConstants.errorFailedToMarkPickupHome}: ${e.toString()}',
        errorCode: AppConstants.errorCodePickupHome,
        actionType: AppConstants.actionTypeMarkPickupHome,
      ));
    }
  }

  Future<void> _onMarkDropToSchoolRequested(
    DriverMarkDropToSchoolRequested event,
    Emitter<DriverState> emit,
  ) async {
    try {
      final response = await _driverService.markDropToSchool(
        event.driverId,
        event.tripId,
        event.studentId,
      );
      
      emit(DriverActionSuccess(
        message: response[AppConstants.keyMessage] ?? AppConstants.msgDropToSchool,
        actionType: AppConstants.actionTypeMarkDropSchool,
      ));
      
      // Refresh dashboard
      add(DriverDashboardRequested(driverId: event.driverId));
      
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToMarkDropSchool}: ${e.toString()}');
      emit(DriverError(
        message: '${AppConstants.errorFailedToMarkDropSchool}: ${e.toString()}',
        errorCode: AppConstants.errorCodeDropSchool,
        actionType: AppConstants.actionTypeMarkDropSchool,
      ));
    }
  }

  Future<void> _onMarkPickupFromSchoolRequested(
    DriverMarkPickupFromSchoolRequested event,
    Emitter<DriverState> emit,
  ) async {
    try {
      final response = await _driverService.markPickupFromSchool(
        event.driverId,
        event.tripId,
        event.studentId,
      );
      
      emit(DriverActionSuccess(
        message: response[AppConstants.keyMessage] ?? AppConstants.msgPickupFromSchool,
        actionType: AppConstants.actionTypeMarkPickupSchool,
      ));
      
      // Refresh dashboard
      add(DriverDashboardRequested(driverId: event.driverId));
      
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToMarkPickupSchool}: ${e.toString()}');
      emit(DriverError(
        message: '${AppConstants.errorFailedToMarkPickupSchool}: ${e.toString()}',
        errorCode: AppConstants.errorCodePickupSchool,
        actionType: AppConstants.actionTypeMarkPickupSchool,
      ));
    }
  }

  Future<void> _onMarkDropToHomeRequested(
    DriverMarkDropToHomeRequested event,
    Emitter<DriverState> emit,
  ) async {
    try {
      final response = await _driverService.markDropToHome(
        event.driverId,
        event.tripId,
        event.studentId,
      );
      
      emit(DriverActionSuccess(
        message: response[AppConstants.keyMessage] ?? AppConstants.msgDropToHome,
        actionType: AppConstants.actionTypeMarkDropHome,
      ));
      
      // Refresh dashboard
      add(DriverDashboardRequested(driverId: event.driverId));
      
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToMarkDropHome}: ${e.toString()}');
      emit(DriverError(
        message: '${AppConstants.errorFailedToMarkDropHome}: ${e.toString()}',
        errorCode: AppConstants.errorCodeDropHome,
        actionType: AppConstants.actionTypeMarkDropHome,
      ));
    }
  }

  Future<void> _onRefreshRequested(
    DriverRefreshRequested event,
    Emitter<DriverState> emit,
  ) async {
    // Emit refreshing state to show loading indicator
    if (state is DriverDashboardLoaded) {
      final currentState = state as DriverDashboardLoaded;
      emit(DriverRefreshing(
        dashboard: currentState.dashboard,
        reports: currentState.reports,
        morningTrips: currentState.morningTrips,
        afternoonTrips: currentState.afternoonTrips,
      ));
    }
    
    // Refresh dashboard data
    add(DriverDashboardRequested(driverId: event.driverId));
  }

  void _startRefreshTimer(int driverId) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      add(DriverRefreshRequested(driverId: driverId));
    });
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }
}

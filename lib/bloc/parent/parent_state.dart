import 'package:equatable/equatable.dart';


abstract class ParentState extends Equatable {
  const ParentState();

  @override
  List<Object?> get props => [];
}

class ParentInitial extends ParentState {
  const ParentInitial();
}

class ParentLoading extends ParentState {
  const ParentLoading();
}

class ParentDashboardLoaded extends ParentState {
  final Map<String, dynamic> dashboard;
  final List<dynamic> students;
  final List<dynamic> trips;
  final List<dynamic> notifications;

  const ParentDashboardLoaded({
    required this.dashboard,
    required this.students,
    required this.trips,
    required this.notifications,
  });

  @override
  List<Object> get props => [dashboard, students, trips, notifications];
}

class ParentProfileLoaded extends ParentState {
  final Map<String, dynamic> profile;

  const ParentProfileLoaded({required this.profile});

  @override
  List<Object> get props => [profile];
}

class ParentStudentsLoaded extends ParentState {
  final List<dynamic> students;

  const ParentStudentsLoaded({required this.students});

  @override
  List<Object> get props => [students];
}

class ParentTripsLoaded extends ParentState {
  final List<dynamic> trips;

  const ParentTripsLoaded({required this.trips});

  @override
  List<Object> get props => [trips];
}

class ParentNotificationsLoaded extends ParentState {
  final List<dynamic> notifications;

  const ParentNotificationsLoaded({required this.notifications});

  @override
  List<Object> get props => [notifications];
}

class ParentAttendanceHistoryLoaded extends ParentState {
  final List<dynamic> attendanceHistory;

  const ParentAttendanceHistoryLoaded({required this.attendanceHistory});

  @override
  List<Object> get props => [attendanceHistory];
}

class ParentMonthlyReportLoaded extends ParentState {
  final Map<String, dynamic> monthlyReport;

  const ParentMonthlyReportLoaded({required this.monthlyReport});

  @override
  List<Object> get props => [monthlyReport];
}

class ParentVehicleTrackingLoaded extends ParentState {
  final Map<String, dynamic> vehicleTracking;
  final Map<String, dynamic>? driverLocation;

  const ParentVehicleTrackingLoaded({
    required this.vehicleTracking,
    this.driverLocation,
  });

  @override
  List<Object?> get props => [vehicleTracking, driverLocation];
}

class ParentDriverLocationLoaded extends ParentState {
  final Map<String, dynamic> driverLocation;

  const ParentDriverLocationLoaded({required this.driverLocation});

  @override
  List<Object> get props => [driverLocation];
}

class ParentActionSuccess extends ParentState {
  final String message;
  final String actionType;

  const ParentActionSuccess({
    required this.message,
    required this.actionType,
  });

  @override
  List<Object> get props => [message, actionType];
}

class ParentError extends ParentState {
  final String message;
  final String? errorCode;
  final String? actionType;

  const ParentError({
    required this.message,
    this.errorCode,
    this.actionType,
  });

  @override
  List<Object?> get props => [message, errorCode, actionType];
}

class ParentRefreshing extends ParentState {
  final Map<String, dynamic>? dashboard;
  final List<dynamic>? students;
  final List<dynamic>? trips;
  final List<dynamic>? notifications;

  const ParentRefreshing({
    this.dashboard,
    this.students,
    this.trips,
    this.notifications,
  });

  @override
  List<Object?> get props => [dashboard, students, trips, notifications];
}

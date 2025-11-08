import 'package:equatable/equatable.dart';

abstract class SchoolState extends Equatable {
  const SchoolState();

  @override
  List<Object?> get props => [];
}

class SchoolInitial extends SchoolState {
  const SchoolInitial();
}

class SchoolLoading extends SchoolState {
  const SchoolLoading();
}

class SchoolDashboardLoaded extends SchoolState {
  final Map<String, dynamic> dashboard;
  final List<dynamic> students;
  final List<dynamic> staff;
  final List<dynamic> vehicles;
  final List<dynamic> trips;
  final List<dynamic> notifications;

  const SchoolDashboardLoaded({
    required this.dashboard,
    required this.students,
    required this.staff,
    required this.vehicles,
    required this.trips,
    required this.notifications,
  });

  @override
  List<Object> get props => [dashboard, students, staff, vehicles, trips, notifications];
}

class SchoolProfileLoaded extends SchoolState {
  final Map<String, dynamic> profile;

  const SchoolProfileLoaded({required this.profile});

  @override
  List<Object> get props => [profile];
}

class SchoolStudentsLoaded extends SchoolState {
  final List<dynamic> students;

  const SchoolStudentsLoaded({required this.students});

  @override
  List<Object> get props => [students];
}

class SchoolStaffLoaded extends SchoolState {
  final List<dynamic> staff;

  const SchoolStaffLoaded({required this.staff});

  @override
  List<Object> get props => [staff];
}

class SchoolVehiclesLoaded extends SchoolState {
  final List<dynamic> vehicles;

  const SchoolVehiclesLoaded({required this.vehicles});

  @override
  List<Object> get props => [vehicles];
}

class SchoolTripsLoaded extends SchoolState {
  final List<dynamic> trips;

  const SchoolTripsLoaded({required this.trips});

  @override
  List<Object> get props => [trips];
}

class SchoolNotificationsLoaded extends SchoolState {
  final List<dynamic> notifications;

  const SchoolNotificationsLoaded({required this.notifications});

  @override
  List<Object> get props => [notifications];
}

class SchoolReportsLoaded extends SchoolState {
  final Map<String, dynamic> reports;

  const SchoolReportsLoaded({required this.reports});

  @override
  List<Object> get props => [reports];
}

class SchoolActionSuccess extends SchoolState {
  final String message;
  final String actionType;

  const SchoolActionSuccess({
    required this.message,
    required this.actionType,
  });

  @override
  List<Object> get props => [message, actionType];
}

class SchoolError extends SchoolState {
  final String message;
  final String? errorCode;
  final String? actionType;

  const SchoolError({
    required this.message,
    this.errorCode,
    this.actionType,
  });

  @override
  List<Object?> get props => [message, errorCode, actionType];
}

class SchoolRefreshing extends SchoolState {
  final Map<String, dynamic>? dashboard;
  final List<dynamic>? students;
  final List<dynamic>? staff;
  final List<dynamic>? vehicles;
  final List<dynamic>? trips;
  final List<dynamic>? notifications;

  const SchoolRefreshing({
    this.dashboard,
    this.students,
    this.staff,
    this.vehicles,
    this.trips,
    this.notifications,
  });

  @override
  List<Object?> get props => [dashboard, students, staff, vehicles, trips, notifications];
}

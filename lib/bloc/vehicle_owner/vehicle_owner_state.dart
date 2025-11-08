import 'package:equatable/equatable.dart';


abstract class VehicleOwnerState extends Equatable {
  const VehicleOwnerState();

  @override
  List<Object?> get props => [];
}

class VehicleOwnerInitial extends VehicleOwnerState {
  const VehicleOwnerInitial();
}

class VehicleOwnerLoading extends VehicleOwnerState {
  const VehicleOwnerLoading();
}

class VehicleOwnerDashboardLoaded extends VehicleOwnerState {
  final Map<String, dynamic> dashboard;
  final List<dynamic> vehicles;
  final List<dynamic> drivers;
  final List<dynamic> trips;
  final List<dynamic> notifications;

  const VehicleOwnerDashboardLoaded({
    required this.dashboard,
    required this.vehicles,
    required this.drivers,
    required this.trips,
    required this.notifications,
  });

  @override
  List<Object> get props => [dashboard, vehicles, drivers, trips, notifications];
}

class VehicleOwnerProfileLoaded extends VehicleOwnerState {
  final Map<String, dynamic> profile;

  const VehicleOwnerProfileLoaded({required this.profile});

  @override
  List<Object> get props => [profile];
}

class VehicleOwnerVehiclesLoaded extends VehicleOwnerState {
  final List<dynamic> vehicles;

  const VehicleOwnerVehiclesLoaded({required this.vehicles});

  @override
  List<Object> get props => [vehicles];
}

class VehicleOwnerDriversLoaded extends VehicleOwnerState {
  final List<dynamic> drivers;

  const VehicleOwnerDriversLoaded({required this.drivers});

  @override
  List<Object> get props => [drivers];
}

class VehicleOwnerTripsLoaded extends VehicleOwnerState {
  final List<dynamic> trips;

  const VehicleOwnerTripsLoaded({required this.trips});

  @override
  List<Object> get props => [trips];
}

class VehicleOwnerNotificationsLoaded extends VehicleOwnerState {
  final List<dynamic> notifications;

  const VehicleOwnerNotificationsLoaded({required this.notifications});

  @override
  List<Object> get props => [notifications];
}

class VehicleOwnerReportsLoaded extends VehicleOwnerState {
  final Map<String, dynamic> reports;

  const VehicleOwnerReportsLoaded({required this.reports});

  @override
  List<Object> get props => [reports];
}

class VehicleOwnerActionSuccess extends VehicleOwnerState {
  final String message;
  final String actionType;

  const VehicleOwnerActionSuccess({
    required this.message,
    required this.actionType,
  });

  @override
  List<Object> get props => [message, actionType];
}

class VehicleOwnerError extends VehicleOwnerState {
  final String message;
  final String? errorCode;
  final String? actionType;

  const VehicleOwnerError({
    required this.message,
    this.errorCode,
    this.actionType,
  });

  @override
  List<Object?> get props => [message, errorCode, actionType];
}

class VehicleOwnerRefreshing extends VehicleOwnerState {
  final Map<String, dynamic>? dashboard;
  final List<dynamic>? vehicles;
  final List<dynamic>? drivers;
  final List<dynamic>? trips;
  final List<dynamic>? notifications;

  const VehicleOwnerRefreshing({
    this.dashboard,
    this.vehicles,
    this.drivers,
    this.trips,
    this.notifications,
  });

  @override
  List<Object?> get props => [dashboard, vehicles, drivers, trips, notifications];
}

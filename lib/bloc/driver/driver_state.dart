import 'package:equatable/equatable.dart';
import '../../utils/constants.dart';
import '../../data/models/driver_dashboard.dart';
import '../../data/models/driver_profile.dart';
import '../../data/models/driver_reports.dart';
import '../../data/models/trip.dart';

abstract class DriverState extends Equatable {
  const DriverState();

  @override
  List<Object?> get props => [];
}

class DriverInitial extends DriverState {
  const DriverInitial();
}

class DriverLoading extends DriverState {
  const DriverLoading();
}

class DriverDashboardLoaded extends DriverState {
  final DriverDashboard dashboard;
  final DriverReports? reports;
  final List<Trip> morningTrips;
  final List<Trip> afternoonTrips;
  final String selectedTripType;

  const DriverDashboardLoaded({
    required this.dashboard,
    this.reports,
    required this.morningTrips,
    required this.afternoonTrips,
    this.selectedTripType = AppConstants.tripTypeMorningPickup,
  });

  @override
  List<Object?> get props => [
        dashboard,
        reports,
        morningTrips,
        afternoonTrips,
        selectedTripType,
      ];

  DriverDashboardLoaded copyWith({
    DriverDashboard? dashboard,
    DriverReports? reports,
    List<Trip>? morningTrips,
    List<Trip>? afternoonTrips,
    String? selectedTripType,
  }) {
    return DriverDashboardLoaded(
      dashboard: dashboard ?? this.dashboard,
      reports: reports ?? this.reports,
      morningTrips: morningTrips ?? this.morningTrips,
      afternoonTrips: afternoonTrips ?? this.afternoonTrips,
      selectedTripType: selectedTripType ?? this.selectedTripType,
    );
  }
}

class DriverTripsLoaded extends DriverState {
  final List<Trip> trips;
  final List<Trip> morningTrips;
  final List<Trip> afternoonTrips;

  const DriverTripsLoaded({
    required this.trips,
    required this.morningTrips,
    required this.afternoonTrips,
  });

  @override
  List<Object> get props => [trips, morningTrips, afternoonTrips];
}

class DriverProfileLoaded extends DriverState {
  final DriverProfile profile;

  const DriverProfileLoaded({required this.profile});

  @override
  List<Object> get props => [profile];
}

class DriverReportsLoaded extends DriverState {
  final DriverReports reports;

  const DriverReportsLoaded({required this.reports});

  @override
  List<Object> get props => [reports];
}

class DriverTripStudentsLoaded extends DriverState {
  final int tripId;
  final List<dynamic> students; // Using dynamic for now, can be typed later

  const DriverTripStudentsLoaded({
    required this.tripId,
    required this.students,
  });

  @override
  List<Object> get props => [tripId, students];
}

class DriverActionSuccess extends DriverState {
  final String message;
  final String actionType;

  const DriverActionSuccess({
    required this.message,
    required this.actionType,
  });

  @override
  List<Object> get props => [message, actionType];
}

class DriverLocationUpdated extends DriverState {
  final double latitude;
  final double longitude;
  final String? address;

  const DriverLocationUpdated({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  @override
  List<Object?> get props => [latitude, longitude, address];
}

class DriverError extends DriverState {
  final String message;
  final String? errorCode;
  final String? actionType;

  const DriverError({
    required this.message,
    this.errorCode,
    this.actionType,
  });

  @override
  List<Object?> get props => [message, errorCode, actionType];
}

class DriverRefreshing extends DriverState {
  final DriverDashboard? dashboard;
  final DriverReports? reports;
  final List<Trip>? morningTrips;
  final List<Trip>? afternoonTrips;

  const DriverRefreshing({
    this.dashboard,
    this.reports,
    this.morningTrips,
    this.afternoonTrips,
  });

  @override
  List<Object?> get props => [dashboard, reports, morningTrips, afternoonTrips];
}

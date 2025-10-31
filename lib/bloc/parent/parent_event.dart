import 'package:equatable/equatable.dart';


abstract class ParentEvent extends Equatable {
  const ParentEvent();

  @override
  List<Object?> get props => [];
}

class ParentDashboardRequested extends ParentEvent {
  final int parentId;

  const ParentDashboardRequested({required this.parentId});

  @override
  List<Object> get props => [parentId];
}

class ParentProfileRequested extends ParentEvent {
  final int parentId;

  const ParentProfileRequested({required this.parentId});

  @override
  List<Object> get props => [parentId];
}

class ParentUpdateRequested extends ParentEvent {
  final int parentId;
  final Map<String, dynamic> parentData;

  const ParentUpdateRequested({
    required this.parentId,
    required this.parentData,
  });

  @override
  List<Object> get props => [parentId, parentData];
}

class ParentStudentsRequested extends ParentEvent {
  final int parentId;

  const ParentStudentsRequested({required this.parentId});

  @override
  List<Object> get props => [parentId];
}

class ParentTripsRequested extends ParentEvent {
  final int parentId;

  const ParentTripsRequested({required this.parentId});

  @override
  List<Object> get props => [parentId];
}

class ParentNotificationsRequested extends ParentEvent {
  final int parentId;

  const ParentNotificationsRequested({required this.parentId});

  @override
  List<Object> get props => [parentId];
}

class ParentAttendanceHistoryRequested extends ParentEvent {
  final int parentId;
  final int? studentId;
  final String? startDate;
  final String? endDate;

  const ParentAttendanceHistoryRequested({
    required this.parentId,
    this.studentId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [parentId, studentId, startDate, endDate];
}

class ParentMonthlyReportRequested extends ParentEvent {
  final int parentId;
  final int? studentId;
  final String? month;
  final String? year;

  const ParentMonthlyReportRequested({
    required this.parentId,
    this.studentId,
    this.month,
    this.year,
  });

  @override
  List<Object?> get props => [parentId, studentId, month, year];
}

class ParentVehicleTrackingRequested extends ParentEvent {
  final int parentId;
  final int? studentId;

  const ParentVehicleTrackingRequested({
    required this.parentId,
    this.studentId,
  });

  @override
  List<Object?> get props => [parentId, studentId];
}

class ParentDriverLocationRequested extends ParentEvent {
  final int driverId;

  const ParentDriverLocationRequested({required this.driverId});

  @override
  List<Object> get props => [driverId];
}

class ParentRefreshRequested extends ParentEvent {
  final int parentId;

  const ParentRefreshRequested({required this.parentId});

  @override
  List<Object> get props => [parentId];
}

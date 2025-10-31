import 'package:equatable/equatable.dart';

abstract class GateStaffEvent extends Equatable {
  const GateStaffEvent();

  @override
  List<Object?> get props => [];
}

class GateStaffDashboardRequested extends GateStaffEvent {
  final int userId;

  const GateStaffDashboardRequested({required this.userId});

  @override
  List<Object> get props => [userId];
}

class GateStaffMarkEntryRequested extends GateStaffEvent {
  final int userId;
  final int studentId;
  final int tripId;
  final String remarks;

  const GateStaffMarkEntryRequested({
    required this.userId,
    required this.studentId,
    required this.tripId,
    required this.remarks,
  });

  @override
  List<Object> get props => [userId, studentId, tripId, remarks];
}

class GateStaffMarkExitRequested extends GateStaffEvent {
  final int userId;
  final int studentId;
  final int tripId;
  final String remarks;

  const GateStaffMarkExitRequested({
    required this.userId,
    required this.studentId,
    required this.tripId,
    required this.remarks,
  });

  @override
  List<Object> get props => [userId, studentId, tripId, remarks];
}

class GateStaffRefreshRequested extends GateStaffEvent {
  final int userId;

  const GateStaffRefreshRequested({required this.userId});

  @override
  List<Object> get props => [userId];
}


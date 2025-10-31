import 'package:equatable/equatable.dart';

abstract class GateStaffState extends Equatable {
  const GateStaffState();

  @override
  List<Object?> get props => [];
}

class GateStaffInitial extends GateStaffState {
  const GateStaffInitial();
}

class GateStaffLoading extends GateStaffState {
  const GateStaffLoading();
}

class GateStaffDashboardLoaded extends GateStaffState {
  final Map<String, dynamic> dashboard;

  const GateStaffDashboardLoaded({required this.dashboard});

  @override
  List<Object> get props => [dashboard];
}

class GateStaffActionSuccess extends GateStaffState {
  final String message;
  final String actionType;

  const GateStaffActionSuccess({
    required this.message,
    required this.actionType,
  });

  @override
  List<Object> get props => [message, actionType];
}

class GateStaffError extends GateStaffState {
  final String message;
  final String? errorCode;
  final String? actionType;

  const GateStaffError({
    required this.message,
    this.errorCode,
    this.actionType,
  });

  @override
  List<Object?> get props => [message, errorCode, actionType];
}

class GateStaffRefreshing extends GateStaffState {
  final Map<String, dynamic>? dashboard;

  const GateStaffRefreshing({this.dashboard});

  @override
  List<Object?> get props => [dashboard];
}


import 'package:equatable/equatable.dart';

abstract class AppAdminState extends Equatable {
  const AppAdminState();

  @override
  List<Object?> get props => [];
}

class AppAdminInitial extends AppAdminState {
  const AppAdminInitial();
}

class AppAdminLoading extends AppAdminState {
  const AppAdminLoading();
}

class AppAdminDashboardLoaded extends AppAdminState {
  final Map<String, dynamic> dashboard;
  final List<dynamic> schools;
  final Map<String, dynamic> systemStats;

  const AppAdminDashboardLoaded({
    required this.dashboard,
    required this.schools,
    required this.systemStats,
  });

  @override
  List<Object> get props => [dashboard, schools, systemStats];
}

class AppAdminProfileLoaded extends AppAdminState {
  final Map<String, dynamic> profile;

  const AppAdminProfileLoaded({required this.profile});

  @override
  List<Object> get props => [profile];
}

class AppAdminSchoolsLoaded extends AppAdminState {
  final List<dynamic> schools;

  const AppAdminSchoolsLoaded({required this.schools});

  @override
  List<Object> get props => [schools];
}

class AppAdminReportsLoaded extends AppAdminState {
  final Map<String, dynamic> reports;

  const AppAdminReportsLoaded({required this.reports});

  @override
  List<Object> get props => [reports];
}

class AppAdminSystemStatsLoaded extends AppAdminState {
  final Map<String, dynamic> systemStats;

  const AppAdminSystemStatsLoaded({required this.systemStats});

  @override
  List<Object> get props => [systemStats];
}

class AppAdminActionSuccess extends AppAdminState {
  final String message;
  final String actionType;

  const AppAdminActionSuccess({
    required this.message,
    required this.actionType,
  });

  @override
  List<Object> get props => [message, actionType];
}

class AppAdminError extends AppAdminState {
  final String message;
  final String? errorCode;
  final String? actionType;

  const AppAdminError({
    required this.message,
    this.errorCode,
    this.actionType,
  });

  @override
  List<Object?> get props => [message, errorCode, actionType];
}

class AppAdminRefreshing extends AppAdminState {
  final Map<String, dynamic>? dashboard;
  final List<dynamic>? schools;
  final Map<String, dynamic>? systemStats;

  const AppAdminRefreshing({
    this.dashboard,
    this.schools,
    this.systemStats,
  });

  @override
  List<Object?> get props => [dashboard, schools, systemStats];
}

import 'package:equatable/equatable.dart';

abstract class AppAdminEvent extends Equatable {
  const AppAdminEvent();

  @override
  List<Object?> get props => [];
}

class AppAdminDashboardRequested extends AppAdminEvent {
  const AppAdminDashboardRequested();
}

class AppAdminProfileRequested extends AppAdminEvent {
  const AppAdminProfileRequested();
}

class AppAdminUpdateRequested extends AppAdminEvent {
  final Map<String, dynamic> adminData;

  const AppAdminUpdateRequested({required this.adminData});

  @override
  List<Object> get props => [adminData];
}

class AppAdminSchoolsRequested extends AppAdminEvent {
  const AppAdminSchoolsRequested();
}

class AppAdminSchoolActivationRequested extends AppAdminEvent {
  final int schoolId;
  final bool isActive;

  const AppAdminSchoolActivationRequested({
    required this.schoolId,
    required this.isActive,
  });

  @override
  List<Object> get props => [schoolId, isActive];
}

class AppAdminSchoolDatesRequested extends AppAdminEvent {
  final int schoolId;
  final String startDate;
  final String endDate;

  const AppAdminSchoolDatesRequested({
    required this.schoolId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [schoolId, startDate, endDate];
}

class AppAdminResendActivationLinkRequested extends AppAdminEvent {
  final int schoolId;

  const AppAdminResendActivationLinkRequested({required this.schoolId});

  @override
  List<Object> get props => [schoolId];
}

class AppAdminReportsRequested extends AppAdminEvent {
  final String? startDate;
  final String? endDate;

  const AppAdminReportsRequested({
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

class AppAdminSystemStatsRequested extends AppAdminEvent {
  const AppAdminSystemStatsRequested();
}

class AppAdminRefreshRequested extends AppAdminEvent {
  const AppAdminRefreshRequested();
}

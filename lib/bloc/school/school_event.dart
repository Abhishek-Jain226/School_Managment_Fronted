import 'package:equatable/equatable.dart';

abstract class SchoolEvent extends Equatable {
  const SchoolEvent();

  @override
  List<Object?> get props => [];
}

class SchoolDashboardRequested extends SchoolEvent {
  final int schoolId;

  const SchoolDashboardRequested({required this.schoolId});

  @override
  List<Object> get props => [schoolId];
}

class SchoolProfileRequested extends SchoolEvent {
  final int schoolId;

  const SchoolProfileRequested({required this.schoolId});

  @override
  List<Object> get props => [schoolId];
}

class SchoolUpdateRequested extends SchoolEvent {
  final int schoolId;
  final Map<String, dynamic> schoolData;

  const SchoolUpdateRequested({
    required this.schoolId,
    required this.schoolData,
  });

  @override
  List<Object> get props => [schoolId, schoolData];
}

class SchoolStudentsRequested extends SchoolEvent {
  final int schoolId;

  const SchoolStudentsRequested({required this.schoolId});

  @override
  List<Object> get props => [schoolId];
}

class SchoolStaffRequested extends SchoolEvent {
  final int schoolId;

  const SchoolStaffRequested({required this.schoolId});

  @override
  List<Object> get props => [schoolId];
}

class SchoolVehiclesRequested extends SchoolEvent {
  final int schoolId;

  const SchoolVehiclesRequested({required this.schoolId});

  @override
  List<Object> get props => [schoolId];
}

class SchoolTripsRequested extends SchoolEvent {
  final int schoolId;

  const SchoolTripsRequested({required this.schoolId});

  @override
  List<Object> get props => [schoolId];
}

class SchoolReportsRequested extends SchoolEvent {
  final int schoolId;

  const SchoolReportsRequested({required this.schoolId});

  @override
  List<Object> get props => [schoolId];
}

class SchoolRefreshRequested extends SchoolEvent {
  final int schoolId;

  const SchoolRefreshRequested({required this.schoolId});

  @override
  List<Object> get props => [schoolId];
}

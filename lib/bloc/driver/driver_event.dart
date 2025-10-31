import 'package:equatable/equatable.dart';
import '../../data/models/student_attendance.dart';
import '../../data/models/notification_request.dart';

abstract class DriverEvent extends Equatable {
  const DriverEvent();

  @override
  List<Object?> get props => [];
}

class DriverDashboardRequested extends DriverEvent {
  final int driverId;

  const DriverDashboardRequested({required this.driverId});

  @override
  List<Object> get props => [driverId];
}

class DriverTripsRequested extends DriverEvent {
  final int driverId;

  const DriverTripsRequested({required this.driverId});

  @override
  List<Object> get props => [driverId];
}

class DriverProfileRequested extends DriverEvent {
  final int driverId;

  const DriverProfileRequested({required this.driverId});

  @override
  List<Object> get props => [driverId];
}

class DriverReportsRequested extends DriverEvent {
  final int driverId;

  const DriverReportsRequested({required this.driverId});

  @override
  List<Object> get props => [driverId];
}

class DriverTripStudentsRequested extends DriverEvent {
  final int driverId;
  final int tripId;

  const DriverTripStudentsRequested({
    required this.driverId,
    required this.tripId,
  });

  @override
  List<Object> get props => [driverId, tripId];
}

class DriverMarkAttendanceRequested extends DriverEvent {
  final int driverId;
  final StudentAttendanceRequest attendanceRequest;

  const DriverMarkAttendanceRequested({
    required this.driverId,
    required this.attendanceRequest,
  });

  @override
  List<Object> get props => [driverId, attendanceRequest];
}

class DriverSendNotificationRequested extends DriverEvent {
  final int driverId;
  final NotificationRequest notificationRequest;

  const DriverSendNotificationRequested({
    required this.driverId,
    required this.notificationRequest,
  });

  @override
  List<Object> get props => [driverId, notificationRequest];
}

class DriverUpdateLocationRequested extends DriverEvent {
  final int driverId;
  final double latitude;
  final double longitude;

  const DriverUpdateLocationRequested({
    required this.driverId,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object> get props => [driverId, latitude, longitude];
}

class DriverEndTripRequested extends DriverEvent {
  final int driverId;
  final int tripId;

  const DriverEndTripRequested({
    required this.driverId,
    required this.tripId,
  });

  @override
  List<Object> get props => [driverId, tripId];
}

class DriverSend5MinuteAlertRequested extends DriverEvent {
  final int driverId;
  final int tripId;

  const DriverSend5MinuteAlertRequested({
    required this.driverId,
    required this.tripId,
  });

  @override
  List<Object> get props => [driverId, tripId];
}

class DriverMarkPickupFromHomeRequested extends DriverEvent {
  final int driverId;
  final int tripId;
  final int studentId;

  const DriverMarkPickupFromHomeRequested({
    required this.driverId,
    required this.tripId,
    required this.studentId,
  });

  @override
  List<Object> get props => [driverId, tripId, studentId];
}

class DriverMarkDropToSchoolRequested extends DriverEvent {
  final int driverId;
  final int tripId;
  final int studentId;

  const DriverMarkDropToSchoolRequested({
    required this.driverId,
    required this.tripId,
    required this.studentId,
  });

  @override
  List<Object> get props => [driverId, tripId, studentId];
}

class DriverMarkPickupFromSchoolRequested extends DriverEvent {
  final int driverId;
  final int tripId;
  final int studentId;

  const DriverMarkPickupFromSchoolRequested({
    required this.driverId,
    required this.tripId,
    required this.studentId,
  });

  @override
  List<Object> get props => [driverId, tripId, studentId];
}

class DriverMarkDropToHomeRequested extends DriverEvent {
  final int driverId;
  final int tripId;
  final int studentId;

  const DriverMarkDropToHomeRequested({
    required this.driverId,
    required this.tripId,
    required this.studentId,
  });

  @override
  List<Object> get props => [driverId, tripId, studentId];
}

class DriverRefreshRequested extends DriverEvent {
  final int driverId;

  const DriverRefreshRequested({required this.driverId});

  @override
  List<Object> get props => [driverId];
}

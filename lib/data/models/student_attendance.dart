import '../../utils/constants.dart';

class StudentAttendanceRequest {
  final int tripId;
  final int studentId;
  final String eventType; // PICKUP_FROM_PARENT, DROP_TO_SCHOOL, PICKUP_FROM_SCHOOL, DROP_TO_PARENT
  final int driverId;
  final String? remarks;
  final String? location;
  final DateTime? eventTime;
  
  // For notifications
  final bool sendNotificationToParent;
  final String? notificationMessage;

  StudentAttendanceRequest({
    required this.tripId,
    required this.studentId,
    required this.eventType,
    required this.driverId,
    this.remarks,
    this.location,
    this.eventTime,
    required this.sendNotificationToParent,
    this.notificationMessage,
  });

  factory StudentAttendanceRequest.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceRequest(
      tripId: json[AppConstants.keyTripId],
      studentId: json[AppConstants.keyStudentId],
      eventType: json[AppConstants.keyEventType],
      driverId: json[AppConstants.keyDriverId],
      remarks: json[AppConstants.keyRemarks],
      location: json[AppConstants.keyLocation],
      eventTime: json[AppConstants.keyEventTime] != null 
          ? DateTime.parse(json[AppConstants.keyEventTime]) 
          : null,
      sendNotificationToParent: json[AppConstants.keySendNotificationToParent] ?? false,
      notificationMessage: json[AppConstants.keyNotificationMessage],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConstants.keyTripId: tripId,
      AppConstants.keyStudentId: studentId,
      AppConstants.keyEventType: eventType,
      AppConstants.keyDriverId: driverId,
      AppConstants.keyRemarks: remarks,
      AppConstants.keyLocation: location,
      AppConstants.keyEventTime: eventTime?.toIso8601String(),
      AppConstants.keySendNotificationToParent: sendNotificationToParent,
      AppConstants.keyNotificationMessage: notificationMessage,
    };
  }

  StudentAttendanceRequest copyWith({
    int? tripId,
    int? studentId,
    String? eventType,
    int? driverId,
    String? remarks,
    String? location,
    DateTime? eventTime,
    bool? sendNotificationToParent,
    String? notificationMessage,
  }) {
    return StudentAttendanceRequest(
      tripId: tripId ?? this.tripId,
      studentId: studentId ?? this.studentId,
      eventType: eventType ?? this.eventType,
      driverId: driverId ?? this.driverId,
      remarks: remarks ?? this.remarks,
      location: location ?? this.location,
      eventTime: eventTime ?? this.eventTime,
      sendNotificationToParent: sendNotificationToParent ?? this.sendNotificationToParent,
      notificationMessage: notificationMessage ?? this.notificationMessage,
    );
  }
}

class StudentAttendanceResponse {
  final bool success;
  final String message;
  final String? data;

  StudentAttendanceResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory StudentAttendanceResponse.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceResponse(
      success: json[AppConstants.keySuccess],
      message: json[AppConstants.keyMessage],
      data: json[AppConstants.keyData],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConstants.keySuccess: success,
      AppConstants.keyMessage: message,
      AppConstants.keyData: data,
    };
  }
}

enum EventType {
  pickupFromParent('PICKUP_FROM_PARENT'),
  dropToSchool('DROP_TO_SCHOOL'),
  pickupFromSchool('PICKUP_FROM_SCHOOL'),
  dropToParent('DROP_TO_PARENT'),
  gateEntry('GATE_ENTRY'),
  gateExit('GATE_EXIT');

  const EventType(this.value);
  final String value;

  static EventType fromString(String value) {
    return EventType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Invalid EventType: $value'),
    );
  }

  String get displayName {
    switch (this) {
      case EventType.pickupFromParent:
        return 'Pickup from Parent';
      case EventType.dropToSchool:
        return 'Drop to School';
      case EventType.pickupFromSchool:
        return 'Pickup from School';
      case EventType.dropToParent:
        return 'Drop to Parent';
      case EventType.gateEntry:
        return 'Gate Entry';
      case EventType.gateExit:
        return 'Gate Exit';
    }
  }
}

enum AttendanceStatus {
  pending('PENDING'),
  pickedUp('PICKED_UP'),
  dropped('DROPPED'),
  absent('ABSENT');

  const AttendanceStatus(this.value);
  final String value;

  static AttendanceStatus fromString(String value) {
    return AttendanceStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Invalid AttendanceStatus: $value'),
    );
  }

  String get displayName {
    switch (this) {
      case AttendanceStatus.pending:
        return 'Pending';
      case AttendanceStatus.pickedUp:
        return 'Picked Up';
      case AttendanceStatus.dropped:
        return 'Dropped';
      case AttendanceStatus.absent:
        return 'Absent';
    }
  }

  String get color {
    switch (this) {
      case AttendanceStatus.pending:
        return 'orange';
      case AttendanceStatus.pickedUp:
        return 'blue';
      case AttendanceStatus.dropped:
        return 'green';
      case AttendanceStatus.absent:
        return 'red';
    }
  }
}

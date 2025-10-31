import '../../utils/constants.dart';

class WebSocketNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final String priority;
  final String? targetUser;
  final String? targetRole;
  final int? schoolId;
  final int? tripId;
  final int? vehicleId;
  final int? studentId;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? action;
  final String? entityType;

  WebSocketNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.priority,
    this.targetUser,
    this.targetRole,
    this.schoolId,
    this.tripId,
    this.vehicleId,
    this.studentId,
    required this.timestamp,
    this.isRead = false,
    this.data,
    this.action,
    this.entityType,
  });

  factory WebSocketNotification.fromJson(Map<String, dynamic> json) {
    return WebSocketNotification(
      id: json[AppConstants.keyId] ?? '',
      type: json[AppConstants.keyType] ?? '',
      title: json[AppConstants.keyTitle] ?? '',
      message: json[AppConstants.keyMessage] ?? '',
      priority: json[AppConstants.keyPriority] ?? 'MEDIUM',
      targetUser: json[AppConstants.keyTargetUser],
      targetRole: json[AppConstants.keyTargetRole],
      schoolId: json[AppConstants.keySchoolId],
      tripId: json[AppConstants.keyTripId],
      vehicleId: json[AppConstants.keyVehicleId],
      studentId: json[AppConstants.keyStudentId],
      timestamp: json[AppConstants.keyTimestamp] != null 
          ? DateTime.parse(json[AppConstants.keyTimestamp]) 
          : DateTime.now(),
      isRead: json[AppConstants.keyIsRead] ?? false,
      data: json[AppConstants.keyData],
      action: json[AppConstants.keyAction],
      entityType: json[AppConstants.keyEntityType],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConstants.keyId: id,
      AppConstants.keyType: type,
      AppConstants.keyTitle: title,
      AppConstants.keyMessage: message,
      AppConstants.keyPriority: priority,
      AppConstants.keyTargetUser: targetUser,
      AppConstants.keyTargetRole: targetRole,
      AppConstants.keySchoolId: schoolId,
      AppConstants.keyTripId: tripId,
      AppConstants.keyVehicleId: vehicleId,
      AppConstants.keyStudentId: studentId,
      AppConstants.keyTimestamp: timestamp.toIso8601String(),
      AppConstants.keyIsRead: isRead,
      AppConstants.keyData: data,
      AppConstants.keyAction: action,
      AppConstants.keyEntityType: entityType,
    };
  }

  WebSocketNotification copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    String? priority,
    String? targetUser,
    String? targetRole,
    int? schoolId,
    int? tripId,
    int? vehicleId,
    int? studentId,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
    String? action,
    String? entityType,
  }) {
    return WebSocketNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      priority: priority ?? this.priority,
      targetUser: targetUser ?? this.targetUser,
      targetRole: targetRole ?? this.targetRole,
      schoolId: schoolId ?? this.schoolId,
      tripId: tripId ?? this.tripId,
      vehicleId: vehicleId ?? this.vehicleId,
      studentId: studentId ?? this.studentId,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
    );
  }
}

// Notification Types
class NotificationType {
  static const String tripUpdate = 'TRIP_UPDATE';
  static const String arrivalNotification = 'ARRIVAL_NOTIFICATION';
  static const String pickupConfirmation = 'PICKUP_CONFIRMATION';
  static const String dropConfirmation = 'DROP_CONFIRMATION';
  static const String delayNotification = 'DELAY_NOTIFICATION';
  static const String systemAlert = 'SYSTEM_ALERT';
  static const String attendanceUpdate = 'ATTENDANCE_UPDATE';
  static const String vehicleStatusUpdate = 'VEHICLE_STATUS_UPDATE';
  static const String notificationSent = 'NOTIFICATION_SENT';
  static const String vehicleAssignmentRequest = 'VEHICLE_ASSIGNMENT_REQUEST';
  static const String vehicleAssignmentApproved = 'VEHICLE_ASSIGNMENT_APPROVED';
  static const String vehicleAssignmentRejected = 'VEHICLE_ASSIGNMENT_REJECTED';
  static const String connectionEstablished = 'CONNECTION_ESTABLISHED';
  static const String locationUpdate = 'LOCATION_UPDATE';
}

// Notification Priority
class NotificationPriority {
  static const String high = 'HIGH';
  static const String medium = 'MEDIUM';
  static const String low = 'LOW';
}

// User Roles
class UserRole {
  static const String schoolAdmin = 'SCHOOL_ADMIN';
  static const String vehicleOwner = 'VEHICLE_OWNER';
  static const String parent = 'PARENT';
  static const String driver = 'DRIVER';
  static const String gateStaff = 'GATE_STAFF';
}

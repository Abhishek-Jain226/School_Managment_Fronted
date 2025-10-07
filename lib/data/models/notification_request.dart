class NotificationRequest {
  final int driverId;
  final int tripId;
  final String notificationType; // ARRIVAL_NOTIFICATION, PICKUP_CONFIRMATION, DROP_CONFIRMATION, DELAY_NOTIFICATION
  final String message;
  final String? title;
  
  // Target students for notification
  final List<int>? studentIds;
  
  // Notification settings
  final bool sendSms;
  final bool sendEmail;
  final bool sendPushNotification;
  
  // Timing
  final int? minutesBeforeArrival; // For arrival notifications

  NotificationRequest({
    required this.driverId,
    required this.tripId,
    required this.notificationType,
    required this.message,
    this.title,
    this.studentIds,
    required this.sendSms,
    required this.sendEmail,
    required this.sendPushNotification,
    this.minutesBeforeArrival,
  });

  factory NotificationRequest.fromJson(Map<String, dynamic> json) {
    return NotificationRequest(
      driverId: json['driverId'],
      tripId: json['tripId'],
      notificationType: json['notificationType'],
      message: json['message'],
      title: json['title'],
      studentIds: json['studentIds'] != null 
          ? List<int>.from(json['studentIds']) 
          : null,
      sendSms: json['sendSms'] ?? false,
      sendEmail: json['sendEmail'] ?? false,
      sendPushNotification: json['sendPushNotification'] ?? false,
      minutesBeforeArrival: json['minutesBeforeArrival'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'tripId': tripId,
      'notificationType': notificationType,
      'message': message,
      'title': title,
      'studentIds': studentIds,
      'sendSms': sendSms,
      'sendEmail': sendEmail,
      'sendPushNotification': sendPushNotification,
      'minutesBeforeArrival': minutesBeforeArrival,
    };
  }

  NotificationRequest copyWith({
    int? driverId,
    int? tripId,
    String? notificationType,
    String? message,
    String? title,
    List<int>? studentIds,
    bool? sendSms,
    bool? sendEmail,
    bool? sendPushNotification,
    int? minutesBeforeArrival,
  }) {
    return NotificationRequest(
      driverId: driverId ?? this.driverId,
      tripId: tripId ?? this.tripId,
      notificationType: notificationType ?? this.notificationType,
      message: message ?? this.message,
      title: title ?? this.title,
      studentIds: studentIds ?? this.studentIds,
      sendSms: sendSms ?? this.sendSms,
      sendEmail: sendEmail ?? this.sendEmail,
      sendPushNotification: sendPushNotification ?? this.sendPushNotification,
      minutesBeforeArrival: minutesBeforeArrival ?? this.minutesBeforeArrival,
    );
  }
}

class NotificationResponse {
  final bool success;
  final String message;
  final String? data;

  NotificationResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
    };
  }
}

enum NotificationType {
  arrivalNotification('ARRIVAL_NOTIFICATION'),
  pickupConfirmation('PICKUP_CONFIRMATION'),
  dropConfirmation('DROP_CONFIRMATION'),
  delayNotification('DELAY_NOTIFICATION');

  const NotificationType(this.value);
  final String value;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Invalid NotificationType: $value'),
    );
  }

  String get displayName {
    switch (this) {
      case NotificationType.arrivalNotification:
        return 'Arrival Notification';
      case NotificationType.pickupConfirmation:
        return 'Pickup Confirmation';
      case NotificationType.dropConfirmation:
        return 'Drop Confirmation';
      case NotificationType.delayNotification:
        return 'Delay Notification';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.arrivalNotification:
        return '🚌';
      case NotificationType.pickupConfirmation:
        return '✅';
      case NotificationType.dropConfirmation:
        return '🏫';
      case NotificationType.delayNotification:
        return '⏰';
    }
  }
}

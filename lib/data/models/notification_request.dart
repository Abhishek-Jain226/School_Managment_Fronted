import '../../utils/constants.dart';

class NotificationRequest {
  final int driverId;
  final int tripId;
  final int? dispatchLogId; // Required by backend but can be null for new notifications
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
    this.dispatchLogId,
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
      driverId: json[AppConstants.keyDriverId],
      tripId: json[AppConstants.keyTripId],
      dispatchLogId: json[AppConstants.keyDispatchLogId],
      notificationType: json[AppConstants.keyNotificationType],
      message: json[AppConstants.keyMessage],
      title: json[AppConstants.keyTitle],
      studentIds: json[AppConstants.keyStudentIds] != null 
          ? List<int>.from(json[AppConstants.keyStudentIds]) 
          : null,
      sendSms: json[AppConstants.keySendSms] ?? false,
      sendEmail: json[AppConstants.keySendEmail] ?? false,
      sendPushNotification: json[AppConstants.keySendPushNotification] ?? false,
      minutesBeforeArrival: json[AppConstants.keyMinutesBeforeArrival],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConstants.keyDriverId: driverId,
      AppConstants.keyTripId: tripId,
      AppConstants.keyDispatchLogId: dispatchLogId,
      AppConstants.keyNotificationType: notificationType,
      AppConstants.keyMessage: message,
      AppConstants.keyTitle: title,
      AppConstants.keyStudentIds: studentIds,
      AppConstants.keySendSms: sendSms,
      AppConstants.keySendEmail: sendEmail,
      AppConstants.keySendPushNotification: sendPushNotification,
      AppConstants.keyMinutesBeforeArrival: minutesBeforeArrival,
    };
  }

  NotificationRequest copyWith({
    int? driverId,
    int? tripId,
    int? dispatchLogId,
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
      dispatchLogId: dispatchLogId ?? this.dispatchLogId,
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

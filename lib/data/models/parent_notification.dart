import '../../utils/constants.dart';

class ParentNotification {
  final int notificationId;
  final String title;
  final String message;
  final String notificationType;
  final String eventType;
  final String studentName;
  final String vehicleNumber;
  final String tripName;
  final DateTime notificationTime;
  final bool isRead;
  final String priority;

  ParentNotification({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.eventType,
    required this.studentName,
    required this.vehicleNumber,
    required this.tripName,
    required this.notificationTime,
    required this.isRead,
    required this.priority,
  });

  factory ParentNotification.fromJson(Map<String, dynamic> json) {
    return ParentNotification(
      notificationId: json[AppConstants.keyNotificationId] ?? 0,
      title: json[AppConstants.keyTitle] ?? '',
      message: json[AppConstants.keyMessage] ?? '',
      notificationType: json[AppConstants.keyNotificationType] ?? '',
      eventType: json[AppConstants.keyEventType] ?? '',
      studentName: json[AppConstants.keyStudentName] ?? '',
      vehicleNumber: json[AppConstants.keyVehicleNumber] ?? 'N/A',
      tripName: json[AppConstants.keyTripName] ?? 'N/A',
      notificationTime: DateTime.parse(json[AppConstants.keyNotificationTime] ?? DateTime.now().toIso8601String()),
      isRead: json[AppConstants.keyIsRead] ?? false,
      priority: json[AppConstants.keyPriority] ?? 'Normal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConstants.keyNotificationId: notificationId,
      AppConstants.keyTitle: title,
      AppConstants.keyMessage: message,
      AppConstants.keyNotificationType: notificationType,
      AppConstants.keyEventType: eventType,
      AppConstants.keyStudentName: studentName,
      AppConstants.keyVehicleNumber: vehicleNumber,
      AppConstants.keyTripName: tripName,
      AppConstants.keyNotificationTime: notificationTime.toIso8601String(),
      AppConstants.keyIsRead: isRead,
      AppConstants.keyPriority: priority,
    };
  }
}

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
      notificationId: json['notificationId'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      notificationType: json['notificationType'] ?? '',
      eventType: json['eventType'] ?? '',
      studentName: json['studentName'] ?? '',
      vehicleNumber: json['vehicleNumber'] ?? 'N/A',
      tripName: json['tripName'] ?? 'N/A',
      notificationTime: DateTime.parse(json['notificationTime'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
      priority: json['priority'] ?? 'Normal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'title': title,
      'message': message,
      'notificationType': notificationType,
      'eventType': eventType,
      'studentName': studentName,
      'vehicleNumber': vehicleNumber,
      'tripName': tripName,
      'notificationTime': notificationTime.toIso8601String(),
      'isRead': isRead,
      'priority': priority,
    };
  }
}

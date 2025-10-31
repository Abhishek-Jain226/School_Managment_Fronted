import 'package:equatable/equatable.dart';
import '../../data/models/websocket_notification.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationConnecting extends NotificationState {
  const NotificationConnecting();
}

class NotificationConnected extends NotificationState {
  final List<WebSocketNotification> notifications;
  final List<String> subscribedChannels;
  final bool isConnected;

  const NotificationConnected({
    required this.notifications,
    required this.subscribedChannels,
    this.isConnected = true,
  });

  @override
  List<Object> get props => [notifications, subscribedChannels, isConnected];

  NotificationConnected copyWith({
    List<WebSocketNotification>? notifications,
    List<String>? subscribedChannels,
    bool? isConnected,
  }) {
    return NotificationConnected(
      notifications: notifications ?? this.notifications,
      subscribedChannels: subscribedChannels ?? this.subscribedChannels,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

class NotificationDisconnected extends NotificationState {
  final List<WebSocketNotification> notifications;
  final String? errorMessage;

  const NotificationDisconnected({
    required this.notifications,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [notifications, errorMessage];
}

class NotificationArrived extends NotificationState {
  final List<WebSocketNotification> notifications;
  final WebSocketNotification newNotification;

  const NotificationArrived({
    required this.notifications,
    required this.newNotification,
  });

  @override
  List<Object> get props => [notifications, newNotification];
}

class NotificationMarkedAsRead extends NotificationState {
  final List<WebSocketNotification> notifications;
  final String notificationId;

  const NotificationMarkedAsRead({
    required this.notifications,
    required this.notificationId,
  });

  @override
  List<Object> get props => [notifications, notificationId];
}

class NotificationAllMarkedAsRead extends NotificationState {
  final List<WebSocketNotification> notifications;

  const NotificationAllMarkedAsRead({required this.notifications});

  @override
  List<Object> get props => [notifications];
}

class NotificationCleared extends NotificationState {
  const NotificationCleared();
}

class NotificationError extends NotificationState {
  final String message;
  final String? errorCode;
  final List<WebSocketNotification>? notifications;

  const NotificationError({
    required this.message,
    this.errorCode,
    this.notifications,
  });

  @override
  List<Object?> get props => [message, errorCode, notifications];
}

// Note: Connection status updates are represented by updating
// existing NotificationConnected/NotificationDisconnected states.

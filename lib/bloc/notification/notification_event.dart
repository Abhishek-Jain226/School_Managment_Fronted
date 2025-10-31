import 'package:equatable/equatable.dart';
import '../../data/models/websocket_notification.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class NotificationConnectRequested extends NotificationEvent {
  final String userId;
  final List<String> roles;
  final int? schoolId;

  const NotificationConnectRequested({
    required this.userId,
    required this.roles,
    this.schoolId,
  });

  @override
  List<Object?> get props => [userId, roles, schoolId];
}

class NotificationDisconnectRequested extends NotificationEvent {
  const NotificationDisconnectRequested();
}

class NotificationReceived extends NotificationEvent {
  final WebSocketNotification notification;

  const NotificationReceived({required this.notification});

  @override
  List<Object> get props => [notification];
}

class NotificationMarkAsReadRequested extends NotificationEvent {
  final String notificationId;

  const NotificationMarkAsReadRequested({required this.notificationId});

  @override
  List<Object> get props => [notificationId];
}

class NotificationMarkAllAsReadRequested extends NotificationEvent {
  const NotificationMarkAllAsReadRequested();
}

class NotificationClearAllRequested extends NotificationEvent {
  const NotificationClearAllRequested();
}

class NotificationRefreshRequested extends NotificationEvent {
  const NotificationRefreshRequested();
}

class NotificationSubscribeToChannelRequested extends NotificationEvent {
  final String channel;
  final String? userId;
  final String? role;
  final int? schoolId;

  const NotificationSubscribeToChannelRequested({
    required this.channel,
    this.userId,
    this.role,
    this.schoolId,
  });

  @override
  List<Object?> get props => [channel, userId, role, schoolId];
}

class NotificationUnsubscribeFromChannelRequested extends NotificationEvent {
  final String channel;

  const NotificationUnsubscribeFromChannelRequested({required this.channel});

  @override
  List<Object> get props => [channel];
}

class NotificationSendMessageRequested extends NotificationEvent {
  final String message;
  final String? targetUserId;
  final String? targetRole;
  final int? targetSchoolId;

  const NotificationSendMessageRequested({
    required this.message,
    this.targetUserId,
    this.targetRole,
    this.targetSchoolId,
  });

  @override
  List<Object?> get props => [message, targetUserId, targetRole, targetSchoolId];
}

class NotificationConnectionStatusChanged extends NotificationEvent {
  final bool isConnected;
  final String? errorMessage;

  const NotificationConnectionStatusChanged({
    required this.isConnected,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [isConnected, errorMessage];
}

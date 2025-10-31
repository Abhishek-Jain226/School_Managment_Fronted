import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/constants.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final WebSocketNotificationService _webSocketService;
  StreamSubscription<WebSocketNotification>? _notificationSubscription;

  NotificationBloc({required WebSocketNotificationService webSocketService})
      : _webSocketService = webSocketService,
        super(const NotificationInitial()) {
    on<NotificationConnectRequested>(_onConnectRequested);
    on<NotificationDisconnectRequested>(_onDisconnectRequested);
    on<NotificationReceived>(_onNotificationReceived);
    on<NotificationMarkAsReadRequested>(_onMarkAsReadRequested);
    on<NotificationMarkAllAsReadRequested>(_onMarkAllAsReadRequested);
    on<NotificationClearAllRequested>(_onClearAllRequested);
    on<NotificationRefreshRequested>(_onRefreshRequested);
    on<NotificationSubscribeToChannelRequested>(_onSubscribeToChannelRequested);
    on<NotificationUnsubscribeFromChannelRequested>(_onUnsubscribeFromChannelRequested);
    on<NotificationSendMessageRequested>(_onSendMessageRequested);
    on<NotificationConnectionStatusChanged>(_onConnectionStatusChanged);
  }

  Future<void> _onConnectRequested(
    NotificationConnectRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(const NotificationConnecting());
    
    try {
      // Initialize WebSocket (connect inside)
      await _webSocketService.initialize();
      
      // Subscribe to user-specific notifications
      await _webSocketService.subscribeToUserNotifications(event.userId);
      
      // Subscribe to role-based notifications
      for (final role in event.roles) {
        await _webSocketService.subscribeToRoleNotifications(role);
      }
      
      // Subscribe to school notifications if schoolId is provided
      if (event.schoolId != null) {
        await _webSocketService.subscribeToSchoolNotifications(event.schoolId!);
      }
      
      // Listen to incoming notifications
      _notificationSubscription = _webSocketService.notificationStream.listen(
        (notification) {
          add(NotificationReceived(notification: notification));
        },
        onError: (error) {
          add(NotificationConnectionStatusChanged(
            isConnected: false,
            errorMessage: error.toString(),
          ));
        },
      );
      
      emit(NotificationConnected(
        notifications: const [],
        subscribedChannels: _getSubscribedChannels(event),
      ));
      
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToConnectNotifications}: ${e.toString()}');
      emit(NotificationError(
        message: '${AppConstants.errorFailedToConnectNotifications}: ${e.toString()}',
        errorCode: AppConstants.errorCodeConnectionError,
      ));
    }
  }

  Future<void> _onDisconnectRequested(
    NotificationDisconnectRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _webSocketService.disconnect();
      _notificationSubscription?.cancel();
      
      if (state is NotificationConnected) {
        final currentState = state as NotificationConnected;
        emit(NotificationDisconnected(
          notifications: currentState.notifications,
        ));
      } else {
        emit(const NotificationDisconnected(notifications: []));
      }
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToDisconnect}: ${e.toString()}');
      emit(NotificationError(
        message: '${AppConstants.errorFailedToDisconnect}: ${e.toString()}',
        errorCode: AppConstants.errorCodeDisconnectError,
      ));
    }
  }

  Future<void> _onNotificationReceived(
    NotificationReceived event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationConnected) {
      final currentState = state as NotificationConnected;
      final updatedNotifications = List<WebSocketNotification>.from(currentState.notifications);
      
      // Add new notification to the beginning of the list
      updatedNotifications.insert(0, event.notification);
      
      // Keep only the latest 100 notifications to prevent memory issues
      if (updatedNotifications.length > 100) {
        updatedNotifications.removeRange(100, updatedNotifications.length);
      }
      
      emit(NotificationArrived(
        notifications: updatedNotifications,
        newNotification: event.notification,
      ));
    }
  }

  Future<void> _onMarkAsReadRequested(
    NotificationMarkAsReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationConnected) {
      final currentState = state as NotificationConnected;
      final updatedNotifications = currentState.notifications.map((notification) {
        if (notification.id == event.notificationId) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();
      
      emit(NotificationMarkedAsRead(
        notifications: updatedNotifications,
        notificationId: event.notificationId,
      ));
    }
  }

  Future<void> _onMarkAllAsReadRequested(
    NotificationMarkAllAsReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationConnected) {
      final currentState = state as NotificationConnected;
      final updatedNotifications = currentState.notifications.map((notification) {
        return notification.copyWith(isRead: true);
      }).toList();
      
      emit(NotificationAllMarkedAsRead(notifications: updatedNotifications));
    }
  }

  Future<void> _onClearAllRequested(
    NotificationClearAllRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(const NotificationCleared());
  }

  Future<void> _onRefreshRequested(
    NotificationRefreshRequested event,
    Emitter<NotificationState> emit,
  ) async {
    // Refresh logic can be implemented here
    // For now, just maintain current state
    if (state is NotificationConnected) {
      final currentState = state as NotificationConnected;
      emit(currentState);
    }
  }

  Future<void> _onSubscribeToChannelRequested(
    NotificationSubscribeToChannelRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      switch (event.channel) {
        case 'user':
          if (event.userId != null) {
            await _webSocketService.subscribeToUserNotifications(event.userId!);
          }
          break;
        case 'role':
          if (event.role != null) {
            await _webSocketService.subscribeToRoleNotifications(event.role!);
          }
          break;
        case 'school':
          if (event.schoolId != null) {
            await _webSocketService.subscribeToSchoolNotifications(event.schoolId!);
          }
          break;
      }
      
      if (state is NotificationConnected) {
        final currentState = state as NotificationConnected;
        final updatedChannels = List<String>.from(currentState.subscribedChannels);
        if (!updatedChannels.contains(event.channel)) {
          updatedChannels.add(event.channel);
        }
        
        emit(currentState.copyWith(subscribedChannels: updatedChannels));
      }
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToSubscribeChannel}: ${e.toString()}');
      emit(NotificationError(
        message: '${AppConstants.errorFailedToSubscribeChannel}: ${e.toString()}',
        errorCode: AppConstants.errorCodeSubscribeError,
      ));
    }
  }

  Future<void> _onUnsubscribeFromChannelRequested(
    NotificationUnsubscribeFromChannelRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      // Unsubscribe logic can be implemented here
      // For now, just remove from subscribed channels
      if (state is NotificationConnected) {
        final currentState = state as NotificationConnected;
        final updatedChannels = List<String>.from(currentState.subscribedChannels);
        updatedChannels.remove(event.channel);
        
        emit(currentState.copyWith(subscribedChannels: updatedChannels));
      }
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToUnsubscribeChannel}: ${e.toString()}');
      emit(NotificationError(
        message: '${AppConstants.errorFailedToUnsubscribeChannel}: ${e.toString()}',
        errorCode: AppConstants.errorCodeUnsubscribeError,
      ));
    }
  }

  Future<void> _onSendMessageRequested(
    NotificationSendMessageRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final payload = <String, dynamic>{
        AppConstants.keyType: AppConstants.notificationTypeSystemAlert,
        AppConstants.keyMessage: event.message,
        if (event.targetUserId != null) AppConstants.keyTargetUserId: event.targetUserId,
        if (event.targetRole != null) AppConstants.keyTargetRole: event.targetRole,
        if (event.targetSchoolId != null) AppConstants.keyTargetSchoolId: event.targetSchoolId,
      };
      await _webSocketService.sendNotification(payload);
      // Message sent successfully, no state change needed
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToSendMessage}: ${e.toString()}');
      emit(NotificationError(
        message: '${AppConstants.errorFailedToSendMessage}: ${e.toString()}',
        errorCode: AppConstants.errorCodeSendMessageError,
      ));
    }
  }

  Future<void> _onConnectionStatusChanged(
    NotificationConnectionStatusChanged event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationConnected) {
      final currentState = state as NotificationConnected;
      emit(currentState.copyWith(isConnected: event.isConnected));
    } else {
      emit(NotificationDisconnected(
        notifications: const [],
        errorMessage: event.errorMessage,
      ));
    }
  }

  List<String> _getSubscribedChannels(NotificationConnectRequested event) {
    final channels = <String>[];
    channels.add('user_${event.userId}');
    channels.addAll(event.roles.map((role) => 'role_$role'));
    if (event.schoolId != null) {
      channels.add('school_${event.schoolId}');
    }
    return channels;
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    _webSocketService.disconnect();
    return super.close();
  }
}

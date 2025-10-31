import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/websocket_notification.dart';
import '../config/app_config.dart';
import '../utils/constants.dart';

class WebSocketNotificationService {
  static final WebSocketNotificationService _instance = WebSocketNotificationService._internal();
  factory WebSocketNotificationService() => _instance;
  WebSocketNotificationService._internal();

  StompClient? _stompClient;
  bool _isConnected = false;
  String? _currentUserRole;
  int? _currentSchoolId;
  int? _currentUserId;

  // Stream controllers for different notification types
  final StreamController<WebSocketNotification> _notificationController = 
      StreamController<WebSocketNotification>.broadcast();
  final StreamController<WebSocketNotification> _tripUpdateController = 
      StreamController<WebSocketNotification>.broadcast();
  final StreamController<WebSocketNotification> _arrivalController = 
      StreamController<WebSocketNotification>.broadcast();
  final StreamController<WebSocketNotification> _pickupController = 
      StreamController<WebSocketNotification>.broadcast();
  final StreamController<WebSocketNotification> _dropController = 
      StreamController<WebSocketNotification>.broadcast();
  final StreamController<WebSocketNotification> _systemAlertController = 
      StreamController<WebSocketNotification>.broadcast();

  // Getters for streams
  Stream<WebSocketNotification> get notificationStream => _notificationController.stream;
  Stream<WebSocketNotification> get tripUpdateStream => _tripUpdateController.stream;
  Stream<WebSocketNotification> get arrivalStream => _arrivalController.stream;
  Stream<WebSocketNotification> get pickupStream => _pickupController.stream;
  Stream<WebSocketNotification> get dropStream => _dropController.stream;
  Stream<WebSocketNotification> get systemAlertStream => _systemAlertController.stream;

  bool get isConnected => _isConnected;

  // Initialize WebSocket connection
  Future<void> initialize() async {
    try {
      await _loadUserData();
      await _connect();
    } catch (e) {
      debugPrint('${AppConstants.errorWebSocketInitialization}: $e');
    }
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserRole = prefs.getString(AppConstants.keyRole);
    _currentSchoolId = prefs.getInt(AppConstants.keySchoolId);
    _currentUserId = prefs.getInt(AppConstants.keyUserId);
    
    debugPrint('${AppConstants.logWebSocketUserData}$_currentUserRole, SchoolId=$_currentSchoolId, UserId=$_currentUserId');
  }

  // Connect to WebSocket using STOMP
  Future<void> _connect() async {
    if (_isConnected) return;

    try {
      // WebSocket URL for STOMP with SockJS
      String wsUrl;
      debugPrint('${AppConstants.logWebSocketBaseUrl}${AppConfig.baseUrl}');
      
      if (AppConfig.baseUrl.contains(AppConstants.wsProtocolHttp)) {
        wsUrl = AppConfig.baseUrl.replaceFirst(AppConstants.wsProtocolHttp, AppConstants.wsProtocolWs) + AppConstants.wsPath;
      } else if (AppConfig.baseUrl.contains(AppConstants.wsProtocolHttps)) {
        wsUrl = AppConfig.baseUrl.replaceFirst(AppConstants.wsProtocolHttps, AppConstants.wsProtocolWss) + AppConstants.wsPath;
      } else {
        wsUrl = AppConstants.wsProtocolWs + AppConfig.baseUrl + AppConstants.wsPath;
      }
      
      debugPrint('${AppConstants.logWebSocketConstructedUrl}$wsUrl');
      debugPrint('${AppConstants.logWebSocketConnecting}$wsUrl');

      // Create STOMP configuration
      final config = StompConfig(
        url: wsUrl,
        onConnect: _onStompConnect,
        onWebSocketError: _onWebSocketError,
        onStompError: _onStompError,
        onDisconnect: _onDisconnect,
        onDebugMessage: (String message) => debugPrint('${AppConstants.logWebSocketDebug}$message'),
      );

      // Create and activate STOMP client
      _stompClient = StompClient(config: config);
      _stompClient!.activate();
      
    } catch (e) {
      debugPrint('${AppConstants.errorWebSocketConnection}: $e');
    }
  }

  // STOMP connection handler
  void _onStompConnect(StompFrame frame) {
    debugPrint(AppConstants.logWebSocketConnected);
    _isConnected = true;
    _subscribeToChannels();
  }

  // STOMP error handler
  void _onStompError(StompFrame frame) {
    debugPrint('${AppConstants.logWebSocketStompError}${frame.body}');
    _isConnected = false;
  }

  // Handle incoming STOMP messages
  void _onStompMessage(StompFrame frame) {
    try {
      debugPrint('${AppConstants.logWebSocketMessageReceived}${frame.body}');

      if (frame.body != null) {
        final Map<String, dynamic> jsonData = jsonDecode(frame.body!);
        debugPrint('${AppConstants.logWebSocketParsedMessage}$jsonData');
        
        final notification = WebSocketNotification.fromJson(jsonData);
        _notificationController.add(notification);
        _routeNotificationToSpecificStreams(notification);
        debugPrint(AppConstants.logWebSocketNotificationProcessed);
      }
    } catch (e) {
      debugPrint('❌ ${AppConstants.errorWebSocketMessage}: $e');
    }
  }

  // Handle disconnection
  void _onDisconnect(StompFrame frame) {
    debugPrint(AppConstants.logWebSocketDisconnected);
    _isConnected = false;
  }

  // Handle WebSocket errors
  void _onWebSocketError(dynamic error) {
    debugPrint('${AppConstants.logWebSocketError}$error');
    _isConnected = false;
  }

  // Subscribe to STOMP notification channels
  void _subscribeToChannels() {
    if (!_isConnected || _stompClient == null) return;

    try {
      // Subscribe to school-specific notifications
      if (_currentSchoolId != null) {
        _stompClient!.subscribe(
          destination: '${AppConstants.wsTopicSchool}/$_currentSchoolId',
          callback: _onStompMessage,
        );
        debugPrint('${AppConstants.logWebSocketSubscribedSchool}${AppConstants.wsTopicSchool}/$_currentSchoolId');
      }

      // Subscribe to user-specific notifications
      if (_currentUserId != null) {
        _stompClient!.subscribe(
          destination: AppConstants.wsTopicUser,
          callback: _onStompMessage,
        );
        debugPrint('${AppConstants.logWebSocketSubscribedUser}${AppConstants.wsTopicUser}');
      }

      // Subscribe to role-specific notifications
      if (_currentUserRole != null) {
        _stompClient!.subscribe(
          destination: '${AppConstants.wsTopicRole}/${_currentUserRole!.toLowerCase()}',
          callback: _onStompMessage,
        );
        debugPrint('${AppConstants.logWebSocketSubscribedRole}${AppConstants.wsTopicRole}/${_currentUserRole!.toLowerCase()}');
      }

      // Subscribe to general notifications
      _stompClient!.subscribe(
        destination: AppConstants.wsTopicAll,
        callback: _onStompMessage,
      );
      debugPrint('${AppConstants.logWebSocketSubscribedGeneral}${AppConstants.wsTopicAll}');

    } catch (e) {
      debugPrint('${AppConstants.errorWebSocketSubscription}: $e');
    }
  }


  // Public subscribe helpers used by BLoC
  Future<void> subscribeToUserNotifications(String userId) async {
    if (!_isConnected || _stompClient == null) return;
    try {
      _stompClient!.subscribe(
        destination: AppConstants.wsTopicUser,
        callback: _onStompMessage,
      );
    } catch (e) {
      debugPrint('${AppConstants.errorWebSocketUserSubscription}: $e');
    }
  }

  Future<void> subscribeToRoleNotifications(String role) async {
    if (!_isConnected || _stompClient == null) return;
    try {
      _stompClient!.subscribe(
        destination: '${AppConstants.wsTopicRole}/${role.toLowerCase()}',
        callback: _onStompMessage,
      );
    } catch (e) {
      debugPrint('${AppConstants.errorWebSocketRoleSubscription}: $e');
    }
  }

  Future<void> subscribeToSchoolNotifications(int schoolId) async {
    if (!_isConnected || _stompClient == null) return;
    try {
      _stompClient!.subscribe(
        destination: '${AppConstants.wsTopicSchool}/$schoolId',
        callback: _onStompMessage,
      );
    } catch (e) {
      debugPrint('${AppConstants.errorWebSocketSchoolSubscription}: $e');
    }
  }


  // Route notifications to specific streams
  void _routeNotificationToSpecificStreams(WebSocketNotification notification) {
    switch (notification.type) {
      case NotificationType.tripUpdate:
        _tripUpdateController.add(notification);
        break;
      case NotificationType.arrivalNotification:
        _arrivalController.add(notification);
        break;
      case NotificationType.pickupConfirmation:
        _pickupController.add(notification);
        break;
      case NotificationType.dropConfirmation:
        _dropController.add(notification);
        break;
      case NotificationType.systemAlert:
        _systemAlertController.add(notification);
        break;
      case NotificationType.vehicleAssignmentRequest:
        _notificationController.add(notification);
        break;
      case NotificationType.vehicleAssignmentApproved:
        _notificationController.add(notification);
        break;
      case NotificationType.vehicleAssignmentRejected:
        _notificationController.add(notification);
        break;
      case NotificationType.connectionEstablished:
        _notificationController.add(notification);
        break;
    }
  }

  // Send notification (for testing)
  Future<void> sendNotification(Map<String, dynamic> notification) async {
    if (!_isConnected || _stompClient == null) return;

    try {
      _stompClient!.send(
        destination: AppConstants.wsDestinationSend,
        body: jsonEncode(notification),
      );
    } catch (e) {
      debugPrint('${AppConstants.errorWebSocketSendNotification}: $e');
    }
  }

  // Reconnect if disconnected
  Future<void> reconnect() async {
    if (_isConnected) return;
    
    debugPrint(AppConstants.logWebSocketAttemptReconnect);
    await _connect();
  }

  // Disconnect
  Future<void> disconnect() async {
    if (_stompClient != null) {
      try {
        _stompClient!.deactivate();
      } catch (_) {}
      _stompClient = null;
    }
    _isConnected = false;
    debugPrint(AppConstants.logWebSocketDisconnectedStomp);
  }

  // Update user data and resubscribe
  Future<void> updateUserData() async {
    await _loadUserData();
    if (_isConnected) {
      _subscribeToChannels();
    }
  }

  // Dispose resources
  void dispose() {
    // fire-and-forget; we don't await inside dispose
    disconnect();
    _notificationController.close();
    _tripUpdateController.close();
    _arrivalController.close();
    _pickupController.close();
    _dropController.close();
    _systemAlertController.close();
  }
}

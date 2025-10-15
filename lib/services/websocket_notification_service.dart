import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/websocket_notification.dart';
import '../config/app_config.dart';

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
      print('Error initializing WebSocket: $e');
    }
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserRole = prefs.getString('role');
    _currentSchoolId = prefs.getInt('schoolId');
    _currentUserId = prefs.getInt('userId');
    
    print('WebSocket User Data: Role=$_currentUserRole, SchoolId=$_currentSchoolId, UserId=$_currentUserId');
  }

  // Connect to WebSocket using STOMP
  Future<void> _connect() async {
    if (_isConnected) return;

    try {
      // WebSocket URL for STOMP with SockJS
      String wsUrl;
      print('🔍 AppConfig.baseUrl: ${AppConfig.baseUrl}');
      
      if (AppConfig.baseUrl.contains('http://')) {
        wsUrl = AppConfig.baseUrl.replaceFirst('http://', 'ws://') + '/ws/websocket';
      } else if (AppConfig.baseUrl.contains('https://')) {
        wsUrl = AppConfig.baseUrl.replaceFirst('https://', 'wss://') + '/ws/websocket';
      } else {
        wsUrl = 'ws://' + AppConfig.baseUrl + '/ws/websocket';
      }
      
      print('🔍 Constructed WebSocket URL: $wsUrl');
      print('Connecting to STOMP WebSocket: $wsUrl');

      // Create STOMP configuration
      final config = StompConfig(
        url: wsUrl,
        onConnect: _onStompConnect,
        onWebSocketError: _onWebSocketError,
        onStompError: _onStompError,
        onDisconnect: _onDisconnect,
        onDebugMessage: (String message) => print('STOMP Debug: $message'),
      );

      // Create and activate STOMP client
      _stompClient = StompClient(config: config);
      _stompClient!.activate();
      
    } catch (e) {
      print('Error connecting to STOMP WebSocket: $e');
    }
  }

  // STOMP connection handler
  void _onStompConnect(StompFrame frame) {
    print('STOMP connected successfully');
    _isConnected = true;
    _subscribeToChannels();
  }

  // STOMP error handler
  void _onStompError(StompFrame frame) {
    print('STOMP Error: ${frame.body}');
    _isConnected = false;
  }

  // Handle incoming STOMP messages
  void _onStompMessage(StompFrame frame) {
    try {
      print('STOMP message received: ${frame.body}');

      if (frame.body != null) {
        final Map<String, dynamic> jsonData = jsonDecode(frame.body!);
        print('Parsed STOMP JSON message: $jsonData');
        
        final notification = WebSocketNotification.fromJson(jsonData);
        _notificationController.add(notification);
        _routeNotificationToSpecificStreams(notification);
        print('✅ STOMP notification processed successfully');
      }
    } catch (e) {
      print('❌ Error processing STOMP message: $e');
    }
  }

  // Handle disconnection
  void _onDisconnect(StompFrame frame) {
    print('WebSocket disconnected');
    _isConnected = false;
  }

  // Handle WebSocket errors
  void _onWebSocketError(dynamic error) {
    print('WebSocket Error: $error');
    _isConnected = false;
  }

  // Subscribe to STOMP notification channels
  void _subscribeToChannels() {
    if (!_isConnected || _stompClient == null) return;

    try {
      // Subscribe to school-specific notifications
      if (_currentSchoolId != null) {
        _stompClient!.subscribe(
          destination: '/topic/school/$_currentSchoolId',
          callback: _onStompMessage,
        );
        print('Subscribed to school notifications: /topic/school/$_currentSchoolId');
      }

      // Subscribe to user-specific notifications
      if (_currentUserId != null) {
        _stompClient!.subscribe(
          destination: '/user/queue/notifications',
          callback: _onStompMessage,
        );
        print('Subscribed to user notifications: /user/queue/notifications');
      }

      // Subscribe to role-specific notifications
      if (_currentUserRole != null) {
        _stompClient!.subscribe(
          destination: '/topic/role/${_currentUserRole!.toLowerCase()}',
          callback: _onStompMessage,
        );
        print('Subscribed to role notifications: /topic/role/${_currentUserRole!.toLowerCase()}');
      }

      // Subscribe to general notifications
      _stompClient!.subscribe(
        destination: '/topic/all',
        callback: _onStompMessage,
      );
      print('Subscribed to general notifications: /topic/all');

    } catch (e) {
      print('Error subscribing to STOMP channels: $e');
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
  void sendNotification(Map<String, dynamic> notification) {
    if (!_isConnected || _stompClient == null) return;

    try {
      _stompClient!.send(
        destination: '/app/chat.sendMessage',
        body: jsonEncode(notification),
      );
    } catch (e) {
      print('Error sending STOMP notification: $e');
    }
  }

  // Reconnect if disconnected
  Future<void> reconnect() async {
    if (_isConnected) return;
    
    print('Attempting to reconnect...');
    await _connect();
  }

  // Disconnect
  void disconnect() {
    if (_stompClient != null) {
      _stompClient!.deactivate();
      _stompClient = null;
    }
    _isConnected = false;
    print('STOMP WebSocket disconnected');
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
    disconnect();
    _notificationController.close();
    _tripUpdateController.close();
    _arrivalController.close();
    _pickupController.close();
    _dropController.close();
    _systemAlertController.close();
  }
}

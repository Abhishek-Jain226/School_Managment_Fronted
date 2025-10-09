import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/websocket_notification.dart';
import '../config/app_config.dart';

class WebSocketNotificationService {
  static final WebSocketNotificationService _instance = WebSocketNotificationService._internal();
  factory WebSocketNotificationService() => _instance;
  WebSocketNotificationService._internal();

  WebSocketChannel? _channel;
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

  // Connect to WebSocket
  Future<void> _connect() async {
    if (_isConnected) return;

    try {
      // WebSocket URL with SockJS support
      final wsUrl = AppConfig.baseUrl.replaceFirst('http', 'ws') + '/ws/websocket';
      print('Connecting to WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      // Listen to messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onWebSocketError,
        onDone: _onDisconnect,
      );
      
      _isConnected = true;
      print('WebSocket connected successfully');
      
      // Send subscription after connection
      _subscribeToChannels();
    } catch (e) {
      print('Error connecting to WebSocket: $e');
    }
  }

  // Handle incoming messages
  void _onMessage(dynamic message) {
    try {
      print('Raw WebSocket message received: $message');
      
      // Handle SockJS messages (they might be wrapped)
      String messageStr = message.toString();
      if (messageStr.startsWith('a[') && messageStr.endsWith(']')) {
        // SockJS array message format
        messageStr = messageStr.substring(2, messageStr.length - 1);
        if (messageStr.startsWith('"') && messageStr.endsWith('"')) {
          messageStr = messageStr.substring(1, messageStr.length - 1);
        }
      }
      
      final notificationData = jsonDecode(messageStr);
      final notification = WebSocketNotification.fromJson(notificationData);
      
      print('Received notification: ${notification.type} - ${notification.message}');
      
      // Add to general notification stream
      _notificationController.add(notification);
      
      // Add to specific streams based on type
      _routeNotificationToSpecificStreams(notification);
      
    } catch (e) {
      print('Error handling message: $e');
      print('Message was: $message');
    }
  }

  // Handle disconnection
  void _onDisconnect() {
    print('WebSocket disconnected');
    _isConnected = false;
  }

  // Handle WebSocket errors
  void _onWebSocketError(dynamic error) {
    print('WebSocket Error: $error');
    _isConnected = false;
  }

  // Subscribe to notification channels (simplified for basic WebSocket)
  void _subscribeToChannels() {
    if (!_isConnected || _channel == null) return;

    try {
      // Send subscription message to backend for school-specific notifications
      if (_currentSchoolId != null) {
        final subscriptionMessage = {
          'type': 'SUBSCRIBE',
          'schoolId': _currentSchoolId,
          'userRole': _currentUserRole,
          'userId': _currentUserId,
        };
        _channel!.sink.add(jsonEncode(subscriptionMessage));
        print('Subscribed to school notifications: $_currentSchoolId');
      }
    } catch (e) {
      print('Error subscribing to channels: $e');
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
    if (!_isConnected || _channel == null) return;

    try {
      _channel!.sink.add(jsonEncode(notification));
    } catch (e) {
      print('Error sending notification: $e');
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
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    _isConnected = false;
    print('WebSocket disconnected');
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

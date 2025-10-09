import 'package:flutter/material.dart';
import '../../data/models/websocket_notification.dart';
import '../../services/websocket_notification_service.dart';
import '../widgets/notification_card.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final WebSocketNotificationService _notificationService = WebSocketNotificationService();
  final List<WebSocketNotification> _notifications = [];
  String _selectedFilter = 'All';
  bool _isLoading = true;

  final List<String> _filterOptions = [
    'All',
    'Trip Updates',
    'Arrivals',
    'Pickups',
    'Drops',
    'System Alerts',
  ];

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    _notificationService.notificationStream.listen((notification) {
      setState(() {
        _notifications.insert(0, notification);
        _isLoading = false;
      });
    });
  }

  List<WebSocketNotification> get _filteredNotifications {
    if (_selectedFilter == 'All') {
      return _notifications;
    }

    String filterType;
    switch (_selectedFilter) {
      case 'Trip Updates':
        filterType = NotificationType.tripUpdate;
        break;
      case 'Arrivals':
        filterType = NotificationType.arrivalNotification;
        break;
      case 'Pickups':
        filterType = NotificationType.pickupConfirmation;
        break;
      case 'Drops':
        filterType = NotificationType.dropConfirmation;
        break;
      case 'System Alerts':
        filterType = NotificationType.systemAlert;
        break;
      default:
        return _notifications;
    }

    return _notifications.where((n) => n.type == filterType).toList();
  }

  void _markAsRead(WebSocketNotification notification) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = notification.copyWith(isRead: true);
      }
    });
  }

  void _dismissNotification(WebSocketNotification notification) {
    setState(() {
      _notifications.removeWhere((n) => n.id == notification.id);
    });
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _notifications.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              onPressed: _clearAllNotifications,
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final filter = _filterOptions[index];
                final isSelected = _selectedFilter == filter;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                  ),
                );
              },
            ),
          ),
          
          // Notifications list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotifications.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          // Refresh logic if needed
                        },
                        child: ListView.builder(
                          itemCount: _filteredNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = _filteredNotifications[index];
                            return NotificationCard(
                              notification: notification,
                              onTap: () => _markAsRead(notification),
                              onDismiss: () => _dismissNotification(notification),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see real-time notifications here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
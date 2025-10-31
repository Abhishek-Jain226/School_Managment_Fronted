import 'package:flutter/material.dart';
import '../../utils/constants.dart';
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
  String _selectedFilter = AppConstants.labelFilterAll;
  bool _isLoading = true;

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
    if (_selectedFilter == AppConstants.labelFilterAll) {
      return _notifications;
    }

    String filterType;
    switch (_selectedFilter) {
      case AppConstants.labelFilterTripUpdates:
        filterType = NotificationType.tripUpdate;
        break;
      case AppConstants.labelFilterArrivals:
        filterType = NotificationType.arrivalNotification;
        break;
      case AppConstants.labelFilterPickups:
        filterType = NotificationType.pickupConfirmation;
        break;
      case AppConstants.labelFilterDrops:
        filterType = NotificationType.dropConfirmation;
        break;
      case AppConstants.labelFilterSystemAlerts:
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
        title: const Text(AppConstants.labelClearAllNotifications),
        content: const Text(AppConstants.msgClearAllNotificationsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppConstants.actionCancel),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _notifications.clear();
              });
              Navigator.pop(context);
            },
            child: const Text(AppConstants.labelClearAll),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.labelNotifications),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              onPressed: _clearAllNotifications,
              icon: const Icon(Icons.clear_all),
              tooltip: AppConstants.labelClearAll,
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            height: AppSizes.notificationFilterHeight,
            padding: const EdgeInsets.symmetric(vertical: AppSizes.notificationFilterPaddingV),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.notificationFilterPaddingH),
              itemCount: AppConstants.notificationFilterOptions.length,
              itemBuilder: (context, index) {
                final filter = AppConstants.notificationFilterOptions[index];
                final isSelected = _selectedFilter == filter;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.notificationFilterChipPadding),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    selectedColor: Theme.of(context).primaryColor.withValues(alpha: AppSizes.notificationFilterOpacity),
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
            size: AppSizes.notificationEmptyIconSize,
            color: AppColors.textSecondary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: AppSizes.notificationEmptySpacing),
          const Text(
            AppConstants.labelNoNotifications,
            style: TextStyle(
              fontSize: AppSizes.notificationEmptyTitleFontSize,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSizes.notificationEmptySpacingSM),
          const Text(
            AppConstants.labelNotificationsSubtitle,
            style: TextStyle(
              fontSize: AppSizes.notificationEmptySubtitleFontSize,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
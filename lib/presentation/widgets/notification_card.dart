import 'package:flutter/material.dart';
import '../../data/models/websocket_notification.dart';

class NotificationCard extends StatelessWidget {
  final WebSocketNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismiss?.call(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: Colors.red,
          child: const Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
        child: ListTile(
          onTap: onTap,
          leading: _buildNotificationIcon(),
          title: Text(
            notification.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.message,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(notification.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          trailing: _buildPriorityIndicator(),
          isThreeLine: true,
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.tripUpdate:
        iconData = Icons.directions_bus;
        iconColor = Colors.blue;
        break;
      case NotificationType.arrivalNotification:
        iconData = Icons.location_on;
        iconColor = Colors.green;
        break;
      case NotificationType.pickupConfirmation:
        iconData = Icons.person_add;
        iconColor = Colors.orange;
        break;
      case NotificationType.dropConfirmation:
        iconData = Icons.person_remove;
        iconColor = Colors.purple;
        break;
      case NotificationType.delayNotification:
        iconData = Icons.schedule;
        iconColor = Colors.red;
        break;
      case NotificationType.systemAlert:
        iconData = Icons.warning;
        iconColor = Colors.red;
        break;
      case NotificationType.attendanceUpdate:
        iconData = Icons.school;
        iconColor = Colors.indigo;
        break;
      case NotificationType.vehicleStatusUpdate:
        iconData = Icons.directions_car;
        iconColor = Colors.teal;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.1),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  Widget _buildPriorityIndicator() {
    Color priorityColor;
    IconData priorityIcon;

    switch (notification.priority) {
      case NotificationPriority.high:
        priorityColor = Colors.red;
        priorityIcon = Icons.priority_high;
        break;
      case NotificationPriority.medium:
        priorityColor = Colors.orange;
        priorityIcon = Icons.remove;
        break;
      case NotificationPriority.low:
        priorityColor = Colors.green;
        priorityIcon = Icons.keyboard_arrow_down;
        break;
      default:
        priorityColor = Colors.grey;
        priorityIcon = Icons.remove;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          priorityIcon,
          color: priorityColor,
          size: 16,
        ),
        if (!notification.isRead)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

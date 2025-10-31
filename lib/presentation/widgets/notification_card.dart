import 'package:flutter/material.dart';
import '../../data/models/websocket_notification.dart';
import '../../utils/constants.dart';

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
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.notificationCardMarginHorizontal,
        vertical: AppSizes.notificationCardMarginVertical,
      ),
      elevation: AppSizes.notificationCardElevation,
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismiss?.call(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(
            right: AppSizes.notificationCardDismissPadding,
          ),
          color: AppColors.notificationCardDismissBackground,
          child: const Icon(
            Icons.delete,
            color: AppColors.notificationCardDismissIconColor,
          ),
        ),
        child: ListTile(
          onTap: onTap,
          leading: _buildNotificationIcon(),
          title: Text(
            notification.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppSizes.notificationCardTitleFontSize,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.message,
                style: const TextStyle(
                  fontSize: AppSizes.notificationCardMessageFontSize,
                ),
                maxLines: AppSizes.notificationCardMaxLines,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSizes.notificationCardSpacing),
              Text(
                _formatTimestamp(notification.timestamp),
                style: TextStyle(
                  fontSize: AppSizes.notificationCardTimeFontSize,
                  color: AppColors.notificationCardTimeColor,
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
        iconColor = AppColors.notificationTypeTripUpdate;
        break;
      case NotificationType.arrivalNotification:
        iconData = Icons.location_on;
        iconColor = AppColors.notificationTypeArrival;
        break;
      case NotificationType.pickupConfirmation:
        iconData = Icons.person_add;
        iconColor = AppColors.notificationTypePickup;
        break;
      case NotificationType.dropConfirmation:
        iconData = Icons.person_remove;
        iconColor = AppColors.notificationTypeDrop;
        break;
      case NotificationType.delayNotification:
        iconData = Icons.schedule;
        iconColor = AppColors.notificationTypeDelay;
        break;
      case NotificationType.systemAlert:
        iconData = Icons.warning;
        iconColor = AppColors.notificationTypeSystemAlert;
        break;
      case NotificationType.attendanceUpdate:
        iconData = Icons.school;
        iconColor = AppColors.notificationTypeAttendance;
        break;
      case NotificationType.vehicleStatusUpdate:
        iconData = Icons.directions_car;
        iconColor = AppColors.notificationTypeVehicleStatus;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = AppColors.notificationTypeDefault;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withValues(
        alpha: AppSizes.notificationCardIconOpacity,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: AppSizes.notificationCardIconSize,
      ),
    );
  }

  Widget _buildPriorityIndicator() {
    Color priorityColor;
    IconData priorityIcon;

    switch (notification.priority) {
      case NotificationPriority.high:
        priorityColor = AppColors.notificationPriorityHigh;
        priorityIcon = Icons.priority_high;
        break;
      case NotificationPriority.medium:
        priorityColor = AppColors.notificationPriorityMedium;
        priorityIcon = Icons.remove;
        break;
      case NotificationPriority.low:
        priorityColor = AppColors.notificationPriorityLow;
        priorityIcon = Icons.keyboard_arrow_down;
        break;
      default:
        priorityColor = AppColors.notificationPriorityDefault;
        priorityIcon = Icons.remove;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          priorityIcon,
          color: priorityColor,
          size: AppSizes.notificationCardPriorityIconSize,
        ),
        if (!notification.isRead)
          Container(
            width: AppSizes.notificationCardUnreadIndicatorSize,
            height: AppSizes.notificationCardUnreadIndicatorSize,
            decoration: const BoxDecoration(
              color: AppColors.notificationCardUnreadIndicator,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < AppSizes.notificationTimeThresholdMinutes) {
      return AppConstants.labelJustNow;
    } else if (difference.inMinutes < AppSizes.notificationTimeThresholdHours) {
      return '${difference.inMinutes}${AppConstants.labelMinutesAgo}';
    } else if (difference.inHours < AppSizes.notificationTimeThresholdDays) {
      return '${difference.inHours}${AppConstants.labelHoursAgo}';
    } else {
      return '${difference.inDays}${AppConstants.labelDaysAgo}';
    }
  }
}

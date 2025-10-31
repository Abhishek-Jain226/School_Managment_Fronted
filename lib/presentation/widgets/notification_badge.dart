import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class NotificationBadge extends StatefulWidget {
  final int notificationCount;
  final VoidCallback? onTap;
  final Color? badgeColor;
  final Color? textColor;

  const NotificationBadge({
    super.key,
    required this.notificationCount,
    this.onTap,
    this.badgeColor,
    this.textColor,
  });

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        children: [
          const Icon(
            Icons.notifications,
            size: AppSizes.notificationIconSize,
            color: AppColors.notificationIconColor,
          ),
          if (widget.notificationCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(AppSizes.notificationBadgePadding),
                decoration: BoxDecoration(
                  color: widget.badgeColor ?? AppColors.notificationBadgeColor,
                  borderRadius: BorderRadius.circular(AppSizes.notificationBadgeRadius),
                ),
                constraints: const BoxConstraints(
                  minWidth: AppSizes.notificationBadgeMinSize,
                  minHeight: AppSizes.notificationBadgeMinSize,
                ),
                child: Text(
                  widget.notificationCount > AppSizes.notificationMaxCount
                      ? AppConstants.labelNotificationOverflow
                      : widget.notificationCount.toString(),
                  style: TextStyle(
                    color: widget.textColor ?? AppColors.notificationBadgeTextColor,
                    fontSize: AppSizes.notificationBadgeFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

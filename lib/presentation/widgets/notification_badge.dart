import 'package:flutter/material.dart';
import '../../data/models/websocket_notification.dart';

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
            size: 28,
            color: Colors.white,
          ),
          if (widget.notificationCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: widget.badgeColor ?? Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  widget.notificationCount > 99 ? '99+' : widget.notificationCount.toString(),
                  style: TextStyle(
                    color: widget.textColor ?? Colors.white,
                    fontSize: 10,
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

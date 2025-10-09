import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/websocket_notification.dart';

class NotificationToast extends StatefulWidget {
  final WebSocketNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationToast({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  @override
  State<NotificationToast> createState() => _NotificationToastState();
}

class _NotificationToastState extends State<NotificationToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();

    // Auto dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _buildNotificationIcon(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.notification.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.notification.message,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        _buildPriorityIndicator(),
                        const SizedBox(height: 4),
                        if (_isRequestNotification())
                          GestureDetector(
                            onTap: () {
                              _dismiss();
                              widget.onTap?.call();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.visibility,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: _dismiss,
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    IconData iconData;
    Color iconColor;

    switch (widget.notification.type) {
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
      case NotificationType.vehicleAssignmentRequest:
        iconData = Icons.assignment;
        iconColor = Colors.deepPurple;
        break;
      case NotificationType.vehicleAssignmentApproved:
        iconData = Icons.check_circle;
        iconColor = Colors.teal;
        break;
      case NotificationType.vehicleAssignmentRejected:
        iconData = Icons.cancel;
        iconColor = Colors.deepOrange;
        break;
      case NotificationType.connectionEstablished:
        iconData = Icons.wifi;
        iconColor = Colors.lightGreen;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return CircleAvatar(
      radius: 20,
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

    switch (widget.notification.priority) {
      case NotificationPriority.high:
        priorityColor = Colors.red;
        break;
      case NotificationPriority.medium:
        priorityColor = Colors.orange;
        break;
      case NotificationPriority.low:
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: priorityColor,
        shape: BoxShape.circle,
      ),
    );
  }

  bool _isRequestNotification() {
    return widget.notification.type == NotificationType.vehicleAssignmentRequest ||
           widget.notification.type == NotificationType.vehicleAssignmentApproved ||
           widget.notification.type == NotificationType.vehicleAssignmentRejected;
  }

  // Static method to show notification toast
  static void show(
    BuildContext context,
    WebSocketNotification notification, {
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: NotificationToast(
            notification: notification,
            onTap: onTap,
            onDismiss: () {
              overlayEntry.remove();
              onDismiss?.call();
            },
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss after 5 seconds
    Timer(const Duration(seconds: 5), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/websocket_notification.dart';
import '../../utils/constants.dart';

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
      duration: const Duration(
        milliseconds: AppSizes.notificationToastAnimationMs,
      ),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(
        AppSizes.notificationToastAnimationStart,
        AppSizes.notificationToastAnimationEnd,
      ),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: AppSizes.notificationToastAnimationEnd,
      end: AppSizes.notificationToastAnimationStart,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();

    // Auto dismiss after 5 seconds
    Future.delayed(
      const Duration(seconds: AppSizes.notificationToastAutoDismissSec),
      () {
        if (mounted) {
          _dismiss();
        }
      },
    );
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
          margin: const EdgeInsets.all(AppSizes.notificationToastMargin),
          decoration: BoxDecoration(
            color: AppColors.notificationToastBackground,
            borderRadius: BorderRadius.circular(AppSizes.notificationToastRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.notificationToastShadowColor.withValues(
                  alpha: AppSizes.notificationToastShadowOpacity,
                ),
                blurRadius: AppSizes.notificationToastShadowBlur,
                offset: const Offset(0, AppSizes.notificationToastShadowOffset),
              ),
            ],
          ),
          child: Material(
            color: AppColors.notificationToastTransparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppSizes.notificationToastRadius),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.notificationToastPadding),
                child: Row(
                  children: [
                    _buildNotificationIcon(),
                    const SizedBox(width: AppSizes.notificationToastSpacingLG),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.notification.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: AppSizes.notificationToastTitleFontSize,
                            ),
                          ),
                          const SizedBox(height: AppSizes.notificationToastSpacingXS),
                          Text(
                            widget.notification.message,
                            style: const TextStyle(
                              fontSize: AppSizes.notificationToastMessageFontSize,
                              color: AppColors.notificationToastMessageColor,
                            ),
                            maxLines: AppSizes.notificationToastMaxLines,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.notificationToastSpacingSM),
                    Column(
                      children: [
                        _buildPriorityIndicator(),
                        const SizedBox(height: AppSizes.notificationToastSpacingXS),
                        if (_isRequestNotification())
                          GestureDetector(
                            onTap: () {
                              _dismiss();
                              widget.onTap?.call();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(
                                AppSizes.notificationToastActionPadding,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.notificationToastActionBackground,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.notificationToastActionRadius,
                                ),
                              ),
                              child: const Icon(
                                Icons.visibility,
                                size: AppSizes.notificationToastActionIconSize,
                                color: AppColors.notificationToastActionIconColor,
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: _dismiss,
                            child: const Icon(
                              Icons.close,
                              size: AppSizes.notificationToastCloseIconSize,
                              color: AppColors.notificationToastCloseIconColor,
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
      case NotificationType.vehicleAssignmentRequest:
        iconData = Icons.assignment;
        iconColor = AppColors.notificationTypeAssignmentRequest;
        break;
      case NotificationType.vehicleAssignmentApproved:
        iconData = Icons.check_circle;
        iconColor = AppColors.notificationTypeAssignmentApproved;
        break;
      case NotificationType.vehicleAssignmentRejected:
        iconData = Icons.cancel;
        iconColor = AppColors.notificationTypeAssignmentRejected;
        break;
      case NotificationType.connectionEstablished:
        iconData = Icons.wifi;
        iconColor = AppColors.notificationTypeConnectionEstablished;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = AppColors.notificationTypeDefault;
    }

    return CircleAvatar(
      radius: AppSizes.notificationToastIconRadius,
      backgroundColor: iconColor.withValues(
        alpha: AppSizes.notificationToastIconOpacity,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: AppSizes.notificationToastIconSize,
      ),
    );
  }

  Widget _buildPriorityIndicator() {
    Color priorityColor;

    switch (widget.notification.priority) {
      case NotificationPriority.high:
        priorityColor = AppColors.notificationPriorityHigh;
        break;
      case NotificationPriority.medium:
        priorityColor = AppColors.notificationPriorityMedium;
        break;
      case NotificationPriority.low:
        priorityColor = AppColors.notificationPriorityLow;
        break;
      default:
        priorityColor = AppColors.notificationPriorityDefault;
    }

    return Container(
      width: AppSizes.notificationToastPrioritySize,
      height: AppSizes.notificationToastPrioritySize,
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
        top: MediaQuery.of(context).padding.top + 
             AppSizes.notificationToastOverlayTop,
        left: AppSizes.notificationToastOverlaySide,
        right: AppSizes.notificationToastOverlaySide,
        child: Material(
          color: AppColors.notificationToastTransparent,
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
    Timer(
      const Duration(seconds: AppSizes.notificationToastAutoDismissSec),
      () {
        if (overlayEntry.mounted) {
          overlayEntry.remove();
        }
      },
    );
  }
}

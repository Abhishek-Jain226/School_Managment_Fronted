import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/constants.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/parent/parent_bloc.dart';
import '../../bloc/parent/parent_event.dart';
import '../../bloc/parent/parent_state.dart';
import '../../app_routes.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart';

class BlocParentDashboard extends StatefulWidget {
  const BlocParentDashboard({super.key});

  @override
  State<BlocParentDashboard> createState() => _BlocParentDashboardState();
}

class _BlocParentDashboardState extends State<BlocParentDashboard> {
  final WebSocketNotificationService _wsService = WebSocketNotificationService();
  StreamSubscription<WebSocketNotification>? _notificationSubscription;
  StreamSubscription<WebSocketNotification>? _tripUpdateSubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadParentData();
    _initializeWebSocket();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _tripUpdateSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadParentData() {
    // Get parent ID (userId) from auth state
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.userId != null) {
      context.read<ParentBloc>().add(
        ParentDashboardRequested(parentId: authState.userId!),
      );
    } else {
      // If userId is not available, show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.msgUserIdNotFound),
          backgroundColor: AppColors.parentErrorColor,
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  void _initializeWebSocket() {
    _wsService.initialize().then((_) {
      debugPrint(AppConstants.msgWebSocketInitializedParent);
      
      // Listen to general notifications (especially for child-related updates)
      _notificationSubscription = _wsService.notificationStream.listen(
        (notification) {
          debugPrint('${AppConstants.msgReceivedNotification}${notification.type}');
          _handleNotification(notification);
        },
        onError: (error) {
          debugPrint('${AppConstants.msgNotificationStreamError}$error');
        },
      );

      // Listen to pickup/drop notifications
      _tripUpdateSubscription = _wsService.pickupStream.listen(
        (notification) {
          debugPrint('${AppConstants.msgReceivedPickupNotification}${notification.message}');
          _handleNotification(notification);
          _refreshDashboard();
        },
        onError: (error) {
          debugPrint('${AppConstants.msgPickupNotificationError}$error');
        },
      );

      // Listen to drop notifications
      _wsService.dropStream.listen(
        (notification) {
          debugPrint('${AppConstants.msgReceivedDropNotification}${notification.message}');
          _handleNotification(notification);
          _refreshDashboard();
        },
        onError: (error) {
          debugPrint('${AppConstants.msgDropNotificationError}$error');
        },
      );
    }).catchError((error) {
      debugPrint('${AppConstants.msgWebSocketInitError}$error');
    });
  }

  void _handleNotification(WebSocketNotification notification) {
    // Only show USER-FACING notifications as SnackBar
    final showAsSnackBar = _shouldShowNotificationToUser(notification.type);
    
    if (mounted) {
      if (showAsSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notification.message),
            backgroundColor: _getNotificationColor(notification.type),
            duration: const Duration(seconds: AppSizes.parentNotificationDurationSeconds),
            action: SnackBarAction(
              label: AppConstants.labelView,
              textColor: AppColors.parentTextWhite,
              onPressed: () {
                // Navigate to vehicle tracking or relevant page
                Navigator.pushNamed(context, AppRoutes.vehicleTracking);
              },
            ),
          ),
        );
      }
      
      // Always refresh dashboard data
      _refreshDashboard();
    }
  }
  
  bool _shouldShowNotificationToUser(String type) {
    // Parents should see child-related notifications
    final userFacingNotifications = [
      AppConstants.notifTypePickupNotification,
      AppConstants.notifTypeDropNotification,
      AppConstants.notifTypePickupFromHome,
      AppConstants.notifTypeDropToHome,
      AppConstants.notifTypeStudentAbsentParent,
      AppConstants.notifTypeTripDelayed,
      AppConstants.notifTypeEmergencyAlert,
    ];
    
    return userFacingNotifications.contains(type.toUpperCase());
  }

  Color _getNotificationColor(String type) {
    switch (type.toUpperCase()) {
      case 'ARRIVAL':
        return AppColors.statusSuccess;
      case 'PICKUP':
      case 'PICKUP_FROM_PARENT':
        return AppColors.statusInfo;
      case 'DROP':
      case 'DROP_TO_PARENT':
        return AppColors.statusWarning;
      case 'ALERT':
      case 'SYSTEM_ALERT':
      case 'DELAY_NOTIFICATION':
        return AppColors.statusError;
      default:
        return AppColors.textSecondary;
    }
  }

  void _refreshDashboard() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.userId != null) {
      context.read<ParentBloc>().add(
        ParentDashboardRequested(parentId: authState.userId!),
      );
    }
  }

  void _startAutoRefresh() {
    // Auto-refresh dashboard every 30 seconds
    _refreshTimer = Timer.periodic(AppDurations.autoRefresh, (timer) {
      if (mounted) {
        _refreshDashboard();
      }
    });
  }

  Future<void> _showLogoutConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppConstants.alertConfirmLogout),
        content: const Text(AppConstants.alertLogoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppConstants.actionCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusError,
              foregroundColor: AppColors.textLight,
            ),
            child: const Text(AppConstants.actionLogout),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<AuthBloc>().add(const AuthLogoutRequested());
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.labelParentDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutConfirmation,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: BlocListener<ParentBloc, ParentState>(
        listener: (context, state) {
          if (state is ParentActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.parentSuccessColor,
              ),
            );
          } else if (state is ParentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.parentErrorColor,
              ),
            );
          }
        },
        child: BlocBuilder<ParentBloc, ParentState>(
          builder: (context, state) {
            if (state is ParentLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ParentDashboardLoaded) {
              return _buildDashboard(state);
            } else if (state is ParentProfileLoaded) {
              // If profile loaded but dashboard state lost, reload dashboard
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated && authState.userId != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    context.read<ParentBloc>().add(
                      ParentDashboardRequested(parentId: authState.userId!),
                    );
                  }
                });
              }
              return const Center(child: CircularProgressIndicator());
            } else if (state is ParentError && state.actionType != AppConstants.actionTypeLoadProfile) {
              return _buildErrorState(state);
            }
            // Fallback: try to reload dashboard
            final authState = context.read<AuthBloc>().state;
            if (authState is AuthAuthenticated && authState.userId != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.read<ParentBloc>().add(
                    ParentDashboardRequested(parentId: authState.userId!),
                  );
                }
              });
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppColors.parentPrimaryColor),
            child: Text(
              AppConstants.labelParentMenu,
              style: TextStyle(
                color: AppColors.parentTextWhite,
                fontSize: AppSizes.parentMenuFontSize,
              ),
            ),
          ),
          BlocListener<ParentBloc, ParentState>(
            listener: (context, state) {
              if (state is ParentProfileLoaded) {
                // Navigate to profile page
                Navigator.pushNamed(
                  context,
                  AppRoutes.parentProfileUpdate,
                  arguments: state.profile,
                ).then((_) {
                  // Reload dashboard when returning from profile page
                  if (mounted) {
                    final authState = context.read<AuthBloc>().state;
                    if (authState is AuthAuthenticated && authState.userId != null) {
                      context.read<ParentBloc>().add(
                        ParentDashboardRequested(parentId: authState.userId!),
                      );
                    }
                  }
                });
              } else if (state is ParentError && state.actionType == AppConstants.actionTypeLoadProfile) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.parentErrorColor,
                  ),
                );
              }
            },
            child: BlocBuilder<ParentBloc, ParentState>(
              builder: (context, state) {
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text(AppConstants.labelProfile),
                  onTap: () {
                    Navigator.pop(context);
                    // Load profile first, then navigate
                    final authState = context.read<AuthBloc>().state;
                    if (authState is AuthAuthenticated && authState.userId != null) {
                      context.read<ParentBloc>().add(
                        ParentProfileRequested(parentId: authState.userId!),
                      );
                    }
                  },
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text(AppConstants.labelAttendanceHistory),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.attendanceHistory);
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text(AppConstants.labelMonthlyReport),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.monthlyReport);
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text(AppConstants.labelTrackVehicle),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.enhancedVehicleTracking);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(ParentDashboardLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadParentData();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.parentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats
            _buildQuickStats(state),
            const SizedBox(height: AppSizes.parentSpacingMD),

            // Children Status
            _buildChildrenStatus(state),
            const SizedBox(height: AppSizes.parentSpacingMD),

            // Recent Notifications
            _buildRecentNotifications(state),
            const SizedBox(height: AppSizes.parentSpacingMD),

            // Quick Actions
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(ParentDashboardLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.parentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.labelQuickStats,
              style: TextStyle(
                fontSize: AppSizes.parentHeaderFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.parentSpacingMD),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelChildren,
                    state.students.length.toString(),
                    Icons.child_care,
                    AppColors.parentPrimaryColor,
                  ),
                ),
                const SizedBox(width: AppSizes.parentSpacingSM),
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelActiveTrips,
                    state.trips.length.toString(),
                    Icons.route,
                    AppColors.parentSuccessColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.parentSpacingSM),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelNotifications,
                    state.notifications.length.toString(),
                    Icons.notifications,
                    AppColors.parentWarningColor,
                  ),
                ),
                const SizedBox(width: AppSizes.parentSpacingSM),
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelAttendance,
                    AppConstants.labelAttendancePercent,
                    Icons.check_circle,
                    AppColors.parentPurpleColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.parentStatCardPadding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppSizes.parentStatBgOpacity),
        borderRadius: BorderRadius.circular(AppSizes.parentStatBorderRadius),
        border: Border.all(
          color: color.withValues(alpha: AppSizes.parentStatBorderOpacity),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: AppSizes.parentStatIconSize),
          const SizedBox(height: AppSizes.parentSpacingXS),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSizes.parentStatValueFontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: AppSizes.parentStatTitleFontSize),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenStatus(ParentDashboardLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.parentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.labelChildrenStatus,
              style: TextStyle(
                fontSize: AppSizes.parentHeaderFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.parentSpacingMD),
            if (state.students.isEmpty)
              const Text(AppConstants.msgNoChildrenRegistered)
            else
              ...state.students.map((student) => _buildStudentCard(student)),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(dynamic student) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.parentCardMargin),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(student['name']?.substring(0, 1) ?? 'S'),
        ),
        title: Text(student['name'] ?? AppConstants.labelUnknown),
        subtitle: Text('${AppConstants.labelClass} ${student['className'] ?? AppConstants.labelNA}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.parentSpacingSM,
            vertical: AppSizes.parentSpacingXS,
          ),
          decoration: BoxDecoration(
            color: AppColors.parentSuccessColor,
            borderRadius: BorderRadius.circular(AppSizes.parentStatCardPadding),
          ),
          child: const Text(
            AppConstants.labelSafe,
            style: TextStyle(
              color: AppColors.parentTextWhite,
              fontSize: AppSizes.parentStatTitleFontSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentNotifications(ParentDashboardLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.parentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.labelRecentNotifications,
              style: TextStyle(
                fontSize: AppSizes.parentHeaderFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.parentSpacingMD),
            if (state.notifications.isEmpty)
              const Text(AppConstants.msgNoNotifications)
            else
              ...state.notifications.take(3).map((notification) => _buildNotificationCard(notification)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(dynamic notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.parentCardMargin),
      child: ListTile(
        leading: const Icon(Icons.notifications),
        title: Text(notification['title'] ?? AppConstants.labelNotification),
        subtitle: Text(notification['message'] ?? ''),
        trailing: Text(
          notification['time'] ?? '',
          style: const TextStyle(fontSize: AppSizes.parentStatTitleFontSize),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.parentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.labelQuickActions,
              style: TextStyle(
                fontSize: AppSizes.parentHeaderFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.parentSpacingMD),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.enhancedVehicleTracking);
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text(AppConstants.labelTrackVehicle),
                  ),
                ),
                const SizedBox(width: AppSizes.parentSpacingSM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.attendanceHistory);
                    },
                    icon: const Icon(Icons.history),
                    label: Text(AppConstants.labelAttendance),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.parentSpacingSM),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.monthlyReport);
                    },
                    icon: const Icon(Icons.analytics),
                    label: const Text(AppConstants.labelReports),
                  ),
                ),
                const SizedBox(width: AppSizes.parentSpacingSM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Load profile first, then navigate
                      final authState = context.read<AuthBloc>().state;
                      if (authState is AuthAuthenticated && authState.userId != null) {
                        context.read<ParentBloc>().add(
                          ParentProfileRequested(parentId: authState.userId!),
                        );
                      }
                    },
                    icon: const Icon(Icons.person),
                    label: const Text(AppConstants.labelProfile),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ParentError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error,
            size: AppSizes.parentErrorIconSize,
            color: AppColors.parentErrorColor,
          ),
          const SizedBox(height: AppSizes.parentSpacingMD),
          Text(
            state.message,
            style: const TextStyle(fontSize: AppSizes.parentErrorTextSize),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.parentSpacingMD),
          ElevatedButton(
            onPressed: _loadParentData,
            child: Text(AppConstants.actionRetry),
          ),
        ],
      ),
    );
  }
}

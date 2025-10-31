import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/constants.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/school/school_bloc.dart';
import '../../bloc/school/school_event.dart';
import '../../bloc/school/school_state.dart';
import '../../app_routes.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart';

class BlocSchoolAdminDashboard extends StatefulWidget {
  const BlocSchoolAdminDashboard({super.key});

  @override
  State<BlocSchoolAdminDashboard> createState() => _BlocSchoolAdminDashboardState();
}

class _BlocSchoolAdminDashboardState extends State<BlocSchoolAdminDashboard> {
  final WebSocketNotificationService _wsService = WebSocketNotificationService();
  StreamSubscription<WebSocketNotification>? _notificationSubscription;
  StreamSubscription<WebSocketNotification>? _tripUpdateSubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadSchoolData();
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

  void _loadSchoolData() {
    // Get school ID from auth state
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.schoolId != null) {
      context.read<SchoolBloc>().add(
        SchoolDashboardRequested(schoolId: authState.schoolId!),
      );
    } else {
      // If schoolId is not available, show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.msgSchoolIdNotFound),
          backgroundColor: AppColors.schoolAdminErrorColor,
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  void _initializeWebSocket() {
    _wsService.initialize().then((_) {
      debugPrint(AppConstants.msgWebSocketInitializedSchoolAdmin);
      
      // Listen to general notifications
      _notificationSubscription = _wsService.notificationStream.listen(
        (notification) {
          debugPrint('${AppConstants.msgReceivedNotification}${notification.type}');
          _handleNotification(notification);
        },
        onError: (error) {
          debugPrint('${AppConstants.msgNotificationStreamError}$error');
        },
      );

      // Listen to trip updates
      _tripUpdateSubscription = _wsService.tripUpdateStream.listen(
        (notification) {
          debugPrint('${AppConstants.msgReceivedTripUpdate}${notification.message}');
          _refreshDashboard();
        },
        onError: (error) {
          debugPrint('${AppConstants.msgTripUpdateStreamError}$error');
        },
      );
    }).catchError((error) {
      debugPrint('${AppConstants.msgWebSocketInitError}$error');
    });
  }

  void _handleNotification(WebSocketNotification notification) {
    // Only show USER-FACING notifications as SnackBar
    // Internal/system notifications should only refresh data
    final showAsSnackBar = _shouldShowNotificationToUser(notification.type);
    
    if (mounted) {
      if (showAsSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notification.message),
            backgroundColor: _getNotificationColor(notification.type),
            duration: AppDurations.snackbarDefault,
          ),
        );
      }
      
      // Always refresh dashboard data for all notifications
      _refreshDashboard();
    }
  }
  
  bool _shouldShowNotificationToUser(String type) {
    // Define which notification types should be shown as SnackBar
    final userFacingNotifications = [
      AppConstants.notifTypeTripStarted,
      AppConstants.notifTypeTripCompleted,
      AppConstants.notifTypeTripAlert,
      AppConstants.notifTypeStudentAbsentSchool,
      AppConstants.notifTypeDriverDelayed,
      AppConstants.notifTypeEmergencyAlert,
      AppConstants.notifTypeSystemAlert,
    ];
    
    // VEHICLE_ASSIGNMENT_REQUEST should NOT show as SnackBar
    // It will still update the "Pending Requests" badge
    return userFacingNotifications.contains(type.toUpperCase());
  }

  Color _getNotificationColor(String type) {
    switch (type.toUpperCase()) {
      case 'ARRIVAL':
        return AppColors.statusSuccess;
      case 'PICKUP':
        return AppColors.statusInfo;
      case 'DROP':
        return AppColors.statusWarning;
      case 'ALERT':
      case 'SYSTEM_ALERT':
        return AppColors.statusError;
      default:
        return AppColors.textSecondary;
    }
  }

  void _refreshDashboard() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.schoolId != null) {
      context.read<SchoolBloc>().add(
        SchoolDashboardRequested(schoolId: authState.schoolId!),
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
        title: const Text(AppConstants.labelSchoolAdminDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutConfirmation,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: BlocListener<SchoolBloc, SchoolState>(
        listener: (context, state) {
          if (state is SchoolActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.schoolAdminSuccessColor,
              ),
            );
          } else if (state is SchoolProfileLoaded) {
            // Navigate to profile page
            Navigator.pushNamed(
              context,
              AppRoutes.schoolProfile,
            ).then((_) {
              // Reload dashboard when returning from profile page
              if (mounted) {
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthAuthenticated && authState.schoolId != null) {
                  context.read<SchoolBloc>().add(
                    SchoolDashboardRequested(schoolId: authState.schoolId!),
                  );
                }
              }
            });
          } else if (state is SchoolError) {
            if (state.actionType == AppConstants.actionTypeLoadProfile) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.schoolAdminErrorColor,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.schoolAdminErrorColor,
                ),
              );
            }
          }
        },
        child: BlocBuilder<SchoolBloc, SchoolState>(
          builder: (context, state) {
            if (state is SchoolLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SchoolDashboardLoaded) {
              return _buildDashboard(state);
            } else if (state is SchoolProfileLoaded) {
              // If profile loaded but dashboard state lost, reload dashboard
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated && authState.schoolId != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    context.read<SchoolBloc>().add(
                      SchoolDashboardRequested(schoolId: authState.schoolId!),
                    );
                  }
                });
              }
              return const Center(child: CircularProgressIndicator());
            } else if (state is SchoolError && state.actionType != AppConstants.actionTypeLoadProfile) {
              return _buildErrorState(state);
            }
            // Fallback: try to reload dashboard
            final authState = context.read<AuthBloc>().state;
            if (authState is AuthAuthenticated && authState.schoolId != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.read<SchoolBloc>().add(
                    SchoolDashboardRequested(schoolId: authState.schoolId!),
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
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.schoolAdminPrimaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Icon(Icons.school, size: AppSizes.schoolAdminLogoSize, color: AppColors.schoolAdminTextWhite),
                SizedBox(height: AppSizes.schoolAdminSpacingSM),
                Text(
                  AppConstants.labelSchoolAdminMenu,
                  style: TextStyle(
                    color: AppColors.schoolAdminTextWhite,
                    fontSize: AppSizes.schoolAdminMenuFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Dashboard
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text(AppConstants.labelDashboard),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          // School Section
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.schoolAdminPadding,
              vertical: AppSizes.schoolAdminSpacingSM,
            ),
            child: Text(
              AppConstants.labelSchool,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.schoolAdminGreyColor,
              ),
            ),
          ),
          BlocListener<SchoolBloc, SchoolState>(
            listener: (context, state) {
              if (state is SchoolProfileLoaded) {
                // Navigation handled in main BlocListener
              } else if (state is SchoolError && state.actionType == AppConstants.actionTypeLoadProfile) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.schoolAdminErrorColor,
                  ),
                );
              }
            },
            child: BlocBuilder<SchoolBloc, SchoolState>(
              builder: (context, state) {
                return ListTile(
                  leading: const Icon(Icons.school),
                  title: const Text(AppConstants.labelSchoolProfile),
                  onTap: () {
                    Navigator.pop(context);
                    // Load profile first, then navigate
                    final authState = context.read<AuthBloc>().state;
                    if (authState is AuthAuthenticated && authState.schoolId != null) {
                      context.read<SchoolBloc>().add(
                        SchoolProfileRequested(schoolId: authState.schoolId!),
                      );
                    }
                  },
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text(AppConstants.labelStudents),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.studentManagement);
            },
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text(AppConstants.labelBulkStudentImport),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.bulkStudentImport);
            },
          ),
          ListTile(
            leading: const Icon(Icons.class_),
            title: const Text(AppConstants.labelClassManagement),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.classManagement);
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text(AppConstants.labelSectionManagement),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.sectionManagement);
            },
          ),
          const Divider(),
          // People Section
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.schoolAdminPadding,
              vertical: AppSizes.schoolAdminSpacingSM,
            ),
            child: Text(
              AppConstants.labelPeople,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.schoolAdminGreyColor,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.work),
            title: const Text(AppConstants.labelStaff),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.staffManagement);
            },
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text(AppConstants.labelVehicleOwners),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.vehicleOwnerManagement);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text(AppConstants.labelDrivers),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.driverManagement);
            },
          ),
          ListTile(
            leading: const Icon(Icons.family_restroom),
            title: const Text(AppConstants.labelParents),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.parentManagement);
            },
          ),
          const Divider(),
          // Transport Section
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.schoolAdminPadding,
              vertical: AppSizes.schoolAdminSpacingSM,
            ),
            child: Text(
              AppConstants.labelTransport,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.schoolAdminGreyColor,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.directions_bus),
            title: const Text(AppConstants.labelVehicles),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.vehicleManagement);
            },
          ),
          ListTile(
            leading: const Icon(Icons.route),
            title: const Text(AppConstants.labelTrips),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.trips);
            },
          ),
          const Divider(),
          // Reports Section
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.schoolAdminPadding,
              vertical: AppSizes.schoolAdminSpacingSM,
            ),
            child: Text(
              AppConstants.labelReports,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.schoolAdminGreyColor,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.assessment),
            title: const Text(AppConstants.labelReports),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.schoolReports);
            },
          ),
          const Divider(),
          // Requests Section
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.schoolAdminPadding,
              vertical: AppSizes.schoolAdminSpacingSM,
            ),
            child: Text(
              AppConstants.labelApprovals,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.schoolAdminGreyColor,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.pending_actions, color: AppColors.schoolAdminWarningColor),
            title: const Text(AppConstants.labelPendingRequests),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.schoolAdminBadgePaddingH,
                vertical: AppSizes.schoolAdminBadgePaddingV,
              ),
              decoration: BoxDecoration(
                color: AppColors.schoolAdminWarningColor,
                borderRadius: BorderRadius.circular(AppSizes.schoolAdminBadgeRadius),
              ),
              child: const Text(
                AppConstants.labelNew,
                style: TextStyle(
                  color: AppColors.schoolAdminTextWhite,
                  fontSize: AppSizes.schoolAdminBadgeFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.pendingRequests);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(SchoolDashboardLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadSchoolData();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.schoolAdminPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats
            _buildQuickStats(state),
            const SizedBox(height: AppSizes.schoolAdminSpacingMD),

            // Recent Activities
            _buildRecentActivities(state),
            const SizedBox(height: AppSizes.schoolAdminSpacingMD),

            // Quick Actions
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(SchoolDashboardLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.schoolAdminPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.labelQuickStats,
              style: TextStyle(fontSize: AppSizes.schoolAdminHeaderFontSize, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.schoolAdminSpacingMD),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelStudents,
                    state.students.length.toString(),
                    Icons.people,
                    AppColors.schoolAdminPrimaryColor,
                  ),
                ),
                const SizedBox(width: AppSizes.schoolAdminSpacingSM),
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelStaff,
                    state.staff.length.toString(),
                    Icons.work,
                    AppColors.schoolAdminSuccessColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.schoolAdminSpacingSM),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelVehicles,
                    state.vehicles.length.toString(),
                    Icons.directions_bus,
                    AppColors.schoolAdminWarningColor,
                  ),
                ),
                const SizedBox(width: AppSizes.schoolAdminSpacingSM),
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelActiveTrips,
                    state.trips.length.toString(),
                    Icons.route,
                    AppColors.schoolAdminPurpleColor,
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
      padding: const EdgeInsets.all(AppSizes.schoolAdminStatCardPadding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppSizes.schoolAdminStatBgOpacity),
        borderRadius: BorderRadius.circular(AppSizes.schoolAdminStatBorderRadius),
        border: Border.all(color: color.withValues(alpha: AppSizes.schoolAdminStatBorderOpacity)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: AppSizes.schoolAdminStatIconSize),
          const SizedBox(height: AppSizes.schoolAdminSpacingXS),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSizes.schoolAdminStatValueFontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: AppSizes.schoolAdminStatTitleFontSize),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(SchoolDashboardLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.schoolAdminPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              AppConstants.labelRecentActivities,
              style: TextStyle(fontSize: AppSizes.schoolAdminHeaderFontSize, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: AppSizes.schoolAdminSpacingMD),
            // This would show recent activities from the dashboard data
            Text(AppConstants.msgNoRecentActivities),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.schoolAdminPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.labelQuickActions,
              style: TextStyle(fontSize: AppSizes.schoolAdminHeaderFontSize, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.schoolAdminSpacingMD),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.registerStudent);
                    },
                    icon: const Icon(Icons.person_add),
                    label: Text(AppConstants.labelAddStudent),
                  ),
                ),
                const SizedBox(width: AppSizes.schoolAdminSpacingSM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.registerVehicleOwner);
                    },
                    icon: const Icon(Icons.business),
                    label: Text(AppConstants.labelAddVehicleOwner),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.schoolAdminSpacingSM),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.registerStaff);
                    },
                    icon: const Icon(Icons.badge),
                    label: Text(AppConstants.labelAddStaff),
                  ),
                ),
                const SizedBox(width: AppSizes.schoolAdminSpacingSM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.createTrip);
                    },
                    icon: const Icon(Icons.route),
                    label: Text(AppConstants.labelCreateTrip),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.schoolAdminSpacingSM),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.pendingRequests);
                    },
                    icon: const Icon(Icons.pending_actions),
                    label: Text(AppConstants.labelViewPendingRequests),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.schoolAdminWarningColor,
                      foregroundColor: AppColors.schoolAdminTextWhite,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(SchoolError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: AppSizes.schoolAdminErrorIconSize, color: AppColors.schoolAdminErrorColor),
          const SizedBox(height: AppSizes.schoolAdminSpacingMD),
          Text(
            state.message,
            style: const TextStyle(fontSize: AppSizes.schoolAdminErrorTextSize),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.schoolAdminSpacingMD),
          ElevatedButton(
            onPressed: _loadSchoolData,
            child: Text(AppConstants.actionRetry),
          ),
        ],
      ),
    );
  }
}

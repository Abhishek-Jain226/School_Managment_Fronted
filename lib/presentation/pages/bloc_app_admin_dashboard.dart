import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/constants.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/app_admin/app_admin_bloc.dart';
import '../../bloc/app_admin/app_admin_event.dart';
import '../../bloc/app_admin/app_admin_state.dart';
import '../../app_routes.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart';

class BlocAppAdminDashboard extends StatefulWidget {
  const BlocAppAdminDashboard({super.key});

  @override
  State<BlocAppAdminDashboard> createState() => _BlocAppAdminDashboardState();
}

class _BlocAppAdminDashboardState extends State<BlocAppAdminDashboard> {
  final WebSocketNotificationService _wsService = WebSocketNotificationService();
  StreamSubscription<WebSocketNotification>? _notificationSubscription;
  StreamSubscription<WebSocketNotification>? _systemAlertSubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAppAdminData();
    _initializeWebSocket();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _systemAlertSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadAppAdminData() {
    context.read<AppAdminBloc>().add(const AppAdminDashboardRequested());
  }

  void _initializeWebSocket() {
    _wsService.initialize().then((_) {
      debugPrint(AppConstants.msgWebSocketInitialized);
      
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

      // Listen to system alerts (important for App Admin)
      _systemAlertSubscription = _wsService.systemAlertStream.listen(
        (notification) {
          debugPrint('${AppConstants.msgReceivedSystemAlert}${notification.message}');
          _handleSystemAlert(notification);
        },
        onError: (error) {
          debugPrint('${AppConstants.msgSystemAlertStreamError}$error');
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
            duration: AppDurations.snackbarDefault,
          ),
        );
      }
      
      // Always refresh dashboard data
      _refreshDashboard();
    }
  }
  
  bool _shouldShowNotificationToUser(String type) {
    // App Admin sees system-wide important notifications only
    final userFacingNotifications = [
      AppConstants.notifTypeNewSchoolRegistration,
      AppConstants.notifTypeSystemError,
      AppConstants.notifTypeEmergencyAlert,
      AppConstants.notifTypeDatabaseBackup,
    ];
    
    return userFacingNotifications.contains(type.toUpperCase());
  }

  void _handleSystemAlert(WebSocketNotification notification) {
    // Show critical system alerts as dialogs
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: AppColors.appAdminErrorColor),
              SizedBox(width: AppSizes.appAdminSpacingSM),
              Text(AppConstants.labelSystemAlert),
            ],
          ),
          content: Text(notification.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppConstants.labelDismiss),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to relevant page based on alert type
              },
              child: const Text(AppConstants.labelViewDetails),
            ),
          ],
        ),
      );
      _refreshDashboard();
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toUpperCase()) {
      case AppConstants.notifTypeSystemAlert:
      case AppConstants.notifTypeAlert:
        return AppColors.statusError;
      case AppConstants.notifTypeInfo:
        return AppColors.statusInfo;
      case AppConstants.notifTypeSuccess:
        return AppColors.statusSuccess;
      default:
        return AppColors.textSecondary;
    }
  }

  void _refreshDashboard() {
    context.read<AppAdminBloc>().add(const AppAdminDashboardRequested());
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
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.labelAppAdminDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutConfirmation,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: BlocListener<AppAdminBloc, AppAdminState>(
        listener: (context, state) {
          if (state is AppAdminActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.appAdminSuccessColor,
              ),
            );
          } else if (state is AppAdminProfileLoaded) {
            // Navigate to profile page
            Navigator.pushNamed(
              context,
              AppRoutes.appAdminProfile,
            ).then((_) {
              // Reload dashboard when returning from profile page
              if (mounted) {
                context.read<AppAdminBloc>().add(
                  const AppAdminDashboardRequested(),
                );
              }
            });
          } else if (state is AppAdminError) {
            if (state.actionType == AppConstants.actionTypeLoadProfile) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.appAdminErrorColor,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.appAdminErrorColor,
                ),
              );
            }
          }
        },
        child: BlocBuilder<AppAdminBloc, AppAdminState>(
          builder: (context, state) {
            if (state is AppAdminLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is AppAdminDashboardLoaded) {
              return _buildDashboard(state);
            } else if (state is AppAdminProfileLoaded) {
              // If profile loaded but dashboard state lost, reload dashboard
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.read<AppAdminBloc>().add(
                    const AppAdminDashboardRequested(),
                  );
                }
              });
              return const Center(child: CircularProgressIndicator());
            } else if (state is AppAdminError && state.actionType != AppConstants.actionTypeLoadProfile) {
              return _buildErrorState(state);
            }
            // Fallback: try to reload dashboard
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.read<AppAdminBloc>().add(
                  const AppAdminDashboardRequested(),
                );
              }
            });
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
            decoration: BoxDecoration(color: AppColors.appAdminPrimaryColor),
            child: Text(
              AppConstants.labelAppAdminMenu,
              style: TextStyle(
                color: AppColors.appAdminTextWhite,
                fontSize: AppSizes.appAdminMenuFontSize,
              ),
            ),
          ),
          BlocListener<AppAdminBloc, AppAdminState>(
            listener: (context, state) {
              if (state is AppAdminProfileLoaded) {
                // Navigation handled in main BlocListener
              } else if (state is AppAdminError && state.actionType == AppConstants.actionTypeLoadProfile) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.appAdminErrorColor,
                  ),
                );
              }
            },
            child: BlocBuilder<AppAdminBloc, AppAdminState>(
              builder: (context, state) {
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text(AppConstants.labelProfile),
                  onTap: () {
                    Navigator.pop(context);
                    // Load profile first, then navigate
                    context.read<AppAdminBloc>().add(
                      const AppAdminProfileRequested(),
                    );
                  },
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text(AppConstants.labelSchoolManagement),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.appAdminSchoolManagement);
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text(AppConstants.labelSystemReports),
            onTap: () {
              Navigator.pop(context);
              // Add system reports route
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(AppAdminDashboardLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadAppAdminData();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.appAdminPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // System Stats
            _buildSystemStats(state),
            const SizedBox(height: AppSizes.appAdminPadding),

            // Schools Overview
            _buildSchoolsOverview(state),
            const SizedBox(height: AppSizes.appAdminPadding),

            // Quick Actions
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStats(AppAdminDashboardLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.appAdminPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.labelSystemStatistics,
              style: TextStyle(
                fontSize: AppSizes.appAdminHeaderFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.appAdminPadding),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelTotalSchools,
                    state.schools.length.toString(),
                    Icons.school,
                    AppColors.appAdminPrimaryColor,
                  ),
                ),
                const SizedBox(width: AppSizes.appAdminSpacingSM),
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelActive,
                    state.schools.where((s) => s[AppConstants.keyIsActive] == true).length.toString(),
                    Icons.check_circle,
                    AppColors.appAdminSuccessColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.appAdminSpacingSM),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelTotalUsers,
                    state.systemStats[AppConstants.keyTotalUsers]?.toString() ?? '0',
                    Icons.people,
                    AppColors.appAdminWarningColor,
                  ),
                ),
                const SizedBox(width: AppSizes.appAdminSpacingSM),
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelActiveSessions,
                    state.systemStats[AppConstants.keyActiveSessions]?.toString() ?? '0',
                    Icons.online_prediction,
                    AppColors.appAdminPurpleColor,
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
      padding: const EdgeInsets.all(AppSizes.appAdminStatCardPadding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppSizes.appAdminStatBgOpacity),
        borderRadius: BorderRadius.circular(AppSizes.appAdminStatBorderRadius),
        border: Border.all(
          color: color.withValues(alpha: AppSizes.appAdminStatBorderOpacity),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: AppSizes.appAdminStatIconSize),
          const SizedBox(height: AppSizes.appAdminSpacingXS),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSizes.appAdminStatValueFontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: AppSizes.appAdminStatTitleFontSize),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolsOverview(AppAdminDashboardLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.appAdminPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  AppConstants.labelSchoolsOverview,
                  style: TextStyle(
                    fontSize: AppSizes.appAdminHeaderFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.appAdminSchoolManagement);
                  },
                  child: const Text(AppConstants.labelViewAll),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.appAdminPadding),
            if (state.schools.isEmpty)
              const Text(AppConstants.msgNoSchoolsRegistered)
            else
              ...state.schools.take(3).map((school) => _buildSchoolCard(school)),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolCard(dynamic school) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.appAdminSchoolCardMargin),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: school[AppConstants.keyIsActive] == true 
              ? AppColors.appAdminSuccessColor 
              : AppColors.appAdminErrorColor,
          child: Icon(
            school[AppConstants.keyIsActive] == true ? Icons.check : Icons.close,
            color: AppColors.appAdminTextWhite,
          ),
        ),
        title: Text(school[AppConstants.keySchoolName] ?? AppConstants.defaultUnknownSchool),
        subtitle: Text('${AppConstants.labelID} ${school[AppConstants.keySchoolId] ?? AppConstants.labelNA}'),
        trailing: Text(
          school[AppConstants.keyIsActive] == true 
              ? AppConstants.labelActive 
              : AppConstants.labelInactive,
          style: TextStyle(
            color: school[AppConstants.keyIsActive] == true 
                ? AppColors.appAdminSuccessColor 
                : AppColors.appAdminErrorColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.appAdminPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.labelQuickActions,
              style: TextStyle(
                fontSize: AppSizes.appAdminHeaderFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.appAdminPadding),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.appAdminSchoolManagement);
                    },
                    icon: const Icon(Icons.school),
                    label: const Text(AppConstants.labelManageSchools),
                  ),
                ),
                const SizedBox(width: AppSizes.appAdminSpacingSM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Load profile first, then navigate
                    context.read<AppAdminBloc>().add(
                      const AppAdminProfileRequested(),
                    );
                    },
                    icon: const Icon(Icons.person),
                    label: const Text(AppConstants.labelProfile),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.appAdminSpacingSM),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Add system reports functionality
                    },
                    icon: const Icon(Icons.analytics),
                    label: const Text(AppConstants.labelSystemReports),
                  ),
                ),
                const SizedBox(width: AppSizes.appAdminSpacingSM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Add system settings functionality
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text(AppConstants.labelSettings),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(AppAdminError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error,
            size: AppSizes.appAdminErrorIconSize,
            color: AppColors.appAdminErrorColor,
          ),
          const SizedBox(height: AppSizes.appAdminPadding),
          Text(
            state.message,
            style: const TextStyle(fontSize: AppSizes.appAdminErrorTextSize),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.appAdminPadding),
          ElevatedButton(
            onPressed: _loadAppAdminData,
            child: const Text(AppConstants.labelRetry),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/vehicle_owner/vehicle_owner_bloc.dart';
import '../../bloc/vehicle_owner/vehicle_owner_event.dart';
import '../../bloc/vehicle_owner/vehicle_owner_state.dart';
import '../../app_routes.dart';
import '../widgets/school_selector.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart';

class BlocVehicleOwnerDashboard extends StatefulWidget {
  const BlocVehicleOwnerDashboard({super.key});

  @override
  State<BlocVehicleOwnerDashboard> createState() => _BlocVehicleOwnerDashboardState();
}

class _BlocVehicleOwnerDashboardState extends State<BlocVehicleOwnerDashboard> {
  int? _currentSchoolId;
  String? _currentSchoolName;
  String? _ownerName;
  String? _ownerEmail;
  
  final WebSocketNotificationService _wsService = WebSocketNotificationService();
  StreamSubscription<WebSocketNotification>? _notificationSubscription;
  StreamSubscription<WebSocketNotification>? _tripUpdateSubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadCurrentSchool();
    _loadOwnerInfo();
    _loadVehicleOwnerData();
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

  Future<void> _loadCurrentSchool() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentSchoolId = prefs.getInt('currentSchoolId');
      _currentSchoolName = prefs.getString('currentSchoolName');
    });
  }

  Future<void> _loadOwnerInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ownerName = prefs.getString('userName');
      _ownerEmail = prefs.getString('email');
    });
  }

  void _onSchoolSelected(int? schoolId, String? schoolName) async {
    final prefs = await SharedPreferences.getInstance();
    if (schoolId != null) {
      await prefs.setInt('currentSchoolId', schoolId);
      await prefs.setString('currentSchoolName', schoolName ?? '');
    } else {
      await prefs.remove('currentSchoolId');
      await prefs.remove('currentSchoolName');
    }
    
    setState(() {
      _currentSchoolId = schoolId;
      _currentSchoolName = schoolName;
    });

    // Reload dashboard data for the selected school
    _loadVehicleOwnerData();
  }

  void _loadVehicleOwnerData() {
    // Get owner ID from auth state
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.ownerId != null) {
      context.read<VehicleOwnerBloc>().add(
        VehicleOwnerDashboardRequested(ownerId: authState.ownerId!),
      );
    } else {
      // If ownerId is not available, show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.msgOwnerIdNotFound),
          backgroundColor: AppColors.vehicleOwnerErrorColor,
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  void _initializeWebSocket() {
    _wsService.initialize().then((_) {
      debugPrint(AppConstants.msgWebSocketInitializedVehicleOwner);
      
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
    // Define which notification types should be shown to Vehicle Owner
    final userFacingNotifications = [
      AppConstants.notifTypeVehicleAssignmentApproved,
      AppConstants.notifTypeVehicleAssignmentRejected,
      AppConstants.notifTypeTripStarted,
      AppConstants.notifTypeTripCompleted,
      AppConstants.notifTypeDriverAlert,
      AppConstants.notifTypeEmergencyAlert,
    ];
    
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
    if (authState is AuthAuthenticated && authState.ownerId != null) {
      context.read<VehicleOwnerBloc>().add(
        VehicleOwnerDashboardRequested(ownerId: authState.ownerId!),
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
        title: const Text(AppConstants.labelVehicleOwnerDashboard),
        actions: [
          // School Selector
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.vehicleOwnerTooltipPaddingRight),
            child: SchoolSelector(
              onSchoolSelected: _onSchoolSelected,
              currentSchoolId: _currentSchoolId,
            ),
          ),

          // Logout Icon
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutConfirmation,
            tooltip: AppConstants.labelLogout,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: BlocListener<VehicleOwnerBloc, VehicleOwnerState>(
        listener: (context, state) {
          if (state is VehicleOwnerActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.vehicleOwnerSuccessColor,
              ),
            );
          } else if (state is VehicleOwnerProfileLoaded) {
            // Navigate to profile page
            Navigator.pushNamed(
              context,
              AppRoutes.vehicleOwnerProfile,
              arguments: state.profile['data']?['ownerId'] ?? state.profile['ownerId'],
            ).then((_) {
              // Reload dashboard when returning from profile page
              if (mounted) {
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthAuthenticated && authState.ownerId != null) {
                  context.read<VehicleOwnerBloc>().add(
                    VehicleOwnerDashboardRequested(ownerId: authState.ownerId!),
                  );
                }
              }
            });
          } else if (state is VehicleOwnerError) {
            if (state.actionType == AppConstants.actionTypeLoadProfile) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.vehicleOwnerErrorColor,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.vehicleOwnerErrorColor,
                ),
              );
            }
          }
        },
        child: BlocBuilder<VehicleOwnerBloc, VehicleOwnerState>(
          builder: (context, state) {
            if (state is VehicleOwnerLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is VehicleOwnerDashboardLoaded) {
              return _buildDashboard(state);
            } else if (state is VehicleOwnerProfileLoaded) {
              // If profile loaded but dashboard state lost, reload dashboard
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated && authState.ownerId != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    context.read<VehicleOwnerBloc>().add(
                      VehicleOwnerDashboardRequested(ownerId: authState.ownerId!),
                    );
                  }
                });
              }
              return const Center(child: CircularProgressIndicator());
            } else if (state is VehicleOwnerError && state.actionType != AppConstants.actionTypeLoadProfile) {
              return _buildErrorState(state);
            }
            // Fallback: try to reload dashboard
            final authState = context.read<AuthBloc>().state;
            if (authState is AuthAuthenticated && authState.ownerId != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.read<VehicleOwnerBloc>().add(
                    VehicleOwnerDashboardRequested(ownerId: authState.ownerId!),
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
            decoration: const BoxDecoration(color: AppColors.vehicleOwnerPrimaryColor),
            child: Text(
              AppConstants.labelVehicleOwnerMenu,
              style: const TextStyle(
                color: AppColors.vehicleOwnerTextWhite,
                fontSize: AppSizes.vehicleOwnerMenuFontSize,
              ),
            ),
          ),
          BlocListener<VehicleOwnerBloc, VehicleOwnerState>(
            listener: (context, state) {
              if (state is VehicleOwnerProfileLoaded) {
                // Navigation handled in main BlocListener
              } else if (state is VehicleOwnerError && state.actionType == AppConstants.actionTypeLoadProfile) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.vehicleOwnerErrorColor,
                  ),
                );
              }
            },
            child: BlocBuilder<VehicleOwnerBloc, VehicleOwnerState>(
              builder: (context, state) {
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text(AppConstants.labelProfile),
                  onTap: () {
                    Navigator.pop(context);
                    // Load profile first, then navigate
                    final authState = context.read<AuthBloc>().state;
                    if (authState is AuthAuthenticated && authState.ownerId != null) {
                      context.read<VehicleOwnerBloc>().add(
                        VehicleOwnerProfileRequested(ownerId: authState.ownerId!),
                      );
                    }
                  },
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.directions_bus),
            title: const Text(AppConstants.labelVehicles),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.vehicleOwnerVehicleManagement);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text(AppConstants.labelDrivers),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.vehicleOwnerDriverManagement);
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment_ind),
            title: const Text(AppConstants.labelDriverAssignment),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.vehicleOwnerDriverAssignment);
            },
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text(AppConstants.labelSchoolMapping),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.requestVehicle);
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment_ind),
            title: const Text(AppConstants.labelStudentTripAssignment),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.vehicleOwnerStudentTripAssignment);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(VehicleOwnerDashboardLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadVehicleOwnerData();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.vehicleOwnerPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats
            _buildQuickStats(state),
            const SizedBox(height: AppSizes.vehicleOwnerSpacingMD),

            // Recent Activities
            _buildRecentActivities(state),
            const SizedBox(height: AppSizes.vehicleOwnerSpacingMD),

            // Quick Actions
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(VehicleOwnerDashboardLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.vehicleOwnerPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.labelQuickStats,
              style: TextStyle(fontSize: AppSizes.vehicleOwnerHeaderFontSize, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.vehicleOwnerSpacingMD),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelVehicles,
                    state.vehicles.length.toString(),
                    Icons.directions_bus,
                    AppColors.vehicleOwnerPrimaryColor,
                  ),
                ),
                const SizedBox(width: AppSizes.vehicleOwnerSpacingSM),
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelDrivers,
                    state.drivers.length.toString(),
                    Icons.people,
                    AppColors.vehicleOwnerSuccessColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.vehicleOwnerSpacingSM),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelActiveTrips,
                    state.trips.length.toString(),
                    Icons.route,
                    AppColors.vehicleOwnerWarningColor,
                  ),
                ),
                const SizedBox(width: AppSizes.vehicleOwnerSpacingSM),
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelTotalRevenue,
                    '₹0',
                    Icons.monetization_on,
                    AppColors.vehicleOwnerPurpleColor,
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
      padding: const EdgeInsets.all(AppSizes.vehicleOwnerStatCardPadding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppSizes.vehicleOwnerStatBgOpacity),
        borderRadius: BorderRadius.circular(AppSizes.vehicleOwnerStatBorderRadius),
        border: Border.all(color: color.withValues(alpha: AppSizes.vehicleOwnerStatBorderOpacity)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: AppSizes.vehicleOwnerStatIconSize),
          const SizedBox(height: AppSizes.vehicleOwnerSpacingXS),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSizes.vehicleOwnerStatValueFontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: AppSizes.vehicleOwnerStatTitleFontSize),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(VehicleOwnerDashboardLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.vehicleOwnerPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              AppConstants.labelRecentActivities,
              style: TextStyle(fontSize: AppSizes.vehicleOwnerHeaderFontSize, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: AppSizes.vehicleOwnerSpacingMD),
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
        padding: const EdgeInsets.all(AppSizes.vehicleOwnerPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.labelQuickActions,
              style: TextStyle(fontSize: AppSizes.vehicleOwnerHeaderFontSize, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.vehicleOwnerSpacingMD),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.registerVehicle);
                    },
                    icon: const Icon(Icons.directions_bus),
                    label: Text(AppConstants.labelAddVehicle),
                  ),
                ),
                const SizedBox(width: AppSizes.vehicleOwnerSpacingSM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.registerDriver);
                    },
                    icon: const Icon(Icons.person_add),
                    label: Text(AppConstants.labelAddDriver),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.vehicleOwnerSpacingSM),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.vehicleOwnerDriverAssignment);
                    },
                    icon: const Icon(Icons.assignment),
                    label: Text(AppConstants.labelAssignDriver),
                  ),
                ),
                const SizedBox(width: AppSizes.vehicleOwnerSpacingSM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.requestVehicle);
                    },
                    icon: const Icon(Icons.send),
                    label: Text(AppConstants.labelRequestSchoolAssignment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vehicleOwnerWarningColor,
                      foregroundColor: AppColors.vehicleOwnerTextWhite,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.vehicleOwnerSpacingSM),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.vehicleOwnerTripAssignment);
                    },
                    icon: const Icon(Icons.route),
                    label: Text(AppConstants.labelManageTrips),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(VehicleOwnerError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: AppSizes.vehicleOwnerErrorIconSize, color: AppColors.vehicleOwnerErrorColor),
          const SizedBox(height: AppSizes.vehicleOwnerSpacingMD),
          Text(
            state.message,
            style: const TextStyle(fontSize: AppSizes.vehicleOwnerErrorTextSize),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.vehicleOwnerSpacingMD),
          ElevatedButton(
            onPressed: _loadVehicleOwnerData,
            child: Text(AppConstants.actionRetry),
          ),
        ],
      ),
    );
  }
}

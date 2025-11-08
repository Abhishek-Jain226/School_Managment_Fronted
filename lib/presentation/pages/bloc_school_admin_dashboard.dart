import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import '../widgets/live_tracking_widget.dart';

class BlocSchoolAdminDashboard extends StatefulWidget {
  const BlocSchoolAdminDashboard({super.key});

  @override
  State<BlocSchoolAdminDashboard> createState() => _BlocSchoolAdminDashboardState();
}

class _BlocSchoolAdminDashboardState extends State<BlocSchoolAdminDashboard> {
  final WebSocketNotificationService _wsService = WebSocketNotificationService();
  StreamSubscription<WebSocketNotification>? _notificationSubscription;
  String? _userName;
  String? _schoolName;
  String? _schoolPhotoBase64;
  Uint8List? _schoolPhotoBytes;
  
  // Live tracking state
  bool _isMapVisible = false;
  bool _mapExpanded = false;
  int? _activeTripId;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadSchoolData();
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final photoBase64 = prefs.getString(AppConstants.keySchoolPhoto);
    Uint8List? photoBytes;
    if (photoBase64 != null && photoBase64.isNotEmpty) {
      photoBytes = _decodeBase64Image(photoBase64);
    }
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString(AppConstants.keyUserName);
      _schoolName = prefs.getString(AppConstants.keySchoolName);
      _schoolPhotoBase64 = photoBase64;
      _schoolPhotoBytes = photoBytes;
    });
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
    }).catchError((error) {
      debugPrint('${AppConstants.msgWebSocketInitError}$error');
    });
  }

  void _handleNotification(WebSocketNotification notification) {
    // Handle trip started notification - show map
    if (notification.type == AppConstants.notificationTypeTripStarted ||
        notification.type == AppConstants.notificationTypeTripUpdate ||
        notification.type == 'LOCATION_UPDATE') {
      if (notification.tripId != null && notification.schoolId != null) {
        // Check if this trip is for the school admin's school
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated && 
            authState.schoolId != null && 
            notification.schoolId == authState.schoolId) {
          // Check if this trip is active in the dashboard
          final currentState = context.read<SchoolBloc>().state;
          if (currentState is SchoolDashboardLoaded) {
            final activeTrip = currentState.trips.firstWhere(
              (trip) => trip['tripId'] == notification.tripId &&
                       (trip['tripStatus'] == 'IN_PROGRESS' || trip['tripStatus'] == 'STARTED'),
              orElse: () => null,
            );
            
            if (activeTrip != null) {
              setState(() {
                _activeTripId = notification.tripId;
                _isMapVisible = true;
                _mapExpanded = false;
              });
            }
          }
        }
      }
    }
    
    // Handle trip completed notification - hide map
    if (notification.type == AppConstants.notificationTypeTripCompleted ||
        (notification.type == AppConstants.notificationTypeTripUpdate &&
         (notification.message.toLowerCase().contains('completed') ||
          notification.message.toLowerCase().contains('ended')))) {
      if (notification.tripId == _activeTripId) {
        setState(() {
          _isMapVisible = false;
          _mapExpanded = false;
          _activeTripId = null;
        });
      }
    }
    
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
        title: const Text(AppConstants.labelSchoolAdmin),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.schoolAdminPadding),
            child: _buildProfileAction(),
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
            _updateSchoolInfoFromData(state.profile, persist: true);
            // Navigate to profile page
            Navigator.pushNamed(
              context,
              AppRoutes.schoolProfile,
            ).then((_) {
              // Reload dashboard when returning from profile page
              if (mounted) {
            _loadUserInfo();
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
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _syncSchoolInfoFromDashboard(state.dashboard);
                  _checkActiveTrip(state);
                }
              });
              return _buildDashboardWithTracking(state);
            } else if (state is SchoolRefreshing &&
                state.dashboard != null &&
                state.students != null &&
                state.staff != null &&
                state.vehicles != null &&
                state.trips != null &&
                state.notifications != null) {
              final loadingState = SchoolDashboardLoaded(
                dashboard: state.dashboard!,
                students: state.students!,
                staff: state.staff!,
                vehicles: state.vehicles!,
                trips: state.trips!,
                notifications: state.notifications!,
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _syncSchoolInfoFromDashboard(state.dashboard!);
                }
              });
              return Stack(
                children: [
                  _buildDashboardWithTracking(loadingState),
                  const Positioned(
                    top: AppSizes.schoolAdminSpacingMD,
                    right: AppSizes.schoolAdminSpacingMD,
                    child: CircularProgressIndicator(),
                  ),
                ],
              );
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

  Widget _buildProfileAction() {
    final displayName = (_userName?.trim().isNotEmpty == true)
        ? _userName!.trim()
        : AppConstants.labelSchoolAdmin;
    final schoolDisplayName = (_schoolName?.trim().isNotEmpty == true)
        ? _schoolName!.trim()
        : AppConstants.labelSchoolName;

    return GestureDetector(
      onTap: _onProfileTapped,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: AppSizes.schoolAdminAvatarRadius,
            backgroundColor: AppColors.schoolAdminPrimaryColor,
            backgroundImage: _schoolPhotoBytes != null ? MemoryImage(_schoolPhotoBytes!) : null,
            child: _schoolPhotoBytes == null
                ? const Icon(
                    Icons.person,
                    color: AppColors.schoolAdminTextWhite,
                  )
                : null,
          ),
          const SizedBox(width: AppSizes.schoolAdminSpacingSM),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                schoolDisplayName,
                style: const TextStyle(
                  fontSize: AppSizes.textSM,
                  color: AppColors.schoolAdminGreyColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onProfileTapped() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.schoolId != null) {
      context.read<SchoolBloc>().add(
        SchoolProfileRequested(schoolId: authState.schoolId!),
      );
    }
  }

  Uint8List? _decodeBase64Image(String data) {
    try {
      final sanitized = data.contains(',') ? data.split(',').last : data;
      return base64Decode(sanitized);
    } catch (e) {
      debugPrint('${AppConstants.msgErrorDecodingImage}$e');
      return null;
    }
  }

  void _updateSchoolInfoFromData(
    Map<String, dynamic> data, {
    bool persist = false,
  }) {
    final name = _findStringValue(data, AppConstants.keySchoolName);
    final photoBase64 = _findStringValue(data, AppConstants.keySchoolPhoto);

    bool shouldUpdateState = false;
    String? updatedName = _schoolName;
    String? updatedPhotoBase64 = _schoolPhotoBase64;
    Uint8List? updatedPhotoBytes = _schoolPhotoBytes;

    if (name != null && name != _schoolName) {
      updatedName = name;
      shouldUpdateState = true;
    }

    if (photoBase64 != null && photoBase64.isNotEmpty && photoBase64 != _schoolPhotoBase64) {
      final decoded = _decodeBase64Image(photoBase64);
      if (decoded != null) {
        updatedPhotoBase64 = photoBase64;
        updatedPhotoBytes = decoded;
        shouldUpdateState = true;
      }
    }

    if (shouldUpdateState && mounted) {
      setState(() {
        _schoolName = updatedName;
        _schoolPhotoBase64 = updatedPhotoBase64;
        _schoolPhotoBytes = updatedPhotoBytes;
      });
    }

    if (persist && (name != null || photoBase64 != null)) {
      SharedPreferences.getInstance().then((prefs) {
        if (name != null && name != prefs.getString(AppConstants.keySchoolName)) {
          prefs.setString(AppConstants.keySchoolName, name);
        }
        if (photoBase64 != null && photoBase64.isNotEmpty &&
            photoBase64 != prefs.getString(AppConstants.keySchoolPhoto)) {
          prefs.setString(AppConstants.keySchoolPhoto, photoBase64);
        }
      });
    }
  }

  void _syncSchoolInfoFromDashboard(Map<String, dynamic> dashboard) {
    _updateSchoolInfoFromData(dashboard, persist: true);
  }

  String? _findStringValue(dynamic source, String key) {
    if (source is Map) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      for (final entry in source.entries) {
        final result = _findStringValue(entry.value, key);
        if (result != null) {
          return result;
        }
      }
    } else if (source is Iterable) {
      for (final item in source) {
        final result = _findStringValue(item, key);
        if (result != null) {
          return result;
        }
      }
    }
    return null;
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
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text(AppConstants.actionLogout),
            onTap: () {
              Navigator.pop(context);
              _showLogoutConfirmation();
            },
          ),
        ],
      ),
    );
  }

  void _checkActiveTrip(SchoolDashboardLoaded state) {
    // Check for active trip with status IN_PROGRESS or STARTED
    // School admin sees all active trips, but we'll show tracking for the first active trip
    final activeTrip = state.trips.firstWhere(
      (trip) => trip['tripStatus'] == 'IN_PROGRESS' || trip['tripStatus'] == 'STARTED',
      orElse: () => null,
    );

    if (activeTrip != null) {
      final tripId = activeTrip['tripId'] as int?;
      
      if (tripId != null && tripId != _activeTripId) {
        setState(() {
          _activeTripId = tripId;
          _isMapVisible = true;
          _mapExpanded = false;
        });
      }
    } else {
      // No active trip found
      if (_activeTripId != null) {
        setState(() {
          _isMapVisible = false;
          _mapExpanded = false;
          _activeTripId = null;
        });
      }
    }
  }

  Widget _buildDashboardWithTracking(SchoolDashboardLoaded state) {
    return Stack(
      children: [
        _buildDashboard(state),
        // Live tracking widget overlay
        if (_isMapVisible && _activeTripId != null)
          LiveTrackingWidget(
            tripId: _activeTripId,
            studentId: null, // School admin doesn't need studentId
            onTripCompleted: () {
              setState(() {
                _isMapVisible = false;
                _mapExpanded = false;
                _activeTripId = null;
              });
            },
          ),
      ],
    );
  }

  Widget _buildDashboard(SchoolDashboardLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated && authState.schoolId != null) {
          context.read<SchoolBloc>().add(
            SchoolRefreshRequested(schoolId: authState.schoolId!),
          );
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.schoolAdminPadding),
        physics: const AlwaysScrollableScrollPhysics(),
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
                const SizedBox(width: AppSizes.schoolAdminSpacingSM),
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelNotifications,
                    state.notifications.length.toString(),
                    Icons.notifications,
                    AppColors.schoolAdminInfoColor,
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

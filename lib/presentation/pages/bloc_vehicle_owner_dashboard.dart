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
import '../../bloc/vehicle_owner/vehicle_owner_bloc.dart';
import '../../bloc/vehicle_owner/vehicle_owner_event.dart';
import '../../bloc/vehicle_owner/vehicle_owner_state.dart';
import '../../app_routes.dart';
import '../widgets/school_selector.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart';
import '../widgets/live_tracking_widget.dart';

class BlocVehicleOwnerDashboard extends StatefulWidget {
  const BlocVehicleOwnerDashboard({super.key});

  @override
  State<BlocVehicleOwnerDashboard> createState() => _BlocVehicleOwnerDashboardState();
}

class _BlocVehicleOwnerDashboardState extends State<BlocVehicleOwnerDashboard> {
  int? _currentSchoolId;
  String? _currentSchoolName;
  String? _ownerName;
  String? _ownerPhotoBase64;
  Uint8List? _ownerPhotoBytes;
  
  // Live tracking state
  bool _isMapVisible = false;
  bool _mapExpanded = false;
  int? _activeTripId;
  
  final WebSocketNotificationService _wsService = WebSocketNotificationService();
  StreamSubscription<WebSocketNotification>? _notificationSubscription;
  StreamSubscription<WebSocketNotification>? _tripUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _loadOwnerInfo();
    _loadCurrentSchool();
    _loadVehicleOwnerData();
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _tripUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadOwnerInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final photoBase64 = prefs.getString(AppConstants.keyOwnerPhoto);
    Uint8List? photoBytes;
    if (photoBase64 != null && photoBase64.isNotEmpty) {
      photoBytes = _decodeBase64Image(photoBase64);
    }
    if (!mounted) return;
    setState(() {
      _ownerName = (prefs.getString(AppConstants.keyOwnerName) ??
              prefs.getString(AppConstants.keyUserName))
          ?.trim();
      _ownerPhotoBase64 = photoBase64;
      _ownerPhotoBytes = photoBytes;
    });
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

  void _updateOwnerInfoFromData(Map<String, dynamic> data, {bool persist = false}) {
    final name = _findStringValue(data, AppConstants.keyOwnerName) ??
        _findStringValue(data, AppConstants.keyName);
    final photoBase64 = _findStringValue(data, AppConstants.keyOwnerPhoto);

    bool shouldUpdateState = false;
    String? updatedName = _ownerName;
    String? updatedPhotoBase64 = _ownerPhotoBase64;
    Uint8List? updatedPhotoBytes = _ownerPhotoBytes;

    if (name != null && name != _ownerName) {
      updatedName = name;
      shouldUpdateState = true;
    }

    if (photoBase64 != null && photoBase64.isNotEmpty && photoBase64 != _ownerPhotoBase64) {
      final decoded = _decodeBase64Image(photoBase64);
      if (decoded != null) {
        updatedPhotoBase64 = photoBase64;
        updatedPhotoBytes = decoded;
        shouldUpdateState = true;
      }
    }

    if (shouldUpdateState && mounted) {
      setState(() {
        _ownerName = updatedName;
        _ownerPhotoBase64 = updatedPhotoBase64;
        _ownerPhotoBytes = updatedPhotoBytes;
      });
    }

    if (persist && (name != null || photoBase64 != null)) {
      SharedPreferences.getInstance().then((prefs) {
        if (name != null && name != prefs.getString(AppConstants.keyOwnerName)) {
          prefs.setString(AppConstants.keyOwnerName, name);
        }
        if (photoBase64 != null && photoBase64.isNotEmpty &&
            photoBase64 != prefs.getString(AppConstants.keyOwnerPhoto)) {
          prefs.setString(AppConstants.keyOwnerPhoto, photoBase64);
        }
      });
    }
  }

  Future<void> _loadCurrentSchool() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentSchoolId = prefs.getInt(AppConstants.keyCurrentSchoolId);
      _currentSchoolName = prefs.getString(AppConstants.keyCurrentSchoolName);
    });
  }

  void _onSchoolSelected(int? schoolId, String? schoolName) async {
    final prefs = await SharedPreferences.getInstance();
    if (schoolId != null) {
      await prefs.setInt(AppConstants.keyCurrentSchoolId, schoolId);
      await prefs.setString(AppConstants.keyCurrentSchoolName, schoolName ?? '');
    } else {
      await prefs.remove(AppConstants.keyCurrentSchoolId);
      await prefs.remove(AppConstants.keyCurrentSchoolName);
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
          _handleNotification(notification);
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
    // Handle trip started notification - show map
    if (notification.type == AppConstants.notificationTypeTripStarted ||
        notification.type == AppConstants.notificationTypeTripUpdate ||
        notification.type == 'LOCATION_UPDATE') {
      if (notification.tripId != null && notification.vehicleId != null) {
        // Check if this trip belongs to the vehicle owner
        final currentState = context.read<VehicleOwnerBloc>().state;
        if (currentState is VehicleOwnerDashboardLoaded) {
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
    final showAsSnackBar = _shouldShowNotificationToUser(notification.type);
    
    if (mounted) {
      if (showAsSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notification.message),
            backgroundColor: _getNotificationColor(notification.type),
            duration: AppDurations.snackbarDefault,
            action: SnackBarAction(
              label: AppConstants.actionRefreshCaps,
              textColor: Colors.white,
              onPressed: _requestRefresh,
            ),
          ),
        );
      }
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

  void _requestRefresh() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.ownerId != null) {
      context.read<VehicleOwnerBloc>().add(
        VehicleOwnerRefreshRequested(ownerId: authState.ownerId!),
      );
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
        leading: _buildMenuAction(),
        titleSpacing: 0,
        title: const Text(AppConstants.labelVehicleOwnerDashboard),
        actions: [
          // School Selector
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.vehicleOwnerTooltipPaddingRight),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: SchoolSelector(
                onSchoolSelected: _onSchoolSelected,
                currentSchoolId: _currentSchoolId,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.vehicleOwnerSpacingSM),
            child: _buildProfileAction(),
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
            _updateOwnerInfoFromData(state.profile, persist: true);
            // Navigate to profile page
            Navigator.pushNamed(
              context,
              AppRoutes.vehicleOwnerProfile,
              arguments: state.profile['data']?['ownerId'] ?? state.profile['ownerId'],
            ).then((_) {
              // Reload dashboard when returning from profile page
              if (mounted) {
                _loadOwnerInfo();
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthAuthenticated && authState.ownerId != null) {
                  context.read<VehicleOwnerBloc>().add(
                    VehicleOwnerRefreshRequested(ownerId: authState.ownerId!),
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
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _updateOwnerInfoFromData(state.dashboard, persist: true);
                  _checkActiveTrip(state);
                }
              });
              return _buildDashboardWithTracking(state);
            } else if (state is VehicleOwnerRefreshing &&
                state.dashboard != null &&
                state.vehicles != null &&
                state.drivers != null &&
                state.trips != null &&
                state.notifications != null) {
              final loadingState = VehicleOwnerDashboardLoaded(
                dashboard: state.dashboard!,
                vehicles: state.vehicles!,
                drivers: state.drivers!,
                trips: state.trips!,
                notifications: state.notifications!,
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _updateOwnerInfoFromData(state.dashboard!, persist: true);
                }
              });
              return Stack(
                children: [
                  _buildDashboardWithTracking(loadingState),
                  const Positioned(
                    top: AppSizes.vehicleOwnerSpacingMD,
                    right: AppSizes.vehicleOwnerSpacingMD,
                    child: CircularProgressIndicator(),
                  ),
                ],
              );
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

  Widget _buildProfileAction() {
    final displayName = (_ownerName?.isNotEmpty == true)
        ? _ownerName!
        : AppConstants.labelVehicleOwner;
    final schoolName = (_currentSchoolName?.isNotEmpty == true)
        ? _currentSchoolName!
        : AppConstants.labelSelectSchool;

    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusMD),
      onTap: _onProfileTapped,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: AppSizes.vehicleOwnerAvatarRadius,
            backgroundColor: AppColors.vehicleOwnerPrimaryColor,
            backgroundImage: _ownerPhotoBytes != null ? MemoryImage(_ownerPhotoBytes!) : null,
            child: _ownerPhotoBytes == null
                ? const Icon(
                    Icons.person,
                    color: AppColors.vehicleOwnerTextWhite,
                  )
                : null,
          ),
          const SizedBox(width: AppSizes.vehicleOwnerSpacingSM),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.vehicleOwnerSpacingXS),
                Row(
                  children: [
                    const Icon(
                      Icons.school,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSizes.vehicleOwnerSpacingXS),
                    Expanded(
                      child: Text(
                        schoolName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuAction() {
    return Builder(
      builder: (context) {
        return IconButton(
          tooltip: AppConstants.labelVehicleOwnerMenu,
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        );
      },
    );
  }

  void _onProfileTapped() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.ownerId != null) {
      context.read<VehicleOwnerBloc>().add(
        VehicleOwnerProfileRequested(ownerId: authState.ownerId!),
      );
    }
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
          const Divider(),
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

  void _checkActiveTrip(VehicleOwnerDashboardLoaded state) {
    // Check for active trip with status IN_PROGRESS or STARTED
    // Vehicle owner sees all their active trips, but we'll show tracking for the first active trip
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

  Widget _buildDashboardWithTracking(VehicleOwnerDashboardLoaded state) {
    return Stack(
      children: [
        _buildDashboard(state),
        // Live tracking widget overlay
        if (_isMapVisible && _activeTripId != null)
          LiveTrackingWidget(
            tripId: _activeTripId,
            studentId: null, // Vehicle owner doesn't need studentId
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

  Widget _buildDashboard(VehicleOwnerDashboardLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        _requestRefresh();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.vehicleOwnerPadding),
        physics: const AlwaysScrollableScrollPhysics(),
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
                    AppConstants.labelNotifications,
                    state.notifications.length.toString(),
                    Icons.notifications,
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

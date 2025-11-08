import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/constants.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/parent/parent_bloc.dart';
import '../../bloc/parent/parent_event.dart';
import '../../bloc/parent/parent_state.dart';
import '../../data/models/parent_dashboard.dart';
import '../../app_routes.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart';
import '../widgets/live_tracking_widget.dart';

class BlocParentDashboard extends StatefulWidget {
  const BlocParentDashboard({super.key});

  @override
  State<BlocParentDashboard> createState() => _BlocParentDashboardState();
}

class _BlocParentDashboardState extends State<BlocParentDashboard> {
  final WebSocketNotificationService _wsService = WebSocketNotificationService();
  StreamSubscription<WebSocketNotification>? _notificationSubscription;
  int? _parentId;
  String? _parentName;
  String? _studentName;
  String? _schoolName;
  String? _parentPhotoBase64;
  Uint8List? _parentPhotoBytes;
  ParentDashboard? _latestDashboard;
  
  // Live tracking state
  bool _isMapVisible = false;
  bool _mapExpanded = false;
  int? _activeTripId;
  int? _activeStudentId;

  @override
  void initState() {
    super.initState();
    _loadParentData();
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _loadParentData() {
    // Get parent ID (userId) from auth state
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.userId != null) {
      _parentId = authState.userId;
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
          debugPrint('🔔 Notification received in dashboard: type=${notification.type}, tripId=${notification.tripId}');
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
    debugPrint('🔔 _handleNotification called: type=${notification.type}, tripId=${notification.tripId}');
    
    // Handle trip started notification - show map and refresh dashboard
    if (notification.type == AppConstants.notificationTypeTripStarted ||
        notification.type == AppConstants.notificationTypeTripUpdate ||
        notification.type == 'LOCATION_UPDATE') {
      if (notification.tripId != null) {
        debugPrint('✅ Setting _activeTripId to ${notification.tripId}');
        
        // Set active trip ID immediately
        setState(() {
          _activeTripId = notification.tripId;
          _activeStudentId = notification.studentId ?? _latestDashboard?.studentId;
          _isMapVisible = true;
          _mapExpanded = false;
        });
        
        debugPrint('✅ _activeTripId set to: $_activeTripId');
        debugPrint('✅ _activeStudentId set to: $_activeStudentId');
        
        // Refresh dashboard to get latest trip data
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated && authState.userId != null) {
          debugPrint('🔄 Refreshing dashboard to get latest trip data...');
          context.read<ParentBloc>().add(
            ParentRefreshRequested(parentId: authState.userId!),
          );
        }
        
        // Also check if this trip is in the current state
        final currentState = context.read<ParentBloc>().state;
        if (currentState is ParentDashboardLoaded) {
          final activeTrip = currentState.trips.firstWhere(
            (trip) => trip['tripId'] == notification.tripId &&
                     (trip['tripStatus'] == 'IN_PROGRESS' || 
                      trip['tripStatus'] == 'STARTED' ||
                      trip['tripStatus'] == 'IN PROGRESS' ||
                      trip['tripStatus'] == ''),
            orElse: () => null,
          );
          
          if (activeTrip == null) {
            // Trip not in current state, refresh will load it
            debugPrint('🔍 Trip ${notification.tripId} not in current state, refreshing dashboard...');
          } else {
            debugPrint('✅ Trip ${notification.tripId} found in current state');
          }
        }
      } else {
        debugPrint('⚠️ Notification has no tripId');
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
            duration: const Duration(seconds: AppSizes.parentNotificationDurationSeconds),
            action: SnackBarAction(
              label: AppConstants.labelView,
              textColor: AppColors.parentTextWhite,
              onPressed: () {
                // Navigate to vehicle tracking with active trip info
                final currentState = context.read<ParentBloc>().state;
                if (currentState is ParentDashboardLoaded && _activeTripId != null) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.enhancedVehicleTracking,
                    arguments: {
                      'tripId': _activeTripId,
                      'studentId': _activeStudentId ?? currentState.dashboard.studentId,
                    },
                  );
                } else {
                  Navigator.pushNamed(context, AppRoutes.enhancedVehicleTracking);
                }
              },
            ),
          ),
        );
      }
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
    final notificationType = type.toUpperCase();
    switch (notificationType) {
      case 'TRIP_STARTED':
      case 'TRIP_START':
        return AppColors.parentSuccessColor;
      case 'TRIP_COMPLETED':
      case 'TRIP_ENDED':
        return AppColors.parentSuccessColor;
      case 'ARRIVAL_NOTIFICATION':
      case 'ARRIVAL_ALERT':
      case 'ARRIVAL':
        return AppColors.parentWarningColor;
      case 'PICKUP_FROM_PARENT':
      case 'PICKUP_FROM_HOME':
      case 'STUDENT_PICKUP':
      case 'PICKUP':
        return AppColors.parentPrimaryColor;
      case 'PICKUP_FROM_SCHOOL':
        return AppColors.parentPrimaryColor;
      case 'DROP_TO_SCHOOL':
      case 'DROP_SCHOOL':
        return AppColors.parentPrimaryColor;
      case 'DROP_TO_PARENT':
      case 'DROP_TO_HOME':
      case 'DROP_HOME':
      case 'DROP':
        return AppColors.parentSuccessColor;
      case 'ALERT':
      case 'SYSTEM_ALERT':
      case 'DELAY_NOTIFICATION':
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
        leading: _buildMenuAction(),
        titleSpacing: 0,
        title: const Text(AppConstants.labelParentDashboard),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.parentSpacingSM),
            child: _buildProfileAction(),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: BlocListener<ParentBloc, ParentState>(
        listener: (context, state) {
          final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
          if (!isCurrentRoute) {
            return;
          }

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
          } else if (state is ParentProfileLoaded) {
            final args = <String, dynamic>{
              ...state.profile,
              if (_latestDashboard != null)
                'dashboard': _latestDashboard!.toJson(),
            };

            Navigator.pushNamed(
              context,
              AppRoutes.parentProfileView,
              arguments: args,
            ).then((_) {
              if (!mounted) return;
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated && authState.userId != null) {
                context.read<ParentBloc>().add(
                  ParentDashboardRequested(parentId: authState.userId!),
                );
              }
            });
          }
        },
        child: BlocBuilder<ParentBloc, ParentState>(
          builder: (context, state) {
            if (state is ParentLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ParentDashboardLoaded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _updateParentHeaderInfo(state.dashboard);
                  _checkActiveTrip(state);
                }
              });
              return _buildDashboardWithTracking(state);
            } else if (state is ParentRefreshing && state.dashboard != null) {
              final loadingState = ParentDashboardLoaded(
                dashboard: state.dashboard!,
                students: state.students ?? const [],
                trips: state.trips ?? const [],
                notifications: state.notifications ?? const [],
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && state.dashboard != null) {
                  _updateParentHeaderInfo(state.dashboard!);
                }
              });
              return Stack(
                children: [
                  _buildDashboardWithTracking(loadingState),
                  const Positioned(
                    top: AppSizes.parentSpacingMD,
                    right: AppSizes.parentSpacingMD,
                    child: CircularProgressIndicator(),
                  ),
                ],
              );
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
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.parentPrimaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.parentPrimaryColor.withValues(alpha: 0.2),
                  backgroundImage: _parentPhotoBytes != null ? MemoryImage(_parentPhotoBytes!) : null,
                  child: _parentPhotoBytes == null
                      ? const Icon(Icons.person, color: AppColors.parentTextWhite, size: 32)
                      : null,
                ),
                const SizedBox(height: AppSizes.parentSpacingSM),
                Text(
                  _studentName?.isNotEmpty == true ? _studentName! : AppConstants.labelStudent,
                  style: const TextStyle(
                    color: AppColors.parentTextWhite,
                    fontSize: AppSizes.parentHeaderFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _parentName ?? AppConstants.labelParent,
                  style: const TextStyle(
                    color: AppColors.parentTextWhite,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (_parentId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.parentTextWhite.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#$_parentId',
                          style: const TextStyle(
                            color: AppColors.parentTextWhite,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (_parentId != null)
                      const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _schoolName ?? AppConstants.labelSchool,
                        style: const TextStyle(
                          color: AppColors.parentTextWhite,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          BlocBuilder<ParentBloc, ParentState>(
            builder: (context, state) {
              return ListTile(
                leading: const Icon(Icons.person),
                title: const Text(AppConstants.labelProfile),
                onTap: () {
                  Navigator.pop(context);
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

  Widget _buildMenuAction() {
    return Builder(
      builder: (context) {
        return IconButton(
          tooltip: AppConstants.labelParentMenu,
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        );
      },
    );
  }

  Widget _buildProfileAction() {
    final displayName = (_studentName != null && _studentName!.isNotEmpty)
        ? _studentName!
        : (_parentName != null && _parentName!.isNotEmpty)
            ? _parentName!
            : (_parentId != null ? '#$_parentId' : AppConstants.labelParent);
    final schoolName = (_schoolName != null && _schoolName!.isNotEmpty)
        ? _schoolName!
        : AppConstants.labelSchool;

    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusMD),
      onTap: _onProfileTapped,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.parentPrimaryColor,
            backgroundImage: _parentPhotoBytes != null ? MemoryImage(_parentPhotoBytes!) : null,
            child: _parentPhotoBytes == null
                ? const Icon(Icons.person, color: AppColors.parentTextWhite)
                : null,
          ),
          const SizedBox(width: AppSizes.parentSpacingSM),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.parentSpacingXS),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_parentId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.parentPrimaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#$_parentId',
                          style: const TextStyle(fontSize: 11, color: AppColors.parentPrimaryColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                    if (_parentId != null)
                      const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        schoolName,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

  void _onProfileTapped() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.userId != null) {
      context.read<ParentBloc>().add(
        ParentProfileRequested(parentId: authState.userId!),
      );
    }
  }

  void _updateParentHeaderInfo(ParentDashboard dashboard) {
    final photoBase64 = dashboard.studentPhoto;
    Uint8List? photoBytes;
    if (photoBase64 != null && photoBase64.isNotEmpty) {
      photoBytes = _decodeBase64Image(photoBase64);
    }

    bool shouldUpdate = false;

    _latestDashboard = dashboard;

    if (_parentId != dashboard.userId) {
      _parentId = dashboard.userId;
      shouldUpdate = true;
    }

    if (_parentName != dashboard.userName) {
      _parentName = dashboard.userName;
      shouldUpdate = true;
    }

    if (_studentName != dashboard.studentName) {
      _studentName = dashboard.studentName;
      shouldUpdate = true;
    }

    if (_schoolName != dashboard.schoolName) {
      _schoolName = dashboard.schoolName;
      shouldUpdate = true;
    }

    if (photoBase64 != _parentPhotoBase64) {
      _parentPhotoBase64 = photoBase64;
      _parentPhotoBytes = photoBytes;
      shouldUpdate = true;
    }

    if (shouldUpdate && mounted) {
      setState(() {});
    }
  }

  Uint8List? _decodeBase64Image(String data) {
    try {
      final sanitized = data.contains(',') ? data.split(',').last : data;
      return base64Decode(sanitized);
    } catch (e) {
      debugPrint('Error decoding parent image: $e');
      return null;
    }
  }

  void _checkActiveTrip(ParentDashboardLoaded state) {
    debugPrint('🔍 _checkActiveTrip called with ${state.trips.length} trips');
    debugPrint('🔍 Current _activeTripId: $_activeTripId');
    
    // If we already have _activeTripId from notification, keep it
    if (_activeTripId != null) {
      debugPrint('✅ Already have _activeTripId: $_activeTripId, keeping it');
      // Verify the trip exists in state
      final tripExists = state.trips.any((trip) => trip['tripId'] == _activeTripId);
      if (tripExists) {
        debugPrint('✅ Trip $_activeTripId exists in state');
        return; // Keep the existing _activeTripId
      } else {
        debugPrint('⚠️ Trip $_activeTripId not found in state, will search for active trip');
      }
    }
    
    // Check for active trip with status IN_PROGRESS
    final activeTrip = state.trips.firstWhere(
      (trip) {
        final status = trip['tripStatus']?.toString() ?? '';
        final isActive = status == 'IN_PROGRESS' || 
                        status == 'STARTED' ||
                        status == 'IN PROGRESS' ||
                        status.isEmpty; // If status is empty, consider it active if we have notification
        debugPrint('🔍 Checking trip ${trip['tripId']}: status="$status", isActive=$isActive');
        return isActive;
      },
      orElse: () => null,
    );

    if (activeTrip != null) {
      final tripId = activeTrip['tripId'] as int?;
      final studentId = activeTrip['studentId'] as int? ?? state.dashboard.studentId;
      
      debugPrint('✅ Found active trip: tripId=$tripId, studentId=$studentId');
      
      if (tripId != null && tripId != _activeTripId) {
        debugPrint('✅ Setting _activeTripId to $tripId');
        setState(() {
          _activeTripId = tripId;
          _activeStudentId = studentId;
          _isMapVisible = true;
          _mapExpanded = false;
        });
      }
    } else {
      debugPrint('⚠️ No active trip found in state.trips');
      // Don't clear _activeTripId if we have it from notification
      // Only clear if we're sure there's no active trip
      if (_activeTripId != null && state.trips.isNotEmpty) {
        // Check if the trip still exists
        final tripExists = state.trips.any((trip) => trip['tripId'] == _activeTripId);
        if (!tripExists) {
          debugPrint('⚠️ Trip $_activeTripId no longer exists, clearing');
          setState(() {
            _isMapVisible = false;
            _mapExpanded = false;
            _activeTripId = null;
          });
        }
      }
    }
  }

  Widget _buildDashboardWithTracking(ParentDashboardLoaded state) {
    return Stack(
      children: [
        _buildDashboard(state),
        // Live tracking widget overlay
        if (_isMapVisible && _activeTripId != null)
          LiveTrackingWidget(
            tripId: _activeTripId,
            studentId: _activeStudentId,
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

  Widget _buildDashboard(ParentDashboardLoaded state) {
    final dashboard = state.dashboard;

    return RefreshIndicator(
      onRefresh: () async {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated && authState.userId != null) {
          context.read<ParentBloc>().add(
            ParentRefreshRequested(parentId: authState.userId!),
          );
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.parentPadding),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Children Status
            _buildChildrenStatus(state.students, dashboard),
            const SizedBox(height: AppSizes.parentSpacingMD),

            // Quick Stats
            _buildQuickStats(
              context,
              dashboard!,
              state.students,
              state.trips,
              state.notifications,
            ),
            const SizedBox(height: AppSizes.parentSpacingMD),

            // Today's Attendance Status
            _buildTodayStatusCard(dashboard),
            const SizedBox(height: AppSizes.parentSpacingMD),

            // Recent Notifications
            _buildRecentNotifications(state.notifications, dashboard),
            const SizedBox(height: AppSizes.parentSpacingMD),

            // Quick Actions
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(
    BuildContext context,
    ParentDashboard dashboard,
    List<dynamic> students,
    List<dynamic> trips,
    List<dynamic> notifications,
  ) {
    final attendance = dashboard.attendancePercentage.isFinite
        ? '${dashboard.attendancePercentage.toStringAsFixed(1)}%'
        : AppConstants.labelNA;

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
                    students.length.toString(),
                    Icons.child_care,
                    AppColors.parentSuccessColor,
                  ),
                ),
                const SizedBox(width: AppSizes.parentSpacingSM),
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelActiveTrips,
                    trips.length.toString(),
                    Icons.directions_bus,
                    AppColors.parentPrimaryColor,
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
                    notifications.length.toString(),
                    Icons.notifications,
                    AppColors.parentWarningColor,
                  ),
                ),
                const SizedBox(width: AppSizes.parentSpacingSM),
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelAttendancePercentage,
                    attendance,
                    Icons.insights,
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

  Widget _buildTodayStatusCard(ParentDashboard dashboard) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.parentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_available, color: AppColors.parentPrimaryColor),
                const SizedBox(width: AppSizes.parentSpacingXS),
                Text(
                  AppConstants.labelTodayAttendance,
                  style: const TextStyle(
                    fontSize: AppSizes.parentHeaderFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.parentSpacingSM),
            _buildStatusRow(AppConstants.labelStatus, dashboard.todayAttendanceStatus),
            const SizedBox(height: AppSizes.parentSpacingXS),
            _buildStatusRow(AppConstants.labelArrivalTime, _formatTime(dashboard.todayArrivalTime)),
            const SizedBox(height: AppSizes.parentSpacingXS),
            _buildStatusRow(AppConstants.labelDepartureTime, _formatTime(dashboard.todayDepartureTime)),
            const SizedBox(height: AppSizes.parentSpacingXS),
            _buildStatusRow(AppConstants.labelLastUpdated, _formatDateTime(dashboard.lastUpdated)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  String _getInitial(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'S';
    }
    return name.trim()[0].toUpperCase();
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) {
      return AppConstants.labelNA;
    }
    try {
      final parsed = DateTime.parse(time);
      return _formatTimeOfDay(parsed);
    } catch (_) {
      return time;
    }
  }

  String _formatTimeOfDay(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDateTime(DateTime dateTime) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = monthNames[dateTime.month - 1];
    final year = dateTime.year;
    final time = _formatTimeOfDay(dateTime);
    return '$day $month $year • $time';
  }

  Widget _buildChildrenStatus(List<dynamic> students, ParentDashboard dashboard) {
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
            if (students.isEmpty)
              _buildPrimaryStudentCard(dashboard)
            else
              ...students.map((student) => _buildStudentCard(student)),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(dynamic student) {
    final Map<String, dynamic> data = student is Map<String, dynamic>
        ? student
        : <String, dynamic>{};
    final firstName = data['firstName']?.toString() ?? '';
    final lastName = data['lastName']?.toString() ?? '';
    final name = '$firstName $lastName'.trim().isNotEmpty
        ? '$firstName $lastName'.trim()
        : AppConstants.labelUnknown;
    final className = data['className']?.toString() ?? AppConstants.labelNA;
    final studentPhoto = data['studentPhoto']?.toString();
    final photoBytes = studentPhoto != null && studentPhoto.isNotEmpty
        ? _decodeBase64Image(studentPhoto)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.parentCardMargin),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: photoBytes != null ? MemoryImage(photoBytes) : null,
          child: photoBytes == null ? Text(_getInitial(name)) : null,
        ),
        title: Text(name),
        subtitle: Text('${AppConstants.labelClass} $className'),
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

  Widget _buildPrimaryStudentCard(ParentDashboard dashboard) {
    final name = dashboard.studentName.isNotEmpty
        ? dashboard.studentName
        : AppConstants.labelUnknown;
    final classInfo = '${AppConstants.labelClass} ${dashboard.className}';
    final photoBytes = dashboard.studentPhoto != null && dashboard.studentPhoto!.isNotEmpty
        ? _decodeBase64Image(dashboard.studentPhoto!)
        : null;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: photoBytes != null ? MemoryImage(photoBytes) : null,
          child: photoBytes == null ? Text(_getInitial(name)) : null,
        ),
        title: Text(name),
        subtitle: Text('$classInfo • ${dashboard.sectionName}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.parentSpacingSM,
            vertical: AppSizes.parentSpacingXS,
          ),
          decoration: BoxDecoration(
            color: AppColors.statusInfo.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppSizes.parentStatCardPadding),
          ),
          child: Text(
            dashboard.schoolName,
            style: const TextStyle(
              color: AppColors.statusInfo,
              fontSize: AppSizes.parentStatTitleFontSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentNotifications(List<dynamic> notifications, ParentDashboard dashboard) {
    final notificationList = notifications.isNotEmpty
        ? notifications
        : dashboard.recentNotifications;

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
            if (notificationList.isEmpty)
              const Text(AppConstants.msgNoNotifications)
            else
              ...notificationList.take(3).map((notification) => _buildNotificationCard(notification)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(dynamic notification) {
    final Map<String, dynamic> data = notification is Map<String, dynamic>
        ? notification
        : <String, dynamic>{};

    // Get notification type or event type from data
    final notificationType = data['type']?.toString() ?? 
                           data['notificationType']?.toString() ?? 
                           data['eventType']?.toString() ?? '';
    
    // Get user-friendly title and message based on notification type
    final titleAndMessage = _getParentNotificationMessage(notificationType, data);
    final title = titleAndMessage['title'] ?? AppConstants.labelNotification;
    final message = titleAndMessage['message'] ?? '';
    
    final time = data['time']?.toString() ?? 
                 data['timestamp']?.toString() ?? 
                 data['createdDate']?.toString() ?? '';
    
    // Format time if it's a DateTime string
    String formattedTime = _formatNotificationTime(time);

    // Check if this is a trip-related notification that should allow tracking
    final tripId = data['tripId'] as int?;
    final isTripRelated = ['TRIP_STARTED', 'TRIP_START', 'LOCATION_UPDATE', 'ARRIVAL_NOTIFICATION', 
                          'TRIP_UPDATE', 'PICKUP_FROM_PARENT', 'DROP_TO_SCHOOL'].contains(notificationType.toUpperCase());
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.parentCardMargin),
      child: ListTile(
        leading: Icon(
          _getNotificationIcon(notificationType),
          color: _getNotificationColor(notificationType),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(message),
        trailing: Text(
          formattedTime,
          style: const TextStyle(
            fontSize: AppSizes.parentStatTitleFontSize,
            color: AppColors.textSecondary,
          ),
        ),
        onTap: isTripRelated && (tripId != null || _activeTripId != null) ? () {
          // Navigate to tracking page with trip info
          final currentState = context.read<ParentBloc>().state;
          if (currentState is ParentDashboardLoaded) {
            final activeTripId = tripId ?? _activeTripId;
            final studentId = data['studentId'] as int? ?? _activeStudentId ?? currentState.dashboard.studentId;
            
            if (activeTripId != null) {
              Navigator.pushNamed(
                context,
                AppRoutes.enhancedVehicleTracking,
                arguments: {
                  'tripId': activeTripId,
                  'studentId': studentId,
                },
              );
            } else {
              Navigator.pushNamed(context, AppRoutes.enhancedVehicleTracking);
            }
          }
        } : null,
      ),
    );
  }

  /// Get user-friendly notification message based on type
  Map<String, String> _getParentNotificationMessage(String notificationType, Map<String, dynamic> data) {
    final type = notificationType.toUpperCase();
    
    // Check message content for trip status updates
    final message = data['message']?.toString().toLowerCase() ?? '';
    
    // Map notification types to user-friendly messages
    switch (type) {
      case 'TRIP_STARTED':
      case 'TRIP_START':
        return {
          'title': 'Trip Update',
          'message': AppConstants.msgParentTripStarted,
        };
      
      case 'TRIP_COMPLETED':
      case 'TRIP_ENDED':
      case 'TRIP_COMPLETE':
        if (message.contains('completed') || message.contains('ended')) {
          return {
            'title': 'Trip Update',
            'message': AppConstants.msgParentTripEnded,
          };
        }
        return {
          'title': 'Trip Update',
          'message': AppConstants.msgParentTripCompleted,
        };
      
      case 'ARRIVAL_NOTIFICATION':
      case 'ARRIVAL_ALERT':
        if (message.contains('5') || message.contains('five') || message.contains('minutes')) {
          return {
            'title': 'Arrival Alert',
            'message': AppConstants.msgParentVehicleComing,
          };
        }
        return {
          'title': 'Arrival Alert',
          'message': AppConstants.msgParentVehicleComing,
        };
      
      case 'PICKUP_FROM_PARENT':
      case 'PICKUP_FROM_HOME':
      case 'STUDENT_PICKUP':
      case 'PICKUP':
        if (message.contains('pickup') || message.contains('picked')) {
          return {
            'title': 'Pickup Update',
            'message': AppConstants.msgParentChildPickedUp,
          };
        }
        return {
          'title': 'Pickup Update',
          'message': AppConstants.msgParentChildPickedUp,
        };
      
      case 'PICKUP_FROM_SCHOOL':
        return {
          'title': 'Pickup Update',
          'message': AppConstants.msgParentChildPickedFromSchool,
        };
      
      case 'DROP_TO_SCHOOL':
      case 'DROP_SCHOOL':
        return {
          'title': 'Drop Update',
          'message': AppConstants.msgParentChildDroppedToSchool,
        };
      
      case 'DROP_TO_PARENT':
      case 'DROP_TO_HOME':
      case 'DROP_HOME':
        return {
          'title': 'Drop Update',
          'message': AppConstants.msgParentChildDroppedToHome,
        };
      
      case 'TRIP_UPDATE':
        // Check message content for trip update types
        if (message.contains('started') || message.contains('start')) {
          return {
            'title': 'Trip Update',
            'message': AppConstants.msgParentTripStarted,
          };
        } else if (message.contains('completed') || message.contains('ended') || message.contains('end')) {
          return {
            'title': 'Trip Update',
            'message': AppConstants.msgParentTripEnded,
          };
        } else if (message.contains('pickup') || message.contains('picked')) {
          return {
            'title': 'Pickup Update',
            'message': AppConstants.msgParentChildPickedUp,
          };
        } else if (message.contains('drop') || message.contains('dropped')) {
          if (message.contains('school')) {
            return {
              'title': 'Drop Update',
              'message': AppConstants.msgParentChildDroppedToSchool,
            };
          } else if (message.contains('home') || message.contains('parent')) {
            return {
              'title': 'Drop Update',
              'message': AppConstants.msgParentChildDroppedToHome,
            };
          }
        } else if (message.contains('5') || message.contains('five') || message.contains('minutes') || message.contains('arrival')) {
          return {
            'title': 'Arrival Alert',
            'message': AppConstants.msgParentVehicleComing,
          };
        }
        // Fallback for generic trip update
        return {
          'title': 'Trip Update',
          'message': AppConstants.msgParentTripStarted,
        };
      
      case 'LOCATION_UPDATE':
        // Location updates are handled separately, but can show as trip update
        return {
          'title': 'Trip Update',
          'message': AppConstants.msgParentTripStarted,
        };
      
      default:
        // For unknown types, use original message or default
        final originalMessage = data['message']?.toString() ?? '';
        if (originalMessage.isNotEmpty) {
          return {
            'title': data['title']?.toString() ?? 'Trip Update',
            'message': originalMessage,
          };
        }
        return {
          'title': 'Trip Update',
          'message': AppConstants.msgParentTripStarted,
        };
    }
  }

  /// Get icon for notification type
  IconData _getNotificationIcon(String notificationType) {
    final type = notificationType.toUpperCase();
    switch (type) {
      case 'TRIP_STARTED':
      case 'TRIP_START':
        return Icons.play_circle_outline;
      case 'TRIP_COMPLETED':
      case 'TRIP_ENDED':
        return Icons.check_circle_outline;
      case 'ARRIVAL_NOTIFICATION':
      case 'ARRIVAL_ALERT':
        return Icons.access_time;
      case 'PICKUP_FROM_PARENT':
      case 'PICKUP_FROM_HOME':
      case 'STUDENT_PICKUP':
        return Icons.arrow_upward;
      case 'PICKUP_FROM_SCHOOL':
        return Icons.arrow_upward;
      case 'DROP_TO_SCHOOL':
        return Icons.school;
      case 'DROP_TO_PARENT':
      case 'DROP_TO_HOME':
        return Icons.home;
      default:
        return Icons.notifications;
    }
  }


  /// Format notification time
  String _formatNotificationTime(String time) {
    if (time.isEmpty) return '';
    
    try {
      // Try to parse as DateTime
      DateTime dateTime;
      if (time.contains('T')) {
        dateTime = DateTime.parse(time);
      } else {
        // Try other formats
        dateTime = DateTime.parse(time);
      }
      
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        // Format as date
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      // If parsing fails, return original time
      return time;
    }
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
                      debugPrint('🔍 Track Vehicle button clicked');
                      debugPrint('🔍 _activeTripId: $_activeTripId');
                      debugPrint('🔍 _activeStudentId: $_activeStudentId');
                      
                      // Pass active trip information when navigating to tracking page
                      final currentState = context.read<ParentBloc>().state;
                      if (currentState is ParentDashboardLoaded) {
                        debugPrint('🔍 Current state has ${currentState.trips.length} trips');
                        
                        // First, try to use _activeTripId if available (from notification)
                        if (_activeTripId != null) {
                          debugPrint('✅ Using _activeTripId: $_activeTripId');
                          Navigator.pushNamed(
                            context,
                            AppRoutes.enhancedVehicleTracking,
                            arguments: {
                              'tripId': _activeTripId,
                              'studentId': _activeStudentId ?? currentState.dashboard.studentId,
                            },
                          );
                          return;
                        }
                        
                        // Find active trip from current state - also check by tripId if we have notification
                        dynamic activeTrip;
                        
                        // If we have trips, try to find the one matching _activeTripId first
                        if (_activeTripId != null) {
                          activeTrip = currentState.trips.firstWhere(
                            (trip) => trip['tripId'] == _activeTripId,
                            orElse: () => null,
                          );
                          if (activeTrip != null) {
                            debugPrint('✅ Found trip by _activeTripId: ${activeTrip['tripId']}');
                          }
                        }
                        
                        // If not found, search for any active trip
                        if (activeTrip == null) {
                          activeTrip = currentState.trips.firstWhere(
                            (trip) {
                              final status = trip['tripStatus']?.toString() ?? '';
                              final isActive = status == 'IN_PROGRESS' || 
                                              status == 'STARTED' ||
                                              status == 'IN PROGRESS' ||
                                              status.isEmpty; // Consider empty status as potentially active
                              debugPrint('🔍 Checking trip ${trip['tripId']}: status="$status", isActive=$isActive');
                              return isActive;
                            },
                            orElse: () => null,
                          );
                        }
                        
                        if (activeTrip != null) {
                          debugPrint('✅ Found active trip in state: ${activeTrip['tripId']}');
                          Navigator.pushNamed(
                            context,
                            AppRoutes.enhancedVehicleTracking,
                            arguments: {
                              'tripId': activeTrip['tripId'],
                              'studentId': activeTrip['studentId'] ?? currentState.dashboard.studentId,
                            },
                          );
                        } else {
                          debugPrint('⚠️ No active trip found in state');
                          // If we have _activeTripId from notification, use it even if not in state
                          if (_activeTripId != null) {
                            debugPrint('✅ Using _activeTripId from notification: $_activeTripId');
                            Navigator.pushNamed(
                              context,
                              AppRoutes.enhancedVehicleTracking,
                              arguments: {
                                'tripId': _activeTripId,
                                'studentId': _activeStudentId ?? currentState.dashboard.studentId,
                              },
                            );
                          } else {
                            debugPrint('⚠️ No tripId available, navigating without tripId');
                            Navigator.pushNamed(context, AppRoutes.enhancedVehicleTracking);
                          }
                        }
                      } else {
                        debugPrint('⚠️ State is not ParentDashboardLoaded, navigating without tripId');
                        Navigator.pushNamed(context, AppRoutes.enhancedVehicleTracking);
                      }
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

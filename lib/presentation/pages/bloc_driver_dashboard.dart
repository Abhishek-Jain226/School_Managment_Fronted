import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/constants.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/driver/driver_bloc.dart';
import '../../bloc/driver/driver_event.dart';
import '../../bloc/driver/driver_state.dart';
import '../../data/models/driver_dashboard.dart';
import '../../data/models/trip.dart';
import '../../app_routes.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart';
import '../../services/location_tracking_service.dart';

class BlocDriverDashboard extends StatefulWidget {
  const BlocDriverDashboard({super.key});

  @override
  State<BlocDriverDashboard> createState() => _BlocDriverDashboardState();
}

class _BlocDriverDashboardState extends State<BlocDriverDashboard> {
  static const String _tripSessionEndedResult = 'tripSessionEnded';

  String _selectedTripType = AppConstants.tripTypeMorningPickup;
  Trip? _selectedTrip;
  bool _isTripActive = false;
  Timer? _locationTimer;
  int? _driverId;
  String? _driverName;
  String? _schoolName;
  String? _driverPhotoBase64;
  Uint8List? _driverPhotoBytes;
  
  final WebSocketNotificationService _wsService = WebSocketNotificationService();
  final LocationTrackingService _locationService = LocationTrackingService();
  StreamSubscription<WebSocketNotification>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    // Check authentication and get driver ID
    _loadDriverData();
    _initializeWebSocket();
  }

  String _formatTripTime(DateTime? dt) {
    if (dt == null) return AppConstants.labelNA;
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _notificationSubscription?.cancel();
    _locationService.dispose();
    super.dispose();
  }

  void _initializeWebSocket() {
    _wsService.initialize().then((_) {
      debugPrint(AppConstants.msgWebSocketInitializedDriver);
      
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
    }
  }
  
  bool _shouldShowNotificationToUser(String type) {
    // Drivers should see trip-related notifications
    final userFacingNotifications = [
      AppConstants.notifTypeTripAssigned,
      AppConstants.notifTypeTripCancelled,
      AppConstants.notifTypeRouteChanged,
      AppConstants.notifTypeStudentAbsent,
      AppConstants.notifTypeEmergencyAlert,
    ];
    
    return userFacingNotifications.contains(type.toUpperCase());
  }

  Color _getNotificationColor(String type) {
    switch (type.toUpperCase()) {
      case AppConstants.notifTypeArrival:
        return AppColors.driverSuccessColor;
      case AppConstants.notifTypePickup:
        return AppColors.driverPrimaryColor;
      case AppConstants.notifTypeDrop:
        return AppColors.driverWarningColor;
      case AppConstants.notifTypeAlert:
      case AppConstants.notifTypeSystemAlert:
        return AppColors.driverErrorColor;
      default:
        return AppColors.driverGreyColor;
    }
  }

  void _loadDriverData() {
    // Get driver ID from auth state
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.driverId != null) {
      _driverId = authState.driverId;
      context.read<DriverBloc>().add(
        DriverDashboardRequested(driverId: authState.driverId!),
      );
    } else {
      // If driverId is not available, show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.msgDriverIdNotFound),
          backgroundColor: AppColors.driverErrorColor,
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.login);
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
              backgroundColor: AppColors.driverErrorColor,
              foregroundColor: AppColors.driverTextWhite,
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

  void _onTripTypeChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedTripType = value;
        _selectedTrip = null;
        _isTripActive = false;
      });
    }
  }

  void _onTripSelected(Trip? trip) {
    setState(() {
      _selectedTrip = trip;
      // Always set trip as inactive when selected on dashboard
      // Trip will be active only when driver clicks "Start Trip" and navigates to trip details page
      _isTripActive = false;
    });
  }

  void _startTrip() async {
    if (_selectedTrip == null) return;

    // Request location permission
    final hasPermission = await _requestLocationPermission();
    if (!hasPermission || !mounted) return;

    // Get current location
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: ${e.toString()}'),
            backgroundColor: AppColors.driverErrorColor,
          ),
        );
      }
      return;
    }

    if (position == null || !mounted) return;

    // Call backend to start trip
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated || authState.driverId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.msgDriverIdNotFound)),
        );
      }
      return;
    }

    // Dispatch event to start trip in backend with location
    context.read<DriverBloc>().add(
      DriverStartTripRequested(
        driverId: authState.driverId!,
        tripId: _selectedTrip!.tripId,
        latitude: position.latitude,
        longitude: position.longitude,
      ),
    );
  }

  void _stopTrip() {
    if (_selectedTrip == null) return;

    setState(() {
      _isTripActive = false;
    });

    // Stop location tracking
    _locationService.stopLocationTracking();
    _locationTimer?.cancel();

    // End trip in backend
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.driverId != null) {
      context.read<DriverBloc>().add(
        DriverEndTripRequested(
          driverId: authState.driverId!,
          tripId: _selectedTrip!.tripId,
        ),
      );
    }
  }

  void _handleTripSessionResult(dynamic result) {
    if (result != _tripSessionEndedResult) return;

    // Stop location tracking when trip session ends
    _locationService.stopLocationTracking();
    _locationTimer?.cancel();
    setState(() {
      _isTripActive = false;
    });

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.driverId != null) {
      context.read<DriverBloc>().add(
        DriverRefreshRequested(driverId: authState.driverId!),
      );
    }
  }

  Future<void> _viewStudentsForSelectedTrip() async {
    final trip = _selectedTrip;
    if (trip == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.msgSelectTripFirst)),
        );
      }
      return;
    }

    // Always show read-only view for View Student button
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated || authState.driverId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.msgDriverIdNotFound)),
        );
      }
      return;
    }

    await Navigator.pushNamed(
      context,
      AppRoutes.simplifiedStudentManagement,
      arguments: {
        'trip': trip,
        'driverId': authState.driverId!,
        'isReadOnly': true, // Always read-only for View Student
      },
    );
  }

  Future<void> _showTripStudentsPreview(Trip trip) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated || authState.driverId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.msgDriverIdNotFound)),
        );
      }
      return;
    }

    await Navigator.pushNamed(
      context,
      AppRoutes.simplifiedStudentManagement,
      arguments: {
        'trip': trip,
        'driverId': authState.driverId!,
        'isReadOnly': true,
      },
    );
  }

  Future<bool> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      _showPermissionDeniedDialog();
      return false;
    } else if (status.isPermanentlyDenied) {
      _showLocationSettingsDialog();
      return false;
    }
    return false;
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppConstants.labelLocationPermissionRequired),
        content: const Text(AppConstants.msgLocationPermissionMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppConstants.actionCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text(AppConstants.labelSettings),
          ),
        ],
      ),
    );
  }

  void _showLocationSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppConstants.labelLocationSettings),
        content: const Text(AppConstants.msgLocationPermissionDenied),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppConstants.actionCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text(AppConstants.labelOpenSettings),
          ),
        ],
      ),
    );
  }

  // Old location tracking methods removed - now using LocationTrackingService
  // The LocationTrackingService handles all location updates via saveLocationUpdate API

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _buildMenuAction(),
        titleSpacing: 0,
        title: const Text(AppConstants.labelDriverDashboard),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.driverSpacingSM),
            child: _buildProfileAction(),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: BlocListener<DriverBloc, DriverState>(
        listener: (context, state) {
          if (state is DriverActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.driverSuccessColor,
              ),
            );
            
            // Initialize background location tracking after successful trip start
            if (state.actionType == AppConstants.actionTypeStartTrip && _selectedTrip != null) {
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated && authState.driverId != null) {
                // Update local state to mark trip as active
                setState(() {
                  _isTripActive = true;
                });
                
                // Start location tracking service in the background
                _locationService.startLocationTracking(
                  driverId: authState.driverId!,
                  tripId: _selectedTrip!.tripId,
                  updateInterval: const Duration(seconds: 15), // Configurable 10-30 seconds
                ).then((trackingStarted) {
                  if (!trackingStarted && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to start location tracking. Location updates may not be available.'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                });
                
                // Navigate to student management page after successful trip start
                if (mounted) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.simplifiedStudentManagement,
                    arguments: {
                      'trip': _selectedTrip,
                      'driverId': authState.driverId!,
                      'isReadOnly': false,
                    },
                  ).then((result) {
                    if (!mounted) return;
                    _handleTripSessionResult(result);
                  });
                }
              }
            }
          } else if (state is DriverError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.driverErrorColor,
              ),
            );
          } else if (state is DriverProfileLoaded) {
            Navigator.pushNamed(
              context,
              AppRoutes.driverProfile,
              arguments: state.profile,
            ).then((_) {
              if (!mounted) return;
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated && authState.driverId != null) {
                context.read<DriverBloc>().add(
                  DriverDashboardRequested(driverId: authState.driverId!),
                );
              }
            });
          } else if (state is DriverReportsLoaded) {
            Navigator.pushNamed(
              context,
              AppRoutes.driverReports,
              arguments: state.reports,
            ).then((_) {
              if (!mounted) return;
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated && authState.driverId != null) {
                context.read<DriverBloc>().add(
                  DriverDashboardRequested(driverId: authState.driverId!),
                );
              }
            });
          }
        },
        child: BlocBuilder<DriverBloc, DriverState>(
          builder: (context, state) {
            if (state is DriverLoading && _selectedTrip == null) {
              // Only show loading if dashboard hasn't loaded yet
              return const Center(child: CircularProgressIndicator());
            } else if (state is DriverDashboardLoaded) {
              _syncSelectedTripWithLatestData(state);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _updateDriverHeaderInfo(state.dashboard);
                }
              });
              return _buildDashboard(state);
            } else if (state is DriverRefreshing &&
                state.dashboard != null &&
                state.morningTrips != null &&
                state.afternoonTrips != null) {
              final loadingState = DriverDashboardLoaded(
                dashboard: state.dashboard!,
                reports: state.reports,
                morningTrips: state.morningTrips!,
                afternoonTrips: state.afternoonTrips!,
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && state.dashboard != null) {
                  _updateDriverHeaderInfo(state.dashboard!);
                }
              });
              return Stack(
                children: [
                  _buildDashboard(loadingState),
                  const Positioned(
                    top: AppSizes.driverSpacingMD,
                    right: AppSizes.driverSpacingMD,
                    child: CircularProgressIndicator(),
                  ),
                ],
              );
            } else if (state is DriverProfileLoaded || state is DriverReportsLoaded) {
              // If profile/reports loaded but dashboard state lost, reload dashboard
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated && authState.driverId != null) {
                // Use WidgetsBinding to ensure state is updated after current frame
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    context.read<DriverBloc>().add(
                      DriverDashboardRequested(driverId: authState.driverId!),
                    );
                  }
                });
                // Show last known dashboard state if available, otherwise loading
                return const Center(child: CircularProgressIndicator());
              }
              return const Center(child: Text(AppConstants.msgNoDataAvailable));
            } else if (state is DriverError && state.actionType != AppConstants.actionTypeLoadProfile && state.actionType != AppConstants.actionTypeLoadReports) {
              // Only show error state if it's not a profile/reports loading error
              return _buildErrorState(state);
            }
            // Fallback: try to reload dashboard
            final authState = context.read<AuthBloc>().state;
            if (authState is AuthAuthenticated && authState.driverId != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.read<DriverBloc>().add(
                    DriverDashboardRequested(driverId: authState.driverId!),
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

  void _syncSelectedTripWithLatestData(DriverDashboardLoaded state) {
    if (_selectedTrip == null) return;
    final currentTripId = _selectedTrip!.tripId;

    Trip? updatedTrip;
    String? updatedTripType;

    for (final trip in state.morningTrips) {
      if (trip.tripId == currentTripId) {
        updatedTrip = trip;
        updatedTripType = AppConstants.tripTypeMorningPickup;
        break;
      }
    }

    if (updatedTrip == null) {
      for (final trip in state.afternoonTrips) {
        if (trip.tripId == currentTripId) {
          updatedTrip = trip;
          updatedTripType = AppConstants.tripTypeAfternoonDrop;
          break;
        }
      }
    }

    if (updatedTrip == null) {
      _selectedTrip = null;
      _isTripActive = false;
      return;
    }

    _selectedTrip = updatedTrip;
    // Don't set trip as active based on database status
    // Trip will be active only when driver clicks "Start Trip" and navigates to trip details page
    _isTripActive = false;
    if (updatedTripType != null && _selectedTripType != updatedTripType) {
      _selectedTripType = updatedTripType;
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppColors.driverPrimaryColor),
            child: Text(
              AppConstants.labelDriverMenu,
              style: TextStyle(
                color: AppColors.driverTextWhite,
                fontSize: AppSizes.driverMenuFontSize,
              ),
            ),
          ),
          BlocBuilder<DriverBloc, DriverState>(
            builder: (context, state) {
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text(AppConstants.labelProfile),
                    onTap: () {
                      Navigator.pop(context);
                      final authState = context.read<AuthBloc>().state;
                      if (authState is AuthAuthenticated && authState.driverId != null) {
                        context.read<DriverBloc>().add(
                          DriverProfileRequested(driverId: authState.driverId!),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.analytics),
                    title: const Text(AppConstants.labelReports),
                    onTap: () {
                      Navigator.pop(context);
                      if (state is DriverDashboardLoaded && state.reports != null) {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.driverReports,
                          arguments: state.reports,
                        ).then((_) {
                          if (mounted) {
                            final authState = context.read<AuthBloc>().state;
                            if (authState is AuthAuthenticated && authState.driverId != null) {
                              context.read<DriverBloc>().add(
                                DriverDashboardRequested(driverId: authState.driverId!),
                              );
                            }
                          }
                        });
                      } else {
                        final authState = context.read<AuthBloc>().state;
                        if (authState is AuthAuthenticated && authState.driverId != null) {
                          context.read<DriverBloc>().add(
                            DriverReportsRequested(driverId: authState.driverId!),
                          );
                        }
                      }
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
              );
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
          tooltip: AppConstants.labelDriverMenu,
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        );
      },
    );
  }

  Widget _buildProfileAction() {
    final displayName = (_driverName != null && _driverName!.isNotEmpty)
        ? _driverName!
        : (_driverId != null ? '#$_driverId' : AppConstants.labelDriver);
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
            backgroundColor: AppColors.driverPrimaryColor,
            backgroundImage: _driverPhotoBytes != null ? MemoryImage(_driverPhotoBytes!) : null,
            child: _driverPhotoBytes == null
                ? const Icon(
                    Icons.person,
                    color: AppColors.driverTextWhite,
                  )
                : null,
          ),
          const SizedBox(width: AppSizes.driverSpacingSM),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.driverSpacingXS),
                Text(
                  schoolName,
                  style: const TextStyle(fontSize: 12, color: AppColors.driverGreyColor),
                  overflow: TextOverflow.ellipsis,
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
    if (authState is AuthAuthenticated && authState.driverId != null) {
      context.read<DriverBloc>().add(
        DriverProfileRequested(driverId: authState.driverId!),
      );
    }
  }

  void _updateDriverHeaderInfo(DriverDashboard dashboard) {
    final photoBase64 = dashboard.driverPhoto;
    Uint8List? photoBytes;
    if (photoBase64 != null && photoBase64.isNotEmpty) {
      photoBytes = _decodeBase64Image(photoBase64);
    }

    bool shouldUpdate = false;

    if (_driverId != dashboard.driverId) {
      _driverId = dashboard.driverId;
      shouldUpdate = true;
    }

    if (_driverName != dashboard.driverName) {
      _driverName = dashboard.driverName;
      shouldUpdate = true;
    }

    if (_schoolName != dashboard.schoolName) {
      _schoolName = dashboard.schoolName;
      shouldUpdate = true;
    }

    if (photoBase64 != _driverPhotoBase64) {
      _driverPhotoBase64 = photoBase64;
      _driverPhotoBytes = photoBytes;
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
      debugPrint('Error decoding driver image: $e');
      return null;
    }
  }

  Widget _buildDashboard(DriverDashboardLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated && authState.driverId != null) {
          context.read<DriverBloc>().add(DriverRefreshRequested(driverId: authState.driverId!));
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.driverPadding),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Performance Summary
            _buildPerformanceSummary(context, state),
            const SizedBox(height: AppSizes.driverSpacingMD),

            // Trip Type Selection
            _buildTripTypeSelection(state),
            const SizedBox(height: AppSizes.driverSpacingMD),

            // Trip Selection
            _buildTripSelection(state),
            const SizedBox(height: AppSizes.driverSpacingMD),

            // Selected Trip Actions
            if (_selectedTrip != null) _buildSelectedTripCard(state),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSummary(BuildContext context, DriverDashboardLoaded state) {
    final reports = state.reports;
    if (reports == null) return const SizedBox.shrink();

    final metrics = [
      _DriverMetric(
        title: AppConstants.labelTotalTrips,
        value: reports.totalTripsCompleted.toString(),
        icon: Icons.directions_bus,
        color: AppColors.driverPrimaryColor,
      ),
      _DriverMetric(
        title: AppConstants.labelTotalStudents,
        value: reports.totalStudentsTransported.toString(),
        icon: Icons.people,
        color: AppColors.driverSuccessColor,
      ),
      _DriverMetric(
        title: AppConstants.labelStudentsPickedUp,
        value: reports.monthPickups.toString(),
        icon: Icons.arrow_upward,
        color: AppColors.driverWarningColor,
      ),
      _DriverMetric(
        title: AppConstants.labelStudentsDropped,
        value: reports.monthDrops.toString(),
        icon: Icons.arrow_downward,
        color: AppColors.driverPurpleColor,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final columns = isCompact ? 2 : 4;

        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.driverPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppConstants.labelDriverPerformanceSummary,
                  style: TextStyle(
                    fontSize: AppSizes.driverHeaderFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.driverSpacingMD),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: AppSizes.driverSpacingSM,
                    mainAxisSpacing: AppSizes.driverSpacingSM,
                    childAspectRatio: isCompact ? 1.3 : 1.6,
                  ),
                  itemCount: metrics.length,
                  itemBuilder: (context, index) => _DriverPerformanceTile(metric: metrics[index]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.driverStatCardPadding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppSizes.driverStatBgOpacity),
        borderRadius: BorderRadius.circular(AppSizes.driverStatBorderRadius),
        border: Border.all(
          color: color.withValues(alpha: AppSizes.driverStatBorderOpacity),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: AppSizes.driverStatIconSize),
          const SizedBox(height: AppSizes.driverSpacingXS),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSizes.driverStatValueFontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: AppSizes.driverStatTitleFontSize),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTripTypeSelection(DriverDashboardLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.driverPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.labelSelectTripType,
              style: TextStyle(
                fontSize: AppSizes.driverSubheaderFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.driverSpacingXXS),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text(AppConstants.labelMorningPickup),
                    value: AppConstants.tripTypeMorningPickup,
                    groupValue: _selectedTripType,
                    onChanged: _onTripTypeChanged,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text(AppConstants.labelAfternoonDrop),
                    value: AppConstants.tripTypeAfternoonDrop,
                    groupValue: _selectedTripType,
                    onChanged: _onTripTypeChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripSelection(DriverDashboardLoaded state) {
    final trips = _selectedTripType == AppConstants.tripTypeMorningPickup
        ? state.morningTrips
        : state.afternoonTrips;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.driverPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.labelSelectTrip,
              style: TextStyle(
                fontSize: AppSizes.driverSubheaderFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.driverSpacingXXS),
            DropdownButtonFormField<Trip>(
              value: _selectedTrip,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: AppConstants.labelChooseTrip,
              ),
              items: trips.map((trip) {
                return DropdownMenuItem<Trip>(
                  value: trip,
                  child: Text('${trip.tripName} - ${trip.scheduledTime ?? _formatTripTime(trip.tripStartTime)}'),
                );
              }).toList(),
              onChanged: _onTripSelected,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTripCard(DriverDashboardLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.driverPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.labelSelectedTrip,
              style: TextStyle(
                fontSize: AppSizes.driverSubheaderFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.driverSpacingXXS),
            Text('${AppConstants.labelTrip} ${_selectedTrip!.tripName}'),
            Text('${AppConstants.labelTime}: ${_selectedTrip!.scheduledTime ?? _formatTripTime(_selectedTrip!.tripStartTime)}'),
            const SizedBox(height: AppSizes.driverSpacingMD),
            // Always show Start Trip and View Student buttons on dashboard
            // End Trip button is only on the trip details page
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _startTrip,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(AppConstants.labelStartTrip),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.driverSuccessColor,
                      foregroundColor: AppColors.driverTextWhite,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.driverSpacingSM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _viewStudentsForSelectedTrip,
                    icon: const Icon(Icons.people),
                    label: const Text(AppConstants.labelViewStudents),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.driverPrimaryColor,
                      foregroundColor: AppColors.driverTextWhite,
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

  Widget _buildErrorState(DriverError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error,
            size: AppSizes.driverErrorIconSize,
            color: AppColors.driverErrorColor,
          ),
          const SizedBox(height: AppSizes.driverSpacingMD),
          Text(
            state.message,
            style: const TextStyle(fontSize: AppSizes.driverErrorTextSize),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.driverSpacingMD),
          ElevatedButton(
            onPressed: _loadDriverData,
            child: const Text(AppConstants.labelRetry),
          ),
        ],
      ),
    );
  }
}

class _DriverMetric {
  const _DriverMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

class _DriverPerformanceTile extends StatelessWidget {
  const _DriverPerformanceTile({required this.metric});

  final _DriverMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.driverStatCardPadding),
      decoration: BoxDecoration(
        color: metric.color.withValues(alpha: AppSizes.driverStatBgOpacity),
        borderRadius: BorderRadius.circular(AppSizes.driverStatBorderRadius),
        border: Border.all(
          color: metric.color.withValues(alpha: AppSizes.driverStatBorderOpacity),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: metric.color.withValues(alpha: AppSizes.driverStatIconBgOpacity),
            child: Icon(metric.icon, color: metric.color),
          ),
          const SizedBox(height: AppSizes.driverSpacingSM),
          Text(
            metric.value,
            style: TextStyle(
              fontSize: AppSizes.driverStatValueFontSize,
              fontWeight: FontWeight.bold,
              color: metric.color,
            ),
          ),
          Text(
            metric.title,
            style: const TextStyle(fontSize: AppSizes.driverStatTitleFontSize),
          ),
        ],
      ),
    );
  }
}

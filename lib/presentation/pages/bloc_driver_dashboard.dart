import 'dart:async';
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
import '../../data/models/trip.dart';
import '../../app_routes.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart';

class BlocDriverDashboard extends StatefulWidget {
  const BlocDriverDashboard({super.key});

  @override
  State<BlocDriverDashboard> createState() => _BlocDriverDashboardState();
}

class _BlocDriverDashboardState extends State<BlocDriverDashboard> {
  String _selectedTripType = AppConstants.tripTypeMorningPickup;
  Trip? _selectedTrip;
  bool _isTripActive = false;
  Timer? _locationTimer;
  
  final WebSocketNotificationService _wsService = WebSocketNotificationService();
  StreamSubscription<WebSocketNotification>? _notificationSubscription;
  StreamSubscription<WebSocketNotification>? _tripUpdateSubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Check authentication and get driver ID
    _loadDriverData();
    _initializeWebSocket();
    _startAutoRefresh();
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
    _tripUpdateSubscription?.cancel();
    _refreshTimer?.cancel();
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

  void _refreshDashboard() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.driverId != null) {
      context.read<DriverBloc>().add(
        DriverDashboardRequested(driverId: authState.driverId!),
      );
    }
  }

  void _startAutoRefresh() {
    // Auto-refresh dashboard every 30 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: AppSizes.driverAutoRefreshSeconds),
      (timer) {
        if (mounted) {
          _refreshDashboard();
        }
      },
    );
  }

  void _loadDriverData() {
    // Get driver ID from auth state
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.driverId != null) {
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
      _isTripActive = false;
    });
  }

  void _startTrip() async {
    if (_selectedTrip == null) return;

    // Request location permission
    final hasPermission = await _requestLocationPermission();
    if (!hasPermission || !mounted) return;

    setState(() {
      _isTripActive = true;
    });

    // Start location tracking
    _startLocationTracking();

    // Navigate to student management
    final authState = context.read<AuthBloc>().state;
    if (mounted && authState is AuthAuthenticated && authState.driverId != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.simplifiedStudentManagement,
        arguments: {
          'trip': _selectedTrip,
          'driverId': authState.driverId!,
          'isTripActive': _isTripActive,
        },
      );
    }
  }

  void _stopTrip() {
    if (_selectedTrip == null) return;

    setState(() {
      _isTripActive = false;
    });

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

  void _startLocationTracking() {
    _locationTimer = Timer.periodic(
      const Duration(seconds: AppSizes.driverLocationUpdateSeconds),
      (timer) {
        _sendLocationUpdate();
      },
    );
  }

  void _sendLocationUpdate() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated && authState.driverId != null && mounted) {
        context.read<DriverBloc>().add(
          DriverUpdateLocationRequested(
            driverId: authState.driverId!,
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        );
      }
    } catch (e) {
      // Handle location error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.labelDriverDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutConfirmation,
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
          } else if (state is DriverError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.driverErrorColor,
              ),
            );
          }
        },
        child: BlocBuilder<DriverBloc, DriverState>(
          builder: (context, state) {
            if (state is DriverLoading && _selectedTrip == null) {
              // Only show loading if dashboard hasn't loaded yet
              return const Center(child: CircularProgressIndicator());
            } else if (state is DriverDashboardLoaded) {
              return _buildDashboard(state);
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
          BlocListener<DriverBloc, DriverState>(
            listener: (context, state) {
              if (state is DriverProfileLoaded) {
                // Navigate to profile page
                Navigator.pushNamed(
                  context,
                  AppRoutes.driverProfile,
                  arguments: state.profile,
                ).then((_) {
                  // Reload dashboard when returning from profile page
                  if (mounted) {
                    final authState = context.read<AuthBloc>().state;
                    if (authState is AuthAuthenticated && authState.driverId != null) {
                      context.read<DriverBloc>().add(
                        DriverDashboardRequested(driverId: authState.driverId!),
                      );
                    }
                  }
                });
              } else if (state is DriverReportsLoaded) {
                // Navigate to reports page
                Navigator.pushNamed(
                  context,
                  AppRoutes.driverReports,
                  arguments: state.reports,
                ).then((_) {
                  // Reload dashboard when returning from reports page
                  if (mounted) {
                    final authState = context.read<AuthBloc>().state;
                    if (authState is AuthAuthenticated && authState.driverId != null) {
                      context.read<DriverBloc>().add(
                        DriverDashboardRequested(driverId: authState.driverId!),
                      );
                    }
                  }
                });
              } else if (state is DriverError && state.actionType == AppConstants.actionTypeLoadProfile) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.driverErrorColor,
                  ),
                );
              } else if (state is DriverError && state.actionType == AppConstants.actionTypeLoadReports) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.driverErrorColor,
                  ),
                );
              }
            },
            child: BlocBuilder<DriverBloc, DriverState>(
              builder: (context, state) {
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text(AppConstants.labelProfile),
                      onTap: () {
                        Navigator.pop(context);
                        // Load profile first, then navigate
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
                        // Check if reports are already loaded in dashboard
                        if (state is DriverDashboardLoaded && state.reports != null) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.driverReports,
                            arguments: state.reports,
                          ).then((_) {
                            // Reload dashboard when returning from reports page
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
                          // Load reports first, then navigate
                          final authState = context.read<AuthBloc>().state;
                          if (authState is AuthAuthenticated && authState.driverId != null) {
                            context.read<DriverBloc>().add(
                              DriverReportsRequested(driverId: authState.driverId!),
                            );
                          }
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Performance Summary
            _buildPerformanceSummary(state),
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

  Widget _buildPerformanceSummary(DriverDashboardLoaded state) {
    final reports = state.reports;
    if (reports == null) return const SizedBox.shrink();

    return Card(
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
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelTotalTrips,
                    reports.totalTripsCompleted.toString(),
                    Icons.directions_bus,
                    AppColors.driverPrimaryColor,
                  ),
                ),
                const SizedBox(width: AppSizes.driverSpacingSM),
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelTotalStudents,
                    reports.totalStudentsTransported.toString(),
                    Icons.people,
                    AppColors.driverSuccessColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.driverSpacingSM),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelStudentsPickedUp,
                    reports.monthPickups.toString(),
                    Icons.arrow_upward,
                    AppColors.driverWarningColor,
                  ),
                ),
                const SizedBox(width: AppSizes.driverSpacingSM),
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelStudentsDropped,
                    reports.monthDrops.toString(),
                    Icons.arrow_downward,
                    AppColors.driverPurpleColor,
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
            Text('${AppConstants.labelStatus}: ${_isTripActive ? AppConstants.labelActiveTripStatus : AppConstants.labelInactiveTripStatus}'),
            const SizedBox(height: AppSizes.driverSpacingMD),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTripActive ? _stopTrip : _startTrip,
                    icon: Icon(_isTripActive ? Icons.stop : Icons.play_arrow),
                    label: Text(_isTripActive ? AppConstants.labelStopTrip : AppConstants.labelStartTrip),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTripActive 
                          ? AppColors.driverErrorColor 
                          : AppColors.driverSuccessColor,
                      foregroundColor: AppColors.driverTextWhite,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.driverSpacingSM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTripActive
                        ? () {
                            final authState = context.read<AuthBloc>().state;
                            if (authState is AuthAuthenticated && authState.driverId != null) {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.simplifiedStudentManagement,
                                arguments: {
                                  'trip': _selectedTrip,
                                  'driverId': authState.driverId!,
                                  'isTripActive': _isTripActive,
                                },
                              );
                            }
                          }
                        : null,
                    icon: const Icon(Icons.people),
                    label: const Text(AppConstants.labelViewStudents),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTripActive 
                          ? AppColors.driverPrimaryColor 
                          : AppColors.driverGreyColor,
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

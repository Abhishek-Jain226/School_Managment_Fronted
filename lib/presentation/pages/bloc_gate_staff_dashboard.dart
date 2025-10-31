import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/gate_staff/gate_staff_bloc.dart';
import '../../bloc/gate_staff/gate_staff_event.dart';
import '../../bloc/gate_staff/gate_staff_state.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart';
import '../../app_routes.dart';

class BlocGateStaffDashboard extends StatefulWidget {
  const BlocGateStaffDashboard({super.key});

  @override
  State<BlocGateStaffDashboard> createState() => _BlocGateStaffDashboardState();
}

class _BlocGateStaffDashboardState extends State<BlocGateStaffDashboard> {
  final WebSocketNotificationService _webSocketService = WebSocketNotificationService();
  
  int? _userId;
  bool _isConnected = false;
  StreamSubscription<WebSocketNotification>? _notificationSubscription;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt(AppConstants.keyUserId);
    });
    
    if (_userId != null) {
      context.read<GateStaffBloc>().add(
        GateStaffDashboardRequested(userId: _userId!),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.msgUserIdNotFoundLogin),
          backgroundColor: AppColors.statusError,
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  void _initializeWebSocket() {
    _webSocketService.initialize().then((_) {
      debugPrint(AppConstants.msgWebSocketInitializedGateStaff);
      setState(() {
        _isConnected = _webSocketService.isConnected;
      });
      
      // Listen to general notifications
      _notificationSubscription = _webSocketService.notificationStream.listen(
        _handleWebSocketNotification,
        onError: (error) {
          debugPrint('${AppConstants.msgWebSocketError}$error');
          setState(() {
            _isConnected = false;
          });
        },
      );
      
      // Listen to gate entry/exit events
      _webSocketService.arrivalStream.listen(
        (notification) {
          debugPrint('${AppConstants.msgGateEventReceived}${notification.message}');
          _handleWebSocketNotification(notification);
        },
        onError: (error) {
          debugPrint('${AppConstants.msgGateNotificationError}$error');
        },
      );
    }).catchError((error) {
      debugPrint('${AppConstants.msgWebSocketInitError}$error');
    });
  }

  void _handleWebSocketNotification(WebSocketNotification notification) {
    debugPrint('${AppConstants.msgGateStaffNotification}${notification.type} - ${notification.message}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${notification.title}: ${notification.message}'),
          backgroundColor: _getNotificationColor(notification.type),
          duration: AppDurations.snackbarDefault,
          action: SnackBarAction(
            label: AppConstants.actionRefreshCaps,
            textColor: Colors.white,
            onPressed: () {
              if (_userId != null) {
                context.read<GateStaffBloc>().add(
                  GateStaffDashboardRequested(userId: _userId!),
                );
              }
            },
          ),
        ),
      );
    }
    if (_isRelevantNotification(notification)) {
      _refreshDashboard();
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toUpperCase()) {
      case 'GATE_ENTRY':
        return AppColors.statusSuccess;
      case 'GATE_EXIT':
        return AppColors.statusWarning;
      case 'ARRIVAL':
      case 'ARRIVAL_NOTIFICATION':
        return AppColors.statusInfo;
      case 'ALERT':
      case 'SYSTEM_ALERT':
        return AppColors.statusError;
      default:
        return AppColors.textSecondary;
    }
  }

  bool _isRelevantNotification(WebSocketNotification notification) {
    return notification.type == NotificationType.attendanceUpdate ||
           notification.type == NotificationType.tripUpdate ||
           notification.type == NotificationType.vehicleAssignmentRequest ||
           notification.type.toUpperCase() == 'GATE_ENTRY' ||
           notification.type.toUpperCase() == 'GATE_EXIT' ||
           notification.type.toUpperCase() == 'ARRIVAL_NOTIFICATION';
  }

  void _refreshDashboard() {
    if (_userId != null) {
      context.read<GateStaffBloc>().add(
        GateStaffDashboardRequested(userId: _userId!),
      );
    }
  }

  Future<void> _showRemarksDialog(int studentId, int tripId, String eventType) async {
    final TextEditingController remarksController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${AppConstants.labelMarkGatePrefix}${eventType.toUpperCase()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(AppConstants.labelAddRemarks),
            const SizedBox(height: AppSizes.gateStaffSpacingXS),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                hintText: AppConstants.labelEnterRemarks,
                border: OutlineInputBorder(),
              ),
              maxLines: AppSizes.gateStaffRemarksMaxLines,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppConstants.actionCancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (_userId != null) {
                if (eventType == AppConstants.labelEntry.toLowerCase()) {
                  context.read<GateStaffBloc>().add(
                    GateStaffMarkEntryRequested(
                      userId: _userId!,
                      studentId: studentId,
                      tripId: tripId,
                      remarks: remarksController.text,
                    ),
                  );
                } else {
                  context.read<GateStaffBloc>().add(
                    GateStaffMarkExitRequested(
                      userId: _userId!,
                      studentId: studentId,
                      tripId: tripId,
                      remarks: remarksController.text,
                    ),
                  );
                }
              }
            },
            child: Text('${AppConstants.labelMarkGatePrefix}${eventType.toUpperCase()}'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppConstants.alertConfirmLogout),
        content: const Text(AppConstants.alertLogoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppConstants.actionCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusError),
            onPressed: () => Navigator.pop(ctx, true),
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
        title: const Text(AppConstants.labelGateStaffDashboard),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textWhite,
        actions: [
          // WebSocket connection status
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.gateStaffPaddingOnly),
            child: Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? AppColors.statusSuccess : AppColors.statusError,
              size: AppSizes.gateStaffWifiIconSize,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDashboard,
            tooltip: AppConstants.labelRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
            tooltip: AppConstants.actionLogout,
          ),
        ],
      ),
      body: BlocListener<GateStaffBloc, GateStaffState>(
        listener: (context, state) {
          if (state is GateStaffActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.statusSuccess,
              ),
            );
          } else if (state is GateStaffError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.statusError,
              ),
            );
          }
        },
        child: BlocBuilder<GateStaffBloc, GateStaffState>(
          builder: (context, state) {
            if (state is GateStaffLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is GateStaffDashboardLoaded) {
              return _buildDashboardContent(state.dashboard);
            } else if (state is GateStaffRefreshing && state.dashboard != null) {
              return Stack(
                children: [
                  _buildDashboardContent(state.dashboard!),
                  const Positioned(
                    top: 16,
                    right: 16,
                    child: CircularProgressIndicator(),
                  ),
                ],
              );
            } else if (state is GateStaffError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error,
                      size: AppSizes.gateStaffErrorIconSize,
                      color: AppColors.statusError,
                    ),
                    const SizedBox(height: AppSizes.gateStaffSpacingMD),
                    Text(
                      AppConstants.msgError,
                      style: const TextStyle(
                        fontSize: AppSizes.gateStaffErrorTitleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.gateStaffSpacingXS),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: AppSizes.gateStaffErrorTextFontSize),
                    ),
                    const SizedBox(height: AppSizes.gateStaffSpacingMD),
                    ElevatedButton(
                      onPressed: _refreshDashboard,
                      child: const Text(AppConstants.labelRetry),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: Text(AppConstants.labelNoDataAvailable));
          },
        ),
      ),
    );
  }

  Widget _buildDashboardContent(Map<String, dynamic> data) {
    final gateStaffName = data['gateStaffName'] ?? AppConstants.labelGateStaff;
    final schoolName = data['schoolName'] ?? AppConstants.labelSchool;
    final totalStudents = data['totalStudents'] ?? 0;
    final studentsWithGateEntry = data['studentsWithGateEntry'] ?? 0;
    final studentsWithGateExit = data['studentsWithGateExit'] ?? 0;
    final studentsByTrip = data['studentsByTrip'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: () async {
        _refreshDashboard();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.gateStaffPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              padding: const EdgeInsets.all(AppSizes.gateStaffPadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryColor.withValues(alpha: 0.8), AppColors.primaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSizes.gateStaffWelcomeRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppConstants.labelWelcome}$gateStaffName!',
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: AppSizes.gateStaffWelcomeFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.gateStaffSpacingXS),
                  Text(
                    schoolName,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: AppSizes.gateStaffWelcomeSubFontSize,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSizes.gateStaffSpacingLG),
            
            // Statistics Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelTotalStudents,
                    totalStudents.toString(),
                    AppColors.primaryColor,
                    Icons.people,
                  ),
                ),
                const SizedBox(width: AppSizes.gateStaffSpacingSM),
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelGateEntry,
                    studentsWithGateEntry.toString(),
                    AppColors.statusSuccess,
                    Icons.login,
                  ),
                ),
                const SizedBox(width: AppSizes.gateStaffSpacingSM),
                Expanded(
                  child: _buildStatCard(
                    AppConstants.labelGateExit,
                    studentsWithGateExit.toString(),
                    AppColors.statusWarning,
                    Icons.logout,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSizes.gateStaffSpacingLG),
            
            // Students by Trip Section
            const Text(
              AppConstants.labelStudentsByTrip,
              style: TextStyle(fontSize: AppSizes.gateStaffTitleFontSize, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.gateStaffSpacingSM),
            
            if (studentsByTrip.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.gateStaffNoTripsPadding),
                  child: Text(
                    AppConstants.labelNoTripsScheduled,
                    style: const TextStyle(fontSize: AppSizes.gateStaffNoTripsFontSize, color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...studentsByTrip.map((tripData) => _buildTripCard(tripData)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: AppSizes.gateStaffStatCardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.gateStaffPadding),
        child: Column(
          children: [
            Icon(icon, color: color, size: AppSizes.gateStaffStatCardIconSize),
            const SizedBox(height: AppSizes.gateStaffSpacingXS),
            Text(
              value,
              style: TextStyle(
                fontSize: AppSizes.gateStaffStatCardValueFontSize,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppSizes.gateStaffStatCardLabelFontSize,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> tripData) {
    final tripName = tripData['tripName'] ?? AppConstants.labelUnknownTrip;
    final vehicleNumber = tripData['vehicleNumber'] ?? AppConstants.labelUnknownVehicle;
    final driverName = tripData['driverName'] ?? AppConstants.labelNoDriver;
    final students = tripData['students'] as List<dynamic>? ?? [];
    final studentCount = tripData['studentCount'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.gateStaffTripCardMargin),
      elevation: AppSizes.gateStaffTripCardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.gateStaffPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_bus, color: AppColors.primaryColor),
                const SizedBox(width: AppSizes.gateStaffSpacingXS),
                Expanded(
                  child: Text(
                    tripName,
                    style: const TextStyle(
                      fontSize: AppSizes.gateStaffTripTitleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.gateStaffSpacingXS, vertical: AppSizes.gateStaffSpacingXS / 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSizes.gateStaffTripCardRadius),
                  ),
                  child: Text(
                    '$studentCount${AppConstants.labelStudentsSuffix}',
                    style: TextStyle(
                      fontSize: AppSizes.gateStaffTripSubFontSize,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.gateStaffSpacingXS),
            Text(
              '${AppConstants.labelVehiclePrefix}$vehicleNumber',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (driverName != AppConstants.labelNoDriver)
              Text(
                '${AppConstants.labelDriverPrefix}$driverName',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            const SizedBox(height: AppSizes.gateStaffSpacingSM),
            
            if (students.isEmpty)
              const Text(
                AppConstants.labelNoStudentsAssigned,
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              ...students.map((student) => _buildStudentCard(student, tripData['tripId'])).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> studentData, int? tripId) {
    final studentId = studentData['studentId'];
    final finalTripId = tripId ?? studentData['tripId'];
    final firstName = studentData['firstName'] ?? '';
    final middleName = studentData['middleName'] ?? '';
    final lastName = studentData['lastName'] ?? '';
    final grade = studentData['grade'] ?? '';
    final section = studentData['section'] ?? '';
    final hasGateEntry = studentData['hasGateEntry'] ?? false;
    final hasGateExit = studentData['hasGateExit'] ?? false;
    
    final studentName = '$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName'.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.gateStaffStudentCardMargin),
      color: hasGateEntry && hasGateExit ? AppColors.statusSuccess.withValues(alpha: 0.1) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: hasGateEntry && hasGateExit ? AppColors.statusSuccess : AppColors.primaryColor,
          child: Icon(
            hasGateEntry && hasGateExit ? Icons.check : Icons.person,
            color: AppColors.textWhite,
          ),
        ),
        title: Text(studentName),
        subtitle: Text('$grade - $section'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!hasGateEntry)
              ElevatedButton(
                onPressed: () => _showRemarksDialog(studentId, finalTripId, AppConstants.labelEntry.toLowerCase()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusSuccess,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.gateStaffButtonPaddingH, vertical: AppSizes.gateStaffButtonPaddingV),
                ),
                child: Text(AppConstants.labelEntry),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.gateStaffButtonPaddingH, vertical: AppSizes.gateStaffButtonPaddingV),
                decoration: BoxDecoration(
                  color: AppColors.statusSuccess.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSizes.gateStaffButtonRadius),
                ),
                child: Text(
                  AppConstants.labelEntryChecked,
                  style: const TextStyle(color: AppColors.statusSuccess, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(width: AppSizes.gateStaffSpacingXS),
            if (!hasGateExit)
              ElevatedButton(
                onPressed: () => _showRemarksDialog(studentId, finalTripId, AppConstants.labelExit.toLowerCase()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusWarning,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.gateStaffButtonPaddingH, vertical: AppSizes.gateStaffButtonPaddingV),
                ),
                child: Text(AppConstants.labelExit),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.gateStaffButtonPaddingH, vertical: AppSizes.gateStaffButtonPaddingV),
                decoration: BoxDecoration(
                  color: AppColors.statusWarning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSizes.gateStaffButtonRadius),
                ),
                child: Text(
                  AppConstants.labelExitChecked,
                  style: const TextStyle(color: AppColors.statusWarning, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


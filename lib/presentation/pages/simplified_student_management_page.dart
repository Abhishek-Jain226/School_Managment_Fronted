import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/models/trip.dart';
import '../../services/driver_service.dart';
import '../../services/location_tracking_service.dart';
import '../../bloc/driver/driver_bloc.dart';
import '../../bloc/driver/driver_event.dart';
import '../../utils/constants.dart';


class SimplifiedStudentManagementPage extends StatefulWidget {
  final Trip trip;
  final int driverId;
  final bool isReadOnly;

  const SimplifiedStudentManagementPage({
    super.key,
    required this.trip,
    required this.driverId,
    this.isReadOnly = false,
  });

  @override
  State<SimplifiedStudentManagementPage> createState() => _SimplifiedStudentManagementPageState();
}

class _SimplifiedStudentManagementPageState extends State<SimplifiedStudentManagementPage> {
  final DriverService _driverService = DriverService();
  bool _isLoading = false;
  bool _isTripActive = false;
  bool _hasRequestedPermissions = false;

  @override
  void initState() {
    super.initState();
    if (widget.isReadOnly) {
      _isTripActive = false;
    } else {
      _requestLocationPermissionsAndStartTrip();
    }
  }

  Future<void> _requestLocationPermissionsAndStartTrip() async {
    if (widget.isReadOnly) return;
    
    if (_hasRequestedPermissions) return;
    
    setState(() {
      _hasRequestedPermissions = true;
    });

    try {
      // Request location permission
      bool hasPermission = await _requestLocationPermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.msgLocationPermissionRequiredToStartTrip),
            backgroundColor: AppColors.errorColor,
          ),
        );
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationSettingsDialog();
        return;
      }

      // Start location tracking
      setState(() {
        _isTripActive = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppConstants.msgTripStartedFor + widget.trip.tripName),
          backgroundColor: AppColors.successColor,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppConstants.msgFailedToStartTrip} $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<bool> _requestLocationPermission() async {
    // Check current permission status
    var status = await Permission.location.status;
    
    debugPrint('🔍 Current location permission status: $status');
    
    // If permission is already granted, return true
    if (status == PermissionStatus.granted) {
      return true;
    }
    
    // If permission is denied permanently, show dialog to open settings
    if (status == PermissionStatus.permanentlyDenied) {
      _showPermissionDeniedDialog();
      return false;
    }
    
    // If permission is denied or restricted, request it
    if (status == PermissionStatus.denied || status == PermissionStatus.restricted) {
      status = await Permission.location.request();
      debugPrint('🔍 Location permission request result: $status');
      
      if (status == PermissionStatus.granted) {
        return true;
      } else if (status == PermissionStatus.permanentlyDenied) {
        _showPermissionDeniedDialog();
        return false;
      } else {
        _showPermissionDeniedDialog();
        return false;
      }
    }
    
    return false;
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppConstants.labelLocationPermissionRequired),
        content: const Text(AppConstants.msgLocationPermissionRequired),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppConstants.actionCancel),
          ),
          ElevatedButton(
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

  void _showLocationSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppConstants.labelLocationSettings),
        content: const Text(AppConstants.msgEnableLocationServices),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppConstants.actionCancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text(AppConstants.labelOpenSettings),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.labelStudents + ' - ${widget.trip.tripName}'),
        actions: widget.isReadOnly
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {});
                  },
                ),
              ],
      ),
      body: Column(
        children: [
          // Trip Information Header
          _buildTripHeader(),
          
          // Students List
          Expanded(
            child: widget.trip.students.isEmpty
                ? const Center(
                    child: Text(
                      AppConstants.msgNoStudentsAssigned,
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.paddingMD),
                    itemCount: widget.trip.students.length,
                    itemBuilder: (context, index) {
                      return _buildStudentCard(widget.trip.students[index]);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMD),
          child: widget.isReadOnly
              ? OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text(AppConstants.actionClose),
                )
              : ElevatedButton.icon(
                  onPressed: _isLoading || !_isTripActive ? null : _endTrip,
                  icon: const Icon(Icons.flag),
                  label: const Text(AppConstants.labelEndTrip),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.driverErrorColor,
                    foregroundColor: AppColors.driverTextWhite,
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSM),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTripHeader() {
    final isMorningTrip = _isMorningTrip();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      color: isMorningTrip ? AppColors.morningTripBg : AppColors.afternoonTripBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isMorningTrip ? Icons.wb_sunny : Icons.wb_twilight,
                color: isMorningTrip ? AppColors.morningTripIcon : AppColors.afternoonTripIcon,
                size: AppSizes.iconMD,
              ),
              const SizedBox(width: AppSizes.marginSM),
              Text(
                widget.trip.tripName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.marginSM),
          Text(
            '${widget.trip.tripType} - ${widget.trip.scheduledTime ?? 'No time set'}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.marginSM),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total',
                  '${widget.trip.totalStudents}',
                  Icons.group,
                  AppColors.primaryColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Picked',
                  '${widget.trip.studentsPickedUp}',
                  Icons.person_add,
                  AppColors.successColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Dropped',
                  '${widget.trip.studentsDropped}',
                  Icons.person_remove,
                  AppColors.warningColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Absent',
                  '${widget.trip.studentsAbsent}',
                  Icons.person_off,
                  AppColors.errorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.marginSM),
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingSM),
            decoration: BoxDecoration(
              color: isMorningTrip ? AppColors.morningTripInfoBg : AppColors.afternoonTripInfoBg,
              borderRadius: BorderRadius.circular(AppSizes.radiusSM),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info,
                  color: isMorningTrip ? AppColors.morningTripInfoIcon : AppColors.afternoonTripInfoIcon,
                  size: AppSizes.iconSM,
                ),
                const SizedBox(width: AppSizes.marginSM),
                Expanded(
                  child: Text(
                    isMorningTrip 
                      ? AppConstants.msgMorningTripInfo
                      : AppConstants.msgAfternoonTripInfo,
                    style: TextStyle(
                      fontSize: 12,
                      color: isMorningTrip ? AppColors.morningTripInfoIcon : AppColors.afternoonTripInfoIcon,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStudentCard(TripStudent student) {
    final statusColor = _getStatusColor(student.attendanceStatus);
    final statusIcon = _getStatusIcon(student.attendanceStatus);
    final isMorningTrip = _isMorningTrip();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSizes.marginSM),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMD)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        child: Column(
          children: [
            // Student Info
            Row(
              children: [
                CircleAvatar(
                  radius: AppSizes.iconXL / 2,
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  child: Icon(statusIcon, color: statusColor, size: AppSizes.iconMD),
                ),
                const SizedBox(width: AppSizes.marginMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.studentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${student.className} - ${student.sectionName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: AppSizes.iconXS, color: AppColors.textSecondary),
                          const SizedBox(width: AppSizes.marginXS),
                          Expanded(
                            child: Text(
                              'Pickup: ${student.pickupLocation}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.location_off, size: AppSizes.iconXS, color: AppColors.textSecondary),
                          const SizedBox(width: AppSizes.marginXS),
                          Expanded(
                            child: Text(
                              'Drop: ${student.dropLocation}',
                              style: TextStyle(
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
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingSM, vertical: AppSizes.paddingXS),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                        border: Border.all(color: statusColor, width: 1),
                      ),
                      child: Text(
                        student.attendanceStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppConstants.labelOrderPrefix + '${student.pickupOrder}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: AppSizes.marginMD),
            
            // Action Buttons
            _buildActionButtons(student, isMorningTrip),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(TripStudent student, bool isMorningTrip) {
    if (widget.isReadOnly) {
      return const SizedBox.shrink();
    }

    // If trip is not active, show disabled buttons with message
    if (!_isTripActive) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusSM),
          border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.location_off, color: AppColors.textSecondary, size: AppSizes.iconLG),
            const SizedBox(height: AppSizes.marginSM),
            Text(
              AppConstants.msgTripNotStartedYet,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.marginXS),
            Text(
              AppConstants.msgLocationPermissionsRequesting,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // 5-Minute Alert Button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _send5MinuteAlert(student),
            icon: const Icon(Icons.notifications, size: AppSizes.iconSM),
            label: const Text(AppConstants.labelSendAlert),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warningColor,
              foregroundColor: AppColors.textWhite,
              padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingXS),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.marginSM),
        
        // Context-sensitive action buttons
        if (isMorningTrip) ...[
          // Morning Trip Actions
          Expanded(
            child: ElevatedButton.icon(
              onPressed: student.attendanceStatus == 'PENDING' 
                ? () => _markPickupFromHome(student)
                : null,
              icon: const Icon(Icons.home, size: AppSizes.iconSM),
              label: const Text(AppConstants.labelPickup),
              style: ElevatedButton.styleFrom(
                backgroundColor: student.attendanceStatus == 'PENDING' ? AppColors.successColor : AppColors.textSecondary,
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingXS),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.marginSM),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: student.attendanceStatus == 'PICKED_UP' 
                ? () => _markDropToSchool(student)
                : null,
              icon: const Icon(Icons.school, size: AppSizes.iconSM),
              label: const Text(AppConstants.labelDrop),
              style: ElevatedButton.styleFrom(
                backgroundColor: student.attendanceStatus == 'PICKED_UP' ? AppColors.primaryColor : AppColors.textSecondary,
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingXS),
              ),
            ),
          ),
        ] else ...[
          // Afternoon Trip Actions
          Expanded(
            child: ElevatedButton.icon(
              onPressed: student.attendanceStatus == 'PENDING' 
                ? () => _markPickupFromSchool(student)
                : null,
              icon: const Icon(Icons.school, size: AppSizes.iconSM),
              label: const Text(AppConstants.labelPickup),
              style: ElevatedButton.styleFrom(
                backgroundColor: student.attendanceStatus == 'PENDING' ? AppColors.successColor : AppColors.textSecondary,
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingXS),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.marginSM),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: student.attendanceStatus == 'PICKED_UP' 
                ? () => _markDropToHome(student)
                : null,
              icon: const Icon(Icons.home, size: AppSizes.iconSM),
              label: const Text(AppConstants.labelDrop),
              style: ElevatedButton.styleFrom(
                backgroundColor: student.attendanceStatus == 'PICKED_UP' ? AppColors.primaryColor : AppColors.textSecondary,
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingXS),
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool _isMorningTrip() {
    return widget.trip.tripType == 'MORNING_PICKUP';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return AppColors.warningColor;
      case 'PICKED_UP':
        return AppColors.primaryColor;
      case 'DROPPED':
        return AppColors.successColor;
      case 'ABSENT':
        return AppColors.errorColor;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'PENDING':
        return Icons.schedule;
      case 'PICKED_UP':
        return Icons.person_add;
      case 'DROPPED':
        return Icons.check_circle;
      case 'ABSENT':
        return Icons.person_off;
      default:
        return Icons.help;
    }
  }

  Future<void> _send5MinuteAlert(TripStudent student) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _driverService.send5MinuteAlert(widget.driverId, widget.trip.tripId, student.studentId);
      
      if (response[AppConstants.keySuccess] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('5-minute alert sent to ${student.studentName}\'s parents'),
            backgroundColor: AppColors.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response[AppConstants.keyMessage] ?? AppConstants.msgFailedToSendAlertGeneric),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppConstants.msgErrorSendingAlert} $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markPickupFromHome(TripStudent student) async {
    await _markStudentAction(student, 'pickup-home', 'Student picked up from home');
  }

  Future<void> _markDropToSchool(TripStudent student) async {
    await _markStudentAction(student, 'drop-school', 'Student dropped at school');
  }

  Future<void> _markPickupFromSchool(TripStudent student) async {
    await _markStudentAction(student, 'pickup-school', 'Student picked up from school');
  }

  Future<void> _markDropToHome(TripStudent student) async {
    await _markStudentAction(student, 'drop-home', 'Student dropped at home');
  }

  Future<void> _markStudentAction(TripStudent student, String action, String successMessage) async {
    try {
      setState(() {
        _isLoading = true;
      });

      Map<String, dynamic> response;
      switch (action) {
        case 'pickup-home':
          response = await _driverService.markPickupFromHome(widget.driverId, widget.trip.tripId, student.studentId);
          break;
        case 'drop-school':
          response = await _driverService.markDropToSchool(widget.driverId, widget.trip.tripId, student.studentId);
          break;
        case 'pickup-school':
          response = await _driverService.markPickupFromSchool(widget.driverId, widget.trip.tripId, student.studentId);
          break;
        case 'drop-home':
          response = await _driverService.markDropToHome(widget.driverId, widget.trip.tripId, student.studentId);
          break;
        default:
          throw Exception('Invalid action: $action');
      }
      
      if (response[AppConstants.keySuccess] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successMessage for ${student.studentName}'),
            backgroundColor: AppColors.successColor,
          ),
        );
        
        // Update student status locally
        setState(() {
          // Find the student in the trip and update their status
          final studentIndex = widget.trip.students.indexWhere((s) => s.studentId == student.studentId);
          if (studentIndex != -1) {
            String newStatus;
            if (action == 'pickup-home' || action == 'pickup-school') {
              newStatus = 'PICKED_UP';
            } else if (action == 'drop-school' || action == 'drop-home') {
              newStatus = 'DROPPED';
            } else {
              newStatus = student.attendanceStatus;
            }
            
            // Create a new TripStudent with updated status
            final updatedStudent = student.copyWith(attendanceStatus: newStatus);
            
            // Create a new Trip with updated students list
            final updatedStudents = List<TripStudent>.from(widget.trip.students);
            updatedStudents[studentIndex] = updatedStudent;
            
            // Note: Trip is immutable, would need to refresh from backend
            // For now, just trigger a rebuild to show the success message
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response[AppConstants.keyMessage] ?? AppConstants.msgFailedToSendAlertGeneric),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppConstants.msgErrorMarkingAction} $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

    Future<void> _endTrip() async {
      if (_isLoading) return;
      setState(() {
        _isLoading = true;
      });

      try {
        // Stop background location tracking service before ending trip
        final locationService = LocationTrackingService();
        locationService.stopLocationTracking();

        // Call backend endTrip API to update trip_status
        context.read<DriverBloc>().add(
          DriverEndTripRequested(
            driverId: widget.driverId,
            tripId: widget.trip.tripId,
          ),
        );
        
        if (!mounted) return;
        setState(() {
          _isTripActive = false;
          _isLoading = false;
        });
        
        // Note: Success message will be shown by BlocListener
        Navigator.pop(context, 'tripSessionEnded');
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppConstants.errorFailedToEndTrip}: $e')),  
        );
      }
    }
}

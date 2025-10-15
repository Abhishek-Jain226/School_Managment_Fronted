import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/models/trip.dart';
import '../../services/driver_service.dart';

class SimplifiedStudentManagementPage extends StatefulWidget {
  final Trip trip;
  final int driverId;

  const SimplifiedStudentManagementPage({
    super.key,
    required this.trip,
    required this.driverId,
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
    _requestLocationPermissionsAndStartTrip();
  }

  Future<void> _requestLocationPermissionsAndStartTrip() async {
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
            content: Text('Location permission is required to start trip'),
            backgroundColor: Colors.red,
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
          content: Text('Trip started! Location tracking enabled for ${widget.trip.tripName}'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start trip: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _requestLocationPermission() async {
    // Check current permission status
    var status = await Permission.location.status;
    
    print('🔍 Current location permission status: $status');
    
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
      print('🔍 Location permission request result: $status');
      
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
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs location permission to track your trip and share your location with parents. Please grant location permission in the app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showLocationSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Location services are disabled. Please enable them in your device settings to start trip tracking.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Students - ${widget.trip.tripName}'),
        actions: [
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
                      'No students assigned to this trip',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.trip.students.length,
                    itemBuilder: (context, index) {
                      return _buildStudentCard(widget.trip.students[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripHeader() {
    final isMorningTrip = _isMorningTrip();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: isMorningTrip ? Colors.orange[50] : Colors.blue[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isMorningTrip ? Icons.wb_sunny : Icons.wb_twilight,
                color: isMorningTrip ? Colors.orange : Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                widget.trip.tripName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.trip.tripType} - ${widget.trip.scheduledTime ?? 'No time set'}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total',
                  '${widget.trip.totalStudents}',
                  Icons.group,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Picked',
                  '${widget.trip.studentsPickedUp}',
                  Icons.person_add,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Dropped',
                  '${widget.trip.studentsDropped}',
                  Icons.person_remove,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Absent',
                  '${widget.trip.studentsAbsent}',
                  Icons.person_off,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isMorningTrip ? Colors.orange[100] : Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info,
                  color: isMorningTrip ? Colors.orange[700] : Colors.blue[700],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isMorningTrip 
                      ? 'Morning Trip: Pickup from Home → Drop to School'
                      : 'Afternoon Trip: Pickup from School → Drop to Home',
                    style: TextStyle(
                      fontSize: 12,
                      color: isMorningTrip ? Colors.orange[700] : Colors.blue[700],
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Student Info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 16),
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
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Pickup: ${student.pickupLocation}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.location_off, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Drop: ${student.dropLocation}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
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
                      'Order: ${student.pickupOrder}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            _buildActionButtons(student, isMorningTrip),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(TripStudent student, bool isMorningTrip) {
    // If trip is not active, show disabled buttons with message
    if (!_isTripActive) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(Icons.location_off, color: Colors.grey[600], size: 32),
            const SizedBox(height: 8),
            Text(
              'Trip not started yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Location permissions are being requested...',
              style: TextStyle(
                color: Colors.grey[600],
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
            icon: const Icon(Icons.notifications, size: 16),
            label: const Text('Send Alert'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        
        // Context-sensitive action buttons
        if (isMorningTrip) ...[
          // Morning Trip Actions
          Expanded(
            child: ElevatedButton.icon(
              onPressed: student.attendanceStatus == 'PENDING' 
                ? () => _markPickupFromHome(student)
                : null,
              icon: const Icon(Icons.home, size: 16),
              label: const Text('Pickup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: student.attendanceStatus == 'PENDING' ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: student.attendanceStatus == 'PICKED_UP' 
                ? () => _markDropToSchool(student)
                : null,
              icon: const Icon(Icons.school, size: 16),
              label: const Text('Drop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: student.attendanceStatus == 'PICKED_UP' ? Colors.blue : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
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
              icon: const Icon(Icons.school, size: 16),
              label: const Text('Pickup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: student.attendanceStatus == 'PENDING' ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: student.attendanceStatus == 'PICKED_UP' 
                ? () => _markDropToHome(student)
                : null,
              icon: const Icon(Icons.home, size: 16),
              label: const Text('Drop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: student.attendanceStatus == 'PICKED_UP' ? Colors.blue : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
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
        return Colors.orange;
      case 'PICKED_UP':
        return Colors.blue;
      case 'DROPPED':
        return Colors.green;
      case 'ABSENT':
        return Colors.red;
      default:
        return Colors.grey;
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

      final response = await _driverService.send5MinuteAlert(widget.driverId, widget.trip.tripId);
      
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('5-minute alert sent to ${student.studentName}\'s parents'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to send alert'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending alert: $e'),
          backgroundColor: Colors.red,
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
      
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successMessage for ${student.studentName}'),
            backgroundColor: Colors.green,
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
            
            // Update the trip with new students list
            final updatedTrip = widget.trip.copyWith(students: updatedStudents);
            
            // Note: Since Trip is also immutable, we would need to refresh from backend
            // For now, just trigger a rebuild to show the success message
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to mark action'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking action: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

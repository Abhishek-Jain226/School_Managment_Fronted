import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/trip.dart';
import '../../data/models/student_attendance.dart';
import '../../services/driver_service.dart';

class StudentAttendancePage extends StatefulWidget {
  final Trip trip;
  final TripStudent? selectedStudent;

  const StudentAttendancePage({
    super.key,
    required this.trip,
    this.selectedStudent,
  });

  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage> {
  final DriverService _driverService = DriverService();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  bool _isLoading = false;
  int? _driverId;
  String _selectedEventType = 'PICKUP_FROM_PARENT';
  bool _sendNotification = true;
  String _notificationMessage = '';

  final List<Map<String, String>> _eventTypes = [
    {'value': 'PICKUP_FROM_PARENT', 'label': 'Pickup from Parent'},
    {'value': 'DROP_TO_SCHOOL', 'label': 'Drop to School'},
    {'value': 'PICKUP_FROM_SCHOOL', 'label': 'Pickup from School'},
    {'value': 'DROP_TO_PARENT', 'label': 'Drop to Parent'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDriverId();
    _setDefaultNotificationMessage();
  }

  Future<void> _loadDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    _driverId = prefs.getInt('driverId');
  }

  void _setDefaultNotificationMessage() {
    final eventType = _eventTypes.firstWhere(
      (e) => e['value'] == _selectedEventType,
      orElse: () => _eventTypes.first,
    );
    
    switch (_selectedEventType) {
      case 'PICKUP_FROM_PARENT':
        _notificationMessage = 'Your child has been picked up from home.';
        break;
      case 'DROP_TO_SCHOOL':
        _notificationMessage = 'Your child has been dropped at school safely.';
        break;
      case 'PICKUP_FROM_SCHOOL':
        _notificationMessage = 'Your child has been picked up from school.';
        break;
      case 'DROP_TO_PARENT':
        _notificationMessage = 'Your child has been dropped at home safely.';
        break;
    }
  }

  Future<void> _markAttendance(TripStudent student) async {
    if (_driverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver ID not found. Please login again.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final attendanceRequest = StudentAttendanceRequest(
        tripId: widget.trip.tripId,
        studentId: student.studentId,
        eventType: _selectedEventType,
        driverId: _driverId!,
        remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        eventTime: DateTime.now(),
        sendNotificationToParent: _sendNotification,
        notificationMessage: _sendNotification ? _notificationMessage : null,
      );

      final response = await _driverService.markAttendance(_driverId!, attendanceRequest);
      
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance marked successfully for ${student.studentName}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear form
        _remarksController.clear();
        _locationController.clear();
        
        // Navigate back
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark attendance: ${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking attendance: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  Widget _buildStudentCard(TripStudent student) {
    final statusColor = _getStatusColor(student.attendanceStatus);
    final statusIcon = _getStatusIcon(student.attendanceStatus);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showAttendanceDialog(student),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
        ),
      ),
    );
  }

  void _showAttendanceDialog(TripStudent student) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Mark Attendance - ${student.studentName}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Type Selection
                    const Text(
                      'Event Type:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedEventType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _eventTypes.map((eventType) {
                        return DropdownMenuItem<String>(
                          value: eventType['value'],
                          child: Text(eventType['label']!),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          _selectedEventType = newValue!;
                          _setDefaultNotificationMessage();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Location
                    TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Remarks
                    TextField(
                      controller: _remarksController,
                      decoration: const InputDecoration(
                        labelText: 'Remarks (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    // Notification Settings
                    CheckboxListTile(
                      title: const Text('Send notification to parent'),
                      subtitle: const Text('Notify parent about this event'),
                      value: _sendNotification,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          _sendNotification = value ?? false;
                        });
                      },
                    ),
                    
                    if (_sendNotification) ...[
                      const SizedBox(height: 8),
                      TextField(
                        onChanged: (value) {
                          setDialogState(() {
                            _notificationMessage = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Notification Message',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.message),
                        ),
                        maxLines: 2,
                        controller: TextEditingController(text: _notificationMessage),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : () {
                    Navigator.of(context).pop();
                    _markAttendance(student);
                  },
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Mark Attendance'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance - ${widget.trip.tripName}'),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.trip.tripName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${widget.trip.tripType} - ${widget.trip.scheduledTime ?? 'No time set'}'),
                const SizedBox(height: 8),
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
              ],
            ),
          ),
          
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

  @override
  void dispose() {
    _remarksController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}

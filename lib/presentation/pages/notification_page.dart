import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/trip.dart';
import '../../data/models/notification_request.dart';
import '../../services/driver_service.dart';

class NotificationPage extends StatefulWidget {
  final Trip trip;
  final List<TripStudent>? selectedStudents;

  const NotificationPage({
    super.key,
    required this.trip,
    this.selectedStudents,
  });

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final DriverService _driverService = DriverService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  
  bool _isLoading = false;
  int? _driverId;
  String _selectedNotificationType = 'ARRIVAL_NOTIFICATION';
  bool _sendSms = true;
  bool _sendEmail = true;
  bool _sendPushNotification = true;
  int _minutesBeforeArrival = 5;
  List<int> _selectedStudentIds = [];

  final List<Map<String, String>> _notificationTypes = [
    {'value': 'ARRIVAL_NOTIFICATION', 'label': 'Arrival Notification'},
    {'value': 'PICKUP_CONFIRMATION', 'label': 'Pickup Confirmation'},
    {'value': 'DROP_CONFIRMATION', 'label': 'Drop Confirmation'},
    {'value': 'DELAY_NOTIFICATION', 'label': 'Delay Notification'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDriverId();
    _setDefaultMessage();
    _initializeSelectedStudents();
  }

  Future<void> _loadDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    _driverId = prefs.getInt('driverId');
  }

  void _initializeSelectedStudents() {
    if (widget.selectedStudents != null) {
      _selectedStudentIds = widget.selectedStudents!.map((s) => s.studentId).toList();
    } else {
      _selectedStudentIds = widget.trip.students.map((s) => s.studentId).toList();
    }
  }

  void _setDefaultMessage() {
    switch (_selectedNotificationType) {
      case 'ARRIVAL_NOTIFICATION':
        _titleController.text = 'Vehicle Arrival Notification';
        _messageController.text = 'Your child\'s school vehicle will arrive in $_minutesBeforeArrival minutes. Please be ready for pickup.';
        break;
      case 'PICKUP_CONFIRMATION':
        _titleController.text = 'Pickup Confirmation';
        _messageController.text = 'Your child has been successfully picked up from home.';
        break;
      case 'DROP_CONFIRMATION':
        _titleController.text = 'Drop Confirmation';
        _messageController.text = 'Your child has been safely dropped at school.';
        break;
      case 'DELAY_NOTIFICATION':
        _titleController.text = 'Delay Notification';
        _messageController.text = 'We apologize for the delay. Your child\'s school vehicle is running behind schedule.';
        break;
    }
  }

  Future<void> _sendNotification() async {
    if (_driverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver ID not found. Please login again.')),
      );
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a notification message')),
      );
      return;
    }

    if (_selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one student')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final notificationRequest = NotificationRequest(
        driverId: _driverId!,
        tripId: widget.trip.tripId,
        notificationType: _selectedNotificationType,
        message: _messageController.text.trim(),
        title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        studentIds: _selectedStudentIds,
        sendSms: _sendSms,
        sendEmail: _sendEmail,
        sendPushNotification: _sendPushNotification,
        minutesBeforeArrival: _selectedNotificationType == 'ARRIVAL_NOTIFICATION' ? _minutesBeforeArrival : null,
      );

      final response = await _driverService.sendNotification(_driverId!, notificationRequest);
      
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification sent successfully to ${_selectedStudentIds.length} parent(s)'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear form
        _messageController.clear();
        _titleController.clear();
        
        // Navigate back
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send notification: ${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildStudentSelectionCard(TripStudent student) {
    final isSelected = _selectedStudentIds.contains(student.studentId);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: CheckboxListTile(
        title: Text(student.studentName),
        subtitle: Text('${student.className} - ${student.sectionName}'),
        value: isSelected,
        onChanged: (bool? value) {
          setState(() {
            if (value == true) {
              _selectedStudentIds.add(student.studentId);
            } else {
              _selectedStudentIds.remove(student.studentId);
            }
          });
        },
        secondary: CircleAvatar(
          radius: 16,
          backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
          child: Icon(
            isSelected ? Icons.check : Icons.person,
            color: isSelected ? Colors.white : Colors.grey[600],
            size: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isLoading ? null : _sendNotification,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trip Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Trip: ${widget.trip.tripName}'),
                          Text('Type: ${widget.trip.tripType}'),
                          Text('Time: ${widget.trip.scheduledTime ?? 'No time set'}'),
                          Text('Students: ${widget.trip.students.length}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Notification Type
                  const Text(
                    'Notification Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedNotificationType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _notificationTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type['value'],
                        child: Text(type['label']!),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedNotificationType = newValue!;
                        _setDefaultMessage();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Minutes Before Arrival (for arrival notifications)
                  if (_selectedNotificationType == 'ARRIVAL_NOTIFICATION') ...[
                    const Text(
                      'Minutes Before Arrival',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _minutesBeforeArrival.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: '$_minutesBeforeArrival minutes',
                      onChanged: (double value) {
                        setState(() {
                          _minutesBeforeArrival = value.round();
                          _setDefaultMessage();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Title
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Notification Title',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Message
                  TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Notification Message',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.message),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  
                  // Delivery Options
                  const Text(
                    'Delivery Options',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            title: const Text('SMS'),
                            subtitle: const Text('Send via text message'),
                            value: _sendSms,
                            onChanged: (bool? value) {
                              setState(() {
                                _sendSms = value ?? false;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: const Text('Email'),
                            subtitle: const Text('Send via email'),
                            value: _sendEmail,
                            onChanged: (bool? value) {
                              setState(() {
                                _sendEmail = value ?? false;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: const Text('Push Notification'),
                            subtitle: const Text('Send push notification to app'),
                            value: _sendPushNotification,
                            onChanged: (bool? value) {
                              setState(() {
                                _sendPushNotification = value ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Student Selection
                  const Text(
                    'Select Students',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Select All/None buttons
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedStudentIds = widget.trip.students.map((s) => s.studentId).toList();
                          });
                        },
                        child: const Text('Select All'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedStudentIds.clear();
                          });
                        },
                        child: const Text('Select None'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Students List
                  ...widget.trip.students.map((student) => _buildStudentSelectionCard(student)),
                  
                  const SizedBox(height: 24),
                  
                  // Send Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _sendNotification,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: Text(_isLoading ? 'Sending...' : 'Send Notification'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _titleController.dispose();
    super.dispose();
  }
}

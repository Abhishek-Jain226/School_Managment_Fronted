import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../services/vehicle_owner_service.dart';
import '../../services/trip_service.dart';
import '../../services/student_service.dart';
import '../../services/trip_student_service.dart';

class VehicleOwnerStudentTripAssignmentPage extends StatefulWidget {
  const VehicleOwnerStudentTripAssignmentPage({super.key});

  @override
  State<VehicleOwnerStudentTripAssignmentPage> createState() => _VehicleOwnerStudentTripAssignmentPageState();
}

class _VehicleOwnerStudentTripAssignmentPageState extends State<VehicleOwnerStudentTripAssignmentPage> {
  final VehicleOwnerService _vehicleOwnerService = VehicleOwnerService();
  final TripService _tripService = TripService();
  final StudentService _studentService = StudentService();
  final TripStudentService _tripStudentService = TripStudentService();
  
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _assignments = [];
  bool _isLoading = true;
  Map<String, dynamic>? _ownerData;
  int? _currentSchoolId;
  Timer? _refreshTimer;
  DateTime? _lastUpdateTime;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startRealTimeUpdates();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRealTimeUpdates() {
    // Refresh data every 30 seconds for real-time updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _currentSchoolId != null) {
        _loadAssignmentsData();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("userId");
      _currentSchoolId = prefs.getInt("currentSchoolId");
      
      if (userId != null && _currentSchoolId != null) {
        // Load owner data
        final ownerResponse = await _vehicleOwnerService.getOwnerByUserId(userId);
        if (ownerResponse['success'] == true) {
          _ownerData = ownerResponse['data'];
          
          // Load trips for the current school
          final tripsResponse = await _tripService.getTripsBySchoolMap(_currentSchoolId!);
          if (tripsResponse['success'] == true) {
            setState(() {
              _trips = List<Map<String, dynamic>>.from(tripsResponse['data'] ?? []);
            });
          }
          
          // Load students for the current school
          final studentsResponse = await _studentService.getStudentsBySchool(_currentSchoolId!);
          if (studentsResponse['success'] == true) {
            setState(() {
              _students = List<Map<String, dynamic>>.from(studentsResponse['data'] ?? []);
            });
          }
          
          // Load existing trip-student assignments
          await _loadAssignmentsData();
        }
      }
    } catch (e) {
      print("Error loading data: $e");
      _showError("Error loading data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAssignmentsData() async {
    if (_currentSchoolId == null) return;
    
    try {
      final assignmentsResponse = await _tripStudentService.getAllAssignmentsBySchool(_currentSchoolId!);
      if (assignmentsResponse['success'] == true) {
        setState(() {
          _assignments = List<Map<String, dynamic>>.from(assignmentsResponse['data'] ?? []);
          _lastUpdateTime = DateTime.now();
        });
        print("🔍 Loaded ${_assignments.length} trip-student assignments");
      } else {
        print("🔍 Failed to load assignments: ${assignmentsResponse['message']}");
        setState(() {
          _assignments = [];
        });
      }
    } catch (e) {
      print("🔍 Error loading assignments: $e");
      setState(() {
        _assignments = [];
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showAssignStudentDialog() {
    if (_trips.isEmpty || _students.isEmpty) {
      _showError("No trips or students available for assignment");
      return;
    }

    String? selectedTripId;
    String? selectedStudentId;
    int pickupOrder = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Assign Student to Trip"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedTripId,
                decoration: const InputDecoration(
                  labelText: "Select Trip",
                  border: OutlineInputBorder(),
                ),
                items: _trips
                    .where((t) => t['isActive'] == true)
                    .map((trip) => DropdownMenuItem(
                          value: trip['tripId'].toString(),
                          child: Text(trip['tripName'] ?? 'Unknown Trip'),
                        ))
                    .toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedTripId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStudentId,
                decoration: const InputDecoration(
                  labelText: "Select Student",
                  border: OutlineInputBorder(),
                ),
                items: _students
                    .where((s) => s['isActive'] == true)
                    .map((student) => DropdownMenuItem(
                          value: student['studentId'].toString(),
                          child: Text("${student['firstName']} ${student['lastName']}"),
                        ))
                    .toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedStudentId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: pickupOrder.toString(),
                decoration: const InputDecoration(
                  labelText: "Pickup Order",
                  border: OutlineInputBorder(),
                  helperText: "Order in which student will be picked up",
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  pickupOrder = int.tryParse(value) ?? 1;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: selectedTripId != null && selectedStudentId != null
                  ? () {
                      Navigator.pop(ctx);
                      _assignStudentToTrip(
                        int.parse(selectedTripId!),
                        int.parse(selectedStudentId!),
                        pickupOrder,
                      );
                    }
                  : null,
              child: const Text("Assign"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignStudentToTrip(int tripId, int studentId, int pickupOrder) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString("userName") ?? "Vehicle Owner";
      
      final response = await _tripStudentService.assignStudentToTrip(
        tripId: tripId,
        studentId: studentId,
        pickupOrder: pickupOrder,
        createdBy: userName,
      );
      
      if (response['success'] == true) {
        _showSuccess("Student assigned to trip successfully");
        await _loadAssignmentsData(); // Refresh the assignments list
      } else {
        _showError("Failed to assign student: ${response['message']}");
      }
    } catch (e) {
      _showError("Error assigning student: $e");
    }
  }

  Future<void> _removeAssignment(int assignmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove Assignment"),
        content: const Text("Are you sure you want to remove this student from the trip?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Remove"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _tripStudentService.removeStudentFromTrip(assignmentId);
        
        if (response['success'] == true) {
          _showSuccess("Assignment removed successfully");
          await _loadAssignmentsData(); // Refresh the assignments list
        } else {
          _showError("Failed to remove assignment: ${response['message']}");
        }
      } catch (e) {
        _showError("Error removing assignment: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Student-Trip Assignments"),
            if (_lastUpdateTime != null)
              Text(
                "Last updated: ${_formatTime(_lastUpdateTime!)}",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _loadData();
              _showSuccess("Data refreshed successfully");
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentSchoolId == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 64,
                        color: Colors.orange.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Please select a school first",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Use the school selector in the dashboard",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Summary Cards
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.route,
                                      size: 32,
                                      color: Colors.blue.shade600,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _trips.length.toString(),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "Trips",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.school,
                                      size: 32,
                                      color: Colors.green.shade600,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _students.length.toString(),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "Students",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.assignment,
                                      size: 32,
                                      color: Colors.orange.shade600,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _assignments.length.toString(),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "Assignments",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Action Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showAssignStudentDialog,
                          icon: const Icon(Icons.add),
                          label: const Text("Assign Student to Trip"),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Assignments List
                    Expanded(
                      child: _assignments.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.assignment_outlined,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No student-trip assignments yet",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Assign students to trips to get started",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _assignments.length,
                              itemBuilder: (context, index) {
                                final assignment = _assignments[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue.shade600,
                                      child: Text(
                                        assignment['pickupOrder']?.toString() ?? '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      assignment['studentName'] ?? 'Unknown Student',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Trip: ${assignment['tripName'] ?? 'Unknown Trip'}"),
                                        Text("Pickup Order: ${assignment['pickupOrder'] ?? 'Not Set'}"),
                                        Text("Assigned on: ${_formatDate(assignment['createdDate'])}"),
                                        if (assignment['createdBy'] != null)
                                          Text("Created by: ${assignment['createdBy']}"),
                                      ],
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'edit':
                                            // TODO: Navigate to edit assignment
                                            _showSuccess("Edit functionality coming soon");
                                            break;
                                          case 'remove':
                                            _removeAssignment(assignment['tripStudentId']);
                                            break;
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 20),
                                              SizedBox(width: 8),
                                              Text('Edit Order'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'remove',
                                          child: Row(
                                            children: [
                                              Icon(Icons.remove_circle, size: 20, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Remove', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown date';
    
    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'Unknown date';
      }
      
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

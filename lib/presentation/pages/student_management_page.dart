import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../services/student_service.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart';

class StudentManagementPage extends StatefulWidget {
  const StudentManagementPage({super.key});

  @override
  State<StudentManagementPage> createState() => _StudentManagementPageState();
}

class _StudentManagementPageState extends State<StudentManagementPage> {
  final StudentService _studentService = StudentService();
  final WebSocketNotificationService _webSocketService = WebSocketNotificationService();
  
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  
  // Real-time updates
  bool _isConnected = false;
  StreamSubscription<WebSocketNotification>? _notificationSubscription;
  Timer? _autoRefreshTimer;
  
  // Filter states
  String? _selectedClass;
  String? _selectedSection;
  String _statusFilter = 'all'; // all, active, inactive
  
  // Dynamic classes and sections from API
  List<String> _classes = [];
  List<String> _sections = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _initializeWebSocket() {
    _webSocketService.initialize().then((_) {
      setState(() {
        _isConnected = _webSocketService.isConnected;
      });
      _notificationSubscription = _webSocketService.notificationStream.listen(
        _handleWebSocketNotification,
        onError: (error) {
          print('WebSocket error: $error');
          setState(() {
            _isConnected = false;
          });
        },
      );
      _startAutoRefresh();
    });
  }

  void _handleWebSocketNotification(WebSocketNotification notification) {
    print('🔔 Student Management - Received notification: ${notification.type} - ${notification.message}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${notification.title}: ${notification.message}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    if (_isRelevantNotification(notification)) {
      _loadStudents();
    }
  }

  bool _isRelevantNotification(WebSocketNotification notification) {
    return notification.type == NotificationType.attendanceUpdate ||
           notification.type == NotificationType.vehicleAssignmentRequest ||
           notification.type == NotificationType.vehicleAssignmentApproved;
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadStudents();
      }
    });
  }

  Future<void> _loadStudents() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final prefs = await SharedPreferences.getInstance();
      final schoolId = prefs.getInt('schoolId');
      
      if (schoolId == null) {
        setState(() {
          _hasError = true;
          _errorMessage = 'School ID not found';
          _isLoading = false;
        });
        return;
      }

      final response = await _studentService.getStudentsBySchool(schoolId);
      
      if (response['success'] == true) {
        setState(() {
          _students = List<Map<String, dynamic>>.from(response['data'] ?? []);
          _filteredStudents = _students;
          _isLoading = false;
        });
        _extractClassesAndSections();
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = response['message'] ?? 'Failed to load students';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error loading students: $e';
        _isLoading = false;
      });
    }
  }

  void _extractClassesAndSections() {
    final classes = <String>{};
    final sections = <String>{};
    
    for (final student in _students) {
      if (student['className'] != null) {
        classes.add(student['className'].toString());
      }
      if (student['section'] != null) {
        sections.add(student['section'].toString());
      }
    }
    
    setState(() {
      _classes = classes.toList()..sort();
      _sections = sections.toList()..sort();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredStudents = _students.where((student) {
        // Class filter
        if (_selectedClass != null && student['className'] != _selectedClass) {
          return false;
        }
        
        // Section filter
        if (_selectedSection != null && student['section'] != _selectedSection) {
          return false;
        }
        
        // Status filter
        if (_statusFilter == 'active' && student['isActive'] != true) {
          return false;
        }
        if (_statusFilter == 'inactive' && student['isActive'] != false) {
          return false;
        }
        
        return true;
      }).toList();
    });
  }

  Future<void> _toggleStudentStatus(int studentId, bool currentStatus) async {
    try {
      // In a real app, you would call an API to update student status
      // For now, we'll just update the local state
      setState(() {
        final studentIndex = _students.indexWhere((s) => s['studentId'] == studentId);
        if (studentIndex != -1) {
          _students[studentIndex]['isActive'] = !currentStatus;
        }
      });
      _applyFilters();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Student ${!currentStatus ? 'activated' : 'deactivated'} successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating student status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
        actions: [
          // WebSocket connection status
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.pushNamed(context, '/register-student');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedClass,
                        decoration: const InputDecoration(
                          labelText: 'Class',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Classes')),
                          ..._classes.map((cls) => DropdownMenuItem(value: cls, child: Text(cls))),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedClass = value;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSection,
                        decoration: const InputDecoration(
                          labelText: 'Section',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Sections')),
                          ..._sections.map((section) => DropdownMenuItem(value: section, child: Text(section))),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSection = value;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'all', label: Text('All')),
                          ButtonSegment(value: 'active', label: Text('Active')),
                          ButtonSegment(value: 'inactive', label: Text('Inactive')),
                        ],
                        selected: {_statusFilter},
                        onSelectionChanged: (Set<String> selection) {
                          setState(() {
                            _statusFilter = selection.first;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Results Summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Students: ${_filteredStudents.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Active: ${_filteredStudents.where((s) => s['isActive'] == true).length}',
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
          
          // Students List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage ?? 'Error loading students',
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadStudents,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredStudents.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.group_off, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No students found',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Try adjusting your filters or add new students',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredStudents.length,
                            itemBuilder: (context, index) {
                              final student = _filteredStudents[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: student['isActive'] == true 
                                        ? Colors.green.shade100 
                                        : Colors.red.shade100,
                                    child: Icon(
                                      Icons.person,
                                      color: student['isActive'] == true 
                                          ? Colors.green 
                                          : Colors.red,
                                    ),
                                  ),
                                  title: Text(
                                    student['studentName'] ?? 'Unknown Student',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Class: ${student['className'] ?? 'N/A'} - ${student['section'] ?? 'N/A'}'),
                                      Text('Parent: ${student['parentName'] ?? 'N/A'}'),
                                      Text('Contact: ${student['primaryContactNumber'] ?? 'N/A'}'),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: student['isActive'] == true,
                                        onChanged: (value) {
                                          _toggleStudentStatus(
                                            student['studentId'], 
                                            student['isActive'] == true
                                          );
                                        },
                                        activeColor: Colors.green,
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            // Navigate to edit student page
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Edit functionality coming soon')),
                                            );
                                          } else if (value == 'view') {
                                            // Navigate to student details page
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('View details coming soon')),
                                            );
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'view',
                                            child: Row(
                                              children: [
                                                Icon(Icons.visibility),
                                                SizedBox(width: 8),
                                                Text('View Details'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit),
                                                SizedBox(width: 8),
                                                Text('Edit'),
                                              ],
                                            ),
                                          ),
                                        ],
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
}

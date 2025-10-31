import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../app_routes.dart';
import '../../utils/constants.dart';
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
          debugPrint('${AppConstants.logWebSocketError}$error');
          setState(() {
            _isConnected = false;
          });
        },
      );
      _startAutoRefresh();
    });
  }

  void _handleWebSocketNotification(WebSocketNotification notification) {
    debugPrint('🔔 Student Management - Received notification: ${notification.type} - ${notification.message}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${notification.title}: ${notification.message}'),
          duration: AppDurations.snackbarDefault,
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
    _autoRefreshTimer = Timer.periodic(AppDurations.autoRefresh, (timer) {
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
      final schoolId = prefs.getInt(AppConstants.keySchoolId);
      
      if (schoolId == null) {
        setState(() {
          _hasError = true;
          _errorMessage = AppConstants.msgSchoolIdNotFound;
          _isLoading = false;
        });
        return;
      }

      final response = await _studentService.getStudentsBySchool(schoolId);
      
      if (response[AppConstants.keySuccess] == true) {
        setState(() {
          _students = List<Map<String, dynamic>>.from(response[AppConstants.keyData] ?? []);
          _filteredStudents = _students;
          _isLoading = false;
        });
        _extractClassesAndSections();
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = response[AppConstants.keyMessage] ?? AppConstants.errorFailedToFetchStudents;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = '${AppConstants.errorFailedToFetchStudents}: $e';
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
          content: Text('${AppConstants.labelStudent} ${!currentStatus ? AppConstants.msgActivated : AppConstants.msgDeactivated}'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppConstants.msgErrorUpdatingStaffStatus}$e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.labelStudentManagement),
        actions: [
          // WebSocket connection status
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? AppColors.successColor : AppColors.errorColor,
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
              Navigator.pushNamed(context, AppRoutes.registerStudent);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            color: AppColors.backgroundColor,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedClass,
                        decoration: const InputDecoration(
                          labelText: AppConstants.labelClass,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text(AppConstants.labelAllClasses)),
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
                    const SizedBox(width: AppSizes.marginSM),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSection,
                        decoration: const InputDecoration(
                          labelText: AppConstants.labelSection,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text(AppConstants.labelAllSections)),
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
                const SizedBox(height: AppSizes.marginSM),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'all', label: Text(AppConstants.labelFilterAll)),
                          ButtonSegment(value: 'active', label: Text(AppConstants.labelActive)),
                          ButtonSegment(value: 'inactive', label: Text(AppConstants.labelInactive)),
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
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMD, vertical: AppSizes.paddingSM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppConstants.labelTotalStudents}: ${_filteredStudents.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${AppConstants.labelActive}: ${_filteredStudents.where((s) => s['isActive'] == true).length}',
                  style: const TextStyle(color: AppColors.successColor),
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
                            const Icon(Icons.error_outline, size: 64, color: AppColors.errorColor),
                            const SizedBox(height: AppSizes.marginMD),
                            Text(
                              _errorMessage ?? AppConstants.errorFailedToFetchStudents,
                              style: const TextStyle(fontSize: AppSizes.textMD),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSizes.marginMD),
                            ElevatedButton(
                              onPressed: _loadStudents,
                              child: const Text(AppConstants.labelRetry),
                            ),
                          ],
                        ),
                      )
                    : _filteredStudents.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.group_off, size: 64, color: AppColors.textSecondary),
                                SizedBox(height: AppSizes.marginMD),
                                Text(
                                  AppConstants.errorNoStudentsFound,
                                  style: TextStyle(fontSize: AppSizes.textMD, color: AppColors.textSecondary),
                                ),
                                SizedBox(height: AppSizes.marginSM),
                                Text(
                                  AppConstants.msgAdjustFiltersOrAddStudents,
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(AppSizes.paddingMD),
                            itemCount: _filteredStudents.length,
                            itemBuilder: (context, index) {
                              final student = _filteredStudents[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: AppSizes.marginSM),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: (student['isActive'] == true 
                                        ? AppColors.successColor 
                                        : AppColors.errorColor).withValues(alpha: 0.2),
                                    child: Icon(
                                      Icons.person,
                                      color: student['isActive'] == true 
                                          ? AppColors.successColor 
                                          : AppColors.errorColor,
                                    ),
                                  ),
                                  title: Text(
                                    student['studentName'] ?? AppConstants.labelUnknown,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${AppConstants.labelClass}: ${student['className'] ?? AppConstants.labelNA} - ${student['section'] ?? AppConstants.labelNA}'),
                                      Text('${AppConstants.labelParent}: ${student['parentName'] ?? AppConstants.labelNA}'),
                                      Text('${AppConstants.labelContactWithColon}${student['primaryContactNumber'] ?? AppConstants.labelNA}'),
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
                                        activeColor: AppColors.successColor,
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            // Navigate to edit student page
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text(AppConstants.msgEditFunctionalityNotImplemented)),
                                            );
                                          } else if (value == 'view') {
                                            // Navigate to student details page
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text(AppConstants.labelViewDetails)),
                                            );
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'view',
                                            child: Row(
                                              children: [
                                                Icon(Icons.visibility),
                                                SizedBox(width: AppSizes.marginSM),
                                                Text(AppConstants.labelViewDetails),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit),
                                                SizedBox(width: AppSizes.marginSM),
                                                Text(AppConstants.actionEdit),
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

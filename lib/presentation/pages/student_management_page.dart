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
  
  // Filter states
  String? _selectedClass;
  String? _selectedSection;
  String _statusFilter = 'all'; // all, active, inactive
  
  // Dynamic classes and sections from API
  List<String> _classes = [];
  List<String> _sections = [];
  Map<String, List<String>> _sectionsByClass = {};

  String? _normalizeString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
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
    final allSections = <String>{};
    final sectionsByClass = <String, Set<String>>{};

    for (final student in _students) {
      final className = _normalizeString(student['className'] ?? student['class']);
      final sectionName = _normalizeString(student['section'] ?? student['sectionName']);

      if (className != null) {
        classes.add(className);
        final classSections = sectionsByClass.putIfAbsent(className, () => <String>{});
        if (sectionName != null) {
          classSections.add(sectionName);
          allSections.add(sectionName);
        }
      } else if (sectionName != null) {
        allSections.add(sectionName);
      }
    }

    final sortedClasses = classes.toList()..sort();
    final sortedSections = allSections.toList()..sort();
    final mappedSections = sectionsByClass.map((key, value) {
      final list = value.toList()..sort();
      return MapEntry(key, list);
    });

    setState(() {
      _classes = sortedClasses;
      _sections = sortedSections;
      _sectionsByClass = mappedSections;

      // Reset selected section if it no longer exists for the chosen class
      final availableSections = _sectionsForClass(_selectedClass);
      if (_selectedSection != null && !availableSections.contains(_selectedSection)) {
        _selectedSection = null;
      }
    });
  }

  List<String> _sectionsForClass(String? className) {
    if (className == null || className.isEmpty) {
      return _sections;
    }
    return _sectionsByClass[className] ?? _sections;
  }

  void _onClassChanged(String? value) {
    final normalized = _normalizeString(value);
    setState(() {
      _selectedClass = normalized;
      final availableSections = _sectionsForClass(normalized);
      if (_selectedSection != null && !availableSections.contains(_selectedSection)) {
        _selectedSection = null;
      }
    });
    _applyFilters();
  }

  void _onSectionChanged(String? value) {
    setState(() {
      _selectedSection = _normalizeString(value);
    });
    _applyFilters();
  }

  String _getStudentDisplayName(Map<String, dynamic> student) {
    final directName = _normalizeString(student['studentName'] ?? student['name']);
    if (directName != null) {
      return directName;
    }

    final firstName = _normalizeString(student['firstName'] ?? student['studentFirstName']);
    final middleName = _normalizeString(student['middleName']);
    final lastName = _normalizeString(student['lastName'] ?? student['studentLastName']);

    final parts = [firstName, middleName, lastName]
        .whereType<String>()
        .toList();

    if (parts.isNotEmpty) {
      return parts.join(' ');
    }

    return AppConstants.labelUnknown;
  }

  Future<void> _showStudentDetailsDialog(Map<String, dynamic> student) async {
    final className = _normalizeString(student['className'] ?? student['class']) ?? AppConstants.labelNA;
    final sectionName = _normalizeString(student['section'] ?? student['sectionName']) ?? AppConstants.labelNA;
    final parentDisplay = _normalizeString(student['parentName'] ?? student['fatherName'] ?? student['motherName']) ?? AppConstants.labelNA;
    final contactNumber = _normalizeString(student['primaryContactNumber'] ?? student['contactNumber']) ?? AppConstants.labelNA;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_getStudentDisplayName(student)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${AppConstants.labelClass}: $className'),
              Text('${AppConstants.labelSection}: $sectionName'),
              Text('${AppConstants.labelParent}: $parentDisplay'),
              Text('${AppConstants.labelContactWithColon}$contactNumber'),
              Text('${AppConstants.labelStatus}: ${(student['isActive'] == true) ? AppConstants.labelActive : AppConstants.labelInactive}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppConstants.actionClose),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editStudent(Map<String, dynamic> student) async {
    final studentId = student['studentId'];
    if (studentId is! int) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.msgStudentIdMissing)),
      );
      return;
    }

    await Navigator.pushNamed(
      context,
      AppRoutes.studentProfile,
      arguments: studentId,
    );

    if (mounted) {
      _loadStudents();
    }
  }

  Future<void> _confirmToggleStudentStatus(Map<String, dynamic> student) async {
    final studentId = student['studentId'];
    if (studentId is! int) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.msgStudentIdMissing)),
      );
      return;
    }

    final currentlyActive = student['isActive'] == true;
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(currentlyActive ? AppConstants.actionDeactivate : AppConstants.actionActivate),
          content: Text(
            currentlyActive
                ? AppConstants.msgConfirmDeactivateStudent
                : AppConstants.msgConfirmActivateStudent,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppConstants.actionCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: currentlyActive ? AppColors.errorColor : AppColors.successColor,
                foregroundColor: AppColors.textWhite,
              ),
              child: Text(currentlyActive ? AppConstants.actionDeactivate : AppConstants.actionActivate),
            ),
          ],
        );
      },
    );

    if (confirmation == true) {
      await _toggleStudentStatus(studentId, currentlyActive);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredStudents = _students.where((student) {
        final studentClass = _normalizeString(student['className'] ?? student['class']);
        final studentSection = _normalizeString(student['section'] ?? student['sectionName']);

        if (_selectedClass != null && studentClass != _selectedClass) {
          return false;
        }

        if (_selectedSection != null && studentSection != _selectedSection) {
          return false;
        }

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
                      child: DropdownButtonFormField<String?>(
                        initialValue: _selectedClass,
                        decoration: const InputDecoration(
                          labelText: AppConstants.labelClass,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text(AppConstants.labelAllClasses)),
                          ..._classes.map((cls) => DropdownMenuItem<String?>(value: cls, child: Text(cls))),
                        ],
                        onChanged: _onClassChanged,
                      ),
                    ),
                    const SizedBox(width: AppSizes.marginSM),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _selectedSection,
                        decoration: const InputDecoration(
                          labelText: AppConstants.labelSection,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text(AppConstants.labelAllSections)),
                          ..._sectionsForClass(_selectedClass).map(
                            (section) => DropdownMenuItem<String?>(value: section, child: Text(section)),
                          ),
                        ],
                        onChanged: _onSectionChanged,
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
                                    _getStudentDisplayName(student),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${AppConstants.labelClass}: ${_normalizeString(student['className'] ?? student['class']) ?? AppConstants.labelNA} - ${_normalizeString(student['section'] ?? student['sectionName']) ?? AppConstants.labelNA}'),
                                      Text('${AppConstants.labelParent}: ${_normalizeString(student['parentName'] ?? student['fatherName'] ?? student['motherName']) ?? AppConstants.labelNA}'),
                                      Text('${AppConstants.labelContactWithColon}${_normalizeString(student['primaryContactNumber'] ?? student['contactNumber']) ?? AppConstants.labelNA}'),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'view') {
                                        _showStudentDetailsDialog(student);
                                      } else if (value == 'edit') {
                                        _editStudent(student);
                                      } else if (value == 'toggle') {
                                        _confirmToggleStudentStatus(student);
                                      }
                                    },
                                    itemBuilder: (context) {
                                      final isActive = student['isActive'] == true;
                                      return [
                                        const PopupMenuItem<String>(
                                          value: 'view',
                                          child: Row(
                                            children: [
                                              Icon(Icons.visibility),
                                              SizedBox(width: AppSizes.marginSM),
                                              Text(AppConstants.labelViewDetails),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit),
                                              SizedBox(width: AppSizes.marginSM),
                                              Text(AppConstants.actionEdit),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'toggle',
                                          child: Row(
                                            children: [
                                              Icon(isActive ? Icons.toggle_off : Icons.toggle_on),
                                              const SizedBox(width: AppSizes.marginSM),
                                              Text(isActive ? AppConstants.actionDeactivate : AppConstants.actionActivate),
                                            ],
                                          ),
                                        ),
                                      ];
                                    },
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

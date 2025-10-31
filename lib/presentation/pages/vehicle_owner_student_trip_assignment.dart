import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../services/vehicle_owner_service.dart';
import '../../services/trip_service.dart';
import '../../services/student_service.dart';
import '../../services/trip_student_service.dart';
import '../../utils/constants.dart';

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
      final userId = prefs.getInt(AppConstants.keyUserId);
      _currentSchoolId = prefs.getInt(AppConstants.keyCurrentSchoolId);
      
      if (userId != null && _currentSchoolId != null) {
        // Load owner data
        final ownerResponse = await _vehicleOwnerService.getOwnerByUserId(userId);
        if (ownerResponse[AppConstants.keySuccess] == true) {
          _ownerData = ownerResponse[AppConstants.keyData];
          
          // Load trips for the current school
          final tripsResponse = await _tripService.getTripsBySchoolMap(_currentSchoolId!);
          if (tripsResponse[AppConstants.keySuccess] == true) {
            setState(() {
              _trips = List<Map<String, dynamic>>.from(tripsResponse[AppConstants.keyData] ?? []);
            });
          }
          
          // Load students for the current school
          final studentsResponse = await _studentService.getStudentsBySchool(_currentSchoolId!);
          if (studentsResponse[AppConstants.keySuccess] == true) {
            setState(() {
              _students = List<Map<String, dynamic>>.from(studentsResponse[AppConstants.keyData] ?? []);
            });
          }
          
          // Load existing trip-student assignments
          await _loadAssignmentsData();
        }
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
      _showError('${AppConstants.msgErrorLoadingData}$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAssignmentsData() async {
    if (_currentSchoolId == null) return;
    
    try {
      final assignmentsResponse = await _tripStudentService.getAllAssignmentsBySchool(_currentSchoolId!);
      if (assignmentsResponse[AppConstants.keySuccess] == true) {
        setState(() {
          _assignments = List<Map<String, dynamic>>.from(assignmentsResponse[AppConstants.keyData] ?? []);
          _lastUpdateTime = DateTime.now();
        });
        debugPrint("🔍 Loaded ${_assignments.length} trip-student assignments");
      } else {
        debugPrint("🔍 Failed to load assignments: ${assignmentsResponse[AppConstants.keyMessage]}");
        setState(() {
          _assignments = [];
        });
      }
    } catch (e) {
      debugPrint("🔍 Error loading assignments: $e");
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
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.successColor,
        ),
      );
    }
  }

  void _showAssignStudentDialog() {
    if (_trips.isEmpty || _students.isEmpty) {
      _showError(AppConstants.msgNoTripsOrStudentsAvailable);
      return;
    }

    String? selectedTripId;
    String? selectedStudentId;
    int pickupOrder = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(AppConstants.titleAssignStudentToTrip),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedTripId,
                decoration: const InputDecoration(
                  labelText: AppConstants.labelSelectTrip,
                  border: OutlineInputBorder(),
                ),
                items: _trips
                    .where((t) => t[AppConstants.keyIsActive] == true)
                    .map((trip) => DropdownMenuItem(
                          value: trip[AppConstants.keyTripId].toString(),
                          child: Text(trip[AppConstants.keyTripName] ?? AppConstants.labelUnknownTrip),
                        ))
                    .toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedTripId = value;
                  });
                },
              ),
              const SizedBox(height: AppSizes.marginMD),
              DropdownButtonFormField<String>(
                value: selectedStudentId,
                decoration: const InputDecoration(
                  labelText: AppConstants.labelSelectStudent,
                  border: OutlineInputBorder(),
                ),
                items: _students
                    .where((s) => s[AppConstants.keyIsActive] == true)
                    .map((student) => DropdownMenuItem(
                          value: student[AppConstants.keyStudentId].toString(),
                          child: Text('${student[AppConstants.keyFirstName]} ${student[AppConstants.keyLastName]}'),
                        ))
                    .toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedStudentId = value;
                  });
                },
              ),
              const SizedBox(height: AppSizes.marginMD),
              TextFormField(
                initialValue: pickupOrder.toString(),
                decoration: const InputDecoration(
                  labelText: AppConstants.labelPickupOrder,
                  border: OutlineInputBorder(),
                  helperText: AppConstants.hintPickupOrder,
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
              child: const Text(AppConstants.actionCancel),
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
              child: const Text(AppConstants.actionAssign),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignStudentToTrip(int tripId, int studentId, int pickupOrder) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString(AppConstants.keyUserName) ?? AppConstants.labelVehicleOwner;
      
      final response = await _tripStudentService.assignStudentToTrip(
        tripId: tripId,
        studentId: studentId,
        pickupOrder: pickupOrder,
        createdBy: userName,
      );
      
      if (response[AppConstants.keySuccess] == true) {
        _showSuccess(AppConstants.msgStudentAssignedToTripSuccess);
        await _loadAssignmentsData(); // Refresh the assignments list
      } else {
        _showError('${AppConstants.msgFailedToAssignStudent}: ${response[AppConstants.keyMessage]}');
      }
    } catch (e) {
      _showError('${AppConstants.msgErrorAssigningStudent}: $e');
    }
  }

  Future<void> _removeAssignment(int assignmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppConstants.titleRemoveAssignment),
        content: const Text(AppConstants.msgConfirmRemoveStudentFromTrip),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppConstants.actionCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppConstants.actionRemove),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _tripStudentService.removeStudentFromTrip(assignmentId);
        
        if (response[AppConstants.keySuccess] == true) {
          _showSuccess(AppConstants.msgAssignmentRemovedSuccess);
          await _loadAssignmentsData(); // Refresh the assignments list
        } else {
          _showError('${AppConstants.msgFailedToRemoveAssignment}: ${response[AppConstants.keyMessage]}');
        }
      } catch (e) {
        _showError('${AppConstants.msgErrorRemovingAssignment}: $e');
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
            const Text(AppConstants.labelStudentTripAssignments),
            if (_lastUpdateTime != null)
              Text(
                '${AppConstants.labelLastUpdated} ${_formatTime(_lastUpdateTime!)}',
                style: const TextStyle(fontSize: AppSizes.textXS, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _loadData();
              _showSuccess(AppConstants.msgDataRefreshedSuccessfully);
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
                        size: AppSizes.iconXL,
                        color: AppColors.warningColor,
                      ),
                      const SizedBox(height: AppSizes.marginMD),
                      Text(
                        AppConstants.msgNoSchoolSelected,
                        style: const TextStyle(fontSize: AppSizes.textXL, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSizes.marginSM),
                      Text(
                        AppConstants.msgUseSchoolSelectorHint,
                        style: const TextStyle(fontSize: AppSizes.textSM, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Summary Cards
                    Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingMD),
                      child: Row(
                        children: [
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSizes.paddingMD),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.route,
                                      size: AppSizes.iconLG,
                                      color: AppColors.primaryDark,
                                    ),
                                    const SizedBox(height: AppSizes.marginSM),
                                    Text(
                                      _trips.length.toString(),
                                      style: const TextStyle(fontSize: AppSizes.textXXL, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      AppConstants.labelTrips,
                                      style: const TextStyle(fontSize: AppSizes.textSM, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.marginSM),
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSizes.paddingMD),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.school,
                                      size: AppSizes.iconLG,
                                      color: AppColors.successColor,
                                    ),
                                    const SizedBox(height: AppSizes.marginSM),
                                    Text(
                                      _students.length.toString(),
                                      style: const TextStyle(fontSize: AppSizes.textXXL, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      AppConstants.labelStudents,
                                      style: const TextStyle(fontSize: AppSizes.textSM, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.marginSM),
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSizes.paddingMD),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.assignment,
                                      size: AppSizes.iconLG,
                                      color: AppColors.warningColor,
                                    ),
                                    const SizedBox(height: AppSizes.marginSM),
                                    Text(
                                      _assignments.length.toString(),
                                      style: const TextStyle(fontSize: AppSizes.textXXL, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      AppConstants.labelAssignments,
                                      style: const TextStyle(fontSize: AppSizes.textSM, color: AppColors.textSecondary),
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
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMD),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showAssignStudentDialog,
                          icon: const Icon(Icons.add),
                          label: const Text(AppConstants.labelAssignStudentToTrip),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppSizes.marginMD),
                    
                    // Assignments List
                    Expanded(
                      child: _assignments.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.assignment_outlined,
                                    size: AppSizes.iconXL,
                                    color: AppColors.grey200,
                                  ),
                                  const SizedBox(height: AppSizes.marginMD),
                                  Text(
                                    AppConstants.emptyStateNoStudentTripAssignments,
                                    style: const TextStyle(fontSize: AppSizes.textXL, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: AppSizes.marginSM),
                                  Text(
                                    AppConstants.emptyStateAssignStudentsHint,
                                    style: const TextStyle(fontSize: AppSizes.textSM, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMD),
                              itemCount: _assignments.length,
                              itemBuilder: (context, index) {
                                final assignment = _assignments[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: AppSizes.marginSM),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primaryDark,
                                      child: Text(
                                        assignment[AppConstants.keyPickupOrder]?.toString() ?? AppConstants.labelQuestion,
                                        style: const TextStyle(
                                          color: AppColors.textWhite,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      assignment[AppConstants.keyStudentName] ?? AppConstants.labelUnknownStudent,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${AppConstants.labelTripPrefix}${assignment[AppConstants.keyTripName] ?? AppConstants.labelUnknownTrip}'),
                                        Text('${AppConstants.labelPickupOrderPrefix}${assignment[AppConstants.keyPickupOrder] ?? AppConstants.labelNotSet}'),
                                        Text('${AppConstants.labelAssignedOnPrefix}${_formatDate(assignment[AppConstants.keyCreatedDate])}'),
                                        if (assignment[AppConstants.keyCreatedBy] != null)
                                          Text('${AppConstants.labelCreatedByPrefix}${assignment[AppConstants.keyCreatedBy]}'),
                                      ],
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'edit':
                                            // TODO: Navigate to edit assignment
                                            _showSuccess(AppConstants.msgEditFunctionalityComingSoon);
                                            break;
                                          case 'remove':
                                            _removeAssignment(assignment[AppConstants.keyTripStudentId]);
                                            break;
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 20),
                                              SizedBox(width: AppSizes.marginSM),
                                              Text(AppConstants.actionEditOrder),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'remove',
                                          child: Row(
                                            children: [
                                              Icon(Icons.remove_circle, size: 20, color: AppColors.errorColor),
                                              SizedBox(width: AppSizes.marginSM),
                                              Text(AppConstants.actionRemove, style: TextStyle(color: AppColors.errorColor)),
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
    if (date == null) return AppConstants.labelUnknownDate;
    
    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return AppConstants.labelUnknownDate;
      }
      
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return AppConstants.labelUnknownDate;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return AppConstants.labelJustNow;
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}${AppConstants.labelMinutesAgoSuffix}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}${AppConstants.labelHoursAgoSuffix}';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

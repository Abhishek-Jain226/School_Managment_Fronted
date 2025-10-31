import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_routes.dart';
import '../../services/school_service.dart';
import '../../utils/constants.dart';


class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  bool _loading = true;
  int? schoolId;
  String? adminName;
  
  // Real-time data from API
  List<Map<String, dynamic>> staffMembers = [];
  int totalStaff = 0;
  int activeStaff = 0;
  int teachers = 0;
  int gateStaff = 0;
  
  final SchoolService _schoolService = SchoolService();

  @override
  void initState() {
    super.initState();
    _loadStaffData();
  }

  Future<void> _loadStaffData() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      schoolId = prefs.getInt("schoolId");
      adminName = prefs.getString("userName");
      
      if (schoolId == null) {
        _showErrorSnackBar(AppConstants.msgSchoolIdNotFound);
        return;
      }
      
      // Fetch real data from API
      final response = await _schoolService.getAllStaffBySchool(schoolId!);
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final staffList = List<Map<String, dynamic>>.from(data['staffList'] ?? []);
        
        setState(() {
          staffMembers = staffList;
          totalStaff = data['totalCount'] ?? 0;
          activeStaff = data['activeCount'] ?? 0;
          teachers = staffList.where((s) => s['role'] == 'TEACHER').length;
          gateStaff = staffList.where((s) => s['role'] == 'GATE_STAFF').length;
          _loading = false;
        });
        
        // Debug: Print all staff data (only TEACHER and GATE_STAFF)
        print('=== STAFF DATA DEBUG (TEACHER & GATE_STAFF ONLY) ===');
        for (var staff in staffList) {
          print('Name: ${staff['name']}, Role: ${staff['role']}, Email: ${staff['email']}');
        }
        print('=== END DEBUG ===');
      } else {
        setState(() => _loading = false);
        _showErrorSnackBar(response['message'] ?? AppConstants.msgFailedToLoadStaffData);
      }
    } catch (e) {
      setState(() => _loading = false);
      _showErrorSnackBar(AppConstants.msgErrorLoadingStaffData + e.toString());
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorColor,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _navigateToAddStaff() async {
    final result = await Navigator.pushNamed(context, AppRoutes.registerGateStaff);
    if (result == true) {
      _loadStaffData(); // Refresh the list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.labelStaffManagement),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStaffData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Quick Actions Card
                Card(
                  margin: const EdgeInsets.all(AppSizes.marginMD),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppConstants.labelQuickActions,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spaceSM),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _navigateToAddStaff,
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text(AppConstants.labelAddStaff),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSM),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Statistics Card
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: AppSizes.marginMD),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMD),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(AppConstants.labelTotalStaff, totalStaff.toString(), Icons.people),
                        _buildStatItem(AppConstants.labelActiveStaff, activeStaff.toString(), Icons.check_circle),
                        _buildStatItem(AppConstants.labelTeachers, teachers.toString(), Icons.school),
                        _buildStatItem(AppConstants.labelGateStaff, gateStaff.toString(), Icons.security),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: AppSizes.spaceMD),
                
                // Staff List
                Expanded(
                  child: staffMembers.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people, size: 64, color: AppColors.textSecondary),
                              SizedBox(height: AppSizes.spaceMD),
                              Text(
                                AppConstants.msgNoStaffMembers,
                                style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                              ),
                              SizedBox(height: AppSizes.spaceSM),
                              Text(
                                AppConstants.msgAddFirstStaff,
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.marginMD),
                          itemCount: staffMembers.length,
                          itemBuilder: (context, index) {
                            final staff = staffMembers[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: AppSizes.marginSM),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: staff['isActive'] == true ? AppColors.successColor : AppColors.textSecondary,
                                  child: Icon(
                                    _getRoleIcon(staff['role']),
                                    color: AppColors.textWhite,
                                  ),
                                ),
                                title: Text(
                                  staff['name'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(AppConstants.labelRoleWithColon + '${staff['role']}'),
                                    Text(AppConstants.labelEmailWithColon + '${staff['email']}'),
                                    Text(AppConstants.labelContactWithColon + '${staff['contactNo']}'),
                                    Row(
                                      children: [
                                        Icon(
                                          staff['isActive'] == true ? Icons.check_circle : Icons.cancel,
                                          size: 16,
                                          color: staff['isActive'] == true ? AppColors.successColor : AppColors.errorColor,
                                        ),
                                        const SizedBox(width: AppSizes.spaceSM),
                                        Text(
                                          staff['isActive'] == true ? AppConstants.labelActive : AppConstants.labelInactive,
                                          style: TextStyle(
                                            color: staff['isActive'] == true ? AppColors.successColor : AppColors.errorColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'view':
                                        _showStaffDetails(staff);
                                        break;
                                      case 'edit':
                                        // TODO: Navigate to edit staff
                                        _showErrorSnackBar(AppConstants.msgEditFunctionalityNotImplemented);
                                        break;
                                      case 'toggle':
                                        _toggleStaffStatus(staff);
                                        break;
                                      case 'delete':
                                        _showDeleteDialog(staff);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'view',
                                      child: Row(
                                        children: [
                                          Icon(Icons.visibility),
                                          SizedBox(width: AppSizes.spaceSM),
                                          Text(AppConstants.labelViewDetails),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: AppSizes.spaceSM),
                                          Text(AppConstants.actionEdit),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Row(
                                        children: [
                                          Icon(staff['isActive'] == true ? Icons.pause : Icons.play_arrow),
                                          const SizedBox(width: AppSizes.spaceSM),
                                          Text(staff['isActive'] == true ? AppConstants.actionDeactivate : AppConstants.actionActivate),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: AppColors.errorColor),
                                          SizedBox(width: AppSizes.spaceSM),
                                          Text(AppConstants.actionDelete, style: TextStyle(color: AppColors.errorColor)),
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: AppSizes.iconMD),
        const SizedBox(height: AppSizes.spaceSM),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role.toUpperCase()) {
      case 'TEACHER':
        return Icons.school;
      case 'GATE_STAFF':
        return Icons.security;
      case 'DRIVER':
        return Icons.drive_eta;
      case 'SCHOOL_ADMIN':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  void _showStaffDetails(Map<String, dynamic> staff) {
    // Create controllers with current staff data
    final nameController = TextEditingController(text: staff['name'] ?? '');
    final emailController = TextEditingController(text: staff['email'] ?? '');
    final contactController = TextEditingController(text: staff['contactNo'] ?? '');
    final roleController = TextEditingController(text: staff['role'] ?? '');
    final joinDateController = TextEditingController(text: staff['joinDate'] ?? '');
    
    bool isEditing = false;
    bool isActive = staff['isActive'] == true;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.person, color: AppColors.primaryColor),
              const SizedBox(width: AppSizes.spaceSM),
              Expanded(
                child: Text(
                  isEditing ? AppConstants.labelEditStaffDetails : AppConstants.labelStaffDetails,
                  style: const TextStyle(fontSize: AppSizes.textXL),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    isEditing = !isEditing;
                  });
                },
                icon: Icon(
                  isEditing ? Icons.visibility : Icons.edit,
                  color: AppColors.primaryColor,
                ),
                tooltip: isEditing ? AppConstants.tooltipViewMode : AppConstants.tooltipEditMode,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name Field
                TextFormField(
                  controller: nameController,
                  enabled: isEditing,
                  decoration: InputDecoration(
                    labelText: AppConstants.labelName,
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.spaceMD),
                
                // Email Field
                TextFormField(
                  controller: emailController,
                  enabled: isEditing,
                  decoration: InputDecoration(
                    labelText: AppConstants.labelEmail,
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.spaceMD),
                
                // Contact Field
                TextFormField(
                  controller: contactController,
                  enabled: isEditing,
                  decoration: InputDecoration(
                    labelText: AppConstants.labelContactNumber,
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.spaceMD),
                
                // Role Field
                TextFormField(
                  controller: roleController,
                  enabled: isEditing,
                  decoration: InputDecoration(
                    labelText: AppConstants.labelRole,
                    prefixIcon: Icon(_getRoleIcon(roleController.text)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.spaceMD),
                
                // Join Date Field
                TextFormField(
                  controller: joinDateController,
                  enabled: isEditing,
                  decoration: InputDecoration(
                    labelText: AppConstants.labelJoinDate,
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.spaceMD),
                
                // Status Toggle (only in edit mode)
                if (isEditing) ...[
                  Row(
                    children: [
                      const Icon(Icons.toggle_on, color: AppColors.primaryColor),
                      const SizedBox(width: AppSizes.spaceSM),
                      const Text(AppConstants.labelStatus),
                      const SizedBox(width: AppSizes.spaceSM),
                      Switch(
                        value: isActive,
                        onChanged: (value) {
                          setState(() {
                            isActive = value;
                          });
                        },
                        activeColor: AppColors.successColor,
                        inactiveThumbColor: AppColors.errorColor,
                      ),
                      Text(
                        isActive ? AppConstants.labelActive : AppConstants.labelInactive,
                        style: TextStyle(
                          color: isActive ? AppColors.successColor : AppColors.errorColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Status Display (view mode)
                  Row(
                    children: [
                      Icon(
                        isActive ? Icons.check_circle : Icons.cancel,
                        color: isActive ? AppColors.successColor : AppColors.errorColor,
                      ),
                      const SizedBox(width: AppSizes.spaceSM),
                      Text(
                        AppConstants.labelStatus + ': ${isActive ? AppConstants.labelActive : AppConstants.labelInactive}',
                        style: TextStyle(
                          color: isActive ? AppColors.successColor : AppColors.errorColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(AppConstants.actionCancel),
            ),
            if (isEditing) ...[
              ElevatedButton(
                onPressed: () async {
                  await _updateStaffDetails(
                    staff,
                    nameController.text,
                    emailController.text,
                    contactController.text,
                    roleController.text,
                    joinDateController.text,
                    isActive,
                    ctx,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.textWhite,
                ),
                child: const Text(AppConstants.labelSaveChanges),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateStaffDetails(
    Map<String, dynamic> staff,
    String name,
    String email,
    String contact,
    String role,
    String joinDate,
    bool isActive,
    BuildContext dialogContext,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: dialogContext,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: AppSizes.spaceMD),
              Text(AppConstants.msgUpdatingStaffDetails),
            ],
          ),
        ),
      );

      // Call the API to update staff details
      final response = await _schoolService.updateStaffDetails(
        staff['staffId'],
        name,
        email,
        contact,
        role,
        joinDate,
        isActive,
        adminName ?? 'Admin',
      );

      // Close loading dialog
      Navigator.of(dialogContext).pop();

      if (response['success'] == true) {
        // Update local data
        setState(() {
          staff['name'] = name;
          staff['email'] = email;
          staff['contactNo'] = contact;
          staff['role'] = role;
          staff['joinDate'] = joinDate;
          staff['isActive'] = isActive;
          
          // Update counters if status changed
          if (staff['isActive'] != isActive) {
            if (isActive) {
              activeStaff++;
            } else {
              activeStaff--;
            }
          }
        });

        // Close the edit dialog
        Navigator.of(dialogContext).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${name} ${AppConstants.msgDetailsUpdated}'),
            backgroundColor: AppColors.successColor,
          ),
        );
      } else {
        _showErrorSnackBar(response['message'] ?? AppConstants.msgFailedToUpdateStaffDetails);
      }
    } catch (e) {
      // Close loading dialog if it's still open
      Navigator.of(dialogContext).pop();
      _showErrorSnackBar(AppConstants.msgErrorUpdatingStaffDetails + e.toString());
    }
  }

  Future<void> _toggleStaffStatus(Map<String, dynamic> staff) async {
    try {
      final newStatus = !staff['isActive'];
      final response = await _schoolService.updateStaffStatus(
        staff['staffId'], 
        newStatus, 
        adminName ?? 'Admin'
      );
      
      if (response['success'] == true) {
        setState(() {
          staff['isActive'] = newStatus;
          // Update counters
          if (newStatus) {
            activeStaff++;
          } else {
            activeStaff--;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${staff['name']} ${newStatus ? AppConstants.msgActivated : AppConstants.msgDeactivated}'),
            backgroundColor: AppColors.successColor,
          ),
        );
      } else {
        _showErrorSnackBar(response['message'] ?? AppConstants.msgFailedToUpdateStaffStatus);
      }
    } catch (e) {
      _showErrorSnackBar(AppConstants.msgErrorUpdatingStaffStatus + e.toString());
    }
  }

  void _showDeleteDialog(Map<String, dynamic> staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppConstants.labelDeleteStaffMember),
        content: Text('${AppConstants.labelAreYouSure} ${staff['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppConstants.actionCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _deleteStaff(staff);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorColor),
            child: const Text(AppConstants.actionDelete, style: TextStyle(color: AppColors.textWhite)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStaff(Map<String, dynamic> staff) async {
    try {
      final response = await _schoolService.deleteStaff(
        staff['staffId'], 
        adminName ?? 'Admin'
      );
      
      if (response['success'] == true) {
        setState(() {
          staffMembers.removeWhere((s) => s['staffId'] == staff['staffId']);
          totalStaff--;
          if (staff['isActive'] == true) {
            activeStaff--;
          }
          // Update role counters
          if (staff['role'] == 'TEACHER') {
            teachers--;
          } else if (staff['role'] == 'GATE_STAFF') {
            gateStaff--;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${staff['name']} ${AppConstants.msgDeleted}'),
            backgroundColor: AppColors.successColor,
          ),
        );
      } else {
        _showErrorSnackBar(response['message'] ?? AppConstants.errorFailedToDeleteStaff);
      }
    } catch (e) {
      _showErrorSnackBar(AppConstants.msgErrorDeletingStaff + e.toString());
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.successColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

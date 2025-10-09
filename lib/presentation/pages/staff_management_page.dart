import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_routes.dart';
import '../../services/school_service.dart';

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
        _showErrorSnackBar("School ID not found. Please login again.");
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
        _showErrorSnackBar(response['message'] ?? "Failed to load staff data");
      }
    } catch (e) {
      setState(() => _loading = false);
      _showErrorSnackBar("Error loading staff data: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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
        title: const Text('Staff Management'),
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
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _navigateToAddStaff,
                                icon: const Icon(Icons.person_add_alt_1),
                                label: const Text('Add Staff'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // TODO: Navigate to bulk import
                                  _showErrorSnackBar('Bulk import not implemented yet');
                                },
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Bulk Import'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Statistics Card
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Total Staff', totalStaff.toString(), Icons.people),
                        _buildStatItem('Active Staff', activeStaff.toString(), Icons.check_circle),
                        _buildStatItem('Teachers', teachers.toString(), Icons.school),
                        _buildStatItem('Gate Staff', gateStaff.toString(), Icons.security),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Staff List
                Expanded(
                  child: staffMembers.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No staff members found',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Add your first staff member to get started',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: staffMembers.length,
                          itemBuilder: (context, index) {
                            final staff = staffMembers[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: staff['isActive'] == true ? Colors.green : Colors.grey,
                                  child: Icon(
                                    _getRoleIcon(staff['role']),
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  staff['name'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Role: ${staff['role']}'),
                                    Text('Email: ${staff['email']}'),
                                    Text('Contact: ${staff['contactNo']}'),
                                    Row(
                                      children: [
                                        Icon(
                                          staff['isActive'] == true ? Icons.check_circle : Icons.cancel,
                                          size: 16,
                                          color: staff['isActive'] == true ? Colors.green : Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          staff['isActive'] == true ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            color: staff['isActive'] == true ? Colors.green : Colors.red,
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
                                        _showErrorSnackBar('Edit functionality not implemented yet');
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
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Row(
                                        children: [
                                          Icon(staff['isActive'] == true ? Icons.pause : Icons.play_arrow),
                                          const SizedBox(width: 8),
                                          Text(staff['isActive'] == true ? 'Deactivate' : 'Activate'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: Colors.red)),
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
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(staff['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Role: ${staff['role']}'),
            const SizedBox(height: 8),
            Text('Email: ${staff['email']}'),
            const SizedBox(height: 8),
            Text('Contact: ${staff['contactNo']}'),
            const SizedBox(height: 8),
            Text('Join Date: ${staff['joinDate']}'),
            const SizedBox(height: 8),
            Text('Status: ${staff['isActive'] == true ? 'Active' : 'Inactive'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
            content: Text('${staff['name']} ${newStatus ? 'activated' : 'deactivated'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorSnackBar(response['message'] ?? 'Failed to update staff status');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating staff status: $e');
    }
  }

  void _showDeleteDialog(Map<String, dynamic> staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Staff Member'),
        content: Text('Are you sure you want to delete ${staff['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _deleteStaff(staff);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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
            content: Text('${staff['name']} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorSnackBar(response['message'] ?? 'Failed to delete staff');
      }
    } catch (e) {
      _showErrorSnackBar('Error deleting staff: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

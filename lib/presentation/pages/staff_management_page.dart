import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_routes.dart';

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  bool _loading = true;
  int? schoolId;
  
  // Mock data - in real app, this would come from API
  List<Map<String, dynamic>> staffMembers = [];

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
      
      // Mock data - replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        staffMembers = [
          {
            'id': 1,
            'name': 'John Smith',
            'role': 'Gate Staff',
            'email': 'john@school.com',
            'contact': '9876543210',
            'isActive': true,
            'joinDate': '2024-01-15',
          },
          {
            'id': 2,
            'name': 'Sarah Johnson',
            'role': 'Teacher',
            'email': 'sarah@school.com',
            'contact': '9876543211',
            'isActive': true,
            'joinDate': '2024-02-01',
          },
          {
            'id': 3,
            'name': 'Mike Wilson',
            'role': 'Driver',
            'email': 'mike@school.com',
            'contact': '9876543212',
            'isActive': false,
            'joinDate': '2023-12-10',
          },
        ];
        _loading = false;
      });
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
                        _buildStatItem('Total Staff', staffMembers.length.toString(), Icons.people),
                        _buildStatItem('Active Staff', staffMembers.where((s) => s['isActive'] == true).length.toString(), Icons.check_circle),
                        _buildStatItem('Teachers', staffMembers.where((s) => s['role'] == 'Teacher').length.toString(), Icons.school),
                        _buildStatItem('Gate Staff', staffMembers.where((s) => s['role'] == 'Gate Staff').length.toString(), Icons.security),
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
                                    Text('Contact: ${staff['contact']}'),
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
    switch (role.toLowerCase()) {
      case 'teacher':
        return Icons.school;
      case 'gate staff':
        return Icons.security;
      case 'driver':
        return Icons.drive_eta;
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
            Text('Contact: ${staff['contact']}'),
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

  void _toggleStaffStatus(Map<String, dynamic> staff) {
    setState(() {
      staff['isActive'] = !staff['isActive'];
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${staff['name']} ${staff['isActive'] ? 'activated' : 'deactivated'} successfully'),
        backgroundColor: Colors.green,
      ),
    );
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
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                staffMembers.removeWhere((s) => s['id'] == staff['id']);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${staff['name']} deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

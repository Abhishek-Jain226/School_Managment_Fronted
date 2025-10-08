import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_routes.dart';
import '../../services/vehicle_owner_service.dart';
import '../../services/auth_service.dart';
import '../widgets/school_selector.dart';

class VehicleOwnerDashboardPage extends StatefulWidget {
  const VehicleOwnerDashboardPage({super.key});

  @override
  State<VehicleOwnerDashboardPage> createState() => _VehicleOwnerDashboardPageState();
}

class _VehicleOwnerDashboardPageState extends State<VehicleOwnerDashboardPage> {
  final VehicleOwnerService _vehicleOwnerService = VehicleOwnerService();
  int? _currentSchoolId;
  String? _currentSchoolName;
  Map<String, dynamic>? _ownerData;
  bool _isLoading = true;
  
  // Dashboard statistics
  int _totalVehicles = 0;
  int _activeDrivers = 0;
  int _vehiclesInTransit = 0;
  int _pendingApprovals = 0;
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadOwnerData();
    _loadCurrentSchool();
  }

  Future<void> _loadCurrentSchool() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentSchoolId = prefs.getInt('currentSchoolId');
      _currentSchoolName = prefs.getString('currentSchoolName');
    });
  }

  Future<void> _loadOwnerData() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("userId");
      
      if (userId != null) {
        final response = await _vehicleOwnerService.getOwnerByUserId(userId);
        if (response['success'] == true) {
          setState(() {
            _ownerData = response['data'];
          });
          // Load statistics after owner data is loaded
          _loadDashboardStatistics();
        }
      }
    } catch (e) {
      print("Error loading owner data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSchoolSelected(int? schoolId, String? schoolName) {
    setState(() {
      _currentSchoolId = schoolId;
      _currentSchoolName = schoolName;
    });
    
    // Reload dashboard data for the selected school
    _loadOwnerData();
    _loadDashboardStatistics();
  }

  Future<void> _loadDashboardStatistics() async {
    if (_currentSchoolId == null || _ownerData == null) return;
    
    setState(() => _isLoadingStats = true);
    
    try {
      final ownerId = _ownerData!['ownerId'];
      print('🔍 Loading dashboard statistics for ownerId: $ownerId');
      
      // Load vehicles by owner
      final vehiclesResponse = await _vehicleOwnerService.getVehiclesByOwner(ownerId);
      print('🔍 Vehicles response: $vehiclesResponse');
      if (vehiclesResponse['success'] == true) {
        final vehicles = vehiclesResponse['data']['vehicles'] as List;
        setState(() {
          _totalVehicles = vehicles.length;
        });
        print('🔍 Total vehicles: $_totalVehicles');
      }
      
      // Load vehicles in transit by owner
      final vehiclesInTransitResponse = await _vehicleOwnerService.getVehiclesInTransitByOwner(ownerId);
      print('🔍 Vehicles in transit response: $vehiclesInTransitResponse');
      if (vehiclesInTransitResponse['success'] == true) {
        setState(() {
          _vehiclesInTransit = vehiclesInTransitResponse['data'] ?? 0;
        });
        print('🔍 Vehicles in transit: $_vehiclesInTransit');
      } else {
        setState(() {
          _vehiclesInTransit = 0;
        });
        print('🔍 Vehicles in transit: 0 (API failed)');
      }
      
      // Load drivers by owner
      final driversResponse = await _vehicleOwnerService.getDriversByOwner(ownerId);
      print('🔍 Drivers response: $driversResponse');
      if (driversResponse['success'] == true) {
        final drivers = driversResponse['data']['drivers'] as List;
        final activeDrivers = drivers.where((driver) => driver['isActive'] == true).length;
        setState(() {
          _activeDrivers = activeDrivers;
          _pendingApprovals = drivers.length - activeDrivers; // Assuming inactive drivers are pending
        });
        print('🔍 Active drivers: $_activeDrivers, Pending approvals: $_pendingApprovals');
      } else {
        // Fallback to mock data if API fails
        setState(() {
          _activeDrivers = 0;
          _pendingApprovals = 0;
        });
        print('🔍 Drivers: 0 (API failed)');
      }
      
      // Load recent activity
      final activityResponse = await _vehicleOwnerService.getRecentActivityByOwner(ownerId);
      print('🔍 Recent activity response: $activityResponse');
      if (activityResponse['success'] == true) {
        setState(() {
          _recentActivities = List<Map<String, dynamic>>.from(activityResponse['data'] ?? []);
        });
        print('🔍 Recent activities: ${_recentActivities.length}');
      } else {
        setState(() {
          _recentActivities = [];
        });
        print('🔍 Recent activities: 0 (API failed)');
      }
      
    } catch (e) {
      print("🔍 Error loading dashboard statistics: $e");
      // Keep existing values on error
    } finally {
      setState(() => _isLoadingStats = false);
    }
  }


  Widget _buildNavigationDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Header
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _ownerData?['name'] ?? "Vehicle Owner",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _ownerData?['email'] ?? "",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                if (_currentSchoolName != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _currentSchoolName!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Dashboard Section
                _buildDrawerSection("DASHBOARD", [
                  _buildDrawerItem(
                    icon: Icons.dashboard,
                    title: "Dashboard",
                    onTap: () {
                      Navigator.pop(context);
                      // Already on dashboard
                    },
                    isSelected: true,
                  ),
                ]),
                
                const Divider(),
                
                // Management Section
                _buildDrawerSection("MANAGEMENT", [
                  _buildDrawerItem(
                    icon: Icons.directions_bus,
                    title: "Vehicles",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.vehicleOwnerVehicleManagement);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: "Drivers",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.vehicleOwnerDriverManagement);
                    },
                  ),
                  // _buildDrawerItem(
                  //   icon: Icons.assignment,
                  //   title: "Assignments",
                  //   onTap: () {
                  //     Navigator.pop(context);
                  //     Navigator.pushNamed(context, AppRoutes.vehicleOwnerAssignments);
                  //   },
                  // ),
                  _buildDrawerItem(
                    icon: Icons.assignment_ind,
                    title: "Driver Assignment",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.vehicleOwnerDriverAssignment);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.school,
                    title: "School Mapping",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.requestVehicle);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.assignment_ind,
                    title: "Student-Trip Assignment",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.vehicleOwnerStudentTripAssignment);
                    },
                  ),
                ]),
                
                const Divider(),
                
                // Account Section
                _buildDrawerSection("ACCOUNT", [
                  _buildDrawerItem(
                    icon: Icons.person_outline,
                    title: "Profile",
                    onTap: () {
                      Navigator.pop(context);
                      if (_ownerData != null) {
                        final ownerId = _ownerData!['ownerId'];
                        Navigator.pushNamed(
                          context,
                          AppRoutes.vehicleOwnerProfile,
                          arguments: ownerId,
                        );
                      }
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: "Logout",
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutDialog();
                    },
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.blue.shade600 : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _logout(context);
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      final authService = AuthService();
      await authService.logout();
      
      // Navigate to login screen and clear navigation stack
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildNavigationDrawer(),
      appBar: AppBar(
        title: const Text("Vehicle Owner Dashboard"),
        actions: [
          // 🔹 School Selector
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: SchoolSelector(
              onSchoolSelected: _onSchoolSelected,
              currentSchoolId: _currentSchoolId,
            ),
          ),

          // 🔹 Owner Name & Avatar
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _ownerData == null
                    ? const Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blueGrey,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Owner",
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    : GestureDetector(
                        onTap: () {
                          final ownerId = _ownerData!['ownerId'];
                          Navigator.pushNamed(
                            context,
                            AppRoutes.vehicleOwnerProfile,
                            arguments: ownerId,
                          );
                        },
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.blueGrey,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _ownerData!['name'] ?? "Owner",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 School Context Card
            if (_currentSchoolName != null)
              Card(
                elevation: 2,
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.blue.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.school,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Current School Context",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _currentSchoolName!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            
            // 🔹 Summary Cards
            if (_currentSchoolId == null)
              Card(
                elevation: 2,
                color: Colors.orange.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.orange.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        color: Colors.orange.shade600,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Please select a school to view dashboard data",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Use the school selector in the top-right corner",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildCard(
                          "Total Vehicles", 
                          _isLoadingStats ? "..." : _totalVehicles.toString(),
                          icon: Icons.directions_bus,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCard(
                          "Active Drivers", 
                          _isLoadingStats ? "..." : _activeDrivers.toString(),
                          icon: Icons.person,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCard(
                          "In Transit", 
                          _isLoadingStats ? "..." : _vehiclesInTransit.toString(),
                          icon: Icons.local_shipping,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCard(
                          "Pending Approvals", 
                          _isLoadingStats ? "..." : _pendingApprovals.toString(),
                          icon: Icons.pending_actions,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 20),

            // 🔹 Recent Activity
            if (_currentSchoolId != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Recent Activity",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (_recentActivities.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            "No recent activity found",
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        ...(_recentActivities.take(5).map((activity) {
                          return ListTile(
                            dense: true,
                            leading: _getActivityIcon(activity['type']),
                            title: Text(activity['description'] ?? 'Activity'),
                            subtitle: Text(_formatDate(activity['createdDate'])),
                          );
                        }).toList()),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // 🔹 Quick Actions
            if (_currentSchoolId != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text("Quick Actions",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                              context, AppRoutes.registerVehicle);
                        },
                        icon: const Icon(Icons.directions_bus),
                        label: const Text("Register Vehicle"),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.registerDriver);
                        },
                        icon: const Icon(Icons.person_add),
                        label: const Text("Register Driver"),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                              context, AppRoutes.requestVehicle);
                        },
                        icon: const Icon(Icons.assignment_turned_in),
                        label: const Text("Request Vehicle Assignment"),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 🔹 Helper Widget for Summary Cards
  Widget _buildCard(String label, String value, {IconData? icon}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) Icon(icon, size: 20, color: Colors.blueGrey),
            Text(label,
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _getActivityIcon(String? activityType) {
    switch (activityType) {
      case 'PICKUP_FROM_PARENT':
        return const Icon(Icons.home, color: Colors.blue);
      case 'DROP_TO_SCHOOL':
        return const Icon(Icons.school, color: Colors.green);
      case 'PICKUP_FROM_SCHOOL':
        return const Icon(Icons.school, color: Colors.orange);
      case 'DROP_TO_PARENT':
        return const Icon(Icons.home, color: Colors.purple);
      case 'GATE_ENTRY':
        return const Icon(Icons.login, color: Colors.teal);
      case 'GATE_EXIT':
        return const Icon(Icons.logout, color: Colors.red);
      default:
        return const Icon(Icons.info, color: Colors.grey);
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown time';
    
    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'Unknown time';
      }
      
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }
}

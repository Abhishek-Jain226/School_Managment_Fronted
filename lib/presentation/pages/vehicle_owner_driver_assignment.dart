import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/vehicle_owner_service.dart';
import '../../services/vehicle_service.dart';
import '../../services/driver_service.dart';
import '../../app_routes.dart';

class VehicleOwnerDriverAssignmentPage extends StatefulWidget {
  const VehicleOwnerDriverAssignmentPage({super.key});

  @override
  State<VehicleOwnerDriverAssignmentPage> createState() => _VehicleOwnerDriverAssignmentPageState();
}

class _VehicleOwnerDriverAssignmentPageState extends State<VehicleOwnerDriverAssignmentPage> {
  final VehicleOwnerService _vehicleOwnerService = VehicleOwnerService();
  final VehicleService _vehicleService = VehicleService();
  final DriverService _driverService = DriverService();
  
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _assignments = [];
  bool _isLoading = true;
  Map<String, dynamic>? _ownerData;
  int? _currentSchoolId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("userId");
      _currentSchoolId = prefs.getInt("schoolId");
      
      if (userId != null) {
        // Load owner data
        final ownerResponse = await _vehicleOwnerService.getOwnerByUserId(userId);
        if (ownerResponse['success'] == true) {
          _ownerData = ownerResponse['data'];
          final ownerId = _ownerData!['ownerId'];
          
          // Load vehicles, drivers, and assignments in parallel
          print("🔍 _loadData: ownerId = $ownerId");
          await Future.wait([
            _loadVehicles(ownerId),
            _loadDrivers(ownerId),
            _loadAssignments(ownerId),
          ]);
          print("🔍 _loadData: After loading, _vehicles.length = ${_vehicles.length}");
        }
      }
    } catch (e) {
      print("Error loading data: $e");
      _showError("Error loading data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadVehicles(int ownerId) async {
    try {
      print("🔍 Loading vehicles for owner ID: $ownerId");
      final vehiclesResponse = await _vehicleOwnerService.getVehiclesByOwner(ownerId);
      print("🔍 Vehicles response: $vehiclesResponse");
      
      if (vehiclesResponse['success'] == true) {
        final vehiclesData = vehiclesResponse['data'];
        print("🔍 Vehicles data: $vehiclesData");
        
        setState(() {
          _vehicles = List<Map<String, dynamic>>.from(vehiclesData['vehicles'] ?? []);
        });
        print("🔍 Loaded ${_vehicles.length} vehicles");
        print("🔍 _vehicles content: $_vehicles");
        print("🔍 _vehicles.isEmpty: ${_vehicles.isEmpty}");
      } else {
        print("🔍 Failed to load vehicles: ${vehiclesResponse['message']}");
        setState(() {
          _vehicles = [];
        });
      }
    } catch (e) {
      print("🔍 Error loading vehicles: $e");
      setState(() {
        _vehicles = [];
      });
    }
    print("🔍 _loadVehicles: Final _vehicles.length = ${_vehicles.length}");
  }

  Future<void> _loadDrivers(int ownerId) async {
    try {
      final driversResponse = await _vehicleOwnerService.getDriversByOwner(ownerId);
      if (driversResponse['success'] == true) {
        setState(() {
          _drivers = List<Map<String, dynamic>>.from(driversResponse['data']['drivers'] ?? []);
        });
      }
    } catch (e) {
      print("Error loading drivers: $e");
    }
  }

  Future<void> _loadAssignments(int ownerId) async {
    try {
      final assignmentsResponse = await _vehicleOwnerService.getDriverAssignments(ownerId);
      if (assignmentsResponse['success'] == true) {
        setState(() {
          _assignments = List<Map<String, dynamic>>.from(assignmentsResponse['data'] ?? []);
        });
      } else {
        setState(() {
          _assignments = [];
        });
      }
    } catch (e) {
      print("Error loading assignments: $e");
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

  Future<void> _showAssignDriverDialog() async {
    print("🔍 _showAssignDriverDialog: _vehicles.length = ${_vehicles.length}");
    print("🔍 _showAssignDriverDialog: _vehicles = $_vehicles");
    
    if (_vehicles.isEmpty) {
      _showError("No vehicles available. Please register a vehicle first.");
      return;
    }
    
    if (_drivers.isEmpty) {
      _showError("No drivers available. Please register a driver first.");
      return;
    }

    if (_currentSchoolId == null) {
      _showError("No school selected. Please select a school first.");
      return;
    }

    Map<String, dynamic>? selectedVehicle;
    Map<String, dynamic>? selectedDriver;
    bool isPrimary = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Assign Driver to Vehicle"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Vehicle Selection
                DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: const InputDecoration(
                    labelText: "Select Vehicle",
                    border: OutlineInputBorder(),
                  ),
                  value: selectedVehicle,
                  items: _vehicles.map((vehicle) {
                    return DropdownMenuItem(
                      value: vehicle,
                      child: Text("${vehicle['vehicleNumber']} (${vehicle['vehicleType']})"),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedVehicle = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Driver Selection
                DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: const InputDecoration(
                    labelText: "Select Driver",
                    border: OutlineInputBorder(),
                  ),
                  value: selectedDriver,
                  items: _drivers.map((driver) {
                    return DropdownMenuItem(
                      value: driver,
                      child: Text("${driver['driverName']} (${driver['driverContactNumber']})"),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedDriver = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Primary Driver Checkbox
                CheckboxListTile(
                  title: const Text("Primary Driver"),
                  subtitle: const Text("Mark as primary driver for this vehicle"),
                  value: isPrimary,
                  onChanged: (value) {
                    setDialogState(() {
                      isPrimary = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: selectedVehicle != null && selectedDriver != null
                  ? () async {
                      Navigator.pop(ctx);
                      await _assignDriverToVehicle(
                        selectedVehicle!,
                        selectedDriver!,
                        isPrimary,
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

  Future<void> _assignDriverToVehicle(
    Map<String, dynamic> vehicle,
    Map<String, dynamic> driver,
    bool isPrimary,
  ) async {
    try {
      final assignmentData = {
        'vehicleId': vehicle['vehicleId'],
        'driverId': driver['driverId'],
        'schoolId': _currentSchoolId,
        'isPrimary': isPrimary,
        'isActive': true,
        'createdBy': _ownerData?['name'] ?? 'Vehicle Owner',
      };

      print("🔍 _assignDriverToVehicle: assignmentData = $assignmentData");
      print("🔍 _assignDriverToVehicle: vehicle = $vehicle");
      print("🔍 _assignDriverToVehicle: driver = $driver");
      print("🔍 _assignDriverToVehicle: _currentSchoolId = $_currentSchoolId");

      final response = await _vehicleOwnerService.assignDriverToVehicle(assignmentData);
      print("🔍 _assignDriverToVehicle: response = $response");
      
      if (response['success'] == true) {
        _showSuccess("Driver assigned to vehicle successfully!");
      } else {
        _showError("Failed to assign driver: ${response['message']}");
      }
      
      // Reload assignments
      if (_ownerData != null) {
        await _loadAssignments(_ownerData!['ownerId']);
      }
    } catch (e) {
      print("🔍 _assignDriverToVehicle: error = $e");
      _showError("Failed to assign driver: $e");
    }
  }

  Future<void> _removeAssignment(Map<String, dynamic> assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove Assignment"),
        content: Text("Are you sure you want to remove this driver assignment?"),
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
        final assignmentId = assignment['vehicleDriverId'];
        final response = await _vehicleOwnerService.removeDriverAssignment(assignmentId);
        if (response['success'] == true) {
          _showSuccess("Assignment removed successfully!");
        } else {
          _showError("Failed to remove assignment: ${response['message']}");
        }
        
        // Reload assignments
        if (_ownerData != null) {
          await _loadAssignments(_ownerData!['ownerId']);
        }
      } catch (e) {
        _showError("Failed to remove assignment: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Assignment"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          "Vehicles",
                          _vehicles.length.toString(),
                          Icons.directions_bus,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          "Drivers",
                          _drivers.length.toString(),
                          Icons.person,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          "Assignments",
                          _assignments.length.toString(),
                          Icons.assignment_ind,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quick Actions
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Quick Actions",
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
                                  onPressed: _showAssignDriverDialog,
                                  icon: const Icon(Icons.assignment_ind),
                                  label: const Text("Assign Driver"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(context, AppRoutes.registerDriver);
                                  },
                                  icon: const Icon(Icons.person_add),
                                  label: const Text("Add Driver"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Current Assignments
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Current Assignments",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_assignments.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  "No assignments found.\nAssign drivers to vehicles to get started.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          else
                            ..._assignments.map((assignment) => _buildAssignmentCard(assignment)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: assignment['isPrimary'] == true ? Colors.orange : Colors.blue,
          child: Icon(
            assignment['isPrimary'] == true ? Icons.star : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          assignment['driverName'] ?? 'Unknown Driver',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Vehicle: ${assignment['vehicleNumber'] ?? 'Unknown'}"),
            Text("Status: ${assignment['isActive'] == true ? 'Active' : 'Inactive'}"),
            if (assignment['isPrimary'] == true)
              const Text(
                "Primary Driver",
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Remove Assignment'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'remove') {
              _removeAssignment(assignment);
            }
          },
        ),
      ),
    );
  }
}

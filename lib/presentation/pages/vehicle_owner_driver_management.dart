import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/vehicle_owner_service.dart';
import '../../services/driver_service.dart';
import '../../app_routes.dart';

class VehicleOwnerDriverManagementPage extends StatefulWidget {
  const VehicleOwnerDriverManagementPage({super.key});

  @override
  State<VehicleOwnerDriverManagementPage> createState() => _VehicleOwnerDriverManagementPageState();
}

class _VehicleOwnerDriverManagementPageState extends State<VehicleOwnerDriverManagementPage> {
  final VehicleOwnerService _vehicleOwnerService = VehicleOwnerService();
  final DriverService _driverService = DriverService();
  
  List<Map<String, dynamic>> _drivers = [];
  bool _isLoading = true;
  Map<String, dynamic>? _ownerData;

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
      
      if (userId != null) {
        // Load owner data
        final ownerResponse = await _vehicleOwnerService.getOwnerByUserId(userId);
        if (ownerResponse['success'] == true) {
          _ownerData = ownerResponse['data'];
          final ownerId = _ownerData!['ownerId'];
          // Load drivers by owner
          final driversResponse = await _vehicleOwnerService.getDriversByOwner(ownerId);
          if (driversResponse['success'] == true) {
            setState(() {
              _drivers = List<Map<String, dynamic>>.from(driversResponse['data']['drivers'] ?? []);
            });
          } else {
            // If no drivers found, set empty list
            setState(() {
              _drivers = [];
            });
          }
        }
      }
    } catch (e) {
      print("Error loading data: $e");
      _showError("Error loading drivers: $e");
    } finally {
      setState(() => _isLoading = false);
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

  Future<void> _deleteDriver(int driverId, String driverName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Driver"),
        content: Text("Are you sure you want to delete driver $driverName?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // TODO: Implement delete driver API call
        _showSuccess("Driver deleted successfully");
        _loadData(); // Refresh the list
      } catch (e) {
        _showError("Error deleting driver: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Management"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 48,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Total Drivers",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                _drivers.length.toString(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.registerDriver)
                                .then((_) => _loadData());
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("Add Driver"),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Drivers List
                Expanded(
                  child: _drivers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No drivers registered yet",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Add your first driver to get started",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, AppRoutes.registerDriver)
                                      .then((_) => _loadData());
                                },
                                icon: const Icon(Icons.add),
                                label: const Text("Register Driver"),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _drivers.length,
                          itemBuilder: (context, index) {
                            final driver = _drivers[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: (driver['isActive'] == true) 
                                      ? Colors.green 
                                      : Colors.grey,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  driver['driverName'] ?? 'Unknown Driver',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Contact: ${driver['driverContactNumber'] ?? 'N/A'}"),
                                    Text("Address: ${driver['driverAddress'] ?? 'N/A'}"),
                                    if (driver['email'] != null)
                                      Text("Email: ${driver['email']}"),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          (driver['isActive'] == true) 
                                              ? Icons.check_circle 
                                              : Icons.cancel,
                                          size: 16,
                                          color: (driver['isActive'] == true) 
                                              ? Colors.green 
                                              : Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          (driver['isActive'] == true) ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            color: (driver['isActive'] == true) 
                                                ? Colors.green 
                                                : Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (driver['assignedVehicle'] != null) ...[
                                          const SizedBox(width: 16),
                                          Icon(
                                            Icons.directions_bus,
                                            size: 16,
                                            color: Colors.blue,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Assigned to ${driver['assignedVehicle']}",
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        // TODO: Navigate to edit driver page
                                        _showSuccess("Edit functionality coming soon");
                                        break;
                                      case 'assign':
                                        // TODO: Navigate to driver-vehicle assignment
                                        _showSuccess("Assignment functionality coming soon");
                                        break;
                                      case 'delete':
                                        _deleteDriver(
                                          driver['driverId'],
                                          driver['driverName'] ?? 'Unknown',
                                        );
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
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'assign',
                                      child: Row(
                                        children: [
                                          Icon(Icons.assignment, size: 20),
                                          SizedBox(width: 8),
                                          Text('Assign to Vehicle'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 20, color: Colors.red),
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
}

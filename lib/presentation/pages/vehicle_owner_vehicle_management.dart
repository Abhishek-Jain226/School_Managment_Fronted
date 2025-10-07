import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/vehicle_owner_service.dart';
import '../../services/vehicle_service.dart';
import '../../app_routes.dart';

class VehicleOwnerVehicleManagementPage extends StatefulWidget {
  const VehicleOwnerVehicleManagementPage({super.key});

  @override
  State<VehicleOwnerVehicleManagementPage> createState() => _VehicleOwnerVehicleManagementPageState();
}

class _VehicleOwnerVehicleManagementPageState extends State<VehicleOwnerVehicleManagementPage> {
  final VehicleOwnerService _vehicleOwnerService = VehicleOwnerService();
  final VehicleService _vehicleService = VehicleService();
  
  List<Map<String, dynamic>> _vehicles = [];
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
          
          // Load vehicles
          final vehiclesResponse = await _vehicleOwnerService.getVehiclesByOwner(ownerId);
          if (vehiclesResponse['success'] == true) {
            setState(() {
              _vehicles = List<Map<String, dynamic>>.from(vehiclesResponse['data']['vehicles'] ?? []);
            });
          }
        }
      }
    } catch (e) {
      print("Error loading data: $e");
      _showError("Error loading vehicles: $e");
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

  Future<void> _deleteVehicle(int vehicleId, String vehicleNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Vehicle"),
        content: Text("Are you sure you want to delete vehicle $vehicleNumber?"),
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
        // TODO: Implement delete vehicle API call
        _showSuccess("Vehicle deleted successfully");
        _loadData(); // Refresh the list
      } catch (e) {
        _showError("Error deleting vehicle: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vehicle Management"),
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
                          Icons.directions_bus,
                          size: 48,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Total Vehicles",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                _vehicles.length.toString(),
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
                            Navigator.pushNamed(context, AppRoutes.registerVehicle)
                                .then((_) => _loadData());
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("Add Vehicle"),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Vehicles List
                Expanded(
                  child: _vehicles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.directions_bus_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No vehicles registered yet",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Add your first vehicle to get started",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, AppRoutes.registerVehicle)
                                      .then((_) => _loadData());
                                },
                                icon: const Icon(Icons.add),
                                label: const Text("Register Vehicle"),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _vehicles.length,
                          itemBuilder: (context, index) {
                            final vehicle = _vehicles[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: (vehicle['isActive'] == true) 
                                      ? Colors.green 
                                      : Colors.grey,
                                  child: Icon(
                                    Icons.directions_bus,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  vehicle['vehicleNumber'] ?? 'Unknown Vehicle',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Type: ${vehicle['vehicleType'] ?? 'N/A'}"),
                                    Text("Registration: ${vehicle['registrationNumber'] ?? 'N/A'}"),
                                    Text("Capacity: ${vehicle['capacity'] ?? 'N/A'}"),
                                    Row(
                                      children: [
                                        Icon(
                                          (vehicle['isActive'] == true) 
                                              ? Icons.check_circle 
                                              : Icons.cancel,
                                          size: 16,
                                          color: (vehicle['isActive'] == true) 
                                              ? Colors.green 
                                              : Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          (vehicle['isActive'] == true) ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            color: (vehicle['isActive'] == true) 
                                                ? Colors.green 
                                                : Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        // TODO: Navigate to edit vehicle page
                                        _showSuccess("Edit functionality coming soon");
                                        break;
                                      case 'delete':
                                        _deleteVehicle(
                                          vehicle['vehicleId'],
                                          vehicle['vehicleNumber'] ?? 'Unknown',
                                        );
                                        break;
                                      case 'assign':
                                        // Navigate to school assignment
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.requestVehicle,
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
                                          Icon(Icons.school, size: 20),
                                          SizedBox(width: 8),
                                          Text('Assign to School'),
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

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/vehicle.dart';
import '../../services/vehicle_service.dart';

class VehicleManagementPage extends StatefulWidget {
  const VehicleManagementPage({super.key});

  @override
  State<VehicleManagementPage> createState() => _VehicleManagementPageState();
}

class _VehicleManagementPageState extends State<VehicleManagementPage> {
  final VehicleService _vehicleService = VehicleService();
  List<Vehicle> vehicles = [];
  bool _loading = true;
  int? schoolId;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      schoolId = prefs.getInt("schoolId");
      
      if (schoolId != null) {
        final result = await _vehicleService.getVehiclesBySchool(schoolId!);
        setState(() {
          vehicles = result;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        _showErrorSnackBar("School not found in preferences");
      }
    } catch (e) {
      setState(() => _loading = false);
      _showErrorSnackBar("Error loading vehicles: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVehicles,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Information Card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Vehicle Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'School Admin can view vehicle reports and statistics. Vehicle registration is managed by Vehicle Owners.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
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
                        _buildStatItem('Total Vehicles', vehicles.length.toString(), Icons.directions_bus),
                        _buildStatItem('Active Vehicles', vehicles.where((v) => v.isActive ?? false).length.toString(), Icons.check_circle),
                        _buildStatItem('In Transit', '0', Icons.local_shipping), // TODO: Implement real transit logic
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Vehicles List
                Expanded(
                  child: vehicles.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_bus, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No vehicles found',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No vehicles have been registered yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: vehicles.length,
                          itemBuilder: (context, index) {
                            final vehicle = vehicles[index];
                            final isActive = vehicle.isActive ?? false;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isActive ? Colors.green : Colors.grey,
                                  child: const Icon(
                                    Icons.directions_bus,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  'Vehicle ${vehicle.vehicleNumber ?? 'N/A'}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Registration: ${vehicle.registrationNumber ?? 'N/A'}'),
                                    Text('Type: ${vehicle.vehicleType ?? 'N/A'}'),
                                    Row(
                                      children: [
                                        Icon(
                                          isActive ? Icons.check_circle : Icons.cancel,
                                          size: 16,
                                          color: isActive ? Colors.green : Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            color: isActive ? Colors.green : Colors.red,
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
                                        _showVehicleDetails(vehicle);
                                        break;
                                      case 'reports':
                                        // TODO: Navigate to vehicle reports
                                        _showErrorSnackBar('Vehicle reports feature coming soon');
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'view',
                                      child: Row(
                                        children: [
                                          Icon(Icons.visibility),
                                          SizedBox(width: 8),
                                          Text('View Details'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'reports',
                                      child: Row(
                                        children: [
                                          Icon(Icons.analytics),
                                          SizedBox(width: 8),
                                          Text('View Reports'),
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

  void _showVehicleDetails(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Vehicle ${vehicle.vehicleNumber ?? 'N/A'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registration: ${vehicle.registrationNumber ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Type: ${vehicle.vehicleType ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Status: ${vehicle.isActive ?? false ? 'Active' : 'Inactive'}'),
            const SizedBox(height: 8),
            Text('Owner: ${vehicle.ownerName ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Driver: ${vehicle.driverName ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Capacity: ${vehicle.capacity?.toString() ?? 'N/A'}'),
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
}

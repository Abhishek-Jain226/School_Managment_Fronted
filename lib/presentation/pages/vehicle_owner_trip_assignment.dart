import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/vehicle_owner_service.dart';
import '../../services/trip_service.dart';
import '../../data/models/trip_response.dart';

class VehicleOwnerTripAssignmentPage extends StatefulWidget {
  const VehicleOwnerTripAssignmentPage({super.key});

  @override
  State<VehicleOwnerTripAssignmentPage> createState() => _VehicleOwnerTripAssignmentPageState();
}

class _VehicleOwnerTripAssignmentPageState extends State<VehicleOwnerTripAssignmentPage> {
  final VehicleOwnerService _vehicleOwnerService = VehicleOwnerService();
  final TripService _tripService = TripService();
  
  // Data variables
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _availableVehicles = [];
  Map<String, dynamic>? _ownerData;
  int? _currentSchoolId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      _currentSchoolId = prefs.getInt("currentSchoolId");
      final ownerId = prefs.getInt("ownerId");
      final ownerName = prefs.getString("ownerName");

      if (_currentSchoolId == null || ownerId == null) {
        setState(() {
          _errorMessage = "School or Owner information not found";
          _isLoading = false;
        });
        return;
      }

      // Set owner data
      _ownerData = {
        "ownerId": ownerId,
        "ownerName": ownerName ?? "Vehicle Owner",
      };

      // Load trips and available vehicles in parallel
      await Future.wait([
        _loadTrips(ownerId),
        _loadAvailableVehicles(ownerId, _currentSchoolId!),
      ]);

    } catch (e) {
      print("Error loading data: $e");
      setState(() {
        _errorMessage = "Error loading data: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTrips(int ownerId) async {
    try {
      print("🔍 Loading trips for owner: $ownerId");
      final response = await _vehicleOwnerService.getTripsByOwner(ownerId);
      
      if (response["success"] == true) {
        setState(() {
          _trips = List<Map<String, dynamic>>.from(response["data"] ?? []);
        });
        print("🔍 Loaded ${_trips.length} trips");
      } else {
        print("🔍 Failed to load trips: ${response["message"]}");
        setState(() {
          _errorMessage = response["message"] ?? "Failed to load trips";
        });
      }
    } catch (e) {
      print("🔍 Error loading trips: $e");
      setState(() {
        _errorMessage = "Error loading trips: $e";
      });
    }
  }

  Future<void> _loadAvailableVehicles(int ownerId, int schoolId) async {
    try {
      print("🔍 Loading available vehicles for owner: $ownerId, school: $schoolId");
      final response = await _vehicleOwnerService.getAvailableVehiclesForTrip(ownerId, schoolId);
      
      if (response["success"] == true) {
        setState(() {
          _availableVehicles = List<Map<String, dynamic>>.from(response["data"] ?? []);
        });
        print("🔍 Loaded ${_availableVehicles.length} available vehicles");
      } else {
        print("🔍 Failed to load vehicles: ${response["message"]}");
        setState(() {
          _errorMessage = response["message"] ?? "Failed to load vehicles";
        });
      }
    } catch (e) {
      print("🔍 Error loading vehicles: $e");
      setState(() {
        _errorMessage = "Error loading vehicles: $e";
      });
    }
  }

  Future<void> _assignTripToVehicle(Map<String, dynamic> trip, Map<String, dynamic> vehicle) async {
    try {
      if (_ownerData == null) {
        _showErrorSnackBar("Owner information not available");
        return;
      }

      final ownerId = _ownerData!["ownerId"] as int;
      final tripId = trip["tripId"] as int;
      final vehicleId = vehicle["vehicleId"] as int;
      final updatedBy = _ownerData!["ownerName"] as String;

      print("🔍 Assigning trip $tripId to vehicle $vehicleId by $updatedBy");

      final response = await _vehicleOwnerService.assignTripToVehicle(
        ownerId, tripId, vehicleId, updatedBy
      );

      if (response["success"] == true) {
        _showSuccessSnackBar("Trip assigned to vehicle successfully!");
        await _loadData(); // Refresh data
      } else {
        _showErrorSnackBar(response["message"] ?? "Failed to assign trip");
      }
    } catch (e) {
      print("🔍 Error assigning trip: $e");
      _showErrorSnackBar("Error assigning trip: $e");
    }
  }

  void _showAssignTripDialog(Map<String, dynamic> trip) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Assign Trip to Vehicle"),
          content: SizedBox(
            width: double.maxFinite,
            height: 400, // Fixed height to prevent overflow
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // Trip Information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Trip: ${trip["tripName"] ?? 'Unknown'}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text("Route: ${trip["routeName"] ?? 'Unknown'}"),
                      Text("Type: ${trip["tripTypeDisplay"] ?? 'Unknown'}"),
                      if (trip["vehicle"] != null)
                        Text("Current Vehicle: ${trip["vehicle"]["vehicleNumber"] ?? 'Unknown'}"),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Vehicle Selection
                DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: const InputDecoration(
                    labelText: "Select Vehicle",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_bus),
                  ),
                  items: _availableVehicles.map((vehicle) {
                    final vehicleNumber = vehicle["vehicleNumber"] ?? 'Unknown';
                    final vehicleType = vehicle["vehicleType"] ?? 'Unknown';
                    final driverName = vehicle["assignedDriverName"] ?? 'No Driver';
                    final hasDriver = vehicle["hasAssignedDriver"] == true;
                    
                    return DropdownMenuItem(
                      value: vehicle,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("$vehicleNumber ($vehicleType)"),
                          Row(
                            children: [
                              Icon(
                                hasDriver ? Icons.person : Icons.person_off,
                                size: 16,
                                color: hasDriver ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                driverName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: hasDriver ? Colors.green[700] : Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (selectedVehicle) {
                    if (selectedVehicle != null) {
                      _assignTripToVehicle(trip, selectedVehicle);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
          ],
        ),
      ),
    );
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip Assignment"),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(fontSize: 16, color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
              : _trips.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            "No trips found",
                            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Trips will appear here once they are created",
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Summary Cards
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  "Total Trips",
                                  _trips.length.toString(),
                                  Icons.assignment,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSummaryCard(
                                  "Available Vehicles",
                                  _availableVehicles.length.toString(),
                                  Icons.directions_bus,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Trips List
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _trips.length,
                            itemBuilder: (context, index) {
                              final trip = _trips[index];
                              return _buildTripCard(trip);
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
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
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final tripName = trip["tripName"] ?? 'Unknown Trip';
    final routeName = trip["routeName"] ?? 'Unknown Route';
    final tripType = trip["tripTypeDisplay"] ?? 'Unknown Type';
    final tripStatus = trip["tripStatus"] ?? 'Not Started';
    final vehicle = trip["vehicle"];
    final driver = trip["driver"];
    
    Color statusColor = Colors.grey;
    switch (tripStatus.toLowerCase()) {
      case 'not_started':
        statusColor = Colors.grey;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tripName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Route: $routeName",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        "Type: $tripType",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    tripStatus.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Vehicle and Driver Info
            if (vehicle != null || driver != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    if (vehicle != null)
                      Row(
                        children: [
                          Icon(Icons.directions_bus, size: 16, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          Text("Vehicle: ${vehicle["vehicleNumber"] ?? 'Unknown'}"),
                        ],
                      ),
                    if (driver != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            driver["isActivated"] == true ? Icons.person : Icons.person_off,
                            size: 16,
                            color: driver["isActivated"] == true ? Colors.green.shade600 : Colors.orange.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text("Driver: ${driver["driverName"] ?? 'Unknown'}"),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAssignTripDialog(trip),
                icon: const Icon(Icons.assignment),
                label: const Text("Assign to Vehicle"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

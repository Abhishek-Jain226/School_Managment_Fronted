import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/vehicle_service.dart';

class RequestVehicleAssignmentPage extends StatefulWidget {
  const RequestVehicleAssignmentPage({super.key});

  @override
  State<RequestVehicleAssignmentPage> createState() =>
      _RequestVehicleAssignmentPageState();
}

class _RequestVehicleAssignmentPageState
    extends State<RequestVehicleAssignmentPage> {
  String? _selectedVehicle;
  List<Map<String, dynamic>> _vehicles = [];
  bool _loading = true;
  final _service = VehicleService();

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString("userName"); // login ke time save hua tha

    if (userName == null) {
      setState(() => _loading = false);
      return;
    }

    // 🔹 Ab API call username se karenge
    final res = await _service.getVehiclesByCreatedBy(userName);

    debugPrint("🔹 Vehicles API Response: $res");

    if (res['success'] == true && res['data'] != null) {
      setState(() {
        _vehicles = List<Map<String, dynamic>>.from(res['data']);
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select vehicle")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final schoolId = prefs.getInt("schoolId");
    final ownerId = prefs.getInt("ownerId");

    if (schoolId == null || ownerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing school or owner info")),
      );
      return;
    }

    final req = {
      "schoolId": schoolId,
      "vehicleId": int.parse(_selectedVehicle!),
      "ownerId": ownerId,
      "createdBy": prefs.getString("userName") ?? "owner"
    };

    debugPrint("📤 Sending Request Body: $req");

    final res = await _service.assignVehicleRequest(req);

    debugPrint("✅ Request API Response: $res");

    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? "Request submitted")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? "Failed to submit request")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Request Vehicle Assignment")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? const Center(child: Text("No vehicles found"))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedVehicle,
                        items: _vehicles
                            .map(
                              (v) => DropdownMenuItem(
                                value: v['vehicleId'].toString(),
                                child: Text(v['vehicleNumber'] ??
                                    "Vehicle ${v['vehicleId']}"),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedVehicle = val),
                        decoration: const InputDecoration(
                          labelText: "Select Vehicle",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submit,
                        child: const Text("Submit Request"),
                      ),
                    ],
                  ),
                ),
    );
  }
}

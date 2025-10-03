import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/trip_request.dart';
import '../../data/models/vehicle.dart';
import '../../services/trip_service.dart';
import '../../services/vehicle_service.dart';

class CreateTripPage extends StatefulWidget {
  const CreateTripPage({super.key});

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final _formKey = GlobalKey<FormState>();
  final _tripNameController = TextEditingController();
  final _tripNumberController = TextEditingController();
  Vehicle? _selectedVehicle;

  final TripService _tripService = TripService();
  final VehicleService _vehicleService = VehicleService();

  List<Vehicle> vehicles = [];
  bool _loading = false;
  bool _loadingVehicles = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final schoolId = prefs.getInt("schoolId") ?? 1;

    final list = await _vehicleService.getVehiclesBySchool(schoolId);
    setState(() {
      vehicles = list;
      _loadingVehicles = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedVehicle == null) return;

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final schoolId = prefs.getInt("schoolId") ?? 1;
      final userName = prefs.getString("userName") ?? "Admin";

      final tripRequest = TripRequest(
        schoolId: schoolId,
        vehicleId: _selectedVehicle!.vehicleId,
        tripName: _tripNameController.text.trim(),
        tripNumber: int.parse(_tripNumberController.text.trim()),
        createdBy: userName,
      );

      final success = await _tripService.createTrip(tripRequest);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Trip Created Successfully ✅")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create trip ❌")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Trip")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loadingVehicles
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _tripNameController,
                      decoration: const InputDecoration(labelText: "Trip Name"),
                      validator: (v) => v == null || v.isEmpty ? "Enter trip name" : null,
                    ),
                    TextFormField(
                      controller: _tripNumberController,
                      decoration: const InputDecoration(labelText: "Trip Number"),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? "Enter trip number" : null,
                    ),
                    DropdownButtonFormField<Vehicle>(
                      value: _selectedVehicle,
                      items: vehicles
                          .map((v) => DropdownMenuItem(
                                value: v,
                                child: Text(v.vehicleNumber),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedVehicle = val),
                      decoration: const InputDecoration(labelText: "Select Vehicle"),
                      validator: (v) => v == null ? "Select a vehicle" : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Create Trip"),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

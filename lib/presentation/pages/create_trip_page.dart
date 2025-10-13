import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/trip_request.dart';
import '../../data/models/trip_type.dart';
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
  final _routeNameController = TextEditingController();
  final _routeDescriptionController = TextEditingController();
  
  Vehicle? _selectedVehicle;
  String _selectedTripType = TripType.morningPickup.value;

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

  @override
  void dispose() {
    _tripNameController.dispose();
    _tripNumberController.dispose();
    _routeNameController.dispose();
    _routeDescriptionController.dispose();
    super.dispose();
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
        vehicleId: _selectedVehicle!.vehicleId!,
        tripName: _tripNameController.text.trim(),
        tripNumber: int.parse(_tripNumberController.text.trim()),
        tripType: _selectedTripType,
        routeName: _routeNameController.text.trim(),
        routeDescription: _routeDescriptionController.text.trim(),
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
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                    TextFormField(
                      controller: _tripNameController,
                      decoration: const InputDecoration(
                        labelText: "Trip Name",
                        hintText: "Enter trip name",
                      ),
                      validator: (v) => v == null || v.isEmpty ? "Enter trip name" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tripNumberController,
                      decoration: const InputDecoration(
                        labelText: "Trip Number",
                        hintText: "Enter trip number",
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? "Enter trip number" : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedTripType,
                      items: TripType.getDropdownItems()
                          .map((item) => DropdownMenuItem(
                                value: item['value'],
                                child: Text(item['label']!),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedTripType = val!),
                      decoration: const InputDecoration(labelText: "Trip Type"),
                      validator: (v) => v == null ? "Select trip type" : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Vehicle>(
                      initialValue: _selectedVehicle,
                      items: vehicles
                          .map((v) => DropdownMenuItem(
                                value: v,
                                child: Text(v.vehicleNumber ?? 'Unknown Vehicle'),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedVehicle = val),
                      decoration: const InputDecoration(labelText: "Select Vehicle"),
                      validator: (v) => v == null ? "Select a vehicle" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _routeNameController,
                      decoration: const InputDecoration(
                        labelText: "Route Name",
                        hintText: "Enter route name",
                      ),
                      validator: (v) => v == null || v.isEmpty ? "Enter route name" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _routeDescriptionController,
                      decoration: const InputDecoration(
                        labelText: "Route Description",
                        hintText: "Enter detailed route information",
                      ),
                      maxLines: 3,
                      validator: (v) => v == null || v.isEmpty ? "Enter route description" : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _loading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 12),
                                Text("Creating Trip..."),
                              ],
                            )
                          : const Text("Create Trip"),
                    ),
                  ],
                  ),
                ),
              ),
      ),
    );
  }
}

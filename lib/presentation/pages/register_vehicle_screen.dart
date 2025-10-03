// lib/screens/register_vehicle_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/New_vehicle_request.dart';
import '../../services/vehicle_service.dart';

class RegisterVehicleScreen extends StatefulWidget {
  const RegisterVehicleScreen({super.key});

  @override
  State<RegisterVehicleScreen> createState() => _RegisterVehicleScreenState();
}

class _RegisterVehicleScreenState extends State<RegisterVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberCtl = TextEditingController();
  final _registrationNumberCtl = TextEditingController();

  String? _photoBase64;
  File? _photoFile;
  bool _submitting = false;

  String? _selectedVehicleType; // ✅ vehicleType dropdown value


  final _service = VehicleService();
  final _picker = ImagePicker();

  final List<String> _vehicleTypes = ["Car", "Auto", "Bus", "Van"]; // ✅ dropdown list 

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked =
        await _picker.pickImage(source: source, imageQuality: 75);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _photoBase64 = base64Encode(bytes);
      _photoFile = File(picked.path);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final createdBy = prefs.getString("userName") ?? "";
      

      final req = VehicleRequest(
        vehicleNumber: _vehicleNumberCtl.text.trim(),
        registrationNumber: _registrationNumberCtl.text.trim(),
        vehiclePhoto: _photoBase64,
        createdBy: createdBy,
         vehicleType: _selectedVehicleType!, // ✅ send type
         
      );

      final res = await _service.registerVehicle(req);

      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Vehicle registered')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _vehicleNumberCtl.dispose();
    _registrationNumberCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register Vehicle")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => SafeArea(
                      child: Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text("Choose from gallery"),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.gallery);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text("Take photo"),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.camera);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      _photoFile != null ? FileImage(_photoFile!) : null,
                  child: _photoFile == null
                      ? const Icon(Icons.camera_alt, size: 36)
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _vehicleNumberCtl,
                decoration: const InputDecoration(labelText: "Vehicle Number"),
                validator: (v) =>
                    v == null || v.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _registrationNumberCtl,
                decoration:
                    const InputDecoration(labelText: "Registration Number"),
                validator: (v) =>
                    v == null || v.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),

              // ✅ Vehicle Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedVehicleType,
                items: _vehicleTypes
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedVehicleType = val),
                decoration: const InputDecoration(labelText: "Vehicle Type"),
                validator: (v) =>
                    v == null ? "Please select vehicle type" : null,
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Register Vehicle"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/vehicle_owner_request.dart';
import '../../services/vehicle_owner_service.dart';

class VehicleOwnerProfilePage extends StatefulWidget {
  final int ownerId; 

  const VehicleOwnerProfilePage({Key? key, required this.ownerId})
      : super(key: key);

  @override
  _VehicleOwnerProfilePageState createState() =>
      _VehicleOwnerProfilePageState();
}

class _VehicleOwnerProfilePageState extends State<VehicleOwnerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _contactCtl = TextEditingController();
  final _addressCtl = TextEditingController();
  final _service = VehicleOwnerService();

  int? _userId;
  String? _createdBy;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt("userId");
    _createdBy = prefs.getString("userName") ?? "system";

    if (widget.ownerId == null) return;

    final resp = await _service.getOwnerByUserId(_userId!);
    if (resp['success'] == true && resp['data'] != null) {
      final data = resp['data'];
      setState(() {
        _nameCtl.text = data['name'] ?? "";
        _emailCtl.text = data['email'] ?? "";
        _contactCtl.text = data['contactNumber'] ?? "";
        _addressCtl.text = data['address'] ?? "";
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load profile")),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final req = VehicleOwnerRequest(
      userId: _userId,
      name: _nameCtl.text.trim(),
      email: _emailCtl.text.trim(),
      contactNumber: _contactCtl.text.trim(),
      address: _addressCtl.text.trim(),
      createdBy: _createdBy ?? "system",
    );

    final resp = await _service.updateOwner(widget.ownerId, req);

    if (resp['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: ${resp['message']}")),
      );
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _contactCtl.dispose();
    _addressCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vehicle Owner Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtl,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (v) => v!.isEmpty ? "Enter name" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtl,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (v) => v!.isEmpty ? "Enter email" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactCtl,
                decoration: const InputDecoration(labelText: "Contact Number"),
                validator: (v) => v!.isEmpty ? "Enter contact number" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtl,
                decoration: const InputDecoration(labelText: "Address"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProfile,
                child: const Text("Update Profile"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

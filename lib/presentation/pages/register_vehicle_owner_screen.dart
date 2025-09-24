// lib/screens/register_vehicle_owner_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/vehicle_owner_request.dart';
import '../../services/vehicle_owner_service.dart';

class RegisterVehicleOwnerScreen extends StatefulWidget {
  const RegisterVehicleOwnerScreen({super.key});

  @override
  State<RegisterVehicleOwnerScreen> createState() => _RegisterVehicleOwnerScreenState();
}

class _RegisterVehicleOwnerScreenState extends State<RegisterVehicleOwnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _contactCtl = TextEditingController();
  final _addressCtl = TextEditingController();

  final _service = VehicleOwnerService();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _contactCtl.dispose();
    _addressCtl.dispose();
    super.dispose();
  }

  String? _validateName(String? v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null;
  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter email';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(v.trim()) ? null : 'Enter valid email';
  }

  String? _validateContact(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter contact number';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    return (digits.length >= 7 && digits.length <= 15) ? null : 'Enter valid phone';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? currentUserId = prefs.getInt('userId'); // saved at login
      final String createdBy = prefs.getString('userName') ?? '';

      final req = VehicleOwnerRequest(
        userId: currentUserId, // may be null if not present
        name: _nameCtl.text.trim(),
        email: _emailCtl.text.trim(),
        contactNumber: _contactCtl.text.trim(),
        address: _addressCtl.text.trim(),
        createdBy: createdBy,
      );

      final res = await _service.registerVehicleOwner(req);
      if (res['success'] == true) {
        // server should have sent activation link; show success and go back
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Vehicle owner registered')),
        );
        Navigator.pop(context, true); // return true so dashboard can refresh if needed
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to register')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Vehicle Owner')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtl,
                decoration: const InputDecoration(labelText: 'Owner Name'),
                validator: _validateName,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: _validateEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactCtl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Contact Number'),
                validator: _validateContact,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtl,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading ? const CircularProgressIndicator() : const Text('Register Owner'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/screens/register_driver_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/driver_request.dart';
import '../../services/driver_service.dart';


class RegisterDriverScreen extends StatefulWidget {
  const RegisterDriverScreen({super.key});

  @override
  State<RegisterDriverScreen> createState() => _RegisterDriverScreenState();
}

class _RegisterDriverScreenState extends State<RegisterDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _contactCtl = TextEditingController();
  final _addressCtl = TextEditingController();
  final _emailCtl = TextEditingController();

  String? _photoBase64;
  File? _photoFile;
  bool _submitting = false;

  final DriverService _service = DriverService();
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source, imageQuality: 75);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _photoBase64 = base64Encode(bytes);
      _photoFile = File(picked.path);
    });
  }

  Future<void> _showImageOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
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
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt("userId");
      final String createdBy = prefs.getString("userName") ?? "";

      print("🔍 Driver Registration: userId = $userId");
      print("🔍 Driver Registration: createdBy = $createdBy");
      print("🔍 Driver Registration: driverName = ${_nameCtl.text.trim()}");
      print("🔍 Driver Registration: contactNumber = ${_contactCtl.text.trim()}");

      if (userId == null) throw Exception("User not found in prefs");

      final req = DriverRequest(
        userId: userId,
        driverName: _nameCtl.text.trim(),
        driverContactNumber: _contactCtl.text.trim(),
        driverAddress: _addressCtl.text.trim(),
        driverPhotoBase64: _photoBase64,
        email: _emailCtl.text.trim().isEmpty ? null : _emailCtl.text.trim(),
        createdBy: createdBy,
      );

      print("🔍 Driver Registration: request = $req");

      final res = await _service.createDriver(req);
      print("🔍 Driver Registration: response = $res");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? "Driver created")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print("🔍 Driver Registration: error = $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildText(String label, TextEditingController ctl,
          {String? Function(String?)? validator, TextInputType type = TextInputType.text, String? hintText}) =>
      TextFormField(
        controller: ctl,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
        ),
        validator: validator ?? (v) => v == null || v.isEmpty ? "Required" : null,
        keyboardType: type,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register Driver")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            GestureDetector(
              onTap: _showImageOptions,
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _photoFile != null ? FileImage(_photoFile!) : null,
                child: _photoFile == null ? const Icon(Icons.camera_alt, size: 36) : null,
              ),
            ),
            const SizedBox(height: 12),
            _buildText("Driver Name *", _nameCtl, 
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Driver name is required";
                  if (v.trim().length > 100) return "Driver name cannot exceed 100 characters";
                  return null;
                }),
            const SizedBox(height: 8),
            _buildText("Driver Contact Number *", _contactCtl, 
                type: TextInputType.phone,
                hintText: "10-digit mobile number",
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Contact number is required";
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length != 10) return "Contact number must be exactly 10 digits";
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) return "Enter valid Indian mobile number (starting with 6-9)";
                  return null;
                }),
            const SizedBox(height: 8),
            _buildText("Driver Address *", _addressCtl,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Driver address is required";
                  if (v.trim().length > 255) return "Driver address cannot exceed 255 characters";
                  return null;
                }),
            const SizedBox(height: 8),
            _buildText("Email (Optional)", _emailCtl, 
                type: TextInputType.emailAddress,
                hintText: "driver@example.com",
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null; // Optional field
                  if (v.trim().length > 150) return "Email cannot exceed 150 characters";
                  final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                  return regex.hasMatch(v.trim()) ? null : "Enter valid email address";
                }),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Register Driver"),
            ),
          ]),
        ),
      ),
    );
  }
}

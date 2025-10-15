// lib/screens/register_vehicle_owner_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
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
  final _imagePicker = ImagePicker();
  bool _loading = false;
  File? _selectedImage;

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _contactCtl.dispose();
    _addressCtl.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter owner name';
    if (v.trim().length < 3) return 'Name must be at least 3 characters';
    if (v.trim().length > 150) return 'Name must not exceed 150 characters';
    return null;
  }
  
  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter email address';
    if (v.trim().length > 150) return 'Email must not exceed 150 characters';
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(v.trim()) ? null : 'Enter valid email address';
  }

  String? _validateContact(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter contact number';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return 'Contact number must be 10 digits';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) return 'Enter valid Indian mobile number';
    return null;
  }

  String? _validateAddress(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter address';
    if (v.trim().length < 5) return 'Address must be at least 5 characters';
    if (v.trim().length > 255) return 'Address must not exceed 255 characters';
    return null;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null && image.path.isNotEmpty) {
        final file = File(image.path);
        if (await file.exists()) {
          setState(() {
            _selectedImage = file;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Selected image file not found")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null && image.path.isNotEmpty) {
        final file = File(image.path);
        if (await file.exists()) {
          setState(() {
            _selectedImage = file;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Captured image file not found")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error taking photo: $e")),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Image Source"),
          content: const Text("Choose how you want to select the image"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImage();
              },
              child: const Text("Gallery"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _takePhoto();
              },
              child: const Text("Camera"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String createdBy = prefs.getString('userName') ?? '';

      String? photoBase64;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        photoBase64 = base64Encode(bytes);
      }

      final req = VehicleOwnerRequest(
        name: _nameCtl.text.trim(),
        email: _emailCtl.text.trim(),
        contactNumber: _contactCtl.text.trim(),
        address: _addressCtl.text.trim(),
        createdBy: createdBy,
        ownerPhoto: photoBase64,
      );

      final res = await _service.registerVehicleOwner(req);
      if (res['success'] == true) {
        // server should have sent activation link; show success and go back
        if (!mounted) return;
        _showSuccessDialog(res['message'] ?? 'Vehicle owner registered successfully');
      } else {
        if (!mounted) return;
        // Check if this is an existing owner case
        if (res['data'] != null && res['data']['action'] == 'USE_EXISTING') {
          _showExistingOwnerDialog(res['data']);
        } else {
          _showErrorSnackBar(res['message'] ?? 'Failed to register vehicle owner');
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Registration Successful!"),
        content: Text(
          "$message\n\n"
          "An activation link has been sent to the vehicle owner's email. "
          "They can use this link to complete their registration."
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pop(context, true); // return true so dashboard can refresh
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showExistingOwnerDialog(Map<String, dynamic> existingOwnerData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Vehicle Owner Already Exists"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("A vehicle owner with this email/contact already exists:"),
            const SizedBox(height: 12),
            Text("Name: ${existingOwnerData['existingOwnerName']}"),
            Text("Email: ${existingOwnerData['existingOwnerEmail']}"),
            Text("Contact: ${existingOwnerData['existingOwnerContact']}"),
            const SizedBox(height: 12),
            const Text("Would you like to associate this existing owner with your school?"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pop(context, false); // Don't refresh dashboard
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _associateExistingOwner(existingOwnerData);
            },
            child: const Text("Associate with School"),
          ),
        ],
      ),
    );
  }

  Future<void> _associateExistingOwner(Map<String, dynamic> existingOwnerData) async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? schoolId = prefs.getInt('schoolId');
      final String createdBy = prefs.getString('userName') ?? '';

      if (schoolId == null) {
        throw Exception("School not found in preferences");
      }

      final ownerId = existingOwnerData['existingOwnerId'];
      final res = await _service.associateOwnerWithSchool(ownerId, schoolId, createdBy);
      
      if (res['success'] == true) {
        if (!mounted) return;
        _showSuccessDialog(res['message'] ?? 'Vehicle owner associated with school successfully');
      } else {
        if (!mounted) return;
        _showErrorSnackBar(res['message'] ?? 'Failed to associate vehicle owner with school');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
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
                decoration: const InputDecoration(
                  labelText: 'Owner Name',
                  hintText: 'Enter full name',
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter email address',
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactCtl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  hintText: 'Enter 10-digit mobile number',
                ),
                validator: _validateContact,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtl,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter complete address',
                ),
                maxLines: 3,
                validator: _validateAddress,
              ),
              const SizedBox(height: 20),
              
              // Photo Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        "Owner Photo (Optional)",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blueGrey,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!) as ImageProvider<Object>?
                            : null,
                        child: _selectedImage == null
                            ? const Icon(Icons.person, color: Colors.white, size: 50)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showImageSourceDialog,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Add Photo"),
                      ),
                      if (_selectedImage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          "Photo selected: ${_selectedImage!.path.split('/').last}",
                          style: const TextStyle(fontSize: 12, color: Colors.green),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                          child: const Text("Remove Photo"),
                        ),
                      ],
                    ],
                  ),
                ),
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

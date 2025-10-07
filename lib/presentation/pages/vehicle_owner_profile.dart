import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
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
  final _imagePicker = ImagePicker();

  int? _userId;
  String? _createdBy;
  String? _ownerPhoto;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt("userId");
    _createdBy = prefs.getString("userName") ?? "system";

    // Load owner data

    final resp = await _service.getOwnerByUserId(_userId!);
    if (resp['success'] == true && resp['data'] != null) {
      final data = resp['data'];
      setState(() {
        _nameCtl.text = data['name'] ?? "";
        _emailCtl.text = data['email'] ?? "";
        _contactCtl.text = data['contactNumber'] ?? "";
        _addressCtl.text = data['address'] ?? "";
        _ownerPhoto = data['ownerPhoto'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load profile")),
      );
    }
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

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

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
      createdBy: _createdBy ?? "system",
      ownerPhoto: photoBase64,
    );

    final resp = await _service.updateOwner(widget.ownerId, req);

    if (resp['success'] == true) {
      setState(() {
        if (photoBase64 != null) {
          _ownerPhoto = photoBase64;
        }
        _selectedImage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: ${resp['message']}")),
      );
    }
  }

  MemoryImage? _getMemoryImage(String base64String) {
    try {
      return MemoryImage(base64Decode(base64String));
    } catch (e) {
      print('Error decoding base64 image: $e');
      return null;
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
              // Photo Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        "Owner Photo",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blueGrey,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!) as ImageProvider<Object>?
                            : (_ownerPhoto != null && _ownerPhoto!.isNotEmpty
                                ? _getMemoryImage(_ownerPhoto!) as ImageProvider<Object>?
                                : null),
                        child: (_selectedImage == null && (_ownerPhoto == null || _ownerPhoto!.isEmpty))
                            ? const Icon(Icons.person, color: Colors.white, size: 50)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showImageSourceDialog,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Change Photo"),
                      ),
                      if (_selectedImage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          "New photo selected",
                          style: TextStyle(color: Colors.green[600], fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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

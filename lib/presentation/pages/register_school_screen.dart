import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/school_request.dart';
import '../../services/school_service.dart';

class RegisterSchoolScreen extends StatefulWidget {
  const RegisterSchoolScreen({super.key});

  @override
  State<RegisterSchoolScreen> createState() => _RegisterSchoolScreenState();
}

class _RegisterSchoolScreenState extends State<RegisterSchoolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = SchoolService();

  // Controllers
  final TextEditingController _schoolName = TextEditingController();
  final TextEditingController _registrationNumber = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _district = TextEditingController();
  final TextEditingController _state = TextEditingController();
  final TextEditingController _pincode = TextEditingController();
  final TextEditingController _contactNo = TextEditingController();
  final TextEditingController _email = TextEditingController();

  // Dropdown values
  String? _schoolType;
  String? _affiliationBoard;

  // Image
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    String? base64Photo;
    if (_selectedImage != null) {
      base64Photo = base64Encode(await _selectedImage!.readAsBytes());
    }

    final request = SchoolRequest(
      schoolName: _schoolName.text,
      schoolType: _schoolType!,
      affiliationBoard: _affiliationBoard!,
      registrationNumber: _registrationNumber.text,
      address: _address.text,
      city: _city.text,
      district: _district.text,
      state: _state.text,
      pincode: int.parse(_pincode.text),
      contactNo: _contactNo.text,
      email: _email.text,
      schoolPhoto: base64Photo,
      createdBy: "SYSTEM",
    );

    try {
      final response = await _service.registerSchool(request);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response["message"] ?? "Registration successful")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("School Registration")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ---------- Form Fields ----------
              TextFormField(
                controller: _schoolName,
                decoration: const InputDecoration(labelText: "School Name"),
                validator: (v) => v!.isEmpty ? "Enter school name" : null,
              ),

              DropdownButtonFormField<String>(
                value: _schoolType,
                items: ["Private", "Government", "International"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _schoolType = val),
                decoration: const InputDecoration(labelText: "School Type"),
                validator: (v) => v == null ? "Select school type" : null,
              ),

              DropdownButtonFormField<String>(
                value: _affiliationBoard,
                items: ["CBSE", "ICSE", "State Board"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _affiliationBoard = val),
                decoration: const InputDecoration(labelText: "Affiliation Board"),
                validator: (v) => v == null ? "Select affiliation board" : null,
              ),

              TextFormField(
                controller: _registrationNumber,
                decoration: const InputDecoration(labelText: "Registration Number"),
                validator: (v) => v!.isEmpty ? "Enter registration number" : null,
              ),

              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: "Address"),
                validator: (v) => v!.isEmpty ? "Enter address" : null,
              ),

              TextFormField(
                controller: _city,
                decoration: const InputDecoration(labelText: "City"),
                validator: (v) => v!.isEmpty ? "Enter city" : null,
              ),

              TextFormField(
                controller: _district,
                decoration: const InputDecoration(labelText: "District"),
                validator: (v) => v!.isEmpty ? "Enter district" : null,
              ),

              TextFormField(
                controller: _state,
                decoration: const InputDecoration(labelText: "State"),
                validator: (v) => v!.isEmpty ? "Enter state" : null,
              ),

              TextFormField(
                controller: _pincode,
                decoration: const InputDecoration(labelText: "Pincode"),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Enter pincode" : null,
              ),

              TextFormField(
                controller: _contactNo,
                decoration: const InputDecoration(labelText: "Contact Number"),
                validator: (v) => v!.isEmpty ? "Enter contact number" : null,
              ),

              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Enter email";
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                    return "Invalid email";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ---------- Photo Section (Bottom) ----------
              Column(
                children: [
                  GestureDetector(
                    onTap: () => _pickImage(ImageSource.gallery),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage:
                          _selectedImage != null ? FileImage(_selectedImage!) : null,
                      child: _selectedImage == null
                          ? const Icon(Icons.add_a_photo,
                              size: 40, color: Colors.black54)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo),
                        label: const Text("Gallery"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Camera"),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ---------- Submit ----------
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text("Register School"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

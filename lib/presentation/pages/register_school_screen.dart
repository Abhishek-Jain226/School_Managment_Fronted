import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../app_routes.dart';
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
  bool _isLoading = false;
  bool _isSubmitted = false;

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

    setState(() => _isLoading = true);

    try {
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
        pincode: _pincode.text,
        contactNo: _contactNo.text,
        email: _email.text,
        schoolPhoto: base64Photo,
        createdBy: "SYSTEM",
      );

      final response = await _service.registerSchool(request);
      
      if (mounted) {
        if (response["success"] == true) {
          setState(() => _isSubmitted = true);
          _showSuccessDialog();
        } else {
          _showErrorSnackBar(response["message"] ?? "Registration failed");
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar("Error: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Registration Successful!"),
        content: const Text(
          "Your school has been registered successfully. "
          "Please check your email for the activation link. "
          "The link is valid for 24 hours."
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacementNamed(AppRoutes.login);
            },
            child: const Text("Go to Login"),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
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
                decoration: const InputDecoration(
                  labelText: "School Name",
                  hintText: "Enter school name",
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Enter school name";
                  if (v.length < 2) return "School name must be at least 2 characters";
                  if (v.length > 200) return "School name must not exceed 200 characters";
                  return null;
                },
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
                decoration: const InputDecoration(
                  labelText: "Registration Number",
                  hintText: "Enter school registration number",
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Enter registration number";
                  if (v.length < 3) return "Registration number must be at least 3 characters";
                  if (v.length > 100) return "Registration number must not exceed 100 characters";
                  return null;
                },
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
                decoration: const InputDecoration(
                  labelText: "Pincode",
                  hintText: "Enter 6-digit pincode",
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Enter pincode";
                  if (v.length != 6) return "Pincode must be 6 digits";
                  if (!RegExp(r'^[0-9]{6}$').hasMatch(v)) return "Pincode must contain only numbers";
                  return null;
                },
              ),

              TextFormField(
                controller: _contactNo,
                decoration: const InputDecoration(
                  labelText: "Contact Number",
                  hintText: "Enter 10-digit mobile number",
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Enter contact number";
                  if (v.length != 10) return "Contact number must be 10 digits";
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(v)) return "Contact number must contain only numbers";
                  return null;
                },
              ),

              TextFormField(
                controller: _email,
                decoration: const InputDecoration(
                  labelText: "Email",
                  hintText: "Enter school email address",
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Enter email";
                  if (v.length > 150) return "Email must not exceed 150 characters";
                  if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(v)) {
                    return "Please enter a valid email address";
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text("Registering..."),
                          ],
                        )
                      : const Text("Register School"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

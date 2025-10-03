// lib/screens/register_student_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/student_request.dart';
import '../../services/student_service.dart';

class RegisterStudentScreen extends StatefulWidget {
  const RegisterStudentScreen({super.key});

  @override
  State<RegisterStudentScreen> createState() => _RegisterStudentScreenState();
}

class _RegisterStudentScreenState extends State<RegisterStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  // controllers
  final _firstCtl = TextEditingController();
  final _middleCtl = TextEditingController();
  final _lastCtl = TextEditingController();
  final _motherCtl = TextEditingController();
  final _fatherCtl = TextEditingController();
  final _primaryContactCtl = TextEditingController();
  final _altContactCtl = TextEditingController();
  final _emailCtl = TextEditingController();

  // dropdown selections
  String _gender = 'Male';
  String _className = 'Nursery';
  String _section = 'A';
  String _relation = 'FATHER'; // ✅ new

  // image
  String? _photoBase64;
  File? _photoFile;

  bool _submitting = false;

  final StudentService _service = StudentService();
  final ImagePicker _picker = ImagePicker();

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _classes = [
    'Nursery', 'KG', '1', '2', '3', '4', '5', '6',
    '7', '8', '9', '10', '11', '12'
  ];
  final List<String> _sections = ['A', 'B', 'C', 'D'];

  // ✅ relation dropdown
  final List<String> _relations = ['FATHER', 'MOTHER', 'GUARDIAN'];

  @override
  void dispose() {
    _firstCtl.dispose();
    _middleCtl.dispose();
    _lastCtl.dispose();
    _motherCtl.dispose();
    _fatherCtl.dispose();
    _primaryContactCtl.dispose();
    _altContactCtl.dispose();
    _emailCtl.dispose();
    super.dispose();
  }

  String? _validateRequired(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return 'Contact number must be 10 digits';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) return 'Enter valid Indian mobile number';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (v.trim().length > 150) return 'Email must not exceed 150 characters';
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(v.trim()) ? null : 'Enter valid email address';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked =
          await _picker.pickImage(source: source, imageQuality: 75);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _photoBase64 = base64Encode(bytes);
        _photoFile = File(picked.path);
      });
    } catch (e) {
      debugPrint("Image pick error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Image pick error: $e")));
    }
  }

  Future<void> _showImageOptions() async {
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
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? schoolId = prefs.getInt('schoolId');
      final String createdBy = prefs.getString('userName') ?? '';

      if (schoolId == null) {
        throw Exception("School not found in preferences");
      }

      final req = StudentRequest(
        firstName: _firstCtl.text.trim(),
        middleName: _middleCtl.text.trim(),
        lastName: _lastCtl.text.trim(),
        gender: _gender,
        className: _className,
        section: _section,
        studentPhotoBase64: _photoBase64,
        schoolId: schoolId,
        motherName: _motherCtl.text.trim(),
        fatherName: _fatherCtl.text.trim(),
        primaryContactNumber: _primaryContactCtl.text.trim(),
        alternateContactNumber: _altContactCtl.text.trim(),
        email: _emailCtl.text.trim(),
        relation: _relation, // ✅ added
        createdBy: createdBy,
      );

      final res = await _service.createStudent(req);

      if (res['success'] == true) {
        if (!mounted) return;
        _showSuccessDialog(res['message'] ?? 'Student registered successfully');
      } else {
        if (!mounted) return;
        _showErrorSnackBar(res['message'] ?? 'Failed to register student');
      }
    } catch (e) {
      debugPrint("Submit error: $e");
      if (mounted) {
        _showErrorSnackBar("Error: $e");
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
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
          "A parent activation link has been sent to the provided email address. "
          "The parent can use this link to complete their registration and access the parent dashboard."
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildText(String label, TextEditingController ctl,
          {String? Function(String?)? validator,
          TextInputType keyboardType = TextInputType.text}) =>
      TextFormField(
        controller: ctl,
        decoration: InputDecoration(labelText: label),
        validator: validator ?? _validateRequired,
        keyboardType: keyboardType,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register Student")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Photo
              GestureDetector(
                onTap: _showImageOptions,
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      _photoFile != null ? FileImage(_photoFile!) : null,
                  child:
                      _photoFile == null ? const Icon(Icons.camera_alt, size: 36) : null,
                ),
              ),
              const SizedBox(height: 12),

              _buildText('First Name', _firstCtl),
              const SizedBox(height: 8),
              _buildText('Middle Name', _middleCtl, validator: (v) => null),
              const SizedBox(height: 8),
              _buildText('Last Name', _lastCtl),
              const SizedBox(height: 8),

              // gender + class + section row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: _genders
                          .map((g) =>
                              DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) => setState(() => _gender = v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _className,
                      decoration: const InputDecoration(labelText: 'Class'),
                      items: _classes
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _className = v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _section,
                      decoration: const InputDecoration(labelText: 'Section'),
                      items: _sections
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _section = v!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              _buildText('Mother Name', _motherCtl),
              const SizedBox(height: 8),
              _buildText('Father Name', _fatherCtl),
              const SizedBox(height: 8),
              TextFormField(
                controller: _primaryContactCtl,
                decoration: const InputDecoration(
                  labelText: 'Primary Contact',
                  hintText: 'Enter 10-digit mobile number',
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: _validatePhone,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _altContactCtl,
                decoration: const InputDecoration(
                  labelText: 'Alternate Contact',
                  hintText: 'Enter 10-digit mobile number (optional)',
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null; // Optional field
                  return _validatePhone(v);
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtl,
                decoration: const InputDecoration(
                  labelText: 'Email (parent contact email)',
                  hintText: 'Enter parent email address (optional)',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),

              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _relation,
                decoration: const InputDecoration(labelText: 'Relation'),
                items: _relations
                    .map((r) =>
                        DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _relation = v!),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Register Student'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

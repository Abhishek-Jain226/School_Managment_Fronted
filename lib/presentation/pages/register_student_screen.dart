// lib/screens/register_student_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/student_request.dart';
import '../../data/models/class_master.dart';
import '../../data/models/section_master.dart';
import '../../services/student_service.dart';
import '../../services/master_data_service.dart';

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
  ClassMaster? _selectedClass;
  SectionMaster? _selectedSection;
  String _relation = 'GUARDIAN'; // Hidden field with default value

  // image
  String? _photoBase64;
  File? _photoFile;

  bool _submitting = false;

  final StudentService _service = StudentService();
  final MasterDataService _masterDataService = MasterDataService();
  final ImagePicker _picker = ImagePicker();

  final List<String> _genders = ['Male', 'Female', 'Other'];
  List<ClassMaster> _classes = []; // Will be loaded from API
  List<SectionMaster> _sections = []; // Will be loaded from API

  // Removed _relations list as relationship dropdown is not needed

  @override
  void initState() {
    super.initState();
    _loadMasterData();
  }

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

  Future<void> _loadMasterData() async {
    try {
      debugPrint('Loading master data...');
      
      // Get school ID from preferences
      final prefs = await SharedPreferences.getInstance();
      final int? schoolId = prefs.getInt('schoolId');
      
      if (schoolId == null) {
        debugPrint('School ID not found in preferences');
        return;
      }
      
      // Load classes for this school
      final classesResponse = await _masterDataService.getAllActiveClasses(schoolId);
      debugPrint('Classes response: $classesResponse');
      
      if (classesResponse['success'] == true && classesResponse['data'] != null) {
        setState(() {
          _classes = (classesResponse['data'] as List)
              .map((json) => ClassMaster.fromJson(json))
              .toList();
          debugPrint('Loaded ${_classes.length} classes');
          // Set default selection to first class
          if (_classes.isNotEmpty && _selectedClass == null) {
            _selectedClass = _classes.first;
            debugPrint('Set default class: ${_selectedClass?.className}');
          }
        });
      } else {
        debugPrint('Failed to load classes: ${classesResponse['message']}');
      }

      // Load sections for this school
      final sectionsResponse = await _masterDataService.getAllActiveSections(schoolId);
      debugPrint('Sections response: $sectionsResponse');
      
      if (sectionsResponse['success'] == true && sectionsResponse['data'] != null) {
        setState(() {
          _sections = (sectionsResponse['data'] as List)
              .map((json) => SectionMaster.fromJson(json))
              .toList();
          debugPrint('Loaded ${_sections.length} sections');
          // Set default selection to first section
          if (_sections.isNotEmpty && _selectedSection == null) {
            _selectedSection = _sections.first;
            debugPrint('Set default section: ${_selectedSection?.sectionName}');
          }
        });
      } else {
        debugPrint('Failed to load sections: ${sectionsResponse['message']}');
      }
    } catch (e) {
      debugPrint('Error loading master data: $e');
    }
  }


  String? _validateRequired(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Name is required';
    if (v.trim().length < 2) return 'Name must be at least 2 characters';
    if (v.trim().length > 50) return 'Name must not exceed 50 characters';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v.trim())) return 'Name can only contain letters and spaces';
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Contact number is required';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return 'Contact number must be exactly 10 digits';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) return 'Enter valid Indian mobile number (starting with 6-9)';
    return null;
  }

  String? _validateOptionalPhone(String? v) {
    if (v == null || v.trim().isEmpty) return null; // Optional field
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return 'Contact number must be exactly 10 digits';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) return 'Enter valid Indian mobile number (starting with 6-9)';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
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

      if (_selectedClass == null) {
        throw Exception("Please select a class");
      }

      if (_selectedSection == null) {
        throw Exception("Please select a section");
      }

      final req = StudentRequest(
        firstName: _firstCtl.text.trim(),
        middleName: _middleCtl.text.trim().isEmpty ? null : _middleCtl.text.trim(),
        lastName: _lastCtl.text.trim(),
        gender: _gender,
        classId: _selectedClass?.classId ?? 0,
        sectionId: _selectedSection?.sectionId ?? 0,
        studentPhotoBase64: _photoBase64?.isEmpty == true ? null : _photoBase64,
        schoolId: schoolId,
        motherName: _motherCtl.text.trim(),
        fatherName: _fatherCtl.text.trim(),
        primaryContactNumber: _primaryContactCtl.text.trim(),
        alternateContactNumber: _altContactCtl.text.trim().isEmpty ? null : _altContactCtl.text.trim(),
        email: _emailCtl.text.trim(),
        relation: _relation, // Hidden field with default value 'GUARDIAN'
        createdBy: createdBy,
      );

      final res = await _service.createStudent(req);

      if (res['success'] == true) {
        if (!mounted) return;
        _showSuccessDialog(res['message'] ?? 'Student registered successfully');
        _resetForm(); // Clear form after successful registration
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

              _buildText('First Name *', _firstCtl, validator: _validateName),
              const SizedBox(height: 8),
              _buildText('Middle Name (Optional)', _middleCtl, validator: (v) {
                if (v == null || v.trim().isEmpty) return null; // Optional field
                if (v.trim().length > 50) return 'Name must not exceed 50 characters';
                if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v.trim())) return 'Name can only contain letters and spaces';
                return null;
              }),
              const SizedBox(height: 8),
              _buildText('Last Name *', _lastCtl, validator: _validateName),
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
                    child: DropdownButtonFormField<ClassMaster>(
                      value: _selectedClass,
                      decoration: const InputDecoration(labelText: 'Class'),
                      items: _classes
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c.className)))
                          .toList(),
                      onChanged: (v) {
                        debugPrint('Class changed to: ${v?.className}');
                        setState(() => _selectedClass = v!);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a class';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<SectionMaster>(
                      value: _selectedSection,
                      decoration: const InputDecoration(labelText: 'Section'),
                      items: _sections
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s.sectionName)))
                          .toList(),
                      onChanged: (v) {
                        debugPrint('Section changed to: ${v?.sectionName}');
                        setState(() => _selectedSection = v!);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a section';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              _buildText('Mother Name *', _motherCtl, validator: _validateName),
              const SizedBox(height: 8),
              _buildText('Father Name *', _fatherCtl, validator: _validateName),
              const SizedBox(height: 8),
              TextFormField(
                controller: _primaryContactCtl,
                decoration: const InputDecoration(
                  labelText: 'Primary Contact *',
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
                  labelText: 'Alternate Contact (Optional)',
                  hintText: 'Enter 10-digit mobile number',
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: _validateOptionalPhone,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtl,
                decoration: const InputDecoration(
                  labelText: 'Email (Parent Contact Email) *',
                  hintText: 'Enter parent email address',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
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

  void _resetForm() {
    _firstCtl.clear();
    _middleCtl.clear();
    _lastCtl.clear();
    _motherCtl.clear();
    _fatherCtl.clear();
    _primaryContactCtl.clear();
    _altContactCtl.clear();
    _emailCtl.clear();
    setState(() {
      _gender = 'Male';
      _selectedClass = _classes.isNotEmpty ? _classes.first : null;
      _selectedSection = _sections.isNotEmpty ? _sections.first : null;
      _relation = 'GUARDIAN'; // Reset to default value
      _photoBase64 = null;
      _photoFile = null;
    });
  }
}

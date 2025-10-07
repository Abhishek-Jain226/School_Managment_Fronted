import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/parent_service.dart';

class StudentProfilePage extends StatefulWidget {
  final int studentId; // ✅ StudentId pass from dashboard

  const StudentProfilePage({Key? key, required this.studentId}) : super(key: key);

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtl = TextEditingController();
  final _lastNameCtl = TextEditingController();
  final _classCtl = TextEditingController();
  final _sectionCtl = TextEditingController();
  final _fatherCtl = TextEditingController();
  final _motherCtl = TextEditingController();
  final _contactCtl = TextEditingController();
  final _altContactCtl = TextEditingController();
  final _emailCtl = TextEditingController();

  final _service = ParentService();
  final _imagePicker = ImagePicker();
  bool _loading = true;
  String? _studentPhoto; // Student photo base64 string
  File? _selectedImage; // Selected image file

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  Future<void> _loadStudent() async {
    try {
      final resp = await _service.getStudentById(widget.studentId);
      if (resp['success'] == true && resp['data'] != null) {
        final data = resp['data'];
        setState(() {
          _firstNameCtl.text = data['firstName'] ?? "";
          _lastNameCtl.text = data['lastName'] ?? "";
          _classCtl.text = data['className'] ?? "";
          _sectionCtl.text = data['sectionName'] ?? "";
          _fatherCtl.text = data['fatherName'] ?? "";
          _motherCtl.text = data['motherName'] ?? "";
          _contactCtl.text = data['primaryContactNumber'] ?? "";
          _altContactCtl.text = data['alternateContactNumber'] ?? "";
          _emailCtl.text = data['email'] ?? "";
          _studentPhoto = data['studentPhoto']; // Load student photo
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${resp['message']}")),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
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

  Future<void> _updateStudent() async {
    if (!_formKey.currentState!.validate()) return;

    String? photoBase64;
    if (_selectedImage != null) {
      final bytes = await _selectedImage!.readAsBytes();
      photoBase64 = base64Encode(bytes);
    }

    final req = {
      "studentId": widget.studentId,
      "firstName": _firstNameCtl.text.trim(),
      "lastName": _lastNameCtl.text.trim(),
      "className": _classCtl.text.trim(),
      "section": _sectionCtl.text.trim(),
      "fatherName": _fatherCtl.text.trim(),
      "motherName": _motherCtl.text.trim(),
      "primaryContactNumber": _contactCtl.text.trim(),
      "alternateContactNumber": _altContactCtl.text.trim(),
      "email": _emailCtl.text.trim(),
      if (photoBase64 != null) "studentPhoto": photoBase64,
      "updatedBy": "ParentApp"
    };

    final resp = await _service.updateStudent(widget.studentId, req);

    if (resp['success'] == true) {
      setState(() {
        if (photoBase64 != null) {
          _studentPhoto = photoBase64;
        }
        _selectedImage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Student updated successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Update failed: ${resp['message']}")),
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
    _firstNameCtl.dispose();
    _lastNameCtl.dispose();
    _classCtl.dispose();
    _sectionCtl.dispose();
    _fatherCtl.dispose();
    _motherCtl.dispose();
    _contactCtl.dispose();
    _altContactCtl.dispose();
    _emailCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Profile"),
        actions: [
          // Student Photo in top-right corner (clickable)
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: _showImageSourceDialog,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blueGrey,
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!) as ImageProvider<Object>?
                    : (_studentPhoto != null && _studentPhoto!.isNotEmpty
                        ? _getMemoryImage(_studentPhoto!) as ImageProvider<Object>?
                        : null),
                child: (_selectedImage == null && (_studentPhoto == null || _studentPhoto!.isEmpty))
                    ? const Icon(Icons.person, color: Colors.white, size: 20)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                              "Student Photo",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.blueGrey,
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!) as ImageProvider<Object>?
                                  : (_studentPhoto != null && _studentPhoto!.isNotEmpty
                                      ? _getMemoryImage(_studentPhoto!) as ImageProvider<Object>?
                                      : null),
                              child: (_selectedImage == null && (_studentPhoto == null || _studentPhoto!.isEmpty))
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
                      controller: _firstNameCtl,
                      decoration: const InputDecoration(labelText: "First Name"),
                      validator: (v) => v!.isEmpty ? "Enter first name" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lastNameCtl,
                      decoration: const InputDecoration(labelText: "Last Name"),
                      validator: (v) => v!.isEmpty ? "Enter last name" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _classCtl,
                      decoration: const InputDecoration(labelText: "Class"),
                      validator: (v) => v!.isEmpty ? "Enter class" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sectionCtl,
                      decoration: const InputDecoration(labelText: "Section"),
                      validator: (v) => v!.isEmpty ? "Enter section" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fatherCtl,
                      decoration: const InputDecoration(labelText: "Father Name"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _motherCtl,
                      decoration: const InputDecoration(labelText: "Mother Name"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contactCtl,
                      decoration: const InputDecoration(labelText: "Primary Contact"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _altContactCtl,
                      decoration: const InputDecoration(labelText: "Alternate Contact"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtl,
                      decoration: const InputDecoration(labelText: "Email"),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateStudent,
                      child: const Text("Update Profile"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

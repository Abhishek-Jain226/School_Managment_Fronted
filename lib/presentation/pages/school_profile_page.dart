import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_config.dart';

class SchoolProfilePage extends StatefulWidget {
  const SchoolProfilePage({super.key});

  @override
  State<SchoolProfilePage> createState() => _SchoolProfilePageState();
}

class _SchoolProfilePageState extends State<SchoolProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isUpdating = false;

  int? schoolId;
  String schoolName = '';
  String schoolType = '';
  String affiliationBoard = '';
  String contactNo = '';
  String email = '';
  String address = '';
  String? schoolPhoto;
  File? _selectedImage;
  final _imagePicker = ImagePicker();

  // 🔹 Using centralized configuration
  String get baseUrl => AppConfig.schoolsUrl;

  @override
  void initState() {
    super.initState();
    _loadSchoolProfile();
  }

  Future<void> _loadSchoolProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt("schoolId");
    if (id == null) return;

    final url = Uri.parse("$baseUrl/$id");
    final resp = await http.get(url);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final school = data["data"];
      setState(() {
        schoolId = school["schoolId"];
        schoolName = school["schoolName"] ?? '';
        schoolType = school["schoolType"] ?? '';
        affiliationBoard = school["affiliationBoard"] ?? '';
        contactNo = school["contactNo"] ?? '';
        email = school["email"] ?? '';
        address = school["address"] ?? '';
        schoolPhoto = school["schoolPhoto"];
        _isLoading = false;
      });
      
      // Save school photo to SharedPreferences for dashboard display
      if (schoolPhoto != null && schoolPhoto!.isNotEmpty) {
        await prefs.setString("schoolPhoto", schoolPhoto!);
      }
    }
  }

  Future<void> _updateSchoolProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    String? photoBase64;
    if (_selectedImage != null) {
      final bytes = await _selectedImage!.readAsBytes();
      photoBase64 = base64Encode(bytes);
    }

    final url = Uri.parse("$baseUrl/$schoolId");
    final body = jsonEncode({
      "schoolName": schoolName,
      "schoolType": schoolType,
      "affiliationBoard": affiliationBoard,
      "contactNo": contactNo,
      "email": email,
      "address": address,
      if (photoBase64 != null) "schoolPhoto": photoBase64,
    });

    final resp = await http.put(url,
        headers: {"Content-Type": "application/json"}, body: body);

    setState(() => _isUpdating = false);

    if (resp.statusCode == 200) {
      setState(() {
        if (photoBase64 != null) {
          schoolPhoto = photoBase64;
        }
        _selectedImage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("School updated successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: ${resp.body}")),
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

  MemoryImage? _getMemoryImage(String base64String) {
    try {
      return MemoryImage(base64Decode(base64String));
    } catch (e) {
      print('Error decoding base64 image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("School Profile")),
      body: _isLoading
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
                              "School Photo",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.blueGrey,
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!) as ImageProvider<Object>?
                                  : (schoolPhoto != null && schoolPhoto!.isNotEmpty
                                      ? _getMemoryImage(schoolPhoto!) as ImageProvider<Object>?
                                      : null),
                              child: (_selectedImage == null && (schoolPhoto == null || schoolPhoto!.isEmpty))
                                  ? const Icon(Icons.school, color: Colors.white, size: 50)
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
                      initialValue: schoolName,
                      decoration: const InputDecoration(labelText: "School Name"),
                      onChanged: (v) => schoolName = v,
                      validator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                    ),
                    TextFormField(
                      initialValue: schoolType,
                      decoration: const InputDecoration(labelText: "School Type"),
                      onChanged: (v) => schoolType = v,
                    ),
                    TextFormField(
                      initialValue: affiliationBoard,
                      decoration:
                          const InputDecoration(labelText: "Affiliation Board"),
                      onChanged: (v) => affiliationBoard = v,
                    ),
                    TextFormField(
                      initialValue: contactNo,
                      decoration:
                          const InputDecoration(labelText: "Contact No"),
                      onChanged: (v) => contactNo = v,
                    ),
                    TextFormField(
                      initialValue: email,
                      decoration: const InputDecoration(labelText: "Email"),
                      onChanged: (v) => email = v,
                    ),
                    TextFormField(
                      initialValue: address,
                      decoration: const InputDecoration(labelText: "Address"),
                      onChanged: (v) => address = v,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isUpdating ? null : _updateSchoolProfile,
                      child: _isUpdating
                          ? const CircularProgressIndicator()
                          : const Text("Update"),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}

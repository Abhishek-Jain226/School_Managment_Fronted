import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_config.dart';
import '../../utils/constants.dart';


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

    final token = prefs.getString("jwt_token");
    final url = Uri.parse("$baseUrl/$id");
    final resp = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );
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

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token");
    
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

    final resp = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: body,
    );

    setState(() => _isUpdating = false);

    if (resp.statusCode == 200) {
      setState(() {
        if (photoBase64 != null) {
          schoolPhoto = photoBase64;
        }
        _selectedImage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.msgSchoolUpdated)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppConstants.msgUpdateFailed}: '+resp.body)),
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
            const SnackBar(content: Text(AppConstants.msgSelectedImageFileNotFound)),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppConstants.msgErrorPickingImage}$e')),
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
            const SnackBar(content: Text(AppConstants.msgCapturedImageFileNotFound)),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppConstants.msgErrorTakingPhoto}$e')),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(AppConstants.dialogTitleSelectImageSource),
          content: const Text(AppConstants.dialogContentChooseImage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImage();
              },
              child: const Text(AppConstants.labelGallery),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _takePhoto();
              },
              child: const Text(AppConstants.labelCamera),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppConstants.actionCancel),
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
      debugPrint('Error decoding base64 image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.labelSchoolProfile)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMD),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Photo Section
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.paddingMD),
                        child: Column(
                          children: [
                            const Text(
                              AppConstants.labelSchoolPhoto,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: AppSizes.marginMD),
                            CircleAvatar(
                              radius: AppSizes.radiusXL, // 20.0; avatar looks balanced with XL
                              backgroundColor: AppColors.primaryLight,
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!) as ImageProvider<Object>?
                                  : (schoolPhoto != null && schoolPhoto!.isNotEmpty
                                      ? _getMemoryImage(schoolPhoto!) as ImageProvider<Object>?
                                      : null),
                              child: (_selectedImage == null && (schoolPhoto == null || schoolPhoto!.isEmpty))
                                  ? const Icon(Icons.school, color: AppColors.textWhite, size: AppSizes.iconXL)
                                  : null,
                            ),
                            const SizedBox(height: AppSizes.marginMD),
                            ElevatedButton.icon(
                              onPressed: _showImageSourceDialog,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text(AppConstants.labelChangePhoto),
                            ),
                            if (_selectedImage != null) ...[
                              const SizedBox(height: AppSizes.marginSM),
                              const Text(
                                AppConstants.labelNewPhotoSelected,
                                style: TextStyle(color: AppColors.successColor, fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.marginMD),
                    TextFormField(
                      initialValue: schoolName,
                      decoration: const InputDecoration(labelText: AppConstants.labelSchoolName),
                      onChanged: (v) => schoolName = v,
                      validator: (v) => v == null || v.isEmpty ? AppConstants.labelRequired : null,
                    ),
                    TextFormField(
                      initialValue: schoolType,
                      decoration: const InputDecoration(labelText: AppConstants.labelSchoolType),
                      onChanged: (v) => schoolType = v,
                    ),
                    TextFormField(
                      initialValue: affiliationBoard,
                      decoration: const InputDecoration(labelText: AppConstants.labelAffiliationBoard),
                      onChanged: (v) => affiliationBoard = v,
                    ),
                    TextFormField(
                      initialValue: contactNo,
                      decoration: const InputDecoration(labelText: AppConstants.labelContactNo),
                      onChanged: (v) => contactNo = v,
                    ),
                    TextFormField(
                      initialValue: email,
                      decoration: const InputDecoration(labelText: AppConstants.labelSchoolEmail),
                      onChanged: (v) => email = v,
                    ),
                    TextFormField(
                      initialValue: address,
                      decoration: const InputDecoration(labelText: AppConstants.labelSchoolAddress),
                      onChanged: (v) => address = v,
                    ),
                    const SizedBox(height: AppSizes.marginLG),
                    ElevatedButton(
                      onPressed: _isUpdating ? null : _updateSchoolProfile,
                      child: _isUpdating
                          ? const CircularProgressIndicator()
                          : const Text(AppConstants.actionUpdate),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}

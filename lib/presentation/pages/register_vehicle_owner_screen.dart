// lib/screens/register_vehicle_owner_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/constants.dart';
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
    if (v == null || v.trim().isEmpty) return AppConstants.msgEnterOwnerName;
    if (v.trim().length < 3) return AppConstants.msgOwnerNameMin3;
    if (v.trim().length > 150) return AppConstants.msgOwnerNameMax150;
    return null;
  }
  
  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return AppConstants.msgEnterEmailAddressGeneric;
    if (v.trim().length > AppConstants.registerOwnerEmailMaxLength) return AppConstants.msgEmailMax150Generic;
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(v.trim()) ? null : AppConstants.msgEnterValidEmailGeneric;
  }

  String? _validateContact(String? v) {
    if (v == null || v.trim().isEmpty) return AppConstants.msgEnterContactNumberGeneric;
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length != AppConstants.registerOwnerContactLength) return AppConstants.msgContactNumberMustBe10DigitsGeneric;
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) return AppConstants.msgEnterValidIndianMobileGeneric;
    return null;
  }

  String? _validateAddress(String? v) {
    if (v == null || v.trim().isEmpty) return AppConstants.msgEnterAddressGeneric;
    if (v.trim().length < 5) return AppConstants.msgAddressMin5;
    if (v.trim().length > 255) return AppConstants.msgAddressMax255;
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
            const SnackBar(content: Text(AppConstants.msgSelectedImageNotFound)),
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
            const SnackBar(content: Text(AppConstants.msgCapturedImageNotFound)),
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
          title: const Text(AppConstants.labelSelectImageSource),
          content: const Text(AppConstants.labelChooseHowToSelect),
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
              child: const Text(AppConstants.labelCancel),
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
      final String createdBy = prefs.getString(AppConstants.keyUserName) ?? '';

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
      if (res[AppConstants.keySuccess] == true) {
        // server should have sent activation link; show success and go back
        if (!mounted) return;
        _showSuccessDialog(res[AppConstants.keyMessage] ?? AppConstants.labelOwnerRegisteredSuccess);
      } else {
        if (!mounted) return;
        // Check if this is an existing owner case
        if (res[AppConstants.keyData] != null && res[AppConstants.keyData]['action'] == 'USE_EXISTING') {
          _showExistingOwnerDialog(res[AppConstants.keyData]);
        } else {
          _showErrorSnackBar(res[AppConstants.keyMessage] ?? AppConstants.msgFailedToRegisterOwner);
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('${AppConstants.labelError}: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text(AppConstants.msgRegistrationSuccessfulTitleGeneric),
        content: Text(
          "$message\n\n${AppConstants.msgOwnerActivationInfo}"
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pop(context, true); // return true so dashboard can refresh
            },
            child: const Text(AppConstants.buttonOk),
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
        title: const Text(AppConstants.labelVehicleOwnerAlreadyExists),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppConstants.msgExistingOwnerWithDetails),
            SizedBox(height: AppSizes.registerOwnerSpacing),
            Text('Name: ${existingOwnerData['existingOwnerName']}'),
            Text('Email: ${existingOwnerData['existingOwnerEmail']}'),
            Text('Contact: ${existingOwnerData['existingOwnerContact']}'),
            SizedBox(height: AppSizes.registerOwnerSpacing),
            const Text(AppConstants.labelWouldYouLikeToAssociate),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pop(context, false); // Don't refresh dashboard
            },
            child: const Text(AppConstants.labelCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _associateExistingOwner(existingOwnerData);
            },
            child: const Text(AppConstants.labelAssociateWithSchool),
          ),
        ],
      ),
    );
  }

  Future<void> _associateExistingOwner(Map<String, dynamic> existingOwnerData) async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? schoolId = prefs.getInt(AppConstants.keySchoolId);
      final String createdBy = prefs.getString(AppConstants.keyUserName) ?? '';

      if (schoolId == null) {
        throw Exception(AppConstants.msgSchoolNotFoundPrefs);
      }

      final ownerId = existingOwnerData['existingOwnerId'];
      final res = await _service.associateOwnerWithSchool(ownerId, schoolId, createdBy);
      
      if (res[AppConstants.keySuccess] == true) {
        if (!mounted) return;
        _showSuccessDialog(res[AppConstants.keyMessage] ?? AppConstants.labelOwnerAssociatedSuccess);
      } else {
        if (!mounted) return;
        _showErrorSnackBar(res[AppConstants.keyMessage] ?? AppConstants.msgFailedToAssociateOwner);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('${AppConstants.labelError}: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorColor,
        duration: const Duration(seconds: AppConstants.registerOwnerSnackDuration),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.labelRegisterVehicleOwner)),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.registerOwnerPadding),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtl,
                decoration: const InputDecoration(
                  labelText: AppConstants.labelOwnerName,
                  hintText: AppConstants.hintOwnerFullName,
                ),
                validator: _validateName,
              ),
              const SizedBox(height: AppSizes.registerOwnerSpacing),
              TextFormField(
                controller: _emailCtl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: AppConstants.labelOwnerEmail,
                  hintText: AppConstants.hintOwnerEmail,
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: AppSizes.registerOwnerSpacing),
              TextFormField(
                controller: _contactCtl,
                keyboardType: TextInputType.phone,
                maxLength: AppConstants.registerOwnerContactLength,
                decoration: const InputDecoration(
                  labelText: AppConstants.labelOwnerContact,
                  hintText: AppConstants.hintMobileNumber,
                ),
                validator: _validateContact,
              ),
              const SizedBox(height: AppSizes.registerOwnerSpacing),
              TextFormField(
                controller: _addressCtl,
                decoration: const InputDecoration(
                  labelText: AppConstants.labelOwnerAddress,
                  hintText: AppConstants.hintOwnerAddress,
                ),
                maxLines: 3,
                validator: _validateAddress,
              ),
              const SizedBox(height: AppSizes.registerOwnerSpacingLG),
              
              // Photo Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.registerOwnerCardPadding),
                  child: Column(
                    children: [
                      const Text(
                        AppConstants.labelOwnerPhotoOptional,
                        style: TextStyle(fontSize: AppSizes.registerOwnerTitleFont, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSizes.registerOwnerSpacingLG),
                      CircleAvatar(
                        radius: AppSizes.registerOwnerAvatarRadius,
                        backgroundColor: AppColors.gateStaffColor,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!) as ImageProvider<Object>?
                            : null,
                        child: _selectedImage == null
                            ? const Icon(Icons.person, color: AppColors.textWhite, size: AppSizes.registerOwnerAvatarIconSize)
                            : null,
                      ),
                      const SizedBox(height: AppSizes.registerOwnerSpacingLG),
                      ElevatedButton.icon(
                        onPressed: _showImageSourceDialog,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text(AppConstants.labelAddPhoto),
                      ),
                      if (_selectedImage != null) ...[
                        const SizedBox(height: AppSizes.registerOwnerSpacing),
                        Text(
                          '${AppConstants.labelPhotoSelectedPrefix}${_selectedImage!.path.split('/').last}',
                          style: const TextStyle(fontSize: 12, color: AppColors.successColor),
                        ),
                        const SizedBox(height: AppSizes.registerOwnerSpacing),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                          child: const Text(AppConstants.labelRemovePhoto),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.registerOwnerSpacingLG),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading ? const CircularProgressIndicator() : const Text(AppConstants.labelRegisterVehicleOwner),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

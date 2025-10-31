import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/vehicle_owner_request.dart';
import '../../services/vehicle_owner_service.dart';
import '../../utils/constants.dart';

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
    _userId = prefs.getInt(AppConstants.keyUserId);
    _createdBy = prefs.getString(AppConstants.keyUserName) ?? AppConstants.registerSchoolCreatedBy;

    // Load owner data

    final resp = await _service.getOwnerByUserId(_userId!);
    if (resp[AppConstants.keySuccess] == true && resp[AppConstants.keyData] != null) {
      final data = resp[AppConstants.keyData];
      setState(() {
        _nameCtl.text = data[AppConstants.keyName] ?? "";
        _emailCtl.text = data[AppConstants.keyEmail] ?? "";
        _contactCtl.text = data[AppConstants.keyContactNumber] ?? "";
        _addressCtl.text = data[AppConstants.keyAddress] ?? "";
        _ownerPhoto = data[AppConstants.keyOwnerPhoto];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.msgErrorLoadingProfile)),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: AppSizes.imageMaxWidth,
        maxHeight: AppSizes.imageMaxHeight,
        imageQuality: AppSizes.imageQuality,
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
        maxWidth: AppSizes.imageMaxWidth,
        maxHeight: AppSizes.imageMaxHeight,
        imageQuality: AppSizes.imageQuality,
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
              child: const Text(AppConstants.actionCancel),
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
      createdBy: _createdBy ?? AppConstants.registerSchoolCreatedBy,
      ownerPhoto: photoBase64,
    );

    final resp = await _service.updateOwner(widget.ownerId, req);

    if (resp[AppConstants.keySuccess] == true) {
      setState(() {
        if (photoBase64 != null) {
          _ownerPhoto = photoBase64;
        }
        _selectedImage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.msgProfileUpdatedSuccessfully)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppConstants.msgUpdateFailed}: ${resp[AppConstants.keyMessage]}')),
      );
    }
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
      appBar: AppBar(title: const Text(AppConstants.labelVehicleOwnerProfile)),
      body: Padding(
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
                      const Text(AppConstants.labelOwnerPhoto, style: TextStyle(fontSize: AppSizes.textXL, fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppSizes.marginMD),
                      CircleAvatar(
                        radius: AppSizes.avatarLG,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!) as ImageProvider<Object>?
                            : (_ownerPhoto != null && _ownerPhoto!.isNotEmpty
                                ? _getMemoryImage(_ownerPhoto!) as ImageProvider<Object>?
                                : null),
                        child: (_selectedImage == null && (_ownerPhoto == null || _ownerPhoto!.isEmpty))
                            ? const Icon(Icons.person, color: AppColors.textWhite, size: AppSizes.iconXL)
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
                        Text(
                          AppConstants.labelNewPhotoSelected,
                          style: const TextStyle(color: AppColors.successColor, fontSize: AppSizes.textXS),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.marginMD),
              TextFormField(
                controller: _nameCtl,
                decoration: const InputDecoration(labelText: AppConstants.labelOwnerName),
                validator: (v) => v!.isEmpty ? AppConstants.msgNameRequired : null,
              ),
              const SizedBox(height: AppSizes.marginSM),
              TextFormField(
                controller: _emailCtl,
                decoration: const InputDecoration(labelText: AppConstants.labelEmail),
                validator: (v) => v!.isEmpty ? AppConstants.msgEnterValidEmail : null,
              ),
              const SizedBox(height: AppSizes.marginSM),
              TextFormField(
                controller: _contactCtl,
                decoration: const InputDecoration(labelText: AppConstants.labelContactNumber),
                validator: (v) => v!.isEmpty ? AppConstants.msgEnterContactNumber : null,
              ),
              const SizedBox(height: AppSizes.marginSM),
              TextFormField(
                controller: _addressCtl,
                decoration: const InputDecoration(labelText: AppConstants.labelAddress),
              ),
              const SizedBox(height: AppSizes.marginLG),
              ElevatedButton(
                onPressed: _updateProfile,
                child: const Text(AppConstants.labelUpdateProfile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/screens/register_driver_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import '../../data/models/driver_request.dart';
import '../../services/driver_service.dart';


class RegisterDriverScreen extends StatefulWidget {
  const RegisterDriverScreen({super.key});

  @override
  State<RegisterDriverScreen> createState() => _RegisterDriverScreenState();
}

class _RegisterDriverScreenState extends State<RegisterDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _contactCtl = TextEditingController();
  final _addressCtl = TextEditingController();
  final _emailCtl = TextEditingController();

  String? _photoBase64;
  File? _photoFile;
  bool _submitting = false;

  final DriverService _service = DriverService();
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source, imageQuality: AppSizes.registerDriverImageQuality);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _photoBase64 = base64Encode(bytes);
      _photoFile = File(picked.path);
    });
  }

  Future<void> _showImageOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text(AppConstants.labelChooseFromGallery),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text(AppConstants.labelTakePhoto),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt(AppConstants.keyUserId);
      final String createdBy = prefs.getString(AppConstants.keyUserName) ?? '';

      debugPrint('🔍 Driver Registration: userId = $userId');
      debugPrint('🔍 Driver Registration: createdBy = $createdBy');
      debugPrint('🔍 Driver Registration: driverName = ${_nameCtl.text.trim()}');
      debugPrint('🔍 Driver Registration: contactNumber = ${_contactCtl.text.trim()}');

      if (userId == null) throw Exception(AppConstants.msgUserNotFoundPrefs);

      final req = DriverRequest(
        userId: userId,
        driverName: _nameCtl.text.trim(),
        driverContactNumber: _contactCtl.text.trim(),
        driverAddress: _addressCtl.text.trim(),
        driverPhotoBase64: _photoBase64,
        email: _emailCtl.text.trim().isEmpty ? null : _emailCtl.text.trim(),
        createdBy: createdBy,
      );

      debugPrint('🔍 Driver Registration: request = $req');

      final res = await _service.createDriver(req);
      debugPrint('🔍 Driver Registration: response = $res');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res[AppConstants.keyMessage] ?? AppConstants.msgDriverCreated)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('🔍 Driver Registration: error = $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppConstants.labelError}: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildText(String label, TextEditingController ctl,
          {String? Function(String?)? validator, TextInputType type = TextInputType.text, String? hintText}) =>
      TextFormField(
        controller: ctl,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
        ),
        validator: validator ?? (v) => v == null || v.isEmpty ? AppConstants.labelRequired : null,
        keyboardType: type,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.labelRegisterDriver)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.registerDriverPadding),
        child: Form(
          key: _formKey,
          child: Column(children: [
            GestureDetector(
              onTap: _showImageOptions,
              child: CircleAvatar(
                radius: AppSizes.registerDriverAvatarRadius,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _photoFile != null ? FileImage(_photoFile!) : null,
                child: _photoFile == null ? const Icon(Icons.camera_alt, size: AppSizes.registerDriverIconSize) : null,
              ),
            ),
            const SizedBox(height: AppSizes.registerDriverSpacing),
            _buildText(AppConstants.labelDriverName, _nameCtl, 
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return AppConstants.msgDriverNameRequired;
                  if (v.trim().length > AppSizes.registerDriverNameMaxLength) return AppConstants.msgDriverNameMaxLength;
                  return null;
                }),
            const SizedBox(height: AppSizes.registerDriverSpacingSM),
            _buildText(AppConstants.labelDriverContactNumber, _contactCtl, 
                type: TextInputType.phone,
                hintText: AppConstants.hintMobileNumber,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return AppConstants.msgContactNumberRequired;
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length != AppSizes.registerDriverContactLength) return AppConstants.msgContactNumberExactDigits;
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) return AppConstants.msgValidIndianMobile;
                  return null;
                }),
            const SizedBox(height: AppSizes.registerDriverSpacingSM),
            _buildText(AppConstants.labelDriverAddress, _addressCtl,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return AppConstants.msgDriverAddressRequired;
                  if (v.trim().length > AppSizes.registerDriverAddressMaxLength) return AppConstants.msgDriverAddressMaxLength;
                  return null;
                }),
            const SizedBox(height: AppSizes.registerDriverSpacingSM),
            _buildText(AppConstants.labelEmailOptional, _emailCtl, 
                type: TextInputType.emailAddress,
                hintText: AppConstants.hintEmailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null; // Optional field
                  if (v.trim().length > AppSizes.registerDriverEmailMaxLength) return AppConstants.msgEmailMaxLength;
                  final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                  return regex.hasMatch(v.trim()) ? null : AppConstants.msgEnterValidEmailAddress;
                }),
            const SizedBox(height: AppSizes.registerDriverSpacingLG),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(AppConstants.labelRegisterDriver),
            ),
          ]),
        ),
      ),
    );
  }
}

// lib/screens/register_vehicle_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import '../../data/models/New_vehicle_request.dart';
import '../../services/vehicle_service.dart';

class RegisterVehicleScreen extends StatefulWidget {
  const RegisterVehicleScreen({super.key});

  @override
  State<RegisterVehicleScreen> createState() => _RegisterVehicleScreenState();
}

class _RegisterVehicleScreenState extends State<RegisterVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberCtl = TextEditingController();
  final _registrationNumberCtl = TextEditingController();
  final _capacityCtl = TextEditingController();

  String? _photoBase64;
  File? _photoFile;
  bool _submitting = false;

  String? _selectedVehicleType; // ✅ vehicleType dropdown value


  final _service = VehicleService();
  final _picker = ImagePicker();

  final List<String> _vehicleTypes = AppConstants.vehicleTypes; // ✅ dropdown list 

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked =
        await _picker.pickImage(source: source, imageQuality: AppSizes.registerStudentImageQuality);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _photoBase64 = base64Encode(bytes);
      _photoFile = File(picked.path);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final createdBy = prefs.getString(AppConstants.keyUserName) ?? "";
      

      final capacityValue = int.parse(_capacityCtl.text.trim());
      debugPrint('🔍 Frontend: Sending capacity value: $capacityValue');
      
      final req = VehicleRequest(
        vehicleNumber: _vehicleNumberCtl.text.trim(),
        registrationNumber: _registrationNumberCtl.text.trim(),
        vehiclePhoto: _photoBase64,
        createdBy: createdBy,
        vehicleType: _selectedVehicleType!, // ✅ send type
        capacity: capacityValue, // ✅ send capacity
      );
      
      debugPrint('🔍 Frontend: Vehicle request JSON: ${req.toJson()}');

      final res = await _service.registerVehicle(req);

      if (!mounted) return;
      if (res[AppConstants.keySuccess] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res[AppConstants.keyMessage] ?? AppConstants.labelVehicleRegistered)));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res[AppConstants.keyMessage] ?? AppConstants.labelFailedGeneric)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${AppConstants.labelError}: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _vehicleNumberCtl.dispose();
    _registrationNumberCtl.dispose();
    _capacityCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.labelRegisterVehicle)),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.registerVehiclePadding),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => SafeArea(
                      child: Wrap(
                        children: [
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
                        ],
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: AppSizes.registerVehicleAvatarRadius,
                  backgroundColor: AppColors.grey200,
                  backgroundImage:
                      _photoFile != null ? FileImage(_photoFile!) : null,
                  child: _photoFile == null
                      ? const Icon(Icons.camera_alt, size: AppSizes.registerVehicleAvatarIcon)
                      : null,
                ),
              ),
              const SizedBox(height: AppSizes.registerVehicleSpacingLG),

              TextFormField(
                controller: _vehicleNumberCtl,
                decoration: const InputDecoration(
                  labelText: AppConstants.labelVehicleNumber,
                  hintText: AppConstants.hintVehicleNumber,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return AppConstants.msgVehicleNumberRequired;
                  if (v.trim().length > 10) return AppConstants.msgVehicleNumberMax10;
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.registerVehicleSpacing),

              TextFormField(
                controller: _registrationNumberCtl,
                decoration: const InputDecoration(
                  labelText: AppConstants.labelVehicleRegistrationNumber,
                  hintText: AppConstants.hintVehicleRegistrationNumber,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return AppConstants.msgRegistrationNumberRequired;
                  if (v.trim().length > 20) return AppConstants.msgRegistrationNumberMax20;
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.registerVehicleSpacing),

              // ✅ Vehicle Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedVehicleType,
                items: _vehicleTypes
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedVehicleType = val),
                decoration: const InputDecoration(labelText: AppConstants.labelVehicleType),
                validator: (v) =>
                    v == null ? AppConstants.msgSelectVehicleType : null,
              ),
              const SizedBox(height: AppSizes.registerVehicleSpacing),

              // ✅ Vehicle Capacity Field
              TextFormField(
                controller: _capacityCtl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: AppConstants.labelVehicleCapacity,
                  hintText: AppConstants.hintVehicleCapacity,
                  suffixText: AppConstants.suffixStudents,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return AppConstants.msgVehicleCapacityRequired;
                  final capacity = int.tryParse(v.trim());
                  if (capacity == null) return AppConstants.msgEnterValidNumber;
                  if (capacity <= 0) return AppConstants.msgCapacityMustBeGreaterThanZero;
                  if (capacity > 100) return AppConstants.msgCapacityCannotExceed100;
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.registerVehicleSpacingLG),

              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const CircularProgressIndicator(color: AppColors.loadingIndicatorColor)
                    : const Text(AppConstants.labelRegisterVehicle),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

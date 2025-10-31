import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import '../../data/models/driver_profile.dart';
import '../../data/models/driver_request.dart';
import '../../services/driver_service.dart';

class DriverProfilePage extends StatefulWidget {
  final DriverProfile profile;

  const DriverProfilePage({super.key, required this.profile});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  final DriverService _driverService = DriverService();
  final ImagePicker _picker = ImagePicker();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _contactController;
  late TextEditingController _addressController;
  
  bool _isEditing = false;
  bool _isLoading = false;
  String? _selectedImagePath;
  String? _base64Image;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.profile.driverName);
    _emailController = TextEditingController(text: widget.profile.email);
    _contactController = TextEditingController(text: widget.profile.driverContactNumber);
    _addressController = TextEditingController(text: widget.profile.driverAddress);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
        
        // Convert to base64
        final bytes = await File(image.path).readAsBytes();
        _base64Image = base64Encode(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppConstants.msgErrorPickingImage}$e'),
            backgroundColor: AppColors.driverProfileErrorColor,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
        
        // Convert to base64
        final bytes = await File(image.path).readAsBytes();
        _base64Image = base64Encode(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppConstants.msgErrorTakingPhoto}$e'),
            backgroundColor: AppColors.driverProfileErrorColor,
          ),
        );
      }
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text(AppConstants.labelChooseFromGallery),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text(AppConstants.labelTakePhoto),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_isEditing) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final request = DriverRequest(
        userId: widget.profile.driverId,
        driverName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        driverContactNumber: _contactController.text.trim(),
        driverAddress: _addressController.text.trim(),
        driverPhotoBase64: _base64Image ?? widget.profile.driverPhoto,
        createdBy: 'driver',
      );

      final response = await _driverService.updateDriverProfile(widget.profile.driverId, request);
      
      if (!mounted) return;
      
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.msgProfileUpdatedSuccessfully),
            backgroundColor: AppColors.driverProfileSuccessColor,
          ),
        );
        
        setState(() {
          _isEditing = false;
        });
        
        // Update SharedPreferences if needed
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.keyDriverName, _nameController.text.trim());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? AppConstants.msgFailedToUpdateProfile),
            backgroundColor: AppColors.driverProfileErrorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppConstants.msgErrorUpdatingProfile}$e'),
            backgroundColor: AppColors.driverProfileErrorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _selectedImagePath = null;
      _base64Image = null;
    });
    _initializeControllers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.labelDriverProfile),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelEdit,
            ),
            IconButton(
              icon: _isLoading 
                ? const SizedBox(
                    width: AppSizes.driverProfileProgressSize,
                    height: AppSizes.driverProfileProgressSize,
                    child: CircularProgressIndicator(strokeWidth: AppSizes.driverProfileProgressStroke),
                  )
                : const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveProfile,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.driverProfilePadding),
        child: Column(
          children: [
            // Profile Photo Section
            _buildProfilePhotoSection(),
            const SizedBox(height: AppSizes.driverProfileSpacingLG),

            // Profile Information
            _buildProfileInfoSection(),
            const SizedBox(height: AppSizes.driverProfileSpacingLG),

            // Account Information (Read-only)
            _buildAccountInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    return Card(
      elevation: AppSizes.driverProfileCardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.driverProfileCardRadius)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.driverProfileCardPadding),
        child: Column(
          children: [
            const Text(
              AppConstants.labelProfilePhoto,
              style: TextStyle(fontSize: AppSizes.driverProfileHeaderFontSize, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.driverProfileSpacingMD),
            Stack(
              children: [
                CircleAvatar(
                  radius: AppSizes.driverProfilePhotoRadius,
                  backgroundColor: AppColors.driverProfilePrimaryColor,
                  backgroundImage: _getProfileImage(),
                  child: _getProfileImage() == null 
                    ? const Icon(Icons.person, size: AppSizes.driverProfilePhotoIconSize, color: AppColors.driverProfileTextWhite)
                    : null,
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showImagePicker,
                      child: Container(
                        padding: const EdgeInsets.all(AppSizes.driverProfileCameraPadding),
                        decoration: const BoxDecoration(
                          color: AppColors.driverProfilePrimaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: AppColors.driverProfileTextWhite,
                          size: AppSizes.driverProfileCameraIconSize,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.driverProfileSpacingSM),
            if (_isEditing)
              TextButton.icon(
                onPressed: _showImagePicker,
                icon: const Icon(Icons.photo_camera),
                label: const Text(AppConstants.labelChangePhoto),
              ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_selectedImagePath != null) {
      return FileImage(File(_selectedImagePath!));
    } else if (widget.profile.driverPhoto != null && widget.profile.driverPhoto!.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(widget.profile.driverPhoto!));
      } catch (e) {
        debugPrint('${AppConstants.msgErrorDecodingImage}$e');
        return null;
      }
    }
    return null;
  }

  Widget _buildProfileInfoSection() {
    return Card(
      elevation: AppSizes.driverProfileCardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.driverProfileCardRadius)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.driverProfileCardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.labelPersonalInformation,
              style: TextStyle(fontSize: AppSizes.driverProfileHeaderFontSize, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.driverProfileSpacingMD),
            
            // Driver Name
            TextFormField(
              controller: _nameController,
              enabled: _isEditing,
              decoration: const InputDecoration(
                labelText: AppConstants.labelFullName,
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSizes.driverProfileSpacingMD),
            
            // Email
            TextFormField(
              controller: _emailController,
              enabled: _isEditing,
              decoration: const InputDecoration(
                labelText: AppConstants.labelEmail,
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSizes.driverProfileSpacingMD),
            
            // Contact Number
            TextFormField(
              controller: _contactController,
              enabled: _isEditing,
              decoration: const InputDecoration(
                labelText: AppConstants.labelContactNumber,
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSizes.driverProfileSpacingMD),
            
            // Address
            TextFormField(
              controller: _addressController,
              enabled: _isEditing,
              decoration: const InputDecoration(
                labelText: AppConstants.labelAddress,
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoSection() {
    return Card(
      elevation: AppSizes.driverProfileCardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.driverProfileCardRadius)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.driverProfileCardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.labelAccountInformation,
              style: TextStyle(fontSize: AppSizes.driverProfileHeaderFontSize, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.driverProfileSpacingMD),
            
            _buildInfoRow(AppConstants.labelDriverID, widget.profile.driverId.toString()),
            _buildInfoRow(AppConstants.labelSchool, widget.profile.schoolName),
            _buildInfoRow(AppConstants.labelVehicle, '${widget.profile.vehicleNumber} (${widget.profile.vehicleType})'),
            _buildInfoRow(AppConstants.labelStatus, widget.profile.isActive ? AppConstants.labelActive : AppConstants.labelInactive),
            _buildInfoRow(AppConstants.labelMemberSince, _formatDate(widget.profile.createdDate)),
            _buildInfoRow(AppConstants.labelLastUpdated, _formatDate(widget.profile.updatedDate)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.driverProfileSpacingXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSizes.driverProfileLabelWidth,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.driverProfileGreyColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

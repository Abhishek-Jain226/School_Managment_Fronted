// lib/screens/register_student_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
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
  String _gender = AppConstants.genderMale;
  ClassMaster? _selectedClass;
  SectionMaster? _selectedSection;
  String _relation = AppConstants.relationGuardian; // Hidden field with default value

  // image
  String? _photoBase64;
  File? _photoFile;

  bool _submitting = false;

  final StudentService _service = StudentService();
  final MasterDataService _masterDataService = MasterDataService();
  final ImagePicker _picker = ImagePicker();

  final List<String> _genders = [
    AppConstants.genderMale,
    AppConstants.genderFemale,
    AppConstants.genderOther,
  ];
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
      debugPrint(AppConstants.logLoadingMasterData);
      
      // Get school ID from preferences
      final prefs = await SharedPreferences.getInstance();
      final int? schoolId = prefs.getInt(AppConstants.keySchoolId);
      
      if (schoolId == null) {
        debugPrint(AppConstants.msgSchoolIdMissingPrefs);
        return;
      }
      
      // Load classes for this school
      final classesResponse = await _masterDataService.getAllActiveClasses(schoolId);
      debugPrint('${AppConstants.logClassesResponse}$classesResponse');
      
      if (classesResponse[AppConstants.keySuccess] == true && classesResponse[AppConstants.keyData] != null) {
        setState(() {
          _classes = (classesResponse[AppConstants.keyData] as List)
              .map((json) => ClassMaster.fromJson(json))
              .toList();
          debugPrint('${AppConstants.logLoadedClassesCount}${_classes.length} classes');
          // Set default selection to first class
          if (_classes.isNotEmpty && _selectedClass == null) {
            _selectedClass = _classes.first;
            debugPrint('${AppConstants.logSetDefaultClass}${_selectedClass?.className}');
          }
        });
      } else {
        debugPrint('${AppConstants.logFailedToLoadClasses}${classesResponse[AppConstants.keyMessage]}');
      }

      // Load sections for this school
      final sectionsResponse = await _masterDataService.getAllActiveSections(schoolId);
      debugPrint('${AppConstants.logSectionsResponse}$sectionsResponse');
      
      if (sectionsResponse[AppConstants.keySuccess] == true && sectionsResponse[AppConstants.keyData] != null) {
        setState(() {
          _sections = (sectionsResponse[AppConstants.keyData] as List)
              .map((json) => SectionMaster.fromJson(json))
              .toList();
          debugPrint('${AppConstants.logLoadedSectionsCount}${_sections.length} sections');
          // Set default selection to first section
          if (_sections.isNotEmpty && _selectedSection == null) {
            _selectedSection = _sections.first;
            debugPrint('${AppConstants.logSetDefaultSection}${_selectedSection?.sectionName}');
          }
        });
      } else {
        debugPrint('${AppConstants.logFailedToLoadSections}${sectionsResponse[AppConstants.keyMessage]}');
      }
    } catch (e) {
      debugPrint('Error loading master data: $e');
    }
  }


  String? _validateRequired(String? v) =>
      (v == null || v.trim().isEmpty) ? AppConstants.msgThisFieldRequired : null;

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return AppConstants.msgNameRequired;
    if (v.trim().length < AppSizes.registerStudentNameMinLength) return AppConstants.msgNameMin2;
    if (v.trim().length > AppSizes.registerStudentNameMaxLength) return AppConstants.msgNameMax50;
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v.trim())) return AppConstants.msgNameLettersSpaces;
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return AppConstants.msgContactRequired;
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length != AppSizes.registerStudentContactLength) return AppConstants.msgContactExact10;
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) return AppConstants.msgValidIndianMobileStart6to9;
    return null;
  }

  String? _validateOptionalPhone(String? v) {
    if (v == null || v.trim().isEmpty) return null; // Optional field
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length != AppSizes.registerStudentContactLength) return AppConstants.msgContactExact10;
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) return AppConstants.msgValidIndianMobileStart6to9;
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return AppConstants.msgEmailRequired;
    if (v.trim().length > AppSizes.registerStudentEmailMaxLength) return AppConstants.msgEmailMax150;
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(v.trim()) ? null : AppConstants.msgEnterValidEmail;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked =
          await _picker.pickImage(source: source, imageQuality: AppSizes.registerStudentImageQuality);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _photoBase64 = base64Encode(bytes);
        _photoFile = File(picked.path);
      });
    } catch (e) {
      debugPrint("Image pick error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${AppConstants.msgImagePickError}$e')));
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
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? schoolId = prefs.getInt(AppConstants.keySchoolId);
      final String createdBy = prefs.getString(AppConstants.keyUserName) ?? '';

      if (schoolId == null) {
        throw Exception(AppConstants.msgSchoolIdMissingPrefs);
      }

      if (_selectedClass == null) {
        throw Exception(AppConstants.msgPleaseSelectClass);
      }

      if (_selectedSection == null) {
        throw Exception(AppConstants.msgPleaseSelectSection);
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

      if (res[AppConstants.keySuccess] == true) {
        if (!mounted) return;
        _showSuccessDialog(res[AppConstants.keyMessage] ?? AppConstants.labelStudentRegisteredSuccessfully);
        _resetForm(); // Clear form after successful registration
      } else {
        if (!mounted) return;
        _showErrorSnackBar(res[AppConstants.keyMessage] ?? AppConstants.msgFailedToRegisterStudent);
      }
    } catch (e) {
      debugPrint('${AppConstants.logSubmitError}$e');
      if (mounted) {
        _showErrorSnackBar('${AppConstants.labelError}: $e');
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
        title: const Text(AppConstants.msgRegistrationSuccessfulTitle),
        content: Text(
          "$message\n\n${AppConstants.msgParentActivationInfo}"
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorColor,
        duration: const Duration(seconds: AppSizes.registerGateStaffErrorDuration),
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
      appBar: AppBar(title: const Text(AppConstants.labelRegisterStudent)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.registerStudentPadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Photo
              GestureDetector(
                onTap: _showImageOptions,
                child: CircleAvatar(
                  radius: AppSizes.registerStudentAvatarRadius,
                  backgroundColor: AppColors.grey200,
                  backgroundImage:
                      _photoFile != null ? FileImage(_photoFile!) : null,
                  child:
                      _photoFile == null ? const Icon(Icons.camera_alt, size: AppSizes.registerStudentIconSize) : null,
                ),
              ),
              const SizedBox(height: AppSizes.registerStudentSpacing),

              _buildText(AppConstants.labelFirstNameRequired, _firstCtl, validator: _validateName),
              const SizedBox(height: AppSizes.registerStudentSpacingSM),
              _buildText(AppConstants.labelMiddleNameOptional, _middleCtl, validator: (v) {
                if (v == null || v.trim().isEmpty) return null; // Optional field
                if (v.trim().length > AppSizes.registerStudentNameMaxLength) return AppConstants.msgNameMax50;
                if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v.trim())) return AppConstants.msgNameLettersSpaces;
                return null;
              }),
              const SizedBox(height: AppSizes.registerStudentSpacingSM),
              _buildText(AppConstants.labelLastNameRequired, _lastCtl, validator: _validateName),
              const SizedBox(height: AppSizes.registerStudentSpacingSM),

              // gender + class + section row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(labelText: AppConstants.labelGender),
                      items: _genders
                          .map((g) =>
                              DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) => setState(() => _gender = v!),
                    ),
                  ),
                  const SizedBox(width: AppSizes.registerStudentSpacingSM),
                  Expanded(
                    child: DropdownButtonFormField<ClassMaster>(
                      value: _selectedClass,
                      decoration: const InputDecoration(labelText: AppConstants.labelClass),
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
                          return AppConstants.msgPleaseSelectClass;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSizes.registerStudentSpacingSM),
                  Expanded(
                    child: DropdownButtonFormField<SectionMaster>(
                      value: _selectedSection,
                      decoration: const InputDecoration(labelText: AppConstants.labelSection),
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
                          return AppConstants.msgPleaseSelectSection;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.registerStudentSpacing),
              _buildText(AppConstants.labelMotherNameRequired, _motherCtl, validator: _validateName),
              const SizedBox(height: AppSizes.registerStudentSpacingSM),
              _buildText(AppConstants.labelFatherNameRequired, _fatherCtl, validator: _validateName),
              const SizedBox(height: AppSizes.registerStudentSpacingSM),
              TextFormField(
                controller: _primaryContactCtl,
                decoration: const InputDecoration(
                  labelText: AppConstants.labelPrimaryContactRequired,
                  hintText: AppConstants.hintMobile10Digits,
                ),
                keyboardType: TextInputType.phone,
                maxLength: AppSizes.registerStudentContactLength,
                validator: _validatePhone,
              ),
              const SizedBox(height: AppSizes.registerStudentSpacingSM),
              TextFormField(
                controller: _altContactCtl,
                decoration: const InputDecoration(
                  labelText: AppConstants.labelAlternateContactOptional,
                  hintText: AppConstants.hintMobile10Digits,
                ),
                keyboardType: TextInputType.phone,
                maxLength: AppSizes.registerStudentContactLength,
                validator: _validateOptionalPhone,
              ),
              const SizedBox(height: AppSizes.registerStudentSpacingSM),
              TextFormField(
                controller: _emailCtl,
                decoration: const InputDecoration(
                  labelText: AppConstants.labelParentEmailRequired,
                  hintText: AppConstants.hintParentEmail,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),

              const SizedBox(height: AppSizes.registerStudentSpacingLG),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                      ? const CircularProgressIndicator(color: AppColors.loadingIndicatorColor)
                    : const Text(AppConstants.labelRegisterStudent),
              ),
              const SizedBox(height: AppSizes.registerStudentSpacingLG),
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

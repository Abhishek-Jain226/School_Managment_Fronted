import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/parent_service.dart';
import '../../utils/constants.dart';

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
      if (resp[AppConstants.keySuccess] == true && resp[AppConstants.keyData] != null) {
        final data = resp[AppConstants.keyData];
        setState(() {
          _firstNameCtl.text = data[AppConstants.keyFirstName] ?? "";
          _lastNameCtl.text = data[AppConstants.keyLastName] ?? "";
          _classCtl.text = data[AppConstants.keyClassName] ?? "";
          _sectionCtl.text = data[AppConstants.keySectionName] ?? "";
          _fatherCtl.text = data[AppConstants.keyFatherName] ?? "";
          _motherCtl.text = data[AppConstants.keyMotherName] ?? "";
          _contactCtl.text = data[AppConstants.keyPrimaryContact] ?? "";
          _altContactCtl.text = data[AppConstants.keyAlternateContact] ?? "";
          _emailCtl.text = data[AppConstants.keyEmail] ?? "";
          _studentPhoto = data[AppConstants.keyStudentPhoto];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppConstants.msgOperationFailed}: ${resp[AppConstants.keyMessage]}')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppConstants.msgError}: $e')),
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppConstants.actionCancel)),
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
      AppConstants.keyStudentId: widget.studentId,
      AppConstants.keyFirstName: _firstNameCtl.text.trim(),
      AppConstants.keyLastName: _lastNameCtl.text.trim(),
      AppConstants.keyClassName: _classCtl.text.trim(),
      AppConstants.keySectionName: _sectionCtl.text.trim(),
      AppConstants.keyFatherName: _fatherCtl.text.trim(),
      AppConstants.keyMotherName: _motherCtl.text.trim(),
      AppConstants.keyPrimaryContact: _contactCtl.text.trim(),
      AppConstants.keyAlternateContact: _altContactCtl.text.trim(),
      AppConstants.keyEmail: _emailCtl.text.trim(),
      if (photoBase64 != null) AppConstants.keyStudentPhoto: photoBase64,
      AppConstants.keyUpdatedBy: AppConstants.labelParent,
    };

    final resp = await _service.updateStudent(widget.studentId, req);

    if (resp[AppConstants.keySuccess] == true) {
      setState(() {
        if (photoBase64 != null) {
          _studentPhoto = photoBase64;
        }
        _selectedImage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.msgStudentUpdatedSuccess)),
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
        title: const Text(AppConstants.labelStudentProfile),
        actions: [
          // Student Photo in top-right corner (clickable)
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.marginMD),
            child: InkWell(
              onTap: _showImageSourceDialog,
              child: CircleAvatar(
                radius: AppSizes.avatarSM,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!) as ImageProvider<Object>?
                    : (_studentPhoto != null && _studentPhoto!.isNotEmpty
                        ? _getMemoryImage(_studentPhoto!) as ImageProvider<Object>?
                        : null),
                child: (_selectedImage == null && (_studentPhoto == null || _studentPhoto!.isEmpty))
                    ? const Icon(Icons.person, color: AppColors.textWhite, size: AppSizes.iconSM)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: _loading
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
                            const Text(AppConstants.labelStudentPhoto, style: TextStyle(fontSize: AppSizes.textXL, fontWeight: FontWeight.bold)),
                            const SizedBox(height: AppSizes.marginMD),
                            CircleAvatar(
                              radius: AppSizes.avatarLG,
                              backgroundColor: AppColors.primaryLight,
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!) as ImageProvider<Object>?
                                  : (_studentPhoto != null && _studentPhoto!.isNotEmpty
                                      ? _getMemoryImage(_studentPhoto!) as ImageProvider<Object>?
                                      : null),
                              child: (_selectedImage == null && (_studentPhoto == null || _studentPhoto!.isEmpty))
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
                      controller: _firstNameCtl,
                      decoration: const InputDecoration(labelText: AppConstants.labelFirstNameRequired),
                      validator: (v) => v!.isEmpty ? AppConstants.msgEnterFullName : null,
                    ),
                    const SizedBox(height: AppSizes.marginSM),
                    TextFormField(
                      controller: _lastNameCtl,
                      decoration: const InputDecoration(labelText: AppConstants.labelLastNameRequired),
                      validator: (v) => v!.isEmpty ? AppConstants.msgNameRequired : null,
                    ),
                    const SizedBox(height: AppSizes.marginSM),
                    TextFormField(
                      controller: _classCtl,
                      decoration: const InputDecoration(labelText: AppConstants.labelClass),
                      validator: (v) => v!.isEmpty ? AppConstants.msgPleaseSelectClass : null,
                    ),
                    const SizedBox(height: AppSizes.marginSM),
                    TextFormField(
                      controller: _sectionCtl,
                      decoration: const InputDecoration(labelText: AppConstants.labelSection),
                      validator: (v) => v!.isEmpty ? AppConstants.msgPleaseSelectSection : null,
                    ),
                    const SizedBox(height: AppSizes.marginSM),
                    TextFormField(
                      controller: _fatherCtl,
                      decoration: const InputDecoration(labelText: AppConstants.labelFatherNameRequired),
                    ),
                    const SizedBox(height: AppSizes.marginSM),
                    TextFormField(
                      controller: _motherCtl,
                      decoration: const InputDecoration(labelText: AppConstants.labelMotherNameRequired),
                    ),
                    const SizedBox(height: AppSizes.marginSM),
                    TextFormField(
                      controller: _contactCtl,
                      decoration: const InputDecoration(labelText: AppConstants.labelPrimaryContactRequired),
                    ),
                    const SizedBox(height: AppSizes.marginSM),
                    TextFormField(
                      controller: _altContactCtl,
                      decoration: const InputDecoration(labelText: AppConstants.labelAlternateContactOptional),
                    ),
                    const SizedBox(height: AppSizes.marginSM),
                    TextFormField(
                      controller: _emailCtl,
                      decoration: const InputDecoration(labelText: AppConstants.labelEmail),
                    ),
                    const SizedBox(height: AppSizes.marginLG),
                    ElevatedButton(
                      onPressed: _updateStudent,
                      child: const Text(AppConstants.labelUpdateProfile),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

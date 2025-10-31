// lib/presentation/pages/section_management_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import '../../data/models/section_master.dart';
import '../../services/master_data_service.dart';

class SectionManagementPage extends StatefulWidget {
  const SectionManagementPage({super.key});

  @override
  State<SectionManagementPage> createState() => _SectionManagementPageState();
}

class _SectionManagementPageState extends State<SectionManagementPage> {
  final MasterDataService _service = MasterDataService();
  final _formKey = GlobalKey<FormState>();
  final _sectionNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<SectionMaster> _sections = [];
  bool _loading = true;
  bool _isEditing = false;
  int? _editingSectionId;
  int? _schoolId;

  @override
  void initState() {
    super.initState();
    _loadSchoolId();
  }

  Future<void> _loadSchoolId() async {
    final prefs = await SharedPreferences.getInstance();
    _schoolId = prefs.getInt(AppConstants.keySchoolId);
    if (_schoolId != null) {
      _loadSections();
    } else {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.msgSchoolIdNotFoundLogin)),
      );
    }
  }

  @override
  void dispose() {
    _sectionNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSections() async {
    if (_schoolId == null) return;
    
    setState(() => _loading = true);
    try {
      final response = await _service.getAllSections(_schoolId!);
      if (response[AppConstants.keySuccess] == true) {
        setState(() {
          _sections = (response[AppConstants.keyData] as List)
              .map((json) => SectionMaster.fromJson(json))
              .toList();
        });
      } else {
        _showErrorSnackBar(response[AppConstants.keyMessage] ?? AppConstants.msgFailedToLoadSections);
      }
    } catch (e) {
      _showErrorSnackBar('${AppConstants.msgErrorLoadingSections}$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final createdBy = prefs.getString(AppConstants.keyUserName) ?? 'Admin';

      final sectionMaster = SectionMaster(
        sectionId: _isEditing ? _editingSectionId : null,
        sectionName: _sectionNameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        schoolId: _schoolId,
        createdBy: createdBy,
      );

      Map<String, dynamic> response;
      if (_isEditing) {
        response = await _service.updateSection(_editingSectionId!, sectionMaster);
      } else {
        response = await _service.createSection(sectionMaster);
      }

      if (response[AppConstants.keySuccess] == true) {
        _showSuccessSnackBar(_isEditing ? AppConstants.msgSectionUpdated : AppConstants.msgSectionCreated);
        _resetForm();
        _loadSections();
      } else {
        _showErrorSnackBar(response[AppConstants.keyMessage] ?? AppConstants.msgOperationFailed);
      }
    } catch (e) {
      _showErrorSnackBar('${AppConstants.labelException}: $e');
    }
  }

  Future<void> _deleteSection(SectionMaster sectionMaster) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppConstants.dialogTitleDeleteSection),
        content: Text('${AppConstants.msgConfirmDeleteSectionStart}${sectionMaster.sectionName}${AppConstants.msgConfirmDeleteSectionEnd}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppConstants.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppConstants.actionDelete, style: TextStyle(color: AppColors.errorColor)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _service.deleteSection(sectionMaster.sectionId!);
        if (response[AppConstants.keySuccess] == true) {
          _showSuccessSnackBar(AppConstants.msgSectionDeleted);
          _loadSections();
        } else {
          _showErrorSnackBar(response[AppConstants.keyMessage] ?? AppConstants.msgFailedToDeleteSection);
        }
      } catch (e) {
        _showErrorSnackBar('Error deleting section: $e');
      }
    }
  }

  Future<void> _toggleStatus(SectionMaster sectionMaster) async {
    try {
      final response = await _service.toggleSectionStatus(sectionMaster.sectionId!);
      if (response[AppConstants.keySuccess] == true) {
        _showSuccessSnackBar(AppConstants.msgSectionStatusUpdated);
        _loadSections();
      } else {
        _showErrorSnackBar(response[AppConstants.keyMessage] ?? AppConstants.msgFailedToUpdateStatus);
      }
    } catch (e) {
      _showErrorSnackBar('${AppConstants.msgErrorUpdatingStatus}$e');
    }
  }

  void _editSection(SectionMaster sectionMaster) {
    setState(() {
      _isEditing = true;
      _editingSectionId = sectionMaster.sectionId;
      _sectionNameController.text = sectionMaster.sectionName;
      _descriptionController.text = sectionMaster.description ?? '';
    });
  }

  void _resetForm() {
    setState(() {
      _isEditing = false;
      _editingSectionId = null;
      _sectionNameController.clear();
      _descriptionController.clear();
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.successColor),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.errorColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.labelSectionManagement),
        actions: [
          IconButton(
            onPressed: _loadSections,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Form Section
                Card(
                  margin: const EdgeInsets.all(AppSizes.marginMD),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMD),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? AppConstants.labelEditSection : AppConstants.labelAddNewSection,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSizes.marginMD),
                          TextFormField(
                            controller: _sectionNameController,
                            decoration: const InputDecoration(
                              labelText: AppConstants.labelSectionName,
                              hintText: AppConstants.hintSectionNameExamples,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppConstants.validationFieldRequired;
                              }
                              if (value.trim().length > 50) {
                                return AppConstants.msgNameTooLong50;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSizes.marginMD),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: AppConstants.labelDescriptionOptional,
                              hintText: AppConstants.hintSectionDescription,
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: AppSizes.marginMD),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: _submitForm,
                                child: Text(_isEditing ? AppConstants.labelUpdateSection : AppConstants.labelAddSection),
                              ),
                              const SizedBox(width: AppSizes.marginMD),
                              if (_isEditing)
                                TextButton(
                                  onPressed: _resetForm,
                                  child: const Text(AppConstants.actionCancel),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // List Section
                Expanded(
                  child: _sections.isEmpty
                      ? const Center(
                          child: Text(
                            AppConstants.msgNoSectionsFoundAddFirst,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMD),
                          itemCount: _sections.length,
                          itemBuilder: (context, index) {
                            final sectionMaster = _sections[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: AppSizes.marginSM),
                              child: ListTile(
                                title: Text(
                                  sectionMaster.sectionName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: sectionMaster.isActive ? null : AppColors.textSecondary,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (sectionMaster.description != null)
                                      Text(sectionMaster.description!),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSizes.paddingSM,
                                            vertical: AppSizes.paddingXS,
                                          ),
                                          decoration: BoxDecoration(
                                            color: sectionMaster.isActive
                                                ? AppColors.successColor
                                                : AppColors.errorColor,
                                            borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                                          ),
                                          child: Text(
                                            sectionMaster.isActive ? AppConstants.labelActive : AppConstants.labelInactive,
                                            style: const TextStyle(
                                              color: AppColors.textWhite,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        _editSection(sectionMaster);
                                        break;
                                      case 'toggle':
                                        _toggleStatus(sectionMaster);
                                        break;
                                      case 'delete':
                                        _deleteSection(sectionMaster);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: 8),
                                          Text(AppConstants.actionEdit),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Row(
                                        children: [
                                          Icon(sectionMaster.isActive
                                              ? Icons.visibility_off
                                              : Icons.visibility),
                                          const SizedBox(width: 8),
                                          Text(sectionMaster.isActive
                                              ? AppConstants.labelInactive
                                              : AppConstants.labelActive),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: AppColors.errorColor),
                                          SizedBox(width: 8),
                                          Text(AppConstants.actionDelete, style: TextStyle(color: AppColors.errorColor)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

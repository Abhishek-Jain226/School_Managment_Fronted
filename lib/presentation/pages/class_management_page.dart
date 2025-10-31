// lib/presentation/pages/class_management_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import '../../data/models/class_master.dart';
import '../../services/master_data_service.dart';

class ClassManagementPage extends StatefulWidget {
  const ClassManagementPage({super.key});

  @override
  State<ClassManagementPage> createState() => _ClassManagementPageState();
}

class _ClassManagementPageState extends State<ClassManagementPage> {
  final MasterDataService _service = MasterDataService();
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _classOrderController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<ClassMaster> _classes = [];
  bool _loading = true;
  bool _isEditing = false;
  int? _editingClassId;
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
      _loadClasses();
    } else {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.msgSchoolIdNotFoundLogin)),
        );
      }
    }
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _classOrderController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    if (_schoolId == null) return;
    
    setState(() => _loading = true);
    try {
      final response = await _service.getAllClasses(_schoolId!);
      if (response['success'] == true) {
        setState(() {
          _classes = (response['data'] as List)
              .map((json) => ClassMaster.fromJson(json))
              .toList();
        });
      } else {
        _showErrorSnackBar(response['message'] ?? AppConstants.msgFailedToLoadClasses);
      }
    } catch (e) {
      _showErrorSnackBar('${AppConstants.msgErrorLoadingClasses}$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final createdBy = prefs.getString(AppConstants.keyUserName) ?? 'Admin';

      final classMaster = ClassMaster(
        classId: _isEditing ? _editingClassId : null,
        className: _classNameController.text.trim(),
        classOrder: int.parse(_classOrderController.text.trim()),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        schoolId: _schoolId,
        createdBy: createdBy,
      );

      Map<String, dynamic> response;
      if (_isEditing) {
        response = await _service.updateClass(_editingClassId!, classMaster);
      } else {
        response = await _service.createClass(classMaster);
      }

      if (response['success'] == true) {
        _showSuccessSnackBar(_isEditing ? AppConstants.msgClassUpdatedSuccessfully : AppConstants.msgClassCreatedSuccessfully);
        _resetForm();
        _loadClasses();
      } else {
        _showErrorSnackBar(response['message'] ?? AppConstants.msgOperationFailed);
      }
    } catch (e) {
      _showErrorSnackBar('${AppConstants.labelError}: $e');
    }
  }

  Future<void> _deleteClass(ClassMaster classMaster) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppConstants.labelDeleteClass),
        content: Text('${AppConstants.msgDeleteConfirmation}${classMaster.className}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppConstants.labelCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppConstants.labelDelete, style: const TextStyle(color: AppColors.classMgmtErrorColor)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _service.deleteClass(classMaster.classId!);
        if (response['success'] == true) {
          _showSuccessSnackBar(AppConstants.msgClassDeletedSuccessfully);
          _loadClasses();
        } else {
          _showErrorSnackBar(response['message'] ?? AppConstants.msgFailedToDeleteClass);
        }
      } catch (e) {
        _showErrorSnackBar('${AppConstants.msgErrorDeletingClass}$e');
      }
    }
  }

  Future<void> _toggleStatus(ClassMaster classMaster) async {
    try {
      final response = await _service.toggleClassStatus(classMaster.classId!);
      if (response['success'] == true) {
        _showSuccessSnackBar(AppConstants.msgClassStatusUpdated);
        _loadClasses();
      } else {
        _showErrorSnackBar(response['message'] ?? AppConstants.msgFailedToUpdateStatus);
      }
    } catch (e) {
      _showErrorSnackBar('${AppConstants.msgErrorUpdatingStatus}$e');
    }
  }

  void _editClass(ClassMaster classMaster) {
    setState(() {
      _isEditing = true;
      _editingClassId = classMaster.classId;
      _classNameController.text = classMaster.className;
      _classOrderController.text = classMaster.classOrder.toString();
      _descriptionController.text = classMaster.description ?? '';
    });
  }

  void _resetForm() {
    setState(() {
      _isEditing = false;
      _editingClassId = null;
      _classNameController.clear();
      _classOrderController.clear();
      _descriptionController.clear();
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.classMgmtSuccessColor),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.classMgmtErrorColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.labelClassManagement),
        actions: [
          IconButton(
            onPressed: _loadClasses,
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
                  margin: const EdgeInsets.all(AppSizes.classMgmtPadding),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.classMgmtPadding),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? AppConstants.labelEditClass : AppConstants.labelAddNewClass,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSizes.classMgmtSpacingMD),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _classNameController,
                                  decoration: const InputDecoration(
                                    labelText: AppConstants.labelClassName,
                                    hintText: AppConstants.hintClassName,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return AppConstants.validationClassNameRequired;
                                    }
                                    if (value.trim().length > 50) {
                                      return AppConstants.validationClassNameMaxLength;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSizes.classMgmtSpacingMD),
                              Expanded(
                                child: TextFormField(
                                  controller: _classOrderController,
                                  decoration: const InputDecoration(
                                    labelText: AppConstants.labelOrder,
                                    hintText: AppConstants.hintClassOrder,
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return AppConstants.validationOrderRequired;
                                    }
                                    if (int.tryParse(value.trim()) == null) {
                                      return AppConstants.validationEnterValidNumber;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.classMgmtSpacingMD),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: AppConstants.labelDescriptionOptional,
                              hintText: AppConstants.hintClassDescription,
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: AppSizes.classMgmtSpacingMD),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: _submitForm,
                                child: Text(_isEditing ? AppConstants.labelUpdateClass : AppConstants.labelAddClass),
                              ),
                              const SizedBox(width: AppSizes.classMgmtSpacingMD),
                              if (_isEditing)
                                TextButton(
                                  onPressed: _resetForm,
                                  child: const Text(AppConstants.labelCancel),
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
                  child: _classes.isEmpty
                      ? const Center(
                          child: Text(
                            AppConstants.msgNoClassesFound,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: AppSizes.classMgmtEmptyTextSize, color: AppColors.classMgmtGreyColor),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.classMgmtPadding),
                          itemCount: _classes.length,
                          itemBuilder: (context, index) {
                            final classMaster = _classes[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: AppSizes.classMgmtCardMargin),
                              child: ListTile(
                                title: Text(
                                  classMaster.className,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: classMaster.isActive ? null : AppColors.classMgmtGreyColor,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${AppConstants.labelOrder}: ${classMaster.classOrder}'),
                                    if (classMaster.description != null)
                                      Text(classMaster.description!),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSizes.classMgmtStatusPaddingH,
                                            vertical: AppSizes.classMgmtStatusPaddingV,
                                          ),
                                          decoration: BoxDecoration(
                                            color: classMaster.isActive
                                                ? AppColors.classMgmtSuccessColor
                                                : AppColors.classMgmtErrorColor,
                                            borderRadius: BorderRadius.circular(AppSizes.classMgmtStatusRadius),
                                          ),
                                          child: Text(
                                            classMaster.isActive ? AppConstants.labelActive : AppConstants.labelInactive,
                                            style: const TextStyle(
                                              color: AppColors.classMgmtTextWhite,
                                              fontSize: AppSizes.classMgmtStatusFontSize,
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
                                        _editClass(classMaster);
                                        break;
                                      case 'toggle':
                                        _toggleStatus(classMaster);
                                        break;
                                      case 'delete':
                                        _deleteClass(classMaster);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: AppSizes.classMgmtSpacingSM),
                                          Text(AppConstants.labelEdit),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Row(
                                        children: [
                                          Icon(classMaster.isActive
                                              ? Icons.visibility_off
                                              : Icons.visibility),
                                          const SizedBox(width: AppSizes.classMgmtSpacingSM),
                                          Text(classMaster.isActive
                                              ? AppConstants.labelDeactivate
                                              : AppConstants.labelActivate),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: const [
                                          Icon(Icons.delete, color: AppColors.classMgmtErrorColor),
                                          SizedBox(width: AppSizes.classMgmtSpacingSM),
                                          Text(AppConstants.labelDelete, style: TextStyle(color: AppColors.classMgmtErrorColor)),
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

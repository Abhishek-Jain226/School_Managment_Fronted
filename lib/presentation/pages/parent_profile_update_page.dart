import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/parent/parent_bloc.dart';
import '../../bloc/parent/parent_event.dart';
import '../../bloc/parent/parent_state.dart';
import '../../utils/constants.dart';

class ParentProfileUpdatePage extends StatefulWidget {
  final Map<String, dynamic>? profileData;

  const ParentProfileUpdatePage({super.key, this.profileData});

  @override
  State<ParentProfileUpdatePage> createState() => _ParentProfileUpdatePageState();
}

class _ParentProfileUpdatePageState extends State<ParentProfileUpdatePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();

  Map<String, dynamic>? _profilePayload;
  int? _parentId;
  String? _studentName;
  String? _schoolName;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _error;

  Map<String, dynamic> get _profileData {
    final payload = _profilePayload;
    if (payload == null) return const <String, dynamic>{};
    final data = payload[AppConstants.keyData];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return payload;
  }

  Map<String, dynamic> get _dashboardData {
    final payload = _profilePayload;
    final data = payload?['dashboard'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return const <String, dynamic>{};
  }

  @override
  void initState() {
    super.initState();
    _profilePayload = widget.profileData;
    _initializeFields();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _initializeFields() {
    final sources = <Map<String, dynamic>>[
      _profileData,
      _dashboardData,
    ];

    for (final source in sources) {
      _parentId ??= _readInt(source, [AppConstants.keyUserId, 'parentId']);
      _studentName ??= _readString(source, [AppConstants.keyStudentName, 'student']);
      _schoolName ??= _readString(source, [AppConstants.keySchoolName]);

      final name = _readString(source, [AppConstants.keyParentName, AppConstants.keyName, AppConstants.keyUserName]);
      if (name.isNotEmpty && (!_isEditing || _nameController.text.isEmpty)) {
        _nameController.text = name;
      }

      final email = _readString(source, [AppConstants.keyEmail]);
      if (email.isNotEmpty && (!_isEditing || _emailController.text.isEmpty)) {
        _emailController.text = email;
      }

      final contact = _readString(source, [AppConstants.keyContactNumber, 'phone']);
      if (contact.isNotEmpty && (!_isEditing || _contactController.text.isEmpty)) {
        _contactController.text = contact;
      }
    }
  }

  String _readString(Map<String, dynamic> source, List<String> keys) {
    final result = _findInMap(source, keys);
    return result ?? '';
  }

  int? _readInt(Map<String, dynamic> source, List<String> keys) {
    final result = _findInMap(source, keys);
    if (result == null) return null;
    return int.tryParse(result);
  }

  String? _findInMap(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value is num) {
        return value.toString();
      }
    }
    for (final entry in map.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        final nested = _findInMap(value, keys);
        if (nested != null && nested.isNotEmpty) {
          return nested;
        }
      } else if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            final nested = _findInMap(item, keys);
            if (nested != null && nested.isNotEmpty) {
              return nested;
            }
          }
        }
      }
    }
    return null;
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      _error = null;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _isSaving = false;
      _error = null;
    });
    _initializeFields();
  }

  void _saveProfile() {
    if (_parentId == null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final payload = <String, dynamic>{
      'userName': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'contactNumber': _contactController.text.trim(),
      'createdBy': 'PARENT',
    };

    context.read<ParentBloc>().add(
          ParentUpdateRequested(parentId: _parentId!, parentData: payload),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ParentBloc, ParentState>(
      listener: (context, state) {
        if (state is ParentActionSuccess && state.actionType == AppConstants.actionTypeUpdateProfile) {
          setState(() {
            _isSaving = false;
            _isEditing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.statusSuccess,
            ),
          );
        } else if (state is ParentError && state.actionType == AppConstants.actionTypeUpdateProfile) {
          setState(() {
            _isSaving = false;
            _error = state.message;
          });
        } else if (state is ParentProfileLoaded) {
          setState(() {
            _profilePayload = {
              ...state.profile,
              if (_dashboardData.isNotEmpty) 'dashboard': _dashboardData,
            };
            _isSaving = false;
            _isEditing = false;
          });
          _initializeFields();
          setState(() {
            _error = null;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppConstants.labelProfileInformation),
          actions: [
            if (_isEditing) ...[
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: AppConstants.actionCancel,
                onPressed: _isSaving ? null : _cancelEditing,
              ),
              IconButton(
                icon: _isSaving
                    ? const SizedBox(
                        width: AppSizes.parentProfileLoadingSize,
                        height: AppSizes.parentProfileLoadingSize,
                        child: CircularProgressIndicator(strokeWidth: AppSizes.parentProfileLoadingStroke),
                      )
                    : const Icon(Icons.save),
                tooltip: AppConstants.actionSave,
                onPressed: _isSaving ? null : _saveProfile,
              ),
            ] else
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: AppConstants.actionEdit,
                onPressed: _toggleEditing,
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.parentPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_studentName != null || _schoolName != null)
                  Card(
                    elevation: AppSizes.parentProfileCardElevation,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.parentPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            AppConstants.labelProfileInformation,
                            style: TextStyle(
                              fontSize: AppSizes.parentProfileTitleFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSizes.parentSpacingSM),
                          if (_studentName != null && _studentName!.isNotEmpty)
                            _InfoTile(
                              icon: Icons.badge,
                              label: AppConstants.labelStudent,
                              value: _studentName!,
                            ),
                          if (_schoolName != null && _schoolName!.isNotEmpty)
                            _InfoTile(
                              icon: Icons.school,
                              label: AppConstants.labelSchool,
                              value: _schoolName!,
                            ),
                          if (_parentId != null)
                            _InfoTile(
                              icon: Icons.numbers,
                              label: AppConstants.labelUserId,
                              value: '#$_parentId',
                            ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSizes.parentSpacingMD),
                Card(
                  elevation: AppSizes.parentProfileCardElevation,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.parentPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppConstants.labelPersonalInformation,
                          style: TextStyle(
                            fontSize: AppSizes.parentProfileTitleFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSizes.parentSpacingSM),
                        TextFormField(
                          controller: _nameController,
                          enabled: _isEditing,
                          decoration: const InputDecoration(
                            labelText: AppConstants.labelFullName,
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (!_isEditing) return null;
                            if (value == null || value.trim().isEmpty) {
                              return AppConstants.msgEnterFullName;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSizes.parentSpacingMD),
                        TextFormField(
                          controller: _emailController,
                          enabled: _isEditing,
                          decoration: const InputDecoration(
                            labelText: AppConstants.labelEmail,
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (!_isEditing) return null;
                            if (value == null || value.trim().isEmpty) {
                              return AppConstants.msgEnterEmail;
                            }
                            final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!regex.hasMatch(value.trim())) {
                              return AppConstants.msgEnterValidEmail;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSizes.parentSpacingMD),
                        TextFormField(
                          controller: _contactController,
                          enabled: _isEditing,
                          decoration: const InputDecoration(
                            labelText: AppConstants.labelContactNumber,
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (!_isEditing) return null;
                            if (value == null || value.trim().isEmpty) {
                              return AppConstants.msgEnterContactNumber;
                            }
                            if (value.trim().length < AppSizes.parentProfileContactMinLength) {
                              return AppConstants.msgContactNumberMinLength;
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (_error != null && _error!.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.parentSpacingMD),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.parentProfileErrorPadding),
                    decoration: BoxDecoration(
                      color: AppColors.errorColor.withValues(alpha: 0.1),
                      border: Border.all(color: AppColors.errorColor),
                      borderRadius: BorderRadius.circular(AppSizes.parentProfileErrorRadius),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.errorColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.parentSpacingSM),
      child: Row(
        children: [
          Icon(icon, color: AppColors.parentPrimaryColor),
          const SizedBox(width: AppSizes.parentSpacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(value.isNotEmpty ? value : AppConstants.labelNA),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import '../../data/models/api_response.dart';
import '../../data/models/staff_request.dart';
import '../../data/models/role.dart';
import '../../services/school_service.dart';
import '../../services/role_service.dart';

class RegisterGateStaffPage extends StatefulWidget {
  @override
  _RegisterGateStaffPageState createState() => _RegisterGateStaffPageState();
}

class _RegisterGateStaffPageState extends State<RegisterGateStaffPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  final _displayNameController = TextEditingController();

  int? _roleId;
  bool _loading = false;
  List<Role> _availableRoles = [];
  bool _rolesLoading = true;

  final SchoolService _service = SchoolService();
  final RoleService _roleService = RoleService();

  @override
  void initState() {
    super.initState();
    _loadRoles();
    // Add listener for real-time display name update
    _displayNameController.addListener(() {
      setState(() {}); // Rebuild to show updated display name
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    try {
      setState(() => _rolesLoading = true);
      // Get only GATE_STAFF role
      final allRoles = await _roleService.getAllRoles();
      final gateStaffRole = allRoles.firstWhere(
        (role) => role.roleName == AppConstants.labelGateStaffRole,
        orElse: () => throw Exception(AppConstants.msgGateStaffRoleNotFound),
      );
      
      setState(() {
        _availableRoles = [gateStaffRole]; // Only GATE_STAFF role
        _roleId = gateStaffRole.roleId; // Set GATE_STAFF role ID
        _rolesLoading = false;
      });
    } catch (e) {
      setState(() => _rolesLoading = false);
      _showErrorSnackBar('${AppConstants.msgFailedToLoadGateStaffRole}$e');
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);
      try {
        final prefs = await SharedPreferences.getInstance();
        final int? schoolId = prefs.getInt(AppConstants.keySchoolId);
        final String createdBy = prefs.getString(AppConstants.keyUserName) ?? '';

        if (schoolId == null) {
          throw Exception(AppConstants.msgSchoolNotFoundPrefs);
        }

        // Use username as provided by SchoolAdmin
        String userName = _userNameController.text.trim();
        
        // Validate username is not empty
        if (userName.isEmpty) {
          throw Exception(AppConstants.msgUsernameRequired);
        }

        final request = StaffRequest(
          userName: userName,
          password: _passwordController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          contactNumber: _contactController.text.trim().isEmpty
              ? null
              : _contactController.text.trim(),
          schoolId: schoolId,
          roleId: _roleId!, // GATE_STAFF role ID
          createdBy: createdBy,
        );

        final ApiResponse response = await _service.createStaff(request);

        if (response.success) {
          String staffName = _nameController.text.trim();
          _showSuccessDialog(AppConstants.msgGateStaffCreatedSuccess.replaceFirst('%s', staffName));
        } else {
          _showErrorSnackBar(response.message ?? AppConstants.msgFailedToCreateStaff);
        }
      } catch (e) {
        _showErrorSnackBar('${AppConstants.labelError}: $e');
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text(AppConstants.msgStaffCreatedSuccessfully),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _resetForm();
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
        backgroundColor: Colors.red,
        duration: const Duration(seconds: AppSizes.registerGateStaffErrorDuration),
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _nameController.clear();
    _userNameController.clear();
    _passwordController.clear();
    _emailController.clear();
    _contactController.clear();
    _displayNameController.clear();
    setState(() {
      // Reset to GATE_STAFF role (first and only role)
      if (_availableRoles.isNotEmpty) {
        _roleId = _availableRoles.first.roleId; // First (and only) role is GATE_STAFF
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.labelRegisterGateStaff)),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.registerGateStaffPadding),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Staff Name Field (Required)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: AppConstants.labelStaffNameRequired,
                  hintText: AppConstants.hintStaffName,
                  prefixIcon: Icon(Icons.person, color: Colors.blue),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return AppConstants.msgEnterStaffName;
                  if (val.length < AppSizes.registerGateStaffNameMinLength) return AppConstants.msgNameMinChars;
                  if (val.length > AppSizes.registerGateStaffNameMaxLength) return AppConstants.msgNameMaxChars;
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.registerGateStaffSpacing),
              // Username Field (Optional - Auto-generated)
              TextFormField(
                controller: _userNameController,
                decoration: const InputDecoration(
                  labelText: AppConstants.labelUsernameRequired,
                  hintText: AppConstants.hintUniqueUsername,
                  suffixIcon: Icon(Icons.person, color: Colors.blue),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return AppConstants.msgUsernameRequired;
                  if (val.length < AppSizes.registerGateStaffUsernameMinLength) return AppConstants.msgUsernameMinChars;
                  if (val.length > AppSizes.registerGateStaffUsernameMaxLength) return AppConstants.msgUsernameMaxChars;
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.registerGateStaffSpacing),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: AppConstants.labelPassword,
                  hintText: AppConstants.hintPassword,
                ),
                obscureText: true,
                validator: (val) {
                  if (val == null || val.isEmpty) return AppConstants.msgEnterPassword;
                  if (val.length < AppSizes.registerGateStaffPasswordMinLength) return AppConstants.msgPasswordMinLength;
                  if (val.length > AppSizes.registerGateStaffPasswordMaxLength) return AppConstants.msgPasswordMaxChars;
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.registerGateStaffSpacing),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: AppConstants.labelEmailOptionalLower,
                  hintText: AppConstants.hintEmailAddressGeneral,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.isEmpty) return null; // Optional field
                  if (val.length > AppSizes.registerGateStaffEmailMaxLength) return AppConstants.msgEmailMaxChars;
                  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                  return emailRegex.hasMatch(val) ? null : AppConstants.msgEnterValidEmail;
                },
              ),
              const SizedBox(height: AppSizes.registerGateStaffSpacing),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: AppConstants.labelContactNumber,
                  hintText: AppConstants.hintMobileNumber,
                ),
                keyboardType: TextInputType.phone,
                maxLength: AppSizes.registerGateStaffContactLength,
                validator: (val) {
                  if (val == null || val.isEmpty) return AppConstants.msgEnterContactNumber;
                  final digits = val.replaceAll(RegExp(r'\D'), '');
                  if (digits.length != AppSizes.registerGateStaffContactLength) return AppConstants.msgContactNumberMustBe10Digits;
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) return AppConstants.msgEnterValidIndianMobile;
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.registerGateStaffSpacing),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: AppConstants.labelDisplayNameOptional,
                  hintText: AppConstants.hintDisplayName,
                ),
                validator: (val) {
                  if (val != null && val.length > AppSizes.registerGateStaffDisplayNameMaxLength) return AppConstants.msgDisplayNameMaxChars;
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.registerGateStaffSpacing),
              // Role Display (Read-only - GATE_STAFF only)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.registerGateStaffContainerPadding,
                  vertical: AppSizes.registerGateStaffContainerPaddingV,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(AppSizes.registerGateStaffBorderRadius),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: Colors.blue),
                    const SizedBox(width: AppSizes.registerGateStaffSpacing),
                    Text(
                      _rolesLoading ? AppConstants.labelLoading : AppConstants.labelGateStaff,
                      style: const TextStyle(
                        fontSize: AppSizes.registerGateStaffFontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.registerGateStaffSpacing),
              // Display Name Preview
              if (_displayNameController.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSizes.registerGateStaffContainerPadding),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: AppSizes.registerGateStaffOpacity),
                    borderRadius: BorderRadius.circular(AppSizes.registerGateStaffBorderRadius2),
                    border: Border.all(color: Colors.blue.withValues(alpha: AppSizes.registerGateStaffOpacity2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: AppSizes.registerGateStaffIconSize),
                      const SizedBox(width: AppSizes.registerGateStaffSpacingSM),
                      Text(
                        '${AppConstants.labelWillBeDisplayedAs}${_displayNameController.text}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSizes.registerGateStaffSpacingLG),
              ElevatedButton(
                onPressed: (_loading || _rolesLoading) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.registerGateStaffButtonPadding),
                ),
                child: _loading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: AppSizes.registerGateStaffLoaderSize,
                            height: AppSizes.registerGateStaffLoaderSize,
                            child: CircularProgressIndicator(strokeWidth: AppSizes.registerGateStaffLoaderStroke),
                          ),
                          SizedBox(width: AppSizes.registerGateStaffSpacing),
                          Text(AppConstants.labelCreatingStaff),
                        ],
                      )
                    : _rolesLoading
                        ? const Text(AppConstants.labelLoading)
                        : const Text(AppConstants.labelCreateGateStaff),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

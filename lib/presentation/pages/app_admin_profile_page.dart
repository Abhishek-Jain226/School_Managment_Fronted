import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppAdminProfilePage extends StatefulWidget {
  const AppAdminProfilePage({super.key});

  @override
  State<AppAdminProfilePage> createState() => _AppAdminProfilePageState();
}

class _AppAdminProfilePageState extends State<AppAdminProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _nameController.text = prefs.getString(AppConstants.keyUserName) ?? 
            AppConstants.defaultAppAdminName;
        _emailController.text = prefs.getString(AppConstants.keyEmail) ?? 
            AppConstants.defaultAppAdminEmail;
        _mobileController.text = prefs.getString(AppConstants.keyContactNumber) ?? 
            AppConstants.defaultAppAdminMobile;
        _isLoading = false;
      });
    } catch (e) {
      _showSnackBar(
        '${AppConstants.msgErrorLoadingProfile}$e',
        AppColors.profileErrorColor,
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Update local storage
      await prefs.setString(
        AppConstants.keyUserName,
        _nameController.text.trim(),
      );
      await prefs.setString(
        AppConstants.keyEmail,
        _emailController.text.trim(),
      );
      await prefs.setString(
        AppConstants.keyContactNumber,
        _mobileController.text.trim(),
      );
      
      setState(() => _isEditing = false);
      _showSnackBar(
        AppConstants.msgProfileUpdatedSuccessfully,
        AppColors.profileSuccessColor,
      );
      
    } catch (e) {
      _showSnackBar(
        '${AppConstants.msgErrorUpdatingProfile}$e',
        AppColors.profileErrorColor,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.labelAppAdminProfile),
        backgroundColor: AppColors.profileAppBarColor,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.profilePadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Card
                    Card(
                      elevation: AppSizes.profileCardElevation,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.profileCardRadius,
                        ),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSizes.profileCardPadding),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.profileAppBarColor.shade700,
                              AppColors.profileAppBarColor.shade400,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSizes.profileCardRadius,
                          ),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: AppSizes.profileAvatarRadius,
                              backgroundColor: AppColors.profileAvatarBackgroundColor,
                              child: Icon(
                                Icons.admin_panel_settings,
                                size: AppSizes.profileAvatarIconSize,
                                color: AppColors.profileAppBarColor.shade700,
                              ),
                            ),
                            const SizedBox(height: AppSizes.profileSpacingMD),
                            Text(
                              _nameController.text,
                              style: const TextStyle(
                                fontSize: AppSizes.profileNameFontSize,
                                fontWeight: FontWeight.bold,
                                color: AppColors.profileTextWhite,
                              ),
                            ),
                            const SizedBox(height: AppSizes.profileSpacingSM),
                            Text(
                              AppConstants.labelAppAdministrator,
                              style: TextStyle(
                                fontSize: AppSizes.profileRoleFontSize,
                                color: AppColors.profileAppBarColor.shade100,
                              ),
                            ),
                            const SizedBox(height: AppSizes.profileSpacingXS),
                            Text(
                              _emailController.text,
                              style: TextStyle(
                                fontSize: AppSizes.profileEmailFontSize,
                                color: AppColors.profileAppBarColor.shade100,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppSizes.profileSpacingLG),
                    
                    // Profile Details Card
                    Card(
                      elevation: AppSizes.profileDetailsCardElevation,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.profileDetailsCardRadius,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.profileCardPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  color: AppColors.profileAppBarColor,
                                ),
                                SizedBox(width: AppSizes.profileSpacingSM),
                                Text(
                                  AppConstants.labelProfileInformation,
                                  style: TextStyle(
                                    fontSize: AppSizes.profileHeaderFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.profileSpacingXL),
                            
                            // Name Field
                            TextFormField(
                              controller: _nameController,
                              enabled: _isEditing,
                              decoration: InputDecoration(
                                labelText: AppConstants.labelFullName,
                                prefixIcon: const Icon(Icons.person_outline),
                                border: const OutlineInputBorder(),
                                filled: !_isEditing,
                                fillColor: _isEditing 
                                    ? null 
                                    : AppColors.profileAppBarColor.shade100,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return AppConstants.validationEnterName;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSizes.profileSpacingMD),
                            
                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              enabled: _isEditing,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: AppConstants.labelEmailAddress,
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: const OutlineInputBorder(),
                                filled: !_isEditing,
                                fillColor: _isEditing 
                                    ? null 
                                    : AppColors.profileAppBarColor.shade100,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return AppConstants.validationEnterEmail;
                                }
                                if (!RegExp(AppConstants.regexEmail).hasMatch(value)) {
                                  return AppConstants.validationEnterValidEmail;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSizes.profileSpacingMD),
                            
                            // Mobile Field
                            TextFormField(
                              controller: _mobileController,
                              enabled: _isEditing,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: AppConstants.labelMobileNumber,
                                prefixIcon: const Icon(Icons.phone_outlined),
                                border: const OutlineInputBorder(),
                                filled: !_isEditing,
                                fillColor: _isEditing 
                                    ? null 
                                    : AppColors.profileAppBarColor.shade100,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return AppConstants.validationEnterMobile;
                                }
                                if (!RegExp(AppConstants.regexPhone10Digit).hasMatch(value)) {
                                  return AppConstants.validationEnterValid10DigitMobile;
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppSizes.profileSpacingLG),
                    
                    // Account Information Card
                    Card(
                      elevation: AppSizes.profileDetailsCardElevation,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.profileDetailsCardRadius,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.profileCardPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.profileAppBarColor,
                                ),
                                SizedBox(width: AppSizes.profileSpacingSM),
                                Text(
                                  AppConstants.labelAccountInformation,
                                  style: TextStyle(
                                    fontSize: AppSizes.profileHeaderFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.profileSpacingXL),
                            
                            _buildInfoRow(
                              AppConstants.labelUserId,
                              AppConstants.defaultAppAdminUserId,
                            ),
                            _buildInfoRow(
                              AppConstants.labelRole,
                              AppConstants.labelAppAdministrator,
                            ),
                            _buildInfoRow(
                              AppConstants.labelAccountStatus,
                              AppConstants.defaultAccountStatusActive,
                              AppColors.profileSuccessColor,
                            ),
                            _buildInfoRow(
                              AppConstants.labelLastLogin,
                              AppConstants.defaultLastLoginJustNow,
                            ),
                            _buildInfoRow(
                              AppConstants.labelAccountCreated,
                              AppConstants.defaultAccountCreatedSystem,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppSizes.profileSpacingLG),
                    
                    // Action Buttons
                    if (_isEditing) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : () {
                                setState(() => _isEditing = false);
                                _loadAdminData(); // Reset to original values
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.profileCancelButtonColor,
                                foregroundColor: AppColors.profileTextWhite,
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSizes.profileButtonPaddingVertical,
                                ),
                              ),
                              child: const Text(AppConstants.labelCancel),
                            ),
                          ),
                          const SizedBox(width: AppSizes.profileSpacingMD),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.profileAppBarColor,
                                foregroundColor: AppColors.profileTextWhite,
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSizes.profileButtonPaddingVertical,
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: AppSizes.profileSavingIndicatorSize,
                                      height: AppSizes.profileSavingIndicatorSize,
                                      child: CircularProgressIndicator(
                                        strokeWidth: AppSizes.profileSavingIndicatorStroke,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.profileTextWhite,
                                        ),
                                      ),
                                    )
                                  : const Text(AppConstants.labelSaveChanges),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: AppSizes.profileSpacingLG),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSizes.profileInfoRowBottomPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSizes.profileInfoLabelWidth,
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.profileInfoLabelFontSize,
                color: AppColors.profileAppBarColor.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppSizes.profileInfoLabelFontSize,
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppColors.profileTextBlack87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }
}

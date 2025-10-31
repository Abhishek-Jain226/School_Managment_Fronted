import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/parent_service.dart';
import '../../utils/constants.dart';
import '../../bloc/parent/parent_bloc.dart';
import '../../bloc/parent/parent_event.dart';
import '../../bloc/parent/parent_state.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';

class ParentProfileUpdatePage extends StatefulWidget {
  final Map<String, dynamic>? profileData;
  
  const ParentProfileUpdatePage({super.key, this.profileData});

  @override
  State<ParentProfileUpdatePage> createState() => _ParentProfileUpdatePageState();
}

class _ParentProfileUpdatePageState extends State<ParentProfileUpdatePage> {
  final ParentService _parentService = ParentService();
  final _formKey = GlobalKey<FormState>();
  
  int? _userId;
  bool _isLoading = false;
  bool _isSaving = false;
  String _error = '';
  
  // Form controllers
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    // If profile data passed from navigation, use it; otherwise load via BLoC
    if (widget.profileData != null) {
      _loadProfileData(widget.profileData!);
    } else {
      _loadUserId();
    }
  }
  
  void _loadProfileData(Map<String, dynamic> profileData) {
    // Extract profile data from response
    final data = profileData[AppConstants.keyData] ?? profileData;
    setState(() {
      _userNameController.text = data['parentName'] ?? data['name'] ?? data['userName'] ?? '';
      _emailController.text = data['email'] ?? '';
      _contactNumberController.text = data['contactNumber'] ?? data['phone'] ?? '';
    });
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _contactNumberController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt(AppConstants.keyUserId);
    });
    
    if (_userId != null) {
      _loadUserData();
    } else {
      setState(() {
        _error = AppConstants.msgUserIdNotFoundLogin;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    if (_userId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Try to get parent profile via BLoC first
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated && authState.userId != null) {
        // Request profile via BLoC
        context.read<ParentBloc>().add(
          ParentProfileRequested(parentId: authState.userId!),
        );
        // Wait for BLoC to load profile, or fallback to direct service call
      }
      
      // Fallback: Get parent data by userId directly
      final response = await _parentService.getParentByUserId(_userId!);
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        setState(() {
          _userNameController.text = data['parentName'] ?? data['name'] ?? data['userName'] ?? '';
          _emailController.text = data['email'] ?? '';
          _contactNumberController.text = data['contactNumber'] ?? data['phone'] ?? '';
        });
      } else {
        // Try getParentProfile as fallback
        final profileResponse = await _parentService.getParentProfile(_userId!);
        if (profileResponse['success'] == true) {
          final profileData = profileResponse[AppConstants.keyData] ?? profileResponse;
          setState(() {
            _userNameController.text = profileData['parentName'] ?? profileData['name'] ?? profileData['userName'] ?? '';
            _emailController.text = profileData['email'] ?? '';
            _contactNumberController.text = profileData['contactNumber'] ?? profileData['phone'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('🔍 Error loading user data: $e');
      setState(() {
        _error = '${AppConstants.msgErrorLoadingUserData}$e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    _error = ''; // Clear previous errors
    
    try {
      final request = {
        'userName': _userNameController.text.trim(),
        'email': _emailController.text.trim(),
        'contactNumber': _contactNumberController.text.trim(),
        'createdBy': 'PARENT',
      };
      
      // Add password if provided
      if (_newPasswordController.text.isNotEmpty) {
        request['password'] = _newPasswordController.text.trim();
      }
      
      // Use BLoC to update profile
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated && authState.userId != null) {
        context.read<ParentBloc>().add(
          ParentUpdateRequested(
            parentId: authState.userId!,
            parentData: request,
          ),
        );
        // State updates will be handled by BlocListener
      } else {
        // Fallback to direct service call
        final response = await _parentService.updateParentProfile(_userId!, request);
        
        if (response['success'] == true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppConstants.msgProfileUpdatedSuccessfully),
              backgroundColor: AppColors.statusSuccess,
            ),
          );
          
          // Clear password fields
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          
          // Go back to dashboard
          Navigator.pop(context);
        } else {
          setState(() {
            _error = response['message'] ?? AppConstants.msgFailedToUpdateProfile;
            _isSaving = false;
          });
        }
      }
    } catch (e) {
      debugPrint('🔍 Error updating profile: $e');
      setState(() {
        _error = '${AppConstants.msgErrorUpdatingProfile}$e';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ParentBloc, ParentState>(
      listener: (context, state) {
        if (state is ParentProfileLoaded) {
          // Load profile data from BLoC
          _loadProfileData(state.profile);
          setState(() => _isLoading = false);
        } else if (state is ParentError && state.actionType == AppConstants.actionTypeLoadProfile) {
          setState(() {
            _error = state.message;
            _isLoading = false;
          });
        } else if (state is ParentActionSuccess && state.actionType == AppConstants.actionTypeUpdateProfile) {
          // Profile updated successfully
          setState(() {
            _isSaving = false;
          });
          
          // Clear password fields
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.statusSuccess,
              ),
            );
            Navigator.pop(context);
          }
        } else if (state is ParentError && state.actionType == AppConstants.actionTypeUpdateProfile) {
          setState(() {
            _error = state.message;
            _isSaving = false;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.edit, size: AppSizes.parentProfileIconSize),
              SizedBox(width: AppSizes.parentProfileIconSpacing),
              Text(AppConstants.labelUpdateProfile),
            ],
          ),
        ),
        body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty && _userNameController.text.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error, style: const TextStyle(color: AppColors.errorColor, fontSize: AppSizes.parentProfileErrorFontSize)),
                      const SizedBox(height: AppSizes.parentProfileErrorSpacing),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        child: const Text(AppConstants.labelRetry),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.parentProfilePadding),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Error Message
                        if (_error.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSizes.parentProfileErrorPadding),
                            margin: const EdgeInsets.only(bottom: AppSizes.parentProfileSpacing),
                            decoration: BoxDecoration(
                              color: AppColors.errorColor.withValues(alpha: AppSizes.parentProfileErrorOpacity),
                              border: Border.all(color: AppColors.errorColor),
                              borderRadius: BorderRadius.circular(AppSizes.parentProfileErrorRadius),
                            ),
                            child: Text(
                              _error,
                              style: const TextStyle(color: AppColors.errorColor),
                            ),
                          ),
                        
                        // Profile Information Card
                        Card(
                          elevation: AppSizes.parentProfileCardElevation,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.parentProfilePadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  AppConstants.labelProfileInformation,
                                  style: TextStyle(fontSize: AppSizes.parentProfileTitleFontSize, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: AppSizes.parentProfileSpacing),
                                
                                // User Name
                                TextFormField(
                                  controller: _userNameController,
                                  decoration: const InputDecoration(
                                    labelText: AppConstants.labelFullName,
                                    prefixIcon: Icon(Icons.person),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return AppConstants.msgEnterFullName;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSizes.parentProfileSpacing),
                                
                                // Email
                                TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    labelText: AppConstants.labelEmail,
                                    prefixIcon: Icon(Icons.email),
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return AppConstants.msgEnterEmail;
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return AppConstants.msgEnterValidEmail;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSizes.parentProfileSpacing),
                                
                                // Contact Number
                                TextFormField(
                                  controller: _contactNumberController,
                                  decoration: const InputDecoration(
                                    labelText: AppConstants.labelContactNumber,
                                    prefixIcon: Icon(Icons.phone),
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return AppConstants.msgEnterContactNumber;
                                    }
                                    if (value.length < AppSizes.parentProfileContactMinLength) {
                                      return AppConstants.msgContactNumberMinLength;
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.parentProfileSpacing),
                        
                        // Password Change Card
                        Card(
                          elevation: AppSizes.parentProfileCardElevation,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.parentProfilePadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  AppConstants.labelChangePasswordOptional,
                                  style: TextStyle(fontSize: AppSizes.parentProfileTitleFontSize, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: AppSizes.parentProfileSpacingSM),
                                const Text(
                                  AppConstants.labelPasswordHint,
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: AppSizes.parentProfileHintFontSize),
                                ),
                                const SizedBox(height: AppSizes.parentProfileSpacing),
                                
                                // Current Password
                                TextFormField(
                                  controller: _currentPasswordController,
                                  decoration: InputDecoration(
                                    labelText: AppConstants.labelCurrentPassword,
                                    prefixIcon: const Icon(Icons.lock),
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscureCurrentPassword ? Icons.visibility : Icons.visibility_off),
                                      onPressed: () {
                                        setState(() {
                                          _obscureCurrentPassword = !_obscureCurrentPassword;
                                        });
                                      },
                                    ),
                                  ),
                                  obscureText: _obscureCurrentPassword,
                                ),
                                const SizedBox(height: AppSizes.parentProfileSpacing),
                                
                                // New Password
                                TextFormField(
                                  controller: _newPasswordController,
                                  decoration: InputDecoration(
                                    labelText: AppConstants.labelNewPassword,
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                                      onPressed: () {
                                        setState(() {
                                          _obscureNewPassword = !_obscureNewPassword;
                                        });
                                      },
                                    ),
                                  ),
                                  obscureText: _obscureNewPassword,
                                  validator: (value) {
                                    if (_newPasswordController.text.isNotEmpty) {
                                      if (value == null || value.length < AppSizes.parentProfilePasswordMinLength) {
                                        return AppConstants.msgPasswordMinLength;
                                      }
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSizes.parentProfileSpacing),
                                
                                // Confirm Password
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  decoration: InputDecoration(
                                    labelText: AppConstants.labelConfirmNewPassword,
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword = !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                  ),
                                  obscureText: _obscureConfirmPassword,
                                  validator: (value) {
                                    if (_newPasswordController.text.isNotEmpty) {
                                      if (value != _newPasswordController.text) {
                                        return AppConstants.msgPasswordsDoNotMatch;
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.parentProfileSpacingLG),
                        
                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: AppSizes.parentProfileButtonHeight,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: AppColors.textWhite,
                            ),
                            child: _isSaving
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: AppSizes.parentProfileLoadingSize,
                                        height: AppSizes.parentProfileLoadingSize,
                                        child: CircularProgressIndicator(
                                          strokeWidth: AppSizes.parentProfileLoadingStroke,
                                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                                        ),
                                      ),
                                      SizedBox(width: AppSizes.parentProfileLoadingSpacing),
                                      Text(AppConstants.labelUpdating),
                                    ],
                                  )
                                : const Text(
                                    AppConstants.labelUpdateProfile,
                                    style: TextStyle(fontSize: AppSizes.parentProfileButtonFontSize, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}

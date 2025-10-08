import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/parent_service.dart';

class ParentProfileUpdatePage extends StatefulWidget {
  const ParentProfileUpdatePage({super.key});

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
    _loadUserId();
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
      _userId = prefs.getInt('userId');
    });
    
    if (_userId != null) {
      _loadUserData();
    } else {
      setState(() {
        _error = 'User ID not found. Please login again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    if (_userId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Get parent data by userId
      final response = await _parentService.getParentByUserId(_userId!);
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        setState(() {
          _userNameController.text = data['parentName'] ?? '';
          _emailController.text = data['email'] ?? '';
          _contactNumberController.text = data['contactNumber'] ?? '';
        });
      }
    } catch (e) {
      print('🔍 Error loading user data: $e');
      setState(() {
        _error = 'Error loading user data: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final request = {
        'userName': _userNameController.text.trim(),
        'email': _emailController.text.trim(),
        'contactNumber': _contactNumberController.text.trim(),
        'createdBy': 'PARENT', // or get from user data
      };
      
      // Add password if provided
      if (_newPasswordController.text.isNotEmpty) {
        request['password'] = _newPasswordController.text.trim();
      }
      
      final response = await _parentService.updateParentProfile(_userId!, request);
      
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
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
          _error = response['message'] ?? 'Failed to update profile';
        });
      }
    } catch (e) {
      print('🔍 Error updating profile: $e');
      setState(() {
        _error = 'Error updating profile: $e';
      });
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.edit, size: 28),
            SizedBox(width: 8),
            Text("Update Profile"),
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
                      Text(_error, style: const TextStyle(color: Colors.red, fontSize: 16)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Error Message
                        if (_error.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              border: Border.all(color: Colors.red),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _error,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        
                        // Profile Information Card
                        Card(
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Profile Information",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                
                                // User Name
                                TextFormField(
                                  controller: _userNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Full Name',
                                    prefixIcon: Icon(Icons.person),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your full name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                // Email
                                TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email),
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                // Contact Number
                                TextFormField(
                                  controller: _contactNumberController,
                                  decoration: const InputDecoration(
                                    labelText: 'Contact Number',
                                    prefixIcon: Icon(Icons.phone),
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your contact number';
                                    }
                                    if (value.length < 10) {
                                      return 'Contact number must be at least 10 digits';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Password Change Card
                        Card(
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Change Password (Optional)",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Leave password fields empty if you don't want to change password",
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                const SizedBox(height: 16),
                                
                                // Current Password
                                TextFormField(
                                  controller: _currentPasswordController,
                                  decoration: InputDecoration(
                                    labelText: 'Current Password',
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
                                const SizedBox(height: 16),
                                
                                // New Password
                                TextFormField(
                                  controller: _newPasswordController,
                                  decoration: InputDecoration(
                                    labelText: 'New Password',
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
                                      if (value == null || value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                // Confirm Password
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  decoration: InputDecoration(
                                    labelText: 'Confirm New Password',
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
                                        return 'Passwords do not match';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: _isSaving
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Updating...'),
                                    ],
                                  )
                                : const Text(
                                    'Update Profile',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

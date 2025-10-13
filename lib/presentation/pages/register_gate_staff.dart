import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  int? _schoolId;
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
        (role) => role.roleName == 'GATE_STAFF',
        orElse: () => throw Exception('GATE_STAFF role not found in database'),
      );
      
      setState(() {
        _availableRoles = [gateStaffRole]; // Only GATE_STAFF role
        _roleId = gateStaffRole.roleId; // Set GATE_STAFF role ID
        _rolesLoading = false;
      });
    } catch (e) {
      setState(() => _rolesLoading = false);
      _showErrorSnackBar("Failed to load GATE_STAFF role: $e");
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);
      try {
        final prefs = await SharedPreferences.getInstance();
        final int? schoolId = prefs.getInt('schoolId');
        final String createdBy = prefs.getString('userName') ?? '';

        if (schoolId == null) {
          throw Exception("School not found in preferences");
        }

        // Use username as provided by SchoolAdmin
        String userName = _userNameController.text.trim();
        
        // Validate username is not empty
        if (userName.isEmpty) {
          throw Exception("Username is required");
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
          _showSuccessDialog("Gate Staff '$staffName' created successfully!");
        } else {
          _showErrorSnackBar(response.message ?? "Failed to create staff");
        }
      } catch (e) {
        _showErrorSnackBar("Error: $e");
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
        title: const Text("Staff Created Successfully!"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _resetForm();
              Navigator.pop(context, true); // return true so dashboard can refresh
            },
            child: const Text("OK"),
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
        duration: const Duration(seconds: 4),
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
      _schoolId = null;
      // Reset to GATE_STAFF role (first and only role)
      if (_availableRoles.isNotEmpty) {
        _roleId = _availableRoles.first.roleId; // First (and only) role is GATE_STAFF
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register Gate Staff")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Staff Name Field (Required)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Staff Name *",
                  hintText: "Enter staff name (e.g., Sunita, Rajesh)",
                  prefixIcon: Icon(Icons.person, color: Colors.blue),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Enter staff name";
                  if (val.length < 2) return "Name must be at least 2 characters";
                  if (val.length > 50) return "Name must not exceed 50 characters";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Username Field (Optional - Auto-generated)
              TextFormField(
                controller: _userNameController,
                decoration: const InputDecoration(
                  labelText: "Username *",
                  hintText: "Enter unique username",
                  suffixIcon: Icon(Icons.person, color: Colors.blue),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Username is required";
                  if (val.length < 3) return "Username must be at least 3 characters";
                  if (val.length > 50) return "Username must not exceed 50 characters";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Password",
                  hintText: "Enter password (6-100 characters)",
                ),
                obscureText: true,
                validator: (val) {
                  if (val == null || val.isEmpty) return "Enter password";
                  if (val.length < 6) return "Password must be at least 6 characters";
                  if (val.length > 100) return "Password must not exceed 100 characters";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email (optional)",
                  hintText: "Enter email address",
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.isEmpty) return null; // Optional field
                  if (val.length > 150) return "Email must not exceed 150 characters";
                  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                  return emailRegex.hasMatch(val) ? null : "Enter valid email address";
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: "Contact Number",
                  hintText: "Enter 10-digit mobile number",
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: (val) {
                  if (val == null || val.isEmpty) return "Enter contact number";
                  final digits = val.replaceAll(RegExp(r'\D'), '');
                  if (digits.length != 10) return "Contact number must be 10 digits";
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) return "Enter valid Indian mobile number";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: "Display Name (Optional)",
                  hintText: "e.g., Teacher, Staff Member, etc.",
                ),
                validator: (val) {
                  if (val != null && val.length > 50) return "Display name must not exceed 50 characters";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Role Display (Read-only - GATE_STAFF only)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: Colors.blue),
                    const SizedBox(width: 12),
                    Text(
                      _rolesLoading ? "Loading..." : "Gate Staff",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Display Name Preview
              if (_displayNameController.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Will be displayed as: ${_displayNameController.text}",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: (_loading || _rolesLoading) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text("Creating Staff..."),
                        ],
                      )
                    : _rolesLoading
                        ? const Text("Loading...")
                        : const Text("Create Gate Staff"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/api_response.dart';
import '../../data/models/staff_request.dart';
import '../../services/school_service.dart';

class RegisterGateStaffPage extends StatefulWidget {
  @override
  _RegisterGateStaffPageState createState() => _RegisterGateStaffPageState();
}

class _RegisterGateStaffPageState extends State<RegisterGateStaffPage> {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();

  int? _schoolId;
  int? _roleId;
  bool _loading = false;

  final SchoolService _service = SchoolService();

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

        final request = StaffRequest(
          userName: _userNameController.text.trim(),
          password: _passwordController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          contactNumber: _contactController.text.trim().isEmpty
              ? null
              : _contactController.text.trim(),
          schoolId: schoolId,
          roleId: _roleId ?? 3, // Default to Gate Staff role
          createdBy: createdBy,
        );

        final ApiResponse response = await _service.createStaff(request);

        if (response.success) {
          _showSuccessDialog(response.message ?? "Staff created successfully");
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
    _userNameController.clear();
    _passwordController.clear();
    _emailController.clear();
    _contactController.clear();
    setState(() {
      _schoolId = null;
      _roleId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register Staff")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _userNameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  hintText: "Enter username (3-50 characters)",
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Enter username";
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
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: "Select Role"),
                value: _roleId,
                items: const [
                  DropdownMenuItem(value: 3, child: Text("Gate Staff")),
                  DropdownMenuItem(value: 4, child: Text("Teacher")),
                  DropdownMenuItem(value: 5, child: Text("Driver")),
                ],
                onChanged: (val) => setState(() => _roleId = val),
                validator: (val) => val == null ? "Please select a role" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
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
                    : const Text("Create Staff"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
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

  final SchoolService _service = SchoolService();

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        final request = StaffRequest(
          userName: _userNameController.text.trim(),
          password: _passwordController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          contactNumber: _contactController.text.trim().isEmpty
              ? null
              : _contactController.text.trim(),
          schoolId: _schoolId ?? 1, // TODO: dynamic school ID
          roleId: _roleId ?? 3,     // TODO: dynamic role ID
          createdBy: "school_admin", // TODO: replace with logged-in admin
        );

        final ApiResponse response = await _service.createStaff(request);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? "No message"),
            backgroundColor: response.success ? Colors.green : Colors.red,
          ),
        );

        if (response.success) {
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
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                decoration: const InputDecoration(labelText: "Username"),
                validator: (val) => val!.isEmpty ? "Enter username" : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (val) => val!.isEmpty ? "Enter password" : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email (optional)"),
              ),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: "Contact Number"),
                validator: (val) =>
                    val!.isEmpty ? "Enter contact number" : null,
              ),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: "Select School"),
                value: _schoolId,
                items: const [
                  DropdownMenuItem(value: 1, child: Text("School A")),
                  DropdownMenuItem(value: 2, child: Text("School B")),
                ],
                onChanged: (val) => setState(() => _schoolId = val),
                validator: (val) =>
                    val == null ? "Please select a school" : null,
              ),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: "Select Role"),
                value: _roleId,
                items: const [
                  DropdownMenuItem(value: 3, child: Text("Gate Staff")),
                  DropdownMenuItem(value: 4, child: Text("Teacher")),
                ],
                onChanged: (val) => setState(() => _roleId = val),
                validator: (val) => val == null ? "Please select a role" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text("Create Staff"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

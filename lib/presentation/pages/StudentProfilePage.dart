import 'package:flutter/material.dart';
import '../../services/parent_service.dart';

class StudentProfilePage extends StatefulWidget {
  final int studentId; // ✅ StudentId pass from dashboard

  const StudentProfilePage({Key? key, required this.studentId}) : super(key: key);

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtl = TextEditingController();
  final _lastNameCtl = TextEditingController();
  final _classCtl = TextEditingController();
  final _sectionCtl = TextEditingController();
  final _fatherCtl = TextEditingController();
  final _motherCtl = TextEditingController();
  final _contactCtl = TextEditingController();
  final _altContactCtl = TextEditingController();
  final _emailCtl = TextEditingController();

  final _service = ParentService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  Future<void> _loadStudent() async {
    try {
      final resp = await _service.getStudentById(widget.studentId);
      if (resp['success'] == true && resp['data'] != null) {
        final data = resp['data'];
        setState(() {
          _firstNameCtl.text = data['firstName'] ?? "";
          _lastNameCtl.text = data['lastName'] ?? "";
          _classCtl.text = data['className'] ?? "";
          _sectionCtl.text = data['section'] ?? "";
          _fatherCtl.text = data['fatherName'] ?? "";
          _motherCtl.text = data['motherName'] ?? "";
          _contactCtl.text = data['primaryContactNumber'] ?? "";
          _altContactCtl.text = data['alternateContactNumber'] ?? "";
          _emailCtl.text = data['email'] ?? "";
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${resp['message']}")),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _updateStudent() async {
    if (!_formKey.currentState!.validate()) return;

    final req = {
      "studentId": widget.studentId,
      "firstName": _firstNameCtl.text.trim(),
      "lastName": _lastNameCtl.text.trim(),
      "className": _classCtl.text.trim(),
      "section": _sectionCtl.text.trim(),
      "fatherName": _fatherCtl.text.trim(),
      "motherName": _motherCtl.text.trim(),
      "primaryContactNumber": _contactCtl.text.trim(),
      "alternateContactNumber": _altContactCtl.text.trim(),
      "email": _emailCtl.text.trim(),
      "updatedBy": "ParentApp"
    };

    final resp = await _service.updateStudent(widget.studentId, req);

    if (resp['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Student updated successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Update failed: ${resp['message']}")),
      );
    }
  }

  @override
  void dispose() {
    _firstNameCtl.dispose();
    _lastNameCtl.dispose();
    _classCtl.dispose();
    _sectionCtl.dispose();
    _fatherCtl.dispose();
    _motherCtl.dispose();
    _contactCtl.dispose();
    _altContactCtl.dispose();
    _emailCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Profile")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _firstNameCtl,
                      decoration: const InputDecoration(labelText: "First Name"),
                      validator: (v) => v!.isEmpty ? "Enter first name" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lastNameCtl,
                      decoration: const InputDecoration(labelText: "Last Name"),
                      validator: (v) => v!.isEmpty ? "Enter last name" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _classCtl,
                      decoration: const InputDecoration(labelText: "Class"),
                      validator: (v) => v!.isEmpty ? "Enter class" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sectionCtl,
                      decoration: const InputDecoration(labelText: "Section"),
                      validator: (v) => v!.isEmpty ? "Enter section" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fatherCtl,
                      decoration: const InputDecoration(labelText: "Father Name"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _motherCtl,
                      decoration: const InputDecoration(labelText: "Mother Name"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contactCtl,
                      decoration: const InputDecoration(labelText: "Primary Contact"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _altContactCtl,
                      decoration: const InputDecoration(labelText: "Alternate Contact"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtl,
                      decoration: const InputDecoration(labelText: "Email"),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateStudent,
                      child: const Text("Update Profile"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

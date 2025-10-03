import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SchoolProfilePage extends StatefulWidget {
  const SchoolProfilePage({super.key});

  @override
  State<SchoolProfilePage> createState() => _SchoolProfilePageState();
}

class _SchoolProfilePageState extends State<SchoolProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isUpdating = false;

  int? schoolId;
  String schoolName = '';
  String schoolType = '';
  String affiliationBoard = '';
  String contactNo = '';
  String email = '';
  String address = '';

  // API base URL
  static const String baseUrl = "http://192.168.29.254:9001/api/schools";

  @override
  void initState() {
    super.initState();
    _loadSchoolProfile();
  }

  Future<void> _loadSchoolProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt("schoolId");
    if (id == null) return;

    final url = Uri.parse("$baseUrl/$id");
    final resp = await http.get(url);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final school = data["data"];
      setState(() {
        schoolId = school["schoolId"];
        schoolName = school["schoolName"] ?? '';
        schoolType = school["schoolType"] ?? '';
        affiliationBoard = school["affiliationBoard"] ?? '';
        contactNo = school["contactNo"] ?? '';
        email = school["email"] ?? '';
        address = school["address"] ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSchoolProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    final url = Uri.parse("$baseUrl/$schoolId");
    final body = jsonEncode({
      "schoolName": schoolName,
      "schoolType": schoolType,
      "affiliationBoard": affiliationBoard,
      "contactNo": contactNo,
      "email": email,
      "address": address,
    });

    final resp = await http.put(url,
        headers: {"Content-Type": "application/json"}, body: body);

    setState(() => _isUpdating = false);

    if (resp.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("School updated successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: ${resp.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("School Profile")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      initialValue: schoolName,
                      decoration: const InputDecoration(labelText: "School Name"),
                      onChanged: (v) => schoolName = v,
                      validator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                    ),
                    TextFormField(
                      initialValue: schoolType,
                      decoration: const InputDecoration(labelText: "School Type"),
                      onChanged: (v) => schoolType = v,
                    ),
                    TextFormField(
                      initialValue: affiliationBoard,
                      decoration:
                          const InputDecoration(labelText: "Affiliation Board"),
                      onChanged: (v) => affiliationBoard = v,
                    ),
                    TextFormField(
                      initialValue: contactNo,
                      decoration:
                          const InputDecoration(labelText: "Contact No"),
                      onChanged: (v) => contactNo = v,
                    ),
                    TextFormField(
                      initialValue: email,
                      decoration: const InputDecoration(labelText: "Email"),
                      onChanged: (v) => email = v,
                    ),
                    TextFormField(
                      initialValue: address,
                      decoration: const InputDecoration(labelText: "Address"),
                      onChanged: (v) => address = v,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isUpdating ? null : _updateSchoolProfile,
                      child: _isUpdating
                          ? const CircularProgressIndicator()
                          : const Text("Update"),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}

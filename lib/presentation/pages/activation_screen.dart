import 'package:flutter/material.dart';
import '../../app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/pending_service.dart';
import 'privacy_policy_screen.dart'; // ✅ नया स्क्रीन import

class ActivationScreen extends StatefulWidget {
  final String token;
  const ActivationScreen({required this.token, super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userNameCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  final _authService = AuthService();
  final _pendingService = PendingService();

  String? _email;
  String? _entityType; // hidden if needed
  int? _entityId;      // hidden if needed
  bool _loading = false;
  bool _verifying = true;

  bool _agreed = false; // ✅ Agreement checkbox state

  @override
  void initState() {
    super.initState();
    _loadTokenInfo();
  }

  Future<void> _loadTokenInfo() async {
    setState(() => _verifying = true);
    try {
      final resp = await _pendingService.verifyToken(widget.token);
      if (resp['success'] == true && resp['data'] != null) {
        final data = resp['data'];
        setState(() {
          _email = data['email']?.toString();
          _entityType = data['entityType']?.toString();
          _entityId = data['entityId'] != null ? (data['entityId'] as num).toInt() : null;
        });
      } else {
        final msg = resp['message'] ?? 'Invalid token';
        _showSnack(msg.toString());
      }
    } catch (e) {
      _showSnack("Verify error: $e");
    } finally {
      setState(() => _verifying = false);
    }
  }

  void _showSnack(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      _showSnack("Please agree to Privacy Policy & Terms");
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await _authService.completeRegistration(
        token: widget.token,
        userName: _userNameCtl.text.trim(),
        password: _passwordCtl.text.trim(),
      );

      if (res['success'] == true) {
        _showSnack(res['message'] ?? "Registration completed. You can now login.");
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        _showSnack(res['message'] ?? 'Activation failed');
      }
    } catch (e) {
      _showSnack("Activation failed: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _userNameCtl.dispose();
    _passwordCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activate Account')),
      body: _verifying
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (_email != null) ...[
                      Text('Email: $_email'),
                      const SizedBox(height: 8),
                    ],

                    TextFormField(
                      controller: _userNameCtl,
                      decoration: const InputDecoration(labelText: 'Choose Username'),
                      validator: (v) => v == null || v.isEmpty ? 'Enter username' : null,
                    ),
                    TextFormField(
                      controller: _passwordCtl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
                    ),
                    TextFormField(
                      controller: _confirmCtl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Confirm Password'),
                      validator: (v) => v != _passwordCtl.text ? 'Passwords do not match' : null,
                    ),

                    const SizedBox(height: 16),

                   // ✅ Agreement Checkbox + Link
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Checkbox(
      value: _agreed,
      onChanged: (val) => setState(() => _agreed = val ?? false),
    ),
    Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.privacyPolicy);
        },
        child: const Text.rich(
          TextSpan(
            text: "I agree to the ",
            children: [
              TextSpan(
                text: "Privacy Policy & Terms",
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ],
),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: (!_agreed || _loading) ? null : _submit,
                      child: _loading
                          ? const CircularProgressIndicator()
                          : const Text('Activate & Create Account'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

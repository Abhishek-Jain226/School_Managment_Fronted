import 'package:flutter/material.dart';

import '../../services/auth_service.dart';


class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginIdCtl = TextEditingController();
  final _otpCtl = TextEditingController();
  final _newPassCtl = TextEditingController();
  final _confirmCtl = TextEditingController();

  final _service = AuthService();
  bool _otpSent = false;
  bool _loading = false;

  Future<void> _sendOtp() async {
    if (_loginIdCtl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter username/email/mobile")),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final resp = await _service.forgotPassword(_loginIdCtl.text.trim());
      if (resp["success"] == true) {
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp["message"] ?? "OTP sent")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp["message"] ?? "Failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final resp = await _service.resetPassword(
        _loginIdCtl.text.trim(),
        _otpCtl.text.trim(),
        _newPassCtl.text.trim(),
      );
      if (resp["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp["message"] ?? "Password reset successful")),
        );
        Navigator.pop(context); // back to login screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp["message"] ?? "Failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _loginIdCtl,
                decoration: const InputDecoration(
                  labelText: "Username / Email / Mobile",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? "Enter login id" : null,
              ),
              const SizedBox(height: 16),

              if (_otpSent) ...[
                TextFormField(
                  controller: _otpCtl,
                  decoration: const InputDecoration(
                    labelText: "Enter OTP",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? "Enter OTP" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPassCtl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "New Password",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v != null && v.length < 6 ? "Min 6 chars" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmCtl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Confirm Password",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v != _newPassCtl.text ? "Passwords do not match" : null,
                ),
                const SizedBox(height: 20),
              ],

              ElevatedButton(
                onPressed: _loading
                    ? null
                    : _otpSent
                        ? _resetPassword
                        : _sendOtp,
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text(_otpSent ? "Reset Password" : "Send OTP"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

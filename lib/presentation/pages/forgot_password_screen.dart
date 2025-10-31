import 'package:flutter/material.dart';
import '../../utils/constants.dart';

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.msgEnterUsernameEmailMobile)),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final resp = await _service.forgotPassword(_loginIdCtl.text.trim());
      if (!mounted) return;
      if (resp[AppConstants.keySuccess] == true) {
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp[AppConstants.keyMessage] ?? AppConstants.msgOTPSent)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp[AppConstants.keyMessage] ?? AppConstants.msgFailed)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppConstants.msgError}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
      if (!mounted) return;
      if (resp[AppConstants.keySuccess] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp[AppConstants.keyMessage] ?? AppConstants.msgPasswordResetSuccessful)),
        );
        Navigator.pop(context); // back to login screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp[AppConstants.keyMessage] ?? AppConstants.msgFailed)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppConstants.msgError}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppConstants.labelForgotPassword)),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.forgotPasswordPadding),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _loginIdCtl,
                decoration: const InputDecoration(
                  labelText: AppConstants.labelUsernameEmailMobile,
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? AppConstants.msgEnterLoginId : null,
              ),
              const SizedBox(height: AppSizes.forgotPasswordSpacing),

              if (_otpSent) ...[
                TextFormField(
                  controller: _otpCtl,
                  decoration: const InputDecoration(
                    labelText: AppConstants.labelEnterOTP,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? AppConstants.msgEnterOTP : null,
                ),
                const SizedBox(height: AppSizes.forgotPasswordSpacing),
                TextFormField(
                  controller: _newPassCtl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: AppConstants.labelNewPassword,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v != null && v.length < AppSizes.forgotPasswordMinLength ? AppConstants.msgMinSixChars : null,
                ),
                const SizedBox(height: AppSizes.forgotPasswordSpacing),
                TextFormField(
                  controller: _confirmCtl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: AppConstants.labelConfirmPassword,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v != _newPassCtl.text ? AppConstants.msgPasswordsDoNotMatch : null,
                ),
                const SizedBox(height: AppSizes.forgotPasswordSpacingLG),
              ],

              ElevatedButton(
                onPressed: _loading
                    ? null
                    : _otpSent
                        ? _resetPassword
                        : _sendOtp,
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text(_otpSent ? AppConstants.labelResetPassword : AppConstants.labelSendOTP),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

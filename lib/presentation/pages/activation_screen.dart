import 'package:flutter/material.dart';
import '../../app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/pending_service.dart';
import '../../services/school_service.dart';
import '../../utils/constants.dart';

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
  bool _isTokenValid = false;
  String? _schoolName;

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
      if (resp[AppConstants.keySuccess] == true && 
          resp[AppConstants.keyData] != null) {
        final data = resp[AppConstants.keyData];
        setState(() {
          _email = data[AppConstants.keyEmail]?.toString();
          _entityType = data[AppConstants.keyEntityType]?.toString();
          _entityId = data[AppConstants.keyEntityId] != null 
              ? (data[AppConstants.keyEntityId] as num).toInt() 
              : null;
          _isTokenValid = true;
        });
        
        // Load school name if it's a school registration
        if (_entityType == AppConstants.entityTypeSchool) {
          await _loadSchoolName();
        }
      } else {
        _showErrorDialog(
          AppConstants.titleInvalidToken,
          resp[AppConstants.keyMessage] ?? AppConstants.msgInvalidTokenExpired,
        );
      }
    } catch (e) {
      _showErrorDialog(
        AppConstants.titleVerificationFailed,
        AppConstants.msgUnableToVerify,
      );
    } finally {
      setState(() => _verifying = false);
    }
  }

  Future<void> _loadSchoolName() async {
    if (_entityId != null) {
      try {
        final schoolService = SchoolService();
        final response = await schoolService.getSchoolById(_entityId!);
        if (response[AppConstants.keySuccess] == true) {
          setState(() {
            _schoolName = response[AppConstants.keyData][AppConstants.keySchoolName];
          });
        }
      } catch (e) {
        // Handle error silently
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacementNamed(AppRoutes.registerSchool);
            },
            child: const Text(AppConstants.labelRegisterAgain),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      _showSnack(AppConstants.msgAgreeToTerms);
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await _authService.completeRegistration(
        token: widget.token,
        userName: _userNameCtl.text.trim(),
        password: _passwordCtl.text.trim(),
      );

      if (res[AppConstants.keySuccess] == true) {
        _showSnack(
          res[AppConstants.keyMessage] ?? AppConstants.msgRegistrationCompleted,
        );
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      } else {
        _showSnack(
          res[AppConstants.keyMessage] ?? AppConstants.msgActivationFailed,
        );
      }
    } catch (e) {
      _showSnack('${AppConstants.msgActivationFailedPrefix}$e');
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
      appBar: AppBar(
        title: const Text(AppConstants.labelActivateAccount),
      ),
      body: _verifying
          ? const Center(child: CircularProgressIndicator())
          : !_isTokenValid
              ? const Center(
                  child: Text(AppConstants.msgInvalidActivationLink),
                )
              : _buildActivationForm(),
    );
  }

  Widget _buildActivationForm() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.activationPadding),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            if (_schoolName != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.activationPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppConstants.labelSchoolInformation,
                        style: TextStyle(
                          fontSize: AppSizes.activationHeaderFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSizes.activationSpacingSM),
                      Text('${AppConstants.labelSchoolWithColon}$_schoolName'),
                      Text('${AppConstants.labelEmailWithColon}$_email'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.activationSpacingMD),
            ] else if (_email != null) ...[
              Text('${AppConstants.labelEmailWithColon}$_email'),
              const SizedBox(height: AppSizes.activationSpacingSM),
            ],

            TextFormField(
              controller: _userNameCtl,
              decoration: const InputDecoration(
                labelText: AppConstants.labelChooseUsername,
              ),
              validator: (v) => v == null || v.isEmpty 
                  ? AppConstants.validationEnterUsername 
                  : null,
            ),
            TextFormField(
              controller: _passwordCtl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: AppConstants.labelPassword,
              ),
              validator: (v) => v == null || v.length < AppSizes.activationPasswordMinLength 
                  ? AppConstants.validationMinChars 
                  : null,
            ),
            TextFormField(
              controller: _confirmCtl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: AppConstants.labelConfirmPassword,
              ),
              validator: (v) => v != _passwordCtl.text 
                  ? AppConstants.validationPasswordsDoNotMatch 
                  : null,
            ),

            const SizedBox(height: AppSizes.activationSpacingMD),

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
                        text: AppConstants.labelAgreeToThe,
                        children: [
                          TextSpan(
                            text: AppConstants.labelPrivacyPolicyTerms,
                            style: TextStyle(
                              color: AppColors.activationLinkColor,
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

            const SizedBox(height: AppSizes.activationSpacingLG),

            ElevatedButton(
              onPressed: (!_agreed || _loading) ? null : _submit,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text(AppConstants.labelActivateCreateAccount),
            ),
          ],
        ),
      ),
    );
  }
}
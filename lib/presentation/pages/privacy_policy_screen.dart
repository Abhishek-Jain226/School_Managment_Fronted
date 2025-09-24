import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Privacy Policy & Terms")),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            """
Privacy Policy & Terms & Conditions

1. We respect your privacy and protect your data.
2. Your credentials will be securely stored and never shared without consent.
3. By registering and activating your account, you agree to these terms.
4. Replace this text with your real privacy policy from your organization.
            """,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

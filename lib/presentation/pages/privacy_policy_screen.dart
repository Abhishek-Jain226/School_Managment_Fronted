import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.labelPrivacyPolicyTerms)),
      body: const Padding(
        padding: EdgeInsets.all(AppSizes.privacyPolicyPadding),
        child: SingleChildScrollView(
          child: Text(
            AppConstants.privacyPolicyContent,
            style: TextStyle(fontSize: AppSizes.privacyPolicyFontSize),
          ),
        ),
      ),
    );
  }
}

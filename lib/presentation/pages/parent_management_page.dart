import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class ParentManagementPage extends StatelessWidget {
  const ParentManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.labelParentManagement),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.family_restroom, size: AppSizes.parentManagementIconSize, color: AppColors.textSecondary),
            SizedBox(height: AppSizes.parentManagementSpacing),
            Text(
              AppConstants.labelParentManagement,
              style: TextStyle(fontSize: AppSizes.parentManagementTitleFontSize, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: AppSizes.parentManagementSpacingSM),
            Text(
              AppConstants.labelViewManageParents,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

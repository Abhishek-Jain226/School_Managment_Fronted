import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class DriverManagementPage extends StatelessWidget {
  const DriverManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.labelDriverManagement),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: AppSizes.driverMgmtIconSize, color: AppColors.driverMgmtGreyColor),
            SizedBox(height: AppSizes.driverMgmtSpacingMD),
            Text(
              AppConstants.labelDriverManagement,
              style: TextStyle(fontSize: AppSizes.driverMgmtTitleFontSize, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: AppSizes.driverMgmtSpacingSM),
            Text(
              AppConstants.labelViewAndManageDrivers,
              style: TextStyle(color: AppColors.driverMgmtGreyColor),
            ),
          ],
        ),
      ),
    );
  }
}


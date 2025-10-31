import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class VehicleOwnerManagementPage extends StatelessWidget {
  const VehicleOwnerManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.labelVehicleOwnerManagement),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: AppSizes.iconXL, color: AppColors.textSecondary),
            SizedBox(height: AppSizes.marginMD),
            Text(AppConstants.labelVehicleOwnerManagement, style: TextStyle(fontSize: AppSizes.textXL, fontWeight: FontWeight.bold)),
            SizedBox(height: AppSizes.marginSM),
            Text(AppConstants.labelViewAndManageVehicleOwners, style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}


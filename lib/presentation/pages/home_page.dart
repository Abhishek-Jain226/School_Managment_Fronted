// lib/screens/home_page.dart
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryColor, AppColors.primaryLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.homePaddingH, vertical: AppSizes.homePaddingV),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school_outlined, size: AppSizes.homeIconSize, color: AppColors.textWhite),
                const SizedBox(height: AppSizes.homeSpacing),
                const Text(
                  AppConstants.labelWelcomeToSchoolTracker,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppSizes.homeTitleFontSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                    letterSpacing: AppSizes.homeLetterSpacing,
                  ),
                ),
                const SizedBox(height: AppSizes.homeButtonSpacing),

                // LOGIN -> opens Login screen
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.login);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, AppSizes.homeButtonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.homeButtonRadius),
                    ),
                  ),
                  child: const Text(AppConstants.labelLoginRegister, style: TextStyle(fontSize: AppSizes.homeButtonTextSize)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

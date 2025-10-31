import 'dart:async';
import 'package:flutter/material.dart';
import '../../app_routes.dart';
import '../../utils/constants.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();

    // Go to Home after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppConstants.splashGradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppConstants.splashIconBg,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: AppConstants.splashCircleAvatarShadowBlur,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(AppConstants.splashIconPadding),
                  child: const Icon(
                    Icons.school,
                    size: AppConstants.splashIconSize,
                    color: AppConstants.splashTitleColor,
                  ),
                ),
                const SizedBox(height: AppConstants.splashSpacingIconToTitle),
                const Text(
                  AppConstants.labelSplashTitle,
                  style: TextStyle(
                    fontSize: AppConstants.splashTitleFontSize,
                    fontWeight: AppConstants.splashTitleFontWeight,
                    color: AppConstants.splashTitleColor,
                    letterSpacing: AppConstants.splashTitleLetterSpacing,
                    shadows: [
                      Shadow(
                        color: AppConstants.splashTitleShadowColor,
                        offset: AppConstants.splashTitleShadowOffset,
                        blurRadius: AppConstants.splashTitleShadowBlur,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.splashSpacingTitleToSubtitle),
                const Text(
                  AppConstants.labelSplashSubtitle,
                  style: TextStyle(
                    fontSize: AppConstants.splashSubtitleFontSize,
                    color: AppConstants.splashSubtitleColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: AppConstants.splashSpacingSubtitleToLoader),
                const CircularProgressIndicator(
                  strokeWidth: AppConstants.splashLoaderStrokeWidth,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

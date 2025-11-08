import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/constants.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/notification/notification_bloc.dart';
import '../../bloc/notification/notification_event.dart';
import '../../app_routes.dart';

class BlocLoginScreen extends StatefulWidget {
  const BlocLoginScreen({super.key});

  @override
  State<BlocLoginScreen> createState() => _BlocLoginScreenState();
}

class _BlocLoginScreenState extends State<BlocLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginIdCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _loginIdCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  void _doLogin() {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    // Dispatch login event to AuthBloc
    context.read<AuthBloc>().add(
      AuthLoginRequested(
        loginId: _loginIdCtl.text.trim(),
        password: _passwordCtl.text.trim(),
      ),
    );
  }

  void _navigateBasedOnRole(List<String> roles, Map<String, dynamic> userData) {
    if (roles.contains(AppConstants.roleAppAdmin)) {
      Navigator.pushReplacementNamed(context, AppRoutes.blocAppAdminDashboard);
    } else if (roles.contains(AppConstants.roleSchoolAdmin)) {
      Navigator.pushReplacementNamed(context, AppRoutes.blocSchoolAdminDashboard);
    } else if (roles.contains(AppConstants.roleDriver)) {
      Navigator.pushReplacementNamed(context, AppRoutes.blocDriverDashboard);
    } else if (roles.contains(AppConstants.roleVehicleOwner)) {
      Navigator.pushReplacementNamed(context, AppRoutes.blocVehicleOwnerDashboard);
    } else if (roles.contains(AppConstants.roleParent)) {
      Navigator.pushReplacementNamed(context, AppRoutes.blocParentDashboard);
    } else if (roles.contains(AppConstants.roleGateStaff)) {
      Navigator.pushReplacementNamed(context, AppRoutes.gateStaffDashboard);
    } else {
      // Default fallback
      Navigator.pushReplacementNamed(context, AppRoutes.splash);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // Connect to notifications
            context.read<NotificationBloc>().add(
              NotificationConnectRequested(
                userId: state.userId?.toString() ?? '',
                roles: state.roles,
                schoolId: state.schoolId,
              ),
            );

            // Navigate based on role
            _navigateBasedOnRole(state.roles, state.userData);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.loginErrorColor,
              ),
            );
          }
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.loginPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo/Title
                        const Icon(
                          Icons.school,
                          size: AppSizes.loginLogoSize,
                          color: AppColors.loginPrimaryColor,
                        ),
                        const SizedBox(height: AppSizes.loginSpacingMD),
                        const Text(
                          AppConstants.labelSchoolTracker,
                          style: TextStyle(
                            fontSize: AppSizes.loginTitleFontSize,
                            fontWeight: FontWeight.bold,
                            color: AppColors.loginPrimaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSizes.loginSpacingLG),

                        // Login ID Field
                        TextFormField(
                          controller: _loginIdCtl,
                          decoration: const InputDecoration(
                            labelText: AppConstants.labelLoginId,
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppConstants.msgEnterLoginId;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSizes.loginSpacingSM),

                        // Password Field
                        TextFormField(
                          controller: _passwordCtl,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: AppConstants.labelPassword,
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppConstants.msgEnterPassword;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSizes.loginSpacingMD),

                        // Login Button
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final isLoading = state is AuthLoading;

                            return ElevatedButton(
                              onPressed: isLoading ? null : _doLogin,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSizes.loginButtonPaddingV,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.loginButtonRadius,
                                  ),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: AppSizes.loginProgressSize,
                                      width: AppSizes.loginProgressSize,
                                      child: CircularProgressIndicator(
                                        strokeWidth: AppSizes.loginProgressStroke,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.loginTextWhite,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      AppConstants.labelLogin,
                                      style: TextStyle(fontSize: AppSizes.loginTextFontSize),
                                    ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSizes.loginSpacingSM),

                        // Register School Link
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.registerSchool);
                          },
                          child: const Text(AppConstants.labelRegisterSchoolLink),
                        ),
                        const SizedBox(height: AppSizes.loginSpacingXS),

                        // Forgot Password Link
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.forgotPassword);
                          },
                          child: const Text(AppConstants.labelForgotPassword),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

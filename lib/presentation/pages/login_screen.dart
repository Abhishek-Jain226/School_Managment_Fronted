import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../app_routes.dart';
import '../../services/auth_service.dart';



class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginIdCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;

  Future<void> _doLogin() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus(); // ✅ close keyboard
    setState(() => _loading = true);

    try {
      // Clear any previous session data before login
      await _authService.logout();
      
      final resp = await _authService.login(
        _loginIdCtl.text.trim(),
        _passwordCtl.text.trim(),
      );

      if (resp['success'] == true) {
        final data = resp['data'];
        final roles = List<String>.from(data['roles'] ?? []);
        
        // Debug: Print login response data to help identify available fields
        print('🔍 Login Response Data: $data');
        print('🔍 Available keys in response: ${data.keys.toList()}');
        print('🔍 Driver ID in response: ${data['driverId']}');
        print('🔍 User roles: ${data['roles']}');
        print('🔍 User ID in response: ${data['userId']}');
        print('🔍 Owner ID in response: ${data['ownerId']}');

        // ✅ Save role in prefs for later use
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt("userId", data['userId']);   // 👈 Save userId
        await prefs.setString("token", data['token'] ?? "");
        
        await prefs.setString("userName", data['userName']); // 👈 optional for display
        await prefs.setString("role", roles.isNotEmpty ? roles.first : "");

        // ✅ Save schoolId if present
if (data['schoolId'] != null) {
  await prefs.setInt("schoolId", data['schoolId']);
}

// ✅ Save ownerId if present
if (data['ownerId'] != null) {
  await prefs.setInt("ownerId", data['ownerId']);
}

// ✅ Save driverId if present
if (data['driverId'] != null) {
  await prefs.setInt("driverId", data['driverId']);
  print('🔍 Driver ID saved: ${data['driverId']}');
} else {
  print('⚠️ Driver ID not found in login response');
}

        // ✅ success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login successful"),
            backgroundColor: Colors.green,
          ),
        );

        // ✅ Navigate role-wise
        if (roles.contains("APP_ADMIN")) {
          Navigator.pushReplacementNamed(context, AppRoutes.appAdminDashboard);
          
        } else if (roles.contains("SCHOOL_ADMIN")) {
         Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          
        } else if (roles.contains("VEHICLE_OWNER")) {
          Navigator.pushReplacementNamed(context, AppRoutes.vehicleOwnerDashboard);
          
        } 
        else if (roles.contains("PARENT")) {
    Navigator.pushReplacementNamed(context, AppRoutes.parentDashboard);
    
    }else     if (roles.contains("DRIVER")) {
      Navigator.pushReplacementNamed(context, AppRoutes.simplifiedDriverDashboard);
    }
    else if (roles.contains("GATE_STAFF")) {
      Navigator.pushReplacementNamed(context, AppRoutes.gateStaffDashboard);
    }
    else if (roles.isEmpty) {
      // ⚠️ temporary fix: agar roles empty hai to sidha GateStaff dashboard
      Navigator.pushReplacementNamed(context, AppRoutes.gateStaffDashboard);
    }

    else {
      
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Unknown role, contact support")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp['message'] ?? "Invalid credentials")),
        );
      }
    } catch (e) {
      // ✅ detailed error logging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _loginIdCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // -------- Username field --------
                TextFormField(
                  controller: _loginIdCtl,
                  decoration: const InputDecoration(
                    labelText: 'Username/Mobile',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Enter username" : null,
                ),
                const SizedBox(height: 16),

                // -------- Password field --------
                TextFormField(
                  controller: _passwordCtl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Enter password" : null,
                ),
                const SizedBox(height: 20),

                // -------- Login button --------
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _doLogin,
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Login'),
                  ),
                ),

                const SizedBox(height: 12),

                // -------- Forgot Password --------
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.forgotPassword);
                  },
                  child: const Text("Forgot Password?"),
                ),

                // -------- Register --------
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.registerSchool);
                  },
                  child: const Text("Don't have an account? Register now"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

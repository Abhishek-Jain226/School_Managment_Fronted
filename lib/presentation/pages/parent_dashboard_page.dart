import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_routes.dart';
import '../../services/parent_service.dart';
import '../../services/auth_service.dart';

class ParentDashboardPage extends StatelessWidget {
  const ParentDashboardPage({super.key});

  Future<void> _logout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        // Clear all stored data
        final authService = AuthService();
        await authService.logout();
        
        // Navigate to login screen and clear navigation stack
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show confirmation dialog when back button is pressed
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Exit App'),
              content: const Text('Are you sure you want to exit the app?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Exit'),
                ),
              ],
            );
          },
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.family_restroom, size: 28),
            SizedBox(width: 8),
            Text("Parent Dashboard"),
          ],
        ),
        actions: [
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: FutureBuilder<Map<String, dynamic>>(
              future: SharedPreferences.getInstance().then((prefs) async {
                final userId = prefs.getInt("userId");
                if (userId == null) return {"success": false};
                final service = ParentService();
                // ✅ API: student data by parent userId
                return await service.getStudentByParentUserId(userId);
              }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2);
                }

                if (!snapshot.hasData || snapshot.data!['success'] != true) {
                  return const Text(
                    "Parent",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  );
                }

                final data = snapshot.data!['data'];
                final studentName =
                    "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}"
                        .trim();
                final studentId = data['studentId'];
                final studentPhoto = data['studentPhoto'];

                return InkWell(
                  onTap: () {
                    // ✅ Navigate to Student Profile Page
                    Navigator.pushNamed(
                      context,
                      AppRoutes.studentProfile,
                      arguments: studentId,
                    );
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blueGrey,
                        backgroundImage: studentPhoto != null && studentPhoto.isNotEmpty
                            ? MemoryImage(base64Decode(studentPhoto))
                            : null,
                        child: studentPhoto == null || studentPhoto.isEmpty
                            ? const Icon(Icons.person, color: Colors.white, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        studentName.isNotEmpty ? studentName : "Student",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ Child Info Card (dynamic data)
            FutureBuilder<Map<String, dynamic>>(
              future: SharedPreferences.getInstance().then((prefs) async {
                final userId = prefs.getInt("userId");
                if (userId == null) return {"success": false};
                final service = ParentService();
                return await service.getStudentByParentUserId(userId);
              }),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!['success'] != true) {
                  return const Text("No child info available");
                }

                final data = snapshot.data!['data'];

                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Child Information",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ListTile(
                          leading: const Icon(Icons.school),
                          title: Text(
                              "Name: ${data['firstName'] ?? 'N/A'} ${data['lastName'] ?? 'N/A'}"),
                          subtitle: Text(
                              "Class: ${data['className'] ?? 'N/A'} - Section ${data['sectionName'] ?? data['section'] ?? 'N/A'}"),
                        ),
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: Text("Father: ${data['fatherName'] ?? 'N/A'}"),
                          subtitle: Text("Mother: ${data['motherName'] ?? 'N/A'}"),
                        ),
                        ListTile(
                          leading: const Icon(Icons.phone),
                          title: Text("Contact: ${data['primaryContactNumber'] ?? 'N/A'}"),
                          subtitle: Text(
                              "Alt: ${data['alternateContactNumber'] ?? 'N/A'}"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // ✅ Attendance & Tracking
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's Attendance",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text("Present"),
                      subtitle: Text("Date: 25 Sept 2025"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ Notifications
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Notifications",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    ListTile(
                      leading: Icon(Icons.notifications),
                      title: Text("Bus has left school"),
                      subtitle: Text("09:00 AM"),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.notifications),
                      title: Text("Bus arrived at Home Stop"),
                      subtitle: Text("01:30 PM"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ Quick Actions
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Quick Actions",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Bus live tracking page
                      },
                      icon: const Icon(Icons.location_on),
                      label: const Text("Track Bus"),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Attendance history
                      },
                      icon: const Icon(Icons.history),
                      label: const Text("View Attendance History"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

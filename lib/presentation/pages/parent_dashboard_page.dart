import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_routes.dart';
import '../../services/parent_service.dart';

class ParentDashboardPage extends StatelessWidget {
  const ParentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.family_restroom, size: 28),
            SizedBox(width: 8),
            Text("Parent Dashboard"),
          ],
        ),
        actions: [
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
                      const CircleAvatar(
                        child: Icon(Icons.person, color: Colors.white),
                        backgroundColor: Colors.blueGrey,
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
                              "Name: ${data['firstName']} ${data['lastName']}"),
                          subtitle: Text(
                              "Class: ${data['className']} - Section ${data['section']}"),
                        ),
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: Text("Father: ${data['fatherName']}"),
                          subtitle: Text("Mother: ${data['motherName']}"),
                        ),
                        ListTile(
                          leading: const Icon(Icons.phone),
                          title: Text("Contact: ${data['primaryContactNumber']}"),
                          subtitle: Text(
                              "Alt: ${data['alternateContactNumber'] ?? '-'}"),
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
    );
  }
}

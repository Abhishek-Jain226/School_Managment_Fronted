import 'package:flutter/material.dart';

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
            child: InkWell(
              onTap: () {
                // TODO: Parent Profile Page open karna hai
              },
              child: Row(
                children: const [
                  CircleAvatar(
                    child: Icon(Icons.person, color: Colors.white),
                    backgroundColor: Colors.blueGrey,
                  ),
                  SizedBox(width: 8),
                  Text("Parent Name"),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ Child Info
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Child Information",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    ListTile(
                      leading: Icon(Icons.school),
                      title: Text("Name: Rohan Sharma"),
                      subtitle: Text("Class 5 - Section A"),
                    ),
                    ListTile(
                      leading: Icon(Icons.directions_bus),
                      title: Text("Bus Number: RJ14AB1234"),
                      subtitle: Text("Route: School to Home"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ Attendance & Tracking
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Today's Attendance",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text("Present"),
                      subtitle: Text("Date: 23 Sept 2025"),
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Notifications",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text("Bus has left school"),
                      subtitle: const Text("09:00 AM"),
                      onTap: () {},
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text("Bus arrived at Home Stop"),
                      subtitle: const Text("01:30 PM"),
                      onTap: () {},
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

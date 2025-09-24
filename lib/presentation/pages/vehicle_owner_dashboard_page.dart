import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_routes.dart';

class VehicleOwnerDashboardPage extends StatelessWidget {
  const VehicleOwnerDashboardPage({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home, // back to login/home page
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vehicle Owner Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: "Logout",
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Confirm Logout"),
                  content: const Text("Are you sure you want to log out?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _logout(context);
                      },
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Row(
              children: const [
                CircleAvatar(
                  backgroundColor: Colors.blueGrey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                SizedBox(width: 8),
                Text(
                  "Owner Name",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildCard("Total Vehicles", "4",
                      icon: Icons.directions_bus),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCard("Active Drivers", "3", icon: Icons.person),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child:
                      _buildCard("In Transit", "2", icon: Icons.local_shipping),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCard("Pending Approvals", "1",
                      icon: Icons.pending_actions),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Recent Activity
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Recent Activity",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    ListTile(
                      dense: true,
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text("Vehicle KA-01-1234 started trip"),
                      subtitle: Text("Today, 09:00 AM"),
                    ),
                    ListTile(
                      dense: true,
                      leading: Icon(Icons.warning, color: Colors.orange),
                      title: Text("Driver Late Login"),
                      subtitle: Text("Today, 08:45 AM"),
                    ),
                    ListTile(
                      dense: true,
                      leading: Icon(Icons.person_add, color: Colors.blue),
                      title: Text("New Driver Added"),
                      subtitle: Text("Yesterday"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Quick Actions
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Quick Actions",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.registerVehicle);
                      },
                      icon: const Icon(Icons.directions_bus),
                      label: const Text("Register Vehicle"),
                    ),
                    const SizedBox(height: 8),
ElevatedButton.icon(
  onPressed: () {
    Navigator.pushNamed(context, AppRoutes.registerDriver);
  },
  icon: const Icon(Icons.person_add),
  label: const Text("Register Driver"),
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

  Widget _buildCard(String label, String value, {IconData? icon}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) Icon(icon, size: 20, color: Colors.blueGrey),
            Text(label,
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

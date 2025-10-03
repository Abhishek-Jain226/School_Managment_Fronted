import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_routes.dart';
import '../../services/vehicle_owner_service.dart';

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
          // 🔹 Logout Button
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

          // 🔹 Owner Name & Avatar (from backend)
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: FutureBuilder<Map<String, dynamic>>(
              future: SharedPreferences.getInstance().then((prefs) async {
                final userId = prefs.getInt("userId");
                if (userId == null) return {"success": false};
                final service = VehicleOwnerService();
                final resp = await service.getOwnerByUserId(userId);
                print("🔹 API Response in Dashboard: $resp");
                return resp;
              }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                if (!snapshot.hasData || snapshot.data!['success'] != true) {
                   print("❌ Snapshot has no data or failed: ${snapshot.data}");
                  return Row(
                    children: const [
                      CircleAvatar(
                        backgroundColor: Colors.blueGrey,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Owner",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                }

                final data = snapshot.data!['data'];
                print("✅ Owner Data: $data"); // 👈 debugging
                final ownerName = data['name'] ?? "Owner";
                final ownerId = data['ownerId'];

                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.vehicleOwnerProfile,
                      arguments: ownerId,
                    );
                  },
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.blueGrey,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ownerName, // 
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
            // 🔹 Summary Cards
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

            // 🔹 Recent Activity
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

            // 🔹 Quick Actions
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
                        Navigator.pushNamed(
                            context, AppRoutes.registerVehicle);
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
                     // 🔹 New Button for Request
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(
                context, AppRoutes.requestVehicle);
          },
          icon: const Icon(Icons.assignment_turned_in),
          label: const Text("Request Vehicle Assignment"),
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

  // 🔹 Helper Widget for Summary Cards
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

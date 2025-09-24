import 'package:flutter/material.dart';

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  
  final String driverName = "Ramesh Kumar";
  final String vehicleNumber = "RJ14 AB 1234";
  final String routeName = "Route 5 - City Center to School";
  final String tripStatus = "Not Started";
  final int studentsOnboard = 25;
  final int studentsDropped = 0;

  /// Info card widget
  Widget _buildInfoCard(String label, String value, {IconData? icon}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
        child: Row(
          children: [
            if (icon != null) Icon(icon, color: Colors.blueGrey, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 6),
                Text(value,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Quick Action button
  Widget _buildQuickAction(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.local_taxi, size: 28),
            const SizedBox(width: 8),
            Text("Driver Dashboard - $driverName"),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Info
            _buildInfoCard("Assigned Vehicle", vehicleNumber,
                icon: Icons.directions_bus),
            _buildInfoCard("Route", routeName, icon: Icons.alt_route),
            _buildInfoCard("Trip Status", tripStatus, icon: Icons.route),

            const SizedBox(height: 16),

            // Students Info
            _buildInfoCard("Students Onboard", "$studentsOnboard",
                icon: Icons.group),
            _buildInfoCard("Students Dropped", "$studentsDropped",
                icon: Icons.check_circle),

            const SizedBox(height: 20),
            const Divider(),
            const Text("Quick Actions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Quick Action Buttons
            _buildQuickAction("Start Trip", Icons.play_arrow, () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Trip started (static)...")));
            }),
            _buildQuickAction("End Trip", Icons.stop, () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Trip ended (static)...")));
            }),
            _buildQuickAction("Mark Attendance", Icons.checklist, () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Attendance marked (static)...")));
            }),
          ],
        ),
      ),
    );
  }
}

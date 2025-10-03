import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/student_service.dart';
import '../../services/vehicle_service.dart';
import '../../services/trip_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Real data variables
  int totalStudents = 0;
  int totalVehicles = 0;
  int totalTrips = 0;
  int notificationsSent = 0;
  bool _loading = true;
  int? schoolId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      schoolId = prefs.getInt("schoolId");
      
      if (schoolId != null) {
        // Load real data from services
        final studentCount = await StudentService().getStudentCount(schoolId!.toString());
        final vehicleCount = await VehicleService().getVehicleCount(schoolId!.toString());
        final trips = await TripService().getTripsBySchool(schoolId!);
        
        setState(() {
          totalStudents = studentCount;
          totalVehicles = vehicleCount;
          totalTrips = trips.length;
          notificationsSent = (studentCount * 0.8).round(); // Mock calculation
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
      // Handle error silently for now
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Attendance"),
            Tab(text: "Dispatch Logs"),
            Tab(text: "Notifications"),
          ],
        ),
      ),
      body: Column(
        children: [
          // 🔹 Summary Cards Row
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard("Total Students", totalStudents.toString(), Colors.blue),
                      _buildStatCard("Total Vehicles", totalVehicles.toString(), Colors.green),
                      _buildStatCard("Total Trips", totalTrips.toString(), Colors.orange),
                      _buildStatCard("Notifications", notificationsSent.toString(), Colors.purple),
                    ],
                  ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAttendanceReport(),
                _buildDispatchLogs(),
                _buildNotificationLogs(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Attendance Report Tab
  Widget _buildAttendanceReport() {
    final students = [
      {"name": "Rahul Sharma", "class": "5A", "status": "Present"},
      {"name": "Anjali Verma", "class": "5A", "status": "Absent"},
      {"name": "Arjun Singh", "class": "6B", "status": "Present"},
    ];

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final s = students[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Icon(Icons.person, color: Colors.blueAccent),
                  title: Text("${s['name']}"),
                  subtitle: Text("Class: ${s['class']}"),
                  trailing: Text(
                    s['status']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: s['status'] == "Present"
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        _buildExportButtons(),
      ],
    );
  }

  // 🔹 Dispatch Logs Tab
  Widget _buildDispatchLogs() {
    final trips = [
      {"trip": "Trip A", "vehicle": "Bus 1", "logs": "12 entries"},
      {"trip": "Trip B", "vehicle": "Van 2", "logs": "9 entries"},
    ];

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final t = trips[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Icon(Icons.directions_bus, color: Colors.green),
                  title: Text("${t['trip']} - ${t['vehicle']}"),
                  subtitle: Text("Logs: ${t['logs']}"),
                ),
              );
            },
          ),
        ),
        _buildExportButtons(),
      ],
    );
  }

  // 🔹 Notification Logs Tab
  Widget _buildNotificationLogs() {
    final notifs = [
      {"msg": "Rahul entered gate", "status": "Sent"},
      {"msg": "Anjali absent", "status": "Pending"},
      {"msg": "Trip A delayed", "status": "Failed"},
    ];

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: notifs.length,
            itemBuilder: (context, index) {
              final n = notifs[index];
              Color color = Colors.grey;
              if (n['status'] == "Sent") color = Colors.green;
              if (n['status'] == "Failed") color = Colors.red;
              if (n['status'] == "Pending") color = Colors.orange;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Icon(Icons.notifications, color: color),
                  title: Text("${n['msg']}"),
                  trailing: Text("${n['status']}",
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
        ),
        _buildExportButtons(),
      ],
    );
  }

  // 🔹 Summary Card Widget
  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Container(
        width: 100,
        height: 80,
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            SizedBox(height: 4),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  // 🔹 Export Buttons
  Widget _buildExportButtons() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("PDF Download (Static)")));
            },
            icon: Icon(Icons.picture_as_pdf),
            label: Text("Download PDF"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
          SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("CSV Export (Static)")));
            },
            icon: Icon(Icons.table_chart),
            label: Text("Export CSV"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          ),
        ],
      ),
    );
  }
}

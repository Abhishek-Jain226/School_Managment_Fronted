import 'package:flutter/material.dart';

class GateStaffDashboardPage extends StatelessWidget {
  const GateStaffDashboardPage({Key? key}) : super(key: key);

  final List<Map<String, String>> dummyStudents = const [
    {"studentName": "Rahul Sharma", "tripName": "Trip A"},
    {"studentName": "Anjali Verma", "tripName": "Trip B"},
    {"studentName": "Arjun Singh", "tripName": "Trip A"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gate Staff Dashboard")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Dashboard Summary Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard("Total Students", "45", Colors.blue),
                _buildStatCard("Active Trips", "3", Colors.green),
                _buildStatCard("Notifications", "12", Colors.orange),
              ],
            ),
            SizedBox(height: 20),

            // 🔹 Student List Section
            Text(
              "Student List (Static)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: dummyStudents.length,
              itemBuilder: (context, index) {
                final student = dummyStudents[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(student["studentName"] ?? "Unknown"),
                    subtitle: Text("Trip: ${student["tripName"]}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      "${student["studentName"]} - Entry Marked")),
                            );
                          },
                          child: Text("Entry"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      "${student["studentName"]} - Exit Marked")),
                            );
                          },
                          child: Text("Exit"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),

            // 🔹 Notifications Section (Static)
            Text(
              "Recent Notifications",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            _buildNotificationTile("Rahul Sharma entered school gate"),
            _buildNotificationTile("Anjali Verma exited to vehicle"),
            _buildNotificationTile("Trip A completed successfully"),
          ],
        ),
      ),
    );
  }

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
            Text(title, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(String message) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.notifications, color: Colors.orange),
        title: Text(message),
      ),
    );
  }
}

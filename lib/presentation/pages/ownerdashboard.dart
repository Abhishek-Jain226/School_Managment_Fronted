// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'driver_form_screen.dart'; // ✅ Import your real Driver form

// class OwnerDashboard extends StatelessWidget {
//   const OwnerDashboard({super.key});

//   // Logout function
//   Future<void> _logout(BuildContext context) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear(); // clear all saved data

//     Navigator.pushReplacementNamed(context, '/login'); // navigate to login
//   }

//   @override
//   Widget build(BuildContext context) {
//     final List<Map<String, dynamic>> sections = [
//       {'title': 'Profile', 'icon': Icons.person},
//       {'title': 'Drivers', 'icon': Icons.people},
//       {'title': 'Vehicles', 'icon': Icons.directions_bus},
//       {'title': 'Trips', 'icon': Icons.route},
//       {'title': 'Students', 'icon': Icons.school},
//       {'title': 'Emergency', 'icon': Icons.warning, 'color': Colors.red},
//     ];

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Vehicle Owner Dashboard"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             tooltip: 'Logout',
//             onPressed: () => _logout(context),
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: GridView.builder(
//           itemCount: sections.length,
//           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 2,
//             mainAxisSpacing: 16,
//             crossAxisSpacing: 16,
//             childAspectRatio: 1.0,
//           ),
//           itemBuilder: (context, index) {
//             final section = sections[index];
//             final String title = section['title'] as String;
//             final IconData icon = section['icon'] as IconData;
//             final Color? cardColor = section['color'] as Color?;

//             return GestureDetector(
//               onTap: () {
//                 if (title == 'Drivers') {
//                   // ✅ Directly open driver form
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => const DriverFormScreen(),
//                     ),
//                   );
//                 } else {
//                   // ✅ For others, still open SectionPage
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => SectionPage(title: title),
//                     ),
//                   );
//                 }
//               },
//               child: Card(
//                 color: cardColor ?? Colors.white,
//                 elevation: 4,
//                 child: Center(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         icon,
//                         size: 50,
//                         color: cardColor != null ? Colors.white : Colors.blue,
//                       ),
//                       const SizedBox(height: 10),
//                       Text(
//                         title,
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: cardColor != null ? Colors.white : Colors.black,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// class SectionPage extends StatelessWidget {
//   final String title;
//   const SectionPage({super.key, required this.title});

//   @override
//   Widget build(BuildContext context) {
//     List<String> items = [];
//     switch (title) {
//       case 'Vehicles':
//         items = ['Vehicle 1', 'Vehicle 2', 'Vehicle 3'];
//         break;
//       case 'Trips':
//         items = ['Trip 1', 'Trip 2'];
//         break;
//       case 'Students':
//         items = ['Student 1', 'Student 2', 'Student 3'];
//         break;
//       case 'Profile':
//         items = ['Name: Abhishek Jain\nContact: 9876543210\nEmail: abhishek@example.com'];
//         break;
//       case 'Emergency':
//         items = ['Tap the button below for emergency alert'];
//         break;
//     }

//     return Scaffold(
//       appBar: AppBar(title: Text(title)),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: title == 'Emergency'
//             ? Center(
//                 child: ElevatedButton.icon(
//                   icon: const Icon(Icons.warning),
//                   label: const Text("Emergency"),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.red,
//                     padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
//                   ),
//                   onPressed: () {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text("Emergency Alert Triggered (Static)")),
//                     );
//                   },
//                 ),
//               )
//             : ListView.builder(
//                 itemCount: items.length,
//                 itemBuilder: (context, index) {
//                   return Card(
//                     child: ListTile(
//                       title: Text(items[index]),
//                       trailing: const Icon(Icons.edit),
//                     ),
//                   );
//                 },
//               ),
//       ),
//     );
//   }
// }

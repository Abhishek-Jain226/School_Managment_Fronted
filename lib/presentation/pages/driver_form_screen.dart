// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';

// class DriverFormScreen extends StatefulWidget {
//   const DriverFormScreen({super.key});

//   @override
//   State<DriverFormScreen> createState() => _DriverFormScreenState();
// }

// class _DriverFormScreenState extends State<DriverFormScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _contactController = TextEditingController();
//   final TextEditingController _addressController = TextEditingController();
//   File? _imageFile;
//   bool _isActive = true;

//   final picker = ImagePicker();

//   // Pick image (choose from camera or gallery)
//   Future<void> _pickImage() async {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         return SafeArea(
//           child: Wrap(
//             children: [
//               ListTile(
//                 leading: const Icon(Icons.photo_library),
//                 title: const Text("Gallery"),
//                 onTap: () async {
//                   final pickedFile =
//                       await picker.pickImage(source: ImageSource.gallery);
//                   if (pickedFile != null) {
//                     setState(() {
//                       _imageFile = File(pickedFile.path);
//                     });
//                   }
//                   Navigator.pop(context); // close sheet
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.camera_alt),
//                 title: const Text("Camera"),
//                 onTap: () async {
//                   final pickedFile =
//                       await picker.pickImage(source: ImageSource.camera);
//                   if (pickedFile != null) {
//                     setState(() {
//                       _imageFile = File(pickedFile.path);
//                     });
//                   }
//                   Navigator.pop(context); // close sheet
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // Convert image to Base64
//   Future<String?> _convertImageToBase64() async {
//     if (_imageFile == null) return null;
//     final bytes = await _imageFile!.readAsBytes();
//     return base64Encode(bytes);
//   }

//   // Submit form
//   Future<void> _submitForm() async {
//     if (!_formKey.currentState!.validate()) return;

//     String? photoBase64 = await _convertImageToBase64();

//     final body = {
//       "driverName": _nameController.text.trim(),
//       "driverPhoto": photoBase64 ?? "",
//       "driverContactNumber": _contactController.text.trim(),
//       "driverAddress": _addressController.text.trim(),
//       "isActive": _isActive,
//       "createdBy": "Owner123" // Example: static owner ID
//     };

//     try {
//       final response = await http.post(
//         Uri.parse("http://10.255.19.208:9001/api/drivers/create"), // 🔥 Update backend URL
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(body),
//       );

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 201) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Driver created successfully")),
//         );
//         Navigator.pop(context); // go back to dashboard
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Error: ${data['message']}")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Register Driver")),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: SingleChildScrollView(
//           child: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 // Driver Name
//                 TextFormField(
//                   controller: _nameController,
//                   decoration: const InputDecoration(labelText: "Driver Name"),
//                   validator: (value) =>
//                       value == null || value.isEmpty ? "Enter driver name" : null,
//                 ),
//                 const SizedBox(height: 10),
//                 // Contact Number
//                 TextFormField(
//                   controller: _contactController,
//                   decoration: const InputDecoration(labelText: "Contact Number"),
//                   keyboardType: TextInputType.phone,
//                   validator: (value) =>
//                       value == null || value.length < 10 ? "Enter valid contact" : null,
//                 ),
//                 const SizedBox(height: 10),

//                 // Address
//                 TextFormField(
//                   controller: _addressController,
//                   decoration: const InputDecoration(labelText: "Address"),
//                   validator: (value) =>
//                       value == null || value.isEmpty ? "Enter address" : null,
//                 ),
//                 const SizedBox(height: 10),

//                 // Active Switch
//                 SwitchListTile(
//                   title: const Text("Is Active"),
//                   value: _isActive,
//                   onChanged: (val) {
//                     setState(() {
//                       _isActive = val;
//                     });
//                   },
//                 ),

//                 const SizedBox(height: 10),

//                 // Photo Upload
//                 Row(
//                   children: [
//                     ElevatedButton.icon(
//                       onPressed: _pickImage,
//                       icon: const Icon(Icons.photo),
//                       label: const Text("Select Photo"),
//                     ),
//                     const SizedBox(width: 10),
//                     _imageFile != null
//                         ? Image.file(_imageFile!,
//                             width: 80, height: 80, fit: BoxFit.cover)
//                         : const Text("No photo selected"),
//                   ],
//                 ), 

//                 const SizedBox(height: 20),

//                 // Submit Button
//                 ElevatedButton(
//                   onPressed: _submitForm,
//                   style: ElevatedButton.styleFrom(
//                     minimumSize: const Size(double.infinity, 50),
//                   ),
//                   child: const Text("Submit"),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

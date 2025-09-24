// // lib/presentation/pages/add_vehicle_page.dart
// import 'package:flutter/material.dart';
// import '../../services/vehicle_service.dart';
// import '../../data/models/vehicle_request.dart';
// import '../../data/models/api_response.dart';

// class AddVehiclePage extends StatefulWidget {
//   const AddVehiclePage({super.key}); // no schoolAdminId needed

//   @override
//   State<AddVehiclePage> createState() => _AddVehiclePageState();
// }

// class _AddVehiclePageState extends State<AddVehiclePage> {
//   final _formKey = GlobalKey<FormState>();
//   final VehicleService _service = VehicleService();

//   // Controllers
//   final _vehicleNumberCtrl = TextEditingController();
//   final _ownerNameCtrl = TextEditingController();
//   final _ownerNumberCtrl = TextEditingController();
//   final _registrationNumberCtrl = TextEditingController();
//   final _vehiclePhotoCtrl = TextEditingController();
//   final _schoolIdCtrl = TextEditingController(); // manual input
//   final _primaryDriverNameCtrl = TextEditingController();
//   final _primaryDriverContactCtrl = TextEditingController();
//   final _primaryDriverPhotoCtrl = TextEditingController();
//   final _alternateDriverNameCtrl = TextEditingController();
//   final _alternateDriverContactCtrl = TextEditingController();
//   final _alternateDriverPhotoCtrl = TextEditingController();

//   String status = 'ACTIVE';
//   bool isAlternateDriver = false;
//   bool isActive = true;
//   bool _isLoading = false;

//   @override
//   void dispose() {
//     _vehicleNumberCtrl.dispose();
//     _ownerNameCtrl.dispose();
//     _ownerNumberCtrl.dispose();
//     _registrationNumberCtrl.dispose();
//     _vehiclePhotoCtrl.dispose();
//     _schoolIdCtrl.dispose();
//     _primaryDriverNameCtrl.dispose();
//     _primaryDriverContactCtrl.dispose();
//     _primaryDriverPhotoCtrl.dispose();
//     _alternateDriverNameCtrl.dispose();
//     _alternateDriverContactCtrl.dispose();
//     _alternateDriverPhotoCtrl.dispose();
//     super.dispose();
//   }

//   void _submit() async {
//     if (!_formKey.currentState!.validate()) return;

//     final int? schoolId = int.tryParse(_schoolIdCtrl.text.trim());
//     if (schoolId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('School Admin ID must be a number')),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);

//     VehicleRequest vehicle = VehicleRequest(
//       vehicleNumber: _vehicleNumberCtrl.text.trim(),
//       ownerName: _ownerNameCtrl.text.trim(),
//       ownerNumber: _ownerNumberCtrl.text.trim(),
//       registrationNumber: _registrationNumberCtrl.text.trim(),
//       vehiclePhoto: _vehiclePhotoCtrl.text.trim(),
//       schoolAdminId: schoolId,
//       primaryDriverName: _primaryDriverNameCtrl.text.trim(),
//       primaryDriverContact: _primaryDriverContactCtrl.text.trim(),
//       primaryDriverPhoto: _primaryDriverPhotoCtrl.text.trim(),
//       alternateDriverName: _alternateDriverNameCtrl.text.trim().isEmpty ? null : _alternateDriverNameCtrl.text.trim(),
//       alternateDriverContact: _alternateDriverContactCtrl.text.trim().isEmpty ? null : _alternateDriverContactCtrl.text.trim(),
//       alternateDriverPhoto: _alternateDriverPhotoCtrl.text.trim().isEmpty ? null : _alternateDriverPhotoCtrl.text.trim(),
//       status: status,
//       isAlternateDriver: isAlternateDriver,
//       isActive: isActive,
//     );

//     ApiResponse res = await _service.addVehicle(vehicle);

//     setState(() => _isLoading = false);

//     if (res.success) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Vehicle added successfully')),
//       );
//       Navigator.pop(context); // back to dashboard
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(res.message ?? 'Error')),
//       );
//     }
//   }

//   Widget _buildTextField(String label, TextEditingController controller,
//       {TextInputType keyboardType = TextInputType.text,
//       bool isOptional = false,
//       String? Function(String?)? customValidator}) {
//     return TextFormField(
//       controller: controller,
//       keyboardType: keyboardType,
//       decoration: InputDecoration(
//         labelText: label,
//         border: const OutlineInputBorder(),
//       ),
//       validator: customValidator ??
//           (v) {
//             if (!isOptional && (v == null || v.trim().isEmpty)) {
//               return '$label is required';
//             }
//             if (keyboardType == TextInputType.phone && v != null && v.trim().isNotEmpty) {
//               final phoneRegex = RegExp(r'^\d{10}$');
//               if (!phoneRegex.hasMatch(v.trim())) return 'Enter valid 10-digit phone number';
//             }
//             return null;
//           },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Add Vehicle"), backgroundColor: Colors.deepPurple),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: _isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : Form(
//                 key: _formKey,
//                 child: ListView(
//                   children: [
//                     _buildTextField('Vehicle Number', _vehicleNumberCtrl),
//                     const SizedBox(height: 8),
//                     _buildTextField('Owner Name', _ownerNameCtrl),
//                     const SizedBox(height: 8),
//                     _buildTextField('Owner Contact', _ownerNumberCtrl, keyboardType: TextInputType.phone),
//                     const SizedBox(height: 8),
//                     _buildTextField('Registration Number', _registrationNumberCtrl),
//                     const SizedBox(height: 8),
//                     _buildTextField('Vehicle Photo URL', _vehiclePhotoCtrl, isOptional: true),
//                     const SizedBox(height: 8),
//                     _buildTextField(
//                       'School Admin ID',
//                       _schoolIdCtrl,
//                       keyboardType: TextInputType.number,
//                       customValidator: (v) {
//                         if (v == null || v.trim().isEmpty) return 'School Admin ID is required';
//                         if (int.tryParse(v.trim()) == null) return 'School Admin ID must be a number';
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 8),
//                     _buildTextField('Primary Driver Name', _primaryDriverNameCtrl),
//                     const SizedBox(height: 8),
//                     _buildTextField('Primary Driver Contact', _primaryDriverContactCtrl, keyboardType: TextInputType.phone),
//                     const SizedBox(height: 8),
//                     _buildTextField('Primary Driver Photo URL', _primaryDriverPhotoCtrl, isOptional: true),
//                     const SizedBox(height: 8),
//                     _buildTextField('Alternate Driver Name', _alternateDriverNameCtrl, isOptional: true),
//                     const SizedBox(height: 8),
//                     _buildTextField('Alternate Driver Contact', _alternateDriverContactCtrl, keyboardType: TextInputType.phone, isOptional: true),
//                     const SizedBox(height: 8),
//                     _buildTextField('Alternate Driver Photo URL', _alternateDriverPhotoCtrl, isOptional: true),
//                     const SizedBox(height: 12),
//                     DropdownButtonFormField<String>(
//                       value: status,
//                       decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
//                       items: const [
//                         DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
//                         DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
//                       ],
//                       onChanged: (v) => setState(() => status = v ?? 'ACTIVE'),
//                     ),
//                     SwitchListTile(
//                       title: const Text("Has Alternate Driver"),
//                       value: isAlternateDriver,
//                       onChanged: (v) => setState(() => isAlternateDriver = v),
//                     ),
//                     SwitchListTile(
//                       title: const Text("Is Active"),
//                       value: isActive,
//                       onChanged: (v) => setState(() => isActive = v),
//                     ),
//                     const SizedBox(height: 20),
//                     ElevatedButton(
//                       onPressed: _submit,
//                       style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
//                       child: const Text('Register Vehicle'),
//                     ),
//                   ],
//                 ),
//               ),
//       ),
//     );
//   }
// }

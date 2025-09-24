// import 'package:flutter/material.dart';
// import '../../data/models/school_admin_request.dart';
// import '../../services/school_admin_service.dart';

// class EditSchoolPage extends StatefulWidget {
//   final SchoolAdminRequest school;
//   const EditSchoolPage({super.key, required this.school});

//   @override
//   State<EditSchoolPage> createState() => _EditSchoolPageState();
// }

// class _EditSchoolPageState extends State<EditSchoolPage> {
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _nameC,
//       _addressC,
//       _cityC,
//       _districtC,
//       _stateC,
//       _pincodeC,
//       _contactC,
//       _emailC;

//   final SchoolAdminService _service = SchoolAdminService();
//   bool _saving = false;

//   @override
//   void initState() {
//     super.initState();
//     final s = widget.school;
//     _nameC = TextEditingController(text: s.schoolName);
//     _addressC = TextEditingController(text: s.address);
//     _cityC = TextEditingController(text: s.city);
//     _districtC = TextEditingController(text: s.district);
//     _stateC = TextEditingController(text: s.state);
//     _pincodeC = TextEditingController(text: s.pincode.toString());
//     _contactC = TextEditingController(text: s.contactNumber);
//     _emailC = TextEditingController(text: s.email);
//   }

//   @override
//   void dispose() {
//     _nameC.dispose();
//     _addressC.dispose();
//     _cityC.dispose();
//     _districtC.dispose();
//     _stateC.dispose();
//     _pincodeC.dispose();
//     _contactC.dispose();
//     _emailC.dispose();
//     super.dispose();
//   }

//   Future<void> _save() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _saving = true);

//     final updated = SchoolAdminRequest(
//       schoolName: _nameC.text.trim(),
//       schoolType: widget.school.schoolType,
//       affiliationBoard: widget.school.affiliationBoard,
//       registrationNumber: widget.school.registrationNumber,
//       address: _addressC.text.trim(),
//       city: _cityC.text.trim(),
//       district: _districtC.text.trim(),
//       state: _stateC.text.trim(),
//       pincode: int.tryParse(_pincodeC.text.trim()) ?? widget.school.pincode,
//       contactNumber: _contactC.text.trim(),
//       email: _emailC.text.trim(),
//       userId: widget.school.userId,
//       password: '',          // ignored
//       confirmPassword: null, // ignored
//     );

//     final success = await _service.updateSchool(updated);
//     setState(() => _saving = false);

//     if (success) {
//       await _service.saveSchoolData(updated);
//       ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('School updated')));
//       Navigator.pop(context, updated);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Update failed')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Edit School')),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               TextFormField(
//                 controller: _nameC,
//                 decoration: const InputDecoration(labelText: 'School Name'),
//                 validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
//               ),
//               const SizedBox(height: 8),
//               TextFormField(controller: _addressC, decoration: const InputDecoration(labelText: 'Address')),
//               const SizedBox(height: 8),
//               TextFormField(controller: _cityC, decoration: const InputDecoration(labelText: 'City')),
//               const SizedBox(height: 8),
//               TextFormField(controller: _districtC, decoration: const InputDecoration(labelText: 'District')),
//               const SizedBox(height: 8),
//               TextFormField(controller: _stateC, decoration: const InputDecoration(labelText: 'State')),
//               const SizedBox(height: 8),
//               TextFormField(controller: _pincodeC, decoration: const InputDecoration(labelText: 'Pincode'), keyboardType: TextInputType.number),
//               const SizedBox(height: 8),
//               TextFormField(controller: _contactC, decoration: const InputDecoration(labelText: 'Contact Number')),
//               const SizedBox(height: 8),
//               TextFormField(controller: _emailC, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
//               const SizedBox(height: 16),
//               _saving ? const CircularProgressIndicator() : ElevatedButton(onPressed: _save, child: const Text('Save')),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

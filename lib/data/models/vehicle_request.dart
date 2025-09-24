// // lib/data/models/vehicle_request.dart
// class VehicleRequest {
//   final String vehicleNumber;
//   final String ownerName;
//   final String ownerNumber;
//   final String registrationNumber;
//   final String vehiclePhoto;
//   final int schoolAdminId; // send numeric id
//   final String primaryDriverName;
//   final String primaryDriverContact;
//   final String primaryDriverPhoto;
//   final String? alternateDriverName;
//   final String? alternateDriverContact;
//   final String? alternateDriverPhoto;
//   final String status;
//   final bool isAlternateDriver;
//   final bool isActive;

//   VehicleRequest({
//     required this.vehicleNumber,
//     required this.ownerName,
//     required this.ownerNumber,
//     required this.registrationNumber,
//     required this.vehiclePhoto,
//     required this.schoolAdminId,
//     required this.primaryDriverName,
//     required this.primaryDriverContact,
//     required this.primaryDriverPhoto,
//     this.alternateDriverName,
//     this.alternateDriverContact,
//     this.alternateDriverPhoto,
//     required this.status,
//     this.isAlternateDriver = false,
//     this.isActive = true,
//   });

//   Map<String, dynamic> toJson() => {
//         'vehicleNumber': vehicleNumber,
//         'ownerName': ownerName,
//         'ownerNumber': ownerNumber,
//         'registrationNumber': registrationNumber,
//         'vehiclePhoto': vehiclePhoto,
//         'schoolAdminId': schoolAdminId,
//         'primaryDriverName': primaryDriverName,
//         'primaryDriverContact': primaryDriverContact,
//         'primaryDriverPhoto': primaryDriverPhoto,
//         'alternateDriverName': alternateDriverName,
//         'alternateDriverContact': alternateDriverContact,
//         'alternateDriverPhoto': alternateDriverPhoto,
//         'status': status,
//         'isAlternateDriver': isAlternateDriver,
//         'isActive': isActive,
//       };
// }

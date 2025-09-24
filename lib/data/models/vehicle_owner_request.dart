// lib/data/models/vehicle_owner_request.dart
class VehicleOwnerRequest {
  int? userId; // id of the user tying this owner (we will fill from prefs)
  final String name;
  final String email;
  final String contactNumber;
  final String address;
  final String createdBy; // who created this (from prefs)

  VehicleOwnerRequest({
    this.userId,
    required this.name,
    required this.email,
    required this.contactNumber,
    required this.address,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() => {
        if (userId != null) 'userId': userId,
        'name': name,
        'email': email,
        'contactNumber': contactNumber,
        'address': address,
        'createdBy': createdBy,
      };
}

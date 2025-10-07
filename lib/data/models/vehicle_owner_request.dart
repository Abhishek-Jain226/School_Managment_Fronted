// lib/data/models/vehicle_owner_request.dart
class VehicleOwnerRequest {
  final String name;
  final String email;
  final String contactNumber;
  final String address;
  final String createdBy; // who created this (from prefs)
  final String? ownerPhoto; // base64 encoded photo

  VehicleOwnerRequest({
    required this.name,
    required this.email,
    required this.contactNumber,
    required this.address,
    required this.createdBy,
    this.ownerPhoto,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'contactNumber': contactNumber,
        'address': address,
        'createdBy': createdBy,
        if (ownerPhoto != null) 'ownerPhoto': ownerPhoto,
      };
}

// lib/data/models/vehicle_owner_request.dart
import '../../utils/constants.dart';

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
        AppConstants.keyName: name,
        AppConstants.keyEmail: email,
        AppConstants.keyContactNumber: contactNumber,
        AppConstants.keyAddress: address,
        AppConstants.keyCreatedBy: createdBy,
        if (ownerPhoto != null) AppConstants.keyOwnerPhoto: ownerPhoto,
      };
}

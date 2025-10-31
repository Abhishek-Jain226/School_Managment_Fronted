// lib/data/models/vehicle_request.dart
import '../../utils/constants.dart';

class VehicleRequest {
  String vehicleNumber;
  String registrationNumber;
  String? vehiclePhoto; // base64 string
  String vehicleType;
  int capacity;

  String createdBy;

  VehicleRequest({
    required this.vehicleNumber,
    required this.registrationNumber,
    this.vehiclePhoto,
    required this.createdBy,
    required this.vehicleType,
    required this.capacity,
  });

  Map<String, dynamic> toJson() => {
        AppConstants.keyVehicleNumber: vehicleNumber,
        AppConstants.keyRegistrationNumber: registrationNumber,
        AppConstants.keyVehiclePhoto: vehiclePhoto,
        AppConstants.keyCreatedBy: createdBy,
        AppConstants.keyVehicleType: vehicleType,
        AppConstants.keyCapacity: capacity,
      };
}

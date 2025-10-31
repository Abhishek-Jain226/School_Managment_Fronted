// models/vehicle.dart
import '../../utils/constants.dart';

class Vehicle {
  final int? vehicleId;
  final String? vehicleNumber;
  final String? registrationNumber;
  final String? vehicleType;
  final bool? isActive;
  final String? ownerName;
  final String? driverName;
  final int? capacity;

  Vehicle({
    this.vehicleId,
    this.vehicleNumber,
    this.registrationNumber,
    this.vehicleType,
    this.isActive,
    this.ownerName,
    this.driverName,
    this.capacity,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      vehicleId: json[AppConstants.keyVehicleId],
      vehicleNumber: json[AppConstants.keyVehicleNumber],
      registrationNumber: json[AppConstants.keyRegistrationNumber],
      vehicleType: json[AppConstants.keyVehicleType],
      isActive: json[AppConstants.keyIsActive],
      ownerName: json[AppConstants.keyOwnerName],
      driverName: json[AppConstants.keyDriverName],
      capacity: json[AppConstants.keyCapacity],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConstants.keyVehicleId: vehicleId,
      AppConstants.keyVehicleNumber: vehicleNumber,
      AppConstants.keyRegistrationNumber: registrationNumber,
      AppConstants.keyVehicleType: vehicleType,
      AppConstants.keyIsActive: isActive,
      AppConstants.keyOwnerName: ownerName,
      AppConstants.keyDriverName: driverName,
      AppConstants.keyCapacity: capacity,
    };
  }
}

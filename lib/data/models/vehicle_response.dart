import '../../utils/constants.dart';

class VehicleResponse {
  final int? vehicleId;
  final String? vehicleNumber;
  final String? registrationNumber;
  final String? vehicleType;
  final bool? isActive;
  final String? ownerName;
  final String? driverName;
  final int? capacity;
  final String? createdBy;
  final String? createdDate;
  final String? updatedBy;
  final String? updatedDate;

  VehicleResponse({
    this.vehicleId,
    this.vehicleNumber,
    this.registrationNumber,
    this.vehicleType,
    this.isActive,
    this.ownerName,
    this.driverName,
    this.capacity,
    this.createdBy,
    this.createdDate,
    this.updatedBy,
    this.updatedDate,
  });

  factory VehicleResponse.fromJson(Map<String, dynamic> json) {
    return VehicleResponse(
      vehicleId: json[AppConstants.keyVehicleId],
      vehicleNumber: json[AppConstants.keyVehicleNumber],
      registrationNumber: json[AppConstants.keyRegistrationNumber],
      vehicleType: json[AppConstants.keyVehicleType],
      isActive: json[AppConstants.keyIsActive],
      ownerName: json[AppConstants.keyOwnerName],
      driverName: json[AppConstants.keyDriverName],
      capacity: json[AppConstants.keyCapacity],
      createdBy: json[AppConstants.keyCreatedBy],
      createdDate: json[AppConstants.keyCreatedDate],
      updatedBy: json[AppConstants.keyUpdatedBy],
      updatedDate: json[AppConstants.keyUpdatedDate],
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
      AppConstants.keyCreatedBy: createdBy,
      AppConstants.keyCreatedDate: createdDate,
      AppConstants.keyUpdatedBy: updatedBy,
      AppConstants.keyUpdatedDate: updatedDate,
    };
  }
}

// lib/data/models/vehicle_request.dart
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
        "vehicleNumber": vehicleNumber,
        "registrationNumber": registrationNumber,
        "vehiclePhoto": vehiclePhoto,
        "createdBy": createdBy,
        "vehicleType": vehicleType,
        "capacity": capacity,
      };
}

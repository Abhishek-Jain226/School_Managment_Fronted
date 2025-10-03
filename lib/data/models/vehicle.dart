// models/vehicle.dart
class Vehicle {
  final int vehicleId;
  final String vehicleNumber;

  Vehicle({
    required this.vehicleId,
    required this.vehicleNumber,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      vehicleId: json["vehicleId"],
      vehicleNumber: json["vehicleNumber"],
    );
  }
}

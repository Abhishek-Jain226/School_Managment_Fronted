// models/vehicle.dart
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
      vehicleId: json["vehicleId"],
      vehicleNumber: json["vehicleNumber"],
      registrationNumber: json["registrationNumber"],
      vehicleType: json["vehicleType"],
      isActive: json["isActive"],
      ownerName: json["ownerName"],
      driverName: json["driverName"],
      capacity: json["capacity"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "vehicleId": vehicleId,
      "vehicleNumber": vehicleNumber,
      "registrationNumber": registrationNumber,
      "vehicleType": vehicleType,
      "isActive": isActive,
      "ownerName": ownerName,
      "driverName": driverName,
      "capacity": capacity,
    };
  }
}

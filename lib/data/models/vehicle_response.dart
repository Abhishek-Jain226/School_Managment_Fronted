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
      vehicleId: json['vehicleId'],
      vehicleNumber: json['vehicleNumber'],
      registrationNumber: json['registrationNumber'],
      vehicleType: json['vehicleType'],
      isActive: json['isActive'],
      ownerName: json['ownerName'],
      driverName: json['driverName'],
      capacity: json['capacity'],
      createdBy: json['createdBy'],
      createdDate: json['createdDate'],
      updatedBy: json['updatedBy'],
      updatedDate: json['updatedDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'vehicleNumber': vehicleNumber,
      'registrationNumber': registrationNumber,
      'vehicleType': vehicleType,
      'isActive': isActive,
      'ownerName': ownerName,
      'driverName': driverName,
      'capacity': capacity,
      'createdBy': createdBy,
      'createdDate': createdDate,
      'updatedBy': updatedBy,
      'updatedDate': updatedDate,
    };
  }
}

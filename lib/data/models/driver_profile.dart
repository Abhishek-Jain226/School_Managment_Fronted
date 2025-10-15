class DriverProfile {
  final int driverId;
  final String driverName;
  final String email;
  final String driverContactNumber;
  final String driverAddress;
  final String? driverPhoto;
  final String schoolName;
  final String vehicleNumber;
  final String vehicleType;
  final bool isActive;
  final DateTime createdDate;
  final DateTime updatedDate;
  final String? licenseNumber;
  final String? emergencyContact;
  final String? bloodGroup;
  final String? experience;

  DriverProfile({
    required this.driverId,
    required this.driverName,
    required this.email,
    required this.driverContactNumber,
    required this.driverAddress,
    this.driverPhoto,
    required this.schoolName,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.isActive,
    required this.createdDate,
    required this.updatedDate,
    this.licenseNumber,
    this.emergencyContact,
    this.bloodGroup,
    this.experience,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      driverId: json['driverId'] ?? 0,
      driverName: json['driverName'] ?? '',
      email: json['email'] ?? '',
      driverContactNumber: json['driverContactNumber'] ?? '',
      driverAddress: json['driverAddress'] ?? '',
      driverPhoto: json['driverPhoto'],
      schoolName: json['schoolName'] ?? '',
      vehicleNumber: json['vehicleNumber'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      isActive: json['isActive'] ?? false,
      createdDate: DateTime.parse(json['createdDate'] ?? DateTime.now().toIso8601String()),
      updatedDate: DateTime.parse(json['updatedDate'] ?? DateTime.now().toIso8601String()),
      licenseNumber: json['licenseNumber'],
      emergencyContact: json['emergencyContact'],
      bloodGroup: json['bloodGroup'],
      experience: json['experience'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'email': email,
      'driverContactNumber': driverContactNumber,
      'driverAddress': driverAddress,
      'driverPhoto': driverPhoto,
      'schoolName': schoolName,
      'vehicleNumber': vehicleNumber,
      'vehicleType': vehicleType,
      'isActive': isActive,
      'createdDate': createdDate.toIso8601String(),
      'updatedDate': updatedDate.toIso8601String(),
      'licenseNumber': licenseNumber,
      'emergencyContact': emergencyContact,
      'bloodGroup': bloodGroup,
      'experience': experience,
    };
  }

  DriverProfile copyWith({
    int? driverId,
    String? driverName,
    String? email,
    String? driverContactNumber,
    String? driverAddress,
    String? driverPhoto,
    String? schoolName,
    String? vehicleNumber,
    String? vehicleType,
    bool? isActive,
    DateTime? createdDate,
    DateTime? updatedDate,
    String? licenseNumber,
    String? emergencyContact,
    String? bloodGroup,
    String? experience,
  }) {
    return DriverProfile(
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      email: email ?? this.email,
      driverContactNumber: driverContactNumber ?? this.driverContactNumber,
      driverAddress: driverAddress ?? this.driverAddress,
      driverPhoto: driverPhoto ?? this.driverPhoto,
      schoolName: schoolName ?? this.schoolName,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      isActive: isActive ?? this.isActive,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      experience: experience ?? this.experience,
    );
  }
}

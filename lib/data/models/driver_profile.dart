import '../../utils/constants.dart';

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
      driverId: json[AppConstants.keyDriverId] ?? 0,
      driverName: json[AppConstants.keyDriverName] ?? '',
      email: json[AppConstants.keyEmail] ?? '',
      driverContactNumber: json[AppConstants.keyDriverContactNumber] ?? '',
      driverAddress: json[AppConstants.keyDriverAddress] ?? '',
      driverPhoto: json[AppConstants.keyDriverPhoto],
      schoolName: json[AppConstants.keySchoolName] ?? '',
      vehicleNumber: json[AppConstants.keyVehicleNumber] ?? '',
      vehicleType: json[AppConstants.keyVehicleType] ?? '',
      isActive: json[AppConstants.keyIsActive] ?? false,
      createdDate: DateTime.parse(json[AppConstants.keyCreatedDate] ?? DateTime.now().toIso8601String()),
      updatedDate: DateTime.parse(json[AppConstants.keyUpdatedDate] ?? DateTime.now().toIso8601String()),
      licenseNumber: json[AppConstants.keyLicenseNumber],
      emergencyContact: json[AppConstants.keyEmergencyContact],
      bloodGroup: json[AppConstants.keyBloodGroup],
      experience: json[AppConstants.keyExperience],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConstants.keyDriverId: driverId,
      AppConstants.keyDriverName: driverName,
      AppConstants.keyEmail: email,
      AppConstants.keyDriverContactNumber: driverContactNumber,
      AppConstants.keyDriverAddress: driverAddress,
      AppConstants.keyDriverPhoto: driverPhoto,
      AppConstants.keySchoolName: schoolName,
      AppConstants.keyVehicleNumber: vehicleNumber,
      AppConstants.keyVehicleType: vehicleType,
      AppConstants.keyIsActive: isActive,
      AppConstants.keyCreatedDate: createdDate.toIso8601String(),
      AppConstants.keyUpdatedDate: updatedDate.toIso8601String(),
      AppConstants.keyLicenseNumber: licenseNumber,
      AppConstants.keyEmergencyContact: emergencyContact,
      AppConstants.keyBloodGroup: bloodGroup,
      AppConstants.keyExperience: experience,
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

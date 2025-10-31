// lib/data/models/driver_request.dart
import '../../utils/constants.dart';

class DriverRequest {
  final int userId; 
  final String driverName;
  final String driverContactNumber;
  final String driverAddress;
  final String? driverPhotoBase64;
  final String? email;
  final String createdBy;

  DriverRequest({
    required this.userId,
    required this.driverName,
    required this.driverContactNumber,
    required this.driverAddress,
    this.driverPhotoBase64,
    this.email,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() => {
        AppConstants.keyUserId: userId,
        AppConstants.keyDriverName: driverName,
        AppConstants.keyDriverContactNumber: driverContactNumber,
        AppConstants.keyDriverAddress: driverAddress,
        AppConstants.keyDriverPhoto: driverPhotoBase64,
        AppConstants.keyEmail: email,
        AppConstants.keyCreatedBy: createdBy,
      };
}

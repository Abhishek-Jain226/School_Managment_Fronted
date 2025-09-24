// lib/data/models/driver_request.dart
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
        "userId": userId,
        "driverName": driverName,
        "driverContactNumber": driverContactNumber,
        "driverAddress": driverAddress,
        "driverPhoto": driverPhotoBase64,
        "email": email,
        "createdBy": createdBy,
      };
}

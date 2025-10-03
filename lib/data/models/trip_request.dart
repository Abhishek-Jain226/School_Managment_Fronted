// models/trip_request.dart
class TripRequest {
  final int schoolId;
  final int vehicleId;
  final String tripName;
  final int tripNumber;
  final String createdBy;
  final String? updatedBy;

  TripRequest({
    required this.schoolId,
    required this.vehicleId,
    required this.tripName,
    required this.tripNumber,
    required this.createdBy,
    this.updatedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      "schoolId": schoolId,
      "vehicleId": vehicleId,
      "tripName": tripName,
      "tripNumber": tripNumber,
      "createdBy": createdBy,
      "updatedBy": updatedBy,
    };
  }
}

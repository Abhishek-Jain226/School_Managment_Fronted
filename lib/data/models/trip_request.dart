// models/trip_request.dart
class TripRequest {
  final int schoolId;
  final int vehicleId;
  final String tripName;
  final int tripNumber;
  final String tripType;
  final String routeName;
  final String routeDescription;
  final String createdBy;
  final String? updatedBy;

  TripRequest({
    required this.schoolId,
    required this.vehicleId,
    required this.tripName,
    required this.tripNumber,
    required this.tripType,
    required this.routeName,
    required this.routeDescription,
    required this.createdBy,
    this.updatedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      "schoolId": schoolId,
      "vehicleId": vehicleId,
      "tripName": tripName,
      "tripNumber": tripNumber,
      "tripType": tripType,
      "routeName": routeName,
      "routeDescription": routeDescription,
      "createdBy": createdBy,
      "updatedBy": updatedBy,
    };
  }
}

// models/trip_request.dart
class TripRequest {
  final int schoolId;
  final int vehicleId;
  final String tripName;
  final int tripNumber;
  final String tripType;
  final String? routeName;
  final String? startTime;
  final String? endTime;
  final String? routeDescription;
  final String createdBy;
  final String? updatedBy;

  TripRequest({
    required this.schoolId,
    required this.vehicleId,
    required this.tripName,
    required this.tripNumber,
    required this.tripType,
    this.routeName,
    this.startTime,
    this.endTime,
    this.routeDescription,
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
      "startTime": startTime,
      "endTime": endTime,
      "routeDescription": routeDescription,
      "createdBy": createdBy,
      "updatedBy": updatedBy,
    };
  }
}

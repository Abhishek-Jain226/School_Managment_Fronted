// models/trip_response.dart
import '../../utils/constants.dart';

class TripResponse {
  final int tripId;
  final int schoolId;
  final String schoolName;
  final int vehicleId;
  final String vehicleNumber;
  final String tripName;
  final int tripNumber;
  final bool isActive;

  TripResponse({
    required this.tripId,
    required this.schoolId,
    required this.schoolName,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.tripName,
    required this.tripNumber,
    required this.isActive,
  });

  factory TripResponse.fromJson(Map<String, dynamic> json) {
    return TripResponse(
      tripId: json[AppConstants.keyTripId],
      schoolId: json[AppConstants.keySchoolId],
      schoolName: json[AppConstants.keySchoolName],
      vehicleId: json[AppConstants.keyVehicleId],
      vehicleNumber: json[AppConstants.keyVehicleNumber],
      tripName: json[AppConstants.keyTripName],
      tripNumber: json[AppConstants.keyTripNumber],
      isActive: json[AppConstants.keyIsActive],
    );
  }
}

// models/trip_request.dart
import '../../utils/constants.dart';

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
      AppConstants.keySchoolId: schoolId,
      AppConstants.keyVehicleId: vehicleId,
      AppConstants.keyTripName: tripName,
      AppConstants.keyTripNumber: tripNumber,
      AppConstants.keyTripType: tripType,
      AppConstants.keyRouteName: routeName,
      AppConstants.keyRouteDescription: routeDescription,
      AppConstants.keyCreatedBy: createdBy,
      AppConstants.keyUpdatedBy: updatedBy,
    };
  }
}

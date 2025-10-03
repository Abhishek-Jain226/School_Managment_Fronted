// models/trip_response.dart
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
      tripId: json["tripId"],
      schoolId: json["schoolId"],
      schoolName: json["schoolName"],
      vehicleId: json["vehicleId"],
      vehicleNumber: json["vehicleNumber"],
      tripName: json["tripName"],
      tripNumber: json["tripNumber"],
      isActive: json["isActive"],
    );
  }
}

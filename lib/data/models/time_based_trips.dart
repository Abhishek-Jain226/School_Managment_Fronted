import 'trip.dart';

class TimeBasedTrips {
  final String currentTime;
  final String timeSlot;
  final String message;
  final List<Trip> availableTrips;
  final List<Trip> allTrips;
  final bool isWorkingHours;
  final String nextTripTime;
  final String workingHoursMessage;

  TimeBasedTrips({
    required this.currentTime,
    required this.timeSlot,
    required this.message,
    required this.availableTrips,
    required this.allTrips,
    required this.isWorkingHours,
    required this.nextTripTime,
    required this.workingHoursMessage,
  });

  factory TimeBasedTrips.fromJson(Map<String, dynamic> json) {
    return TimeBasedTrips(
      currentTime: json['currentTime'] ?? '',
      timeSlot: json['timeSlot'] ?? '',
      message: json['message'] ?? '',
      availableTrips: (json['availableTrips'] as List<dynamic>?)
          ?.map((trip) => Trip.fromJson(trip))
          .toList() ?? [],
      allTrips: (json['allTrips'] as List<dynamic>?)
          ?.map((trip) => Trip.fromJson(trip))
          .toList() ?? [],
      isWorkingHours: json['isWorkingHours'] ?? false,
      nextTripTime: json['nextTripTime'] ?? '',
      workingHoursMessage: json['workingHoursMessage'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentTime': currentTime,
      'timeSlot': timeSlot,
      'message': message,
      'availableTrips': availableTrips.map((trip) => trip.toJson()).toList(),
      'allTrips': allTrips.map((trip) => trip.toJson()).toList(),
      'isWorkingHours': isWorkingHours,
      'nextTripTime': nextTripTime,
      'workingHoursMessage': workingHoursMessage,
    };
  }

  // Helper methods for UI
  String get timeSlotDisplayName {
    switch (timeSlot) {
      case 'MORNING':
        return 'Morning Pickup (6 AM - 12 PM)';
      case 'AFTERNOON':
        return 'Afternoon Drop (12 PM - 6 PM)';
      case 'EVENING':
        return 'Evening (6 PM - 10 PM)';
      case 'NIGHT':
        return 'Night (10 PM - 6 AM)';
      default:
        return timeSlot;
    }
  }

  String get timeSlotIcon {
    switch (timeSlot) {
      case 'MORNING':
        return '🌅';
      case 'AFTERNOON':
        return '☀️';
      case 'EVENING':
        return '🌆';
      case 'NIGHT':
        return '🌙';
      default:
        return '🕐';
    }
  }

  String get statusMessage {
    if (isWorkingHours) {
      return 'You have ${availableTrips.length} trip(s) scheduled for this time slot.';
    } else {
      return 'No trips scheduled for this time slot.';
    }
  }
}

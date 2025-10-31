import '../../utils/constants.dart';

class DriverReports {
  final int totalTripsCompleted;
  final int totalStudentsTransported;
  final int totalDistanceCovered;
  final double averageRating;
  final int todayTrips;
  final int todayStudents;
  final int todayPickups;
  final int todayDrops;
  final int weekTrips;
  final int weekStudents;
  final int weekPickups;
  final int weekDrops;
  final int monthTrips;
  final int monthStudents;
  final int monthPickups;
  final int monthDrops;
  final List<AttendanceRecord> attendanceRecords;
  final List<RecentTrip> recentTrips;

  DriverReports({
    required this.totalTripsCompleted,
    required this.totalStudentsTransported,
    required this.totalDistanceCovered,
    required this.averageRating,
    required this.todayTrips,
    required this.todayStudents,
    required this.todayPickups,
    required this.todayDrops,
    required this.weekTrips,
    required this.weekStudents,
    required this.weekPickups,
    required this.weekDrops,
    required this.monthTrips,
    required this.monthStudents,
    required this.monthPickups,
    required this.monthDrops,
    required this.attendanceRecords,
    required this.recentTrips,
  });

  factory DriverReports.fromJson(Map<String, dynamic> json) {
    return DriverReports(
      totalTripsCompleted: json[AppConstants.keyTotalTripsCompleted] ?? 0,
      totalStudentsTransported: json[AppConstants.keyTotalStudentsTransported] ?? 0,
      totalDistanceCovered: json[AppConstants.keyTotalDistanceCovered] ?? 0,
      averageRating: (json[AppConstants.keyAverageRating] ?? 0.0).toDouble(),
      todayTrips: json[AppConstants.keyTodayTrips] ?? 0,
      todayStudents: json[AppConstants.keyTodayStudents] ?? 0,
      todayPickups: json[AppConstants.keyTodayPickups] ?? 0,
      todayDrops: json[AppConstants.keyTodayDrops] ?? 0,
      weekTrips: json[AppConstants.keyWeekTrips] ?? 0,
      weekStudents: json[AppConstants.keyWeekStudents] ?? 0,
      weekPickups: json[AppConstants.keyWeekPickups] ?? 0,
      weekDrops: json[AppConstants.keyWeekDrops] ?? 0,
      monthTrips: json[AppConstants.keyMonthTrips] ?? 0,
      monthStudents: json[AppConstants.keyMonthStudents] ?? 0,
      monthPickups: json[AppConstants.keyMonthPickups] ?? 0,
      monthDrops: json[AppConstants.keyMonthDrops] ?? 0,
      attendanceRecords: (json[AppConstants.keyAttendanceRecords] as List<dynamic>?)
          ?.map((record) => AttendanceRecord.fromJson(record))
          .toList() ?? [],
      recentTrips: (json[AppConstants.keyRecentTrips] as List<dynamic>?)
          ?.map((trip) => RecentTrip.fromJson(trip))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConstants.keyTotalTripsCompleted: totalTripsCompleted,
      AppConstants.keyTotalStudentsTransported: totalStudentsTransported,
      AppConstants.keyTotalDistanceCovered: totalDistanceCovered,
      AppConstants.keyAverageRating: averageRating,
      AppConstants.keyTodayTrips: todayTrips,
      AppConstants.keyTodayStudents: todayStudents,
      AppConstants.keyTodayPickups: todayPickups,
      AppConstants.keyTodayDrops: todayDrops,
      AppConstants.keyWeekTrips: weekTrips,
      AppConstants.keyWeekStudents: weekStudents,
      AppConstants.keyWeekPickups: weekPickups,
      AppConstants.keyWeekDrops: weekDrops,
      AppConstants.keyMonthTrips: monthTrips,
      AppConstants.keyMonthStudents: monthStudents,
      AppConstants.keyMonthPickups: monthPickups,
      AppConstants.keyMonthDrops: monthDrops,
      AppConstants.keyAttendanceRecords: attendanceRecords.map((record) => record.toJson()).toList(),
      AppConstants.keyRecentTrips: recentTrips.map((trip) => trip.toJson()).toList(),
    };
  }
}

class AttendanceRecord {
  final DateTime date;
  final int totalTrips;
  final int completedTrips;
  final int studentsPickedUp;
  final int studentsDropped;
  final String status;

  AttendanceRecord({
    required this.date,
    required this.totalTrips,
    required this.completedTrips,
    required this.studentsPickedUp,
    required this.studentsDropped,
    required this.status,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: DateTime.parse(json[AppConstants.keyDate] ?? DateTime.now().toIso8601String()),
      totalTrips: json[AppConstants.keyTotalTrips] ?? 0,
      completedTrips: json[AppConstants.keyCompletedTrips] ?? 0,
      studentsPickedUp: json[AppConstants.keyStudentsPickedUp] ?? 0,
      studentsDropped: json[AppConstants.keyStudentsDropped] ?? 0,
      status: json[AppConstants.keyStatus] ?? 'UNKNOWN',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConstants.keyDate: date.toIso8601String(),
      AppConstants.keyTotalTrips: totalTrips,
      AppConstants.keyCompletedTrips: completedTrips,
      AppConstants.keyStudentsPickedUp: studentsPickedUp,
      AppConstants.keyStudentsDropped: studentsDropped,
      AppConstants.keyStatus: status,
    };
  }
}

class RecentTrip {
  final int tripId;
  final String tripName;
  final String tripType;
  final DateTime tripDate;
  final String startTime;
  final String endTime;
  final int studentsCount;
  final String status;
  final String route;

  RecentTrip({
    required this.tripId,
    required this.tripName,
    required this.tripType,
    required this.tripDate,
    required this.startTime,
    required this.endTime,
    required this.studentsCount,
    required this.status,
    required this.route,
  });

  factory RecentTrip.fromJson(Map<String, dynamic> json) {
    return RecentTrip(
      tripId: json[AppConstants.keyTripId] ?? 0,
      tripName: json[AppConstants.keyCurrentTripName] ?? '',
      tripType: json[AppConstants.keyTripType] ?? '',
      tripDate: DateTime.parse(json[AppConstants.keyTripDate] ?? DateTime.now().toIso8601String()),
      startTime: json[AppConstants.keyStartTime] ?? '',
      endTime: json[AppConstants.keyEndTime] ?? '',
      studentsCount: json[AppConstants.keyStudentsCount] ?? 0,
      status: json[AppConstants.keyStatus] ?? '',
      route: json[AppConstants.keyRoute] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConstants.keyTripId: tripId,
      AppConstants.keyCurrentTripName: tripName,
      AppConstants.keyTripType: tripType,
      AppConstants.keyTripDate: tripDate.toIso8601String(),
      AppConstants.keyStartTime: startTime,
      AppConstants.keyEndTime: endTime,
      AppConstants.keyStudentsCount: studentsCount,
      AppConstants.keyStatus: status,
      AppConstants.keyRoute: route,
    };
  }
}

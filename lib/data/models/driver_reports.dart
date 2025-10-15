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
      totalTripsCompleted: json['totalTripsCompleted'] ?? 0,
      totalStudentsTransported: json['totalStudentsTransported'] ?? 0,
      totalDistanceCovered: json['totalDistanceCovered'] ?? 0,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      todayTrips: json['todayTrips'] ?? 0,
      todayStudents: json['todayStudents'] ?? 0,
      todayPickups: json['todayPickups'] ?? 0,
      todayDrops: json['todayDrops'] ?? 0,
      weekTrips: json['weekTrips'] ?? 0,
      weekStudents: json['weekStudents'] ?? 0,
      weekPickups: json['weekPickups'] ?? 0,
      weekDrops: json['weekDrops'] ?? 0,
      monthTrips: json['monthTrips'] ?? 0,
      monthStudents: json['monthStudents'] ?? 0,
      monthPickups: json['monthPickups'] ?? 0,
      monthDrops: json['monthDrops'] ?? 0,
      attendanceRecords: (json['attendanceRecords'] as List<dynamic>?)
          ?.map((record) => AttendanceRecord.fromJson(record))
          .toList() ?? [],
      recentTrips: (json['recentTrips'] as List<dynamic>?)
          ?.map((trip) => RecentTrip.fromJson(trip))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTripsCompleted': totalTripsCompleted,
      'totalStudentsTransported': totalStudentsTransported,
      'totalDistanceCovered': totalDistanceCovered,
      'averageRating': averageRating,
      'todayTrips': todayTrips,
      'todayStudents': todayStudents,
      'todayPickups': todayPickups,
      'todayDrops': todayDrops,
      'weekTrips': weekTrips,
      'weekStudents': weekStudents,
      'weekPickups': weekPickups,
      'weekDrops': weekDrops,
      'monthTrips': monthTrips,
      'monthStudents': monthStudents,
      'monthPickups': monthPickups,
      'monthDrops': monthDrops,
      'attendanceRecords': attendanceRecords.map((record) => record.toJson()).toList(),
      'recentTrips': recentTrips.map((trip) => trip.toJson()).toList(),
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
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      totalTrips: json['totalTrips'] ?? 0,
      completedTrips: json['completedTrips'] ?? 0,
      studentsPickedUp: json['studentsPickedUp'] ?? 0,
      studentsDropped: json['studentsDropped'] ?? 0,
      status: json['status'] ?? 'UNKNOWN',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'totalTrips': totalTrips,
      'completedTrips': completedTrips,
      'studentsPickedUp': studentsPickedUp,
      'studentsDropped': studentsDropped,
      'status': status,
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
      tripId: json['tripId'] ?? 0,
      tripName: json['tripName'] ?? '',
      tripType: json['tripType'] ?? '',
      tripDate: DateTime.parse(json['tripDate'] ?? DateTime.now().toIso8601String()),
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      studentsCount: json['studentsCount'] ?? 0,
      status: json['status'] ?? '',
      route: json['route'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'tripName': tripName,
      'tripType': tripType,
      'tripDate': tripDate.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'studentsCount': studentsCount,
      'status': status,
      'route': route,
    };
  }
}

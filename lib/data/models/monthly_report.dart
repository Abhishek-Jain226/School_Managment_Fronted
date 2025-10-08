class MonthlyReport {
  final int studentId;
  final String studentName;
  final String schoolName;
  final String className;
  final String sectionName;
  final int year;
  final int month;
  final String monthName;
  final int totalSchoolDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final double attendancePercentage;
  final int totalTrips;
  final int completedTrips;
  final int missedTrips;
  final double tripCompletionRate;
  final Map<String, dynamic> performanceMetrics;
  final List<DailyReport> dailyReports;
  final List<WeeklyReport> weeklyReports;

  MonthlyReport({
    required this.studentId,
    required this.studentName,
    required this.schoolName,
    required this.className,
    required this.sectionName,
    required this.year,
    required this.month,
    required this.monthName,
    required this.totalSchoolDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.attendancePercentage,
    required this.totalTrips,
    required this.completedTrips,
    required this.missedTrips,
    required this.tripCompletionRate,
    required this.performanceMetrics,
    required this.dailyReports,
    required this.weeklyReports,
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    return MonthlyReport(
      studentId: json['studentId'] ?? 0,
      studentName: json['studentName'] ?? '',
      schoolName: json['schoolName'] ?? '',
      className: json['className'] ?? '',
      sectionName: json['sectionName'] ?? '',
      year: json['year'] ?? DateTime.now().year,
      month: json['month'] ?? DateTime.now().month,
      monthName: json['monthName'] ?? '',
      totalSchoolDays: json['totalSchoolDays'] ?? 0,
      presentDays: json['presentDays'] ?? 0,
      absentDays: json['absentDays'] ?? 0,
      lateDays: json['lateDays'] ?? 0,
      attendancePercentage: (json['attendancePercentage'] ?? 0.0).toDouble(),
      totalTrips: json['totalTrips'] ?? 0,
      completedTrips: json['completedTrips'] ?? 0,
      missedTrips: json['missedTrips'] ?? 0,
      tripCompletionRate: (json['tripCompletionRate'] ?? 0.0).toDouble(),
      performanceMetrics: Map<String, dynamic>.from(json['performanceMetrics'] ?? {}),
      dailyReports: (json['dailyReports'] as List<dynamic>?)
          ?.map((report) => DailyReport.fromJson(report))
          .toList() ?? [],
      weeklyReports: (json['weeklyReports'] as List<dynamic>?)
          ?.map((report) => WeeklyReport.fromJson(report))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'schoolName': schoolName,
      'className': className,
      'sectionName': sectionName,
      'year': year,
      'month': month,
      'monthName': monthName,
      'totalSchoolDays': totalSchoolDays,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'lateDays': lateDays,
      'attendancePercentage': attendancePercentage,
      'totalTrips': totalTrips,
      'completedTrips': completedTrips,
      'missedTrips': missedTrips,
      'tripCompletionRate': tripCompletionRate,
      'performanceMetrics': performanceMetrics,
      'dailyReports': dailyReports.map((report) => report.toJson()).toList(),
      'weeklyReports': weeklyReports.map((report) => report.toJson()).toList(),
    };
  }
}

class DailyReport {
  final DateTime date;
  final String dayOfWeek;
  final String attendanceStatus;
  final String tripStatus;
  final String? arrivalTime;
  final String? departureTime;
  final String? remarks;

  DailyReport({
    required this.date,
    required this.dayOfWeek,
    required this.attendanceStatus,
    required this.tripStatus,
    this.arrivalTime,
    this.departureTime,
    this.remarks,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    return DailyReport(
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      dayOfWeek: json['dayOfWeek'] ?? '',
      attendanceStatus: json['attendanceStatus'] ?? '',
      tripStatus: json['tripStatus'] ?? '',
      arrivalTime: json['arrivalTime'],
      departureTime: json['departureTime'],
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'dayOfWeek': dayOfWeek,
      'attendanceStatus': attendanceStatus,
      'tripStatus': tripStatus,
      'arrivalTime': arrivalTime,
      'departureTime': departureTime,
      'remarks': remarks,
    };
  }
}

class WeeklyReport {
  final int weekNumber;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final double weeklyAttendancePercentage;

  WeeklyReport({
    required this.weekNumber,
    required this.weekStart,
    required this.weekEnd,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.weeklyAttendancePercentage,
  });

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    return WeeklyReport(
      weekNumber: json['weekNumber'] ?? 0,
      weekStart: DateTime.parse(json['weekStart'] ?? DateTime.now().toIso8601String()),
      weekEnd: DateTime.parse(json['weekEnd'] ?? DateTime.now().toIso8601String()),
      presentDays: json['presentDays'] ?? 0,
      absentDays: json['absentDays'] ?? 0,
      lateDays: json['lateDays'] ?? 0,
      weeklyAttendancePercentage: (json['weeklyAttendancePercentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekNumber': weekNumber,
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'presentDays': presentDays,
      'absentDays': absentDays,
      'lateDays': lateDays,
      'weeklyAttendancePercentage': weeklyAttendancePercentage,
    };
  }
}

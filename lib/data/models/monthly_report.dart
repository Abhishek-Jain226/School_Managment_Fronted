import '../../utils/constants.dart';

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
      studentId: json[AppConstants.keyStudentId] ?? 0,
      studentName: json[AppConstants.keyStudentName] ?? '',
      schoolName: json[AppConstants.keySchoolName] ?? '',
      className: json[AppConstants.keyClassName] ?? '',
      sectionName: json[AppConstants.keySectionName] ?? '',
      year: json[AppConstants.keyYear] ?? DateTime.now().year,
      month: json[AppConstants.keyMonth] ?? DateTime.now().month,
      monthName: json[AppConstants.keyMonthName] ?? '',
      totalSchoolDays: json[AppConstants.keyTotalSchoolDays] ?? 0,
      presentDays: json[AppConstants.keyPresentDays] ?? 0,
      absentDays: json[AppConstants.keyAbsentDays] ?? 0,
      lateDays: json[AppConstants.keyLateDays] ?? 0,
      attendancePercentage: (json[AppConstants.keyAttendancePercentage] ?? 0.0).toDouble(),
      totalTrips: json[AppConstants.keyTotalTrips] ?? 0,
      completedTrips: json[AppConstants.keyCompletedTrips] ?? 0,
      missedTrips: json[AppConstants.keyMissedTrips] ?? 0,
      tripCompletionRate: (json[AppConstants.keyTripCompletionRate] ?? 0.0).toDouble(),
      performanceMetrics: Map<String, dynamic>.from(json[AppConstants.keyPerformanceMetrics] ?? {}),
      dailyReports: (json[AppConstants.keyDailyReports] as List<dynamic>?)
          ?.map((report) => DailyReport.fromJson(report))
          .toList() ?? [],
      weeklyReports: (json[AppConstants.keyWeeklyReports] as List<dynamic>?)
          ?.map((report) => WeeklyReport.fromJson(report))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConstants.keyStudentId: studentId,
      AppConstants.keyStudentName: studentName,
      AppConstants.keySchoolName: schoolName,
      AppConstants.keyClassName: className,
      AppConstants.keySectionName: sectionName,
      AppConstants.keyYear: year,
      AppConstants.keyMonth: month,
      AppConstants.keyMonthName: monthName,
      AppConstants.keyTotalSchoolDays: totalSchoolDays,
      AppConstants.keyPresentDays: presentDays,
      AppConstants.keyAbsentDays: absentDays,
      AppConstants.keyLateDays: lateDays,
      AppConstants.keyAttendancePercentage: attendancePercentage,
      AppConstants.keyTotalTrips: totalTrips,
      AppConstants.keyCompletedTrips: completedTrips,
      AppConstants.keyMissedTrips: missedTrips,
      AppConstants.keyTripCompletionRate: tripCompletionRate,
      AppConstants.keyPerformanceMetrics: performanceMetrics,
      AppConstants.keyDailyReports: dailyReports.map((report) => report.toJson()).toList(),
      AppConstants.keyWeeklyReports: weeklyReports.map((report) => report.toJson()).toList(),
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
      date: DateTime.parse(json[AppConstants.keyDate] ?? DateTime.now().toIso8601String()),
      dayOfWeek: json[AppConstants.keyDayOfWeek] ?? '',
      attendanceStatus: json[AppConstants.keyAttendanceStatus] ?? '',
      tripStatus: json[AppConstants.keyTripStatus] ?? '',
      arrivalTime: json[AppConstants.keyArrivalTime],
      departureTime: json[AppConstants.keyDepartureTime],
      remarks: json[AppConstants.keyRemarks],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConstants.keyDate: date.toIso8601String(),
      AppConstants.keyDayOfWeek: dayOfWeek,
      AppConstants.keyAttendanceStatus: attendanceStatus,
      AppConstants.keyTripStatus: tripStatus,
      AppConstants.keyArrivalTime: arrivalTime,
      AppConstants.keyDepartureTime: departureTime,
      AppConstants.keyRemarks: remarks,
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
      weekNumber: json[AppConstants.keyWeekNumber] ?? 0,
      weekStart: DateTime.parse(json[AppConstants.keyWeekStart] ?? DateTime.now().toIso8601String()),
      weekEnd: DateTime.parse(json[AppConstants.keyWeekEnd] ?? DateTime.now().toIso8601String()),
      presentDays: json[AppConstants.keyPresentDays] ?? 0,
      absentDays: json[AppConstants.keyAbsentDays] ?? 0,
      lateDays: json[AppConstants.keyLateDays] ?? 0,
      weeklyAttendancePercentage: (json[AppConstants.keyWeeklyAttendancePercentage] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConstants.keyWeekNumber: weekNumber,
      AppConstants.keyWeekStart: weekStart.toIso8601String(),
      AppConstants.keyWeekEnd: weekEnd.toIso8601String(),
      AppConstants.keyPresentDays: presentDays,
      AppConstants.keyAbsentDays: absentDays,
      AppConstants.keyLateDays: lateDays,
      AppConstants.keyWeeklyAttendancePercentage: weeklyAttendancePercentage,
    };
  }
}

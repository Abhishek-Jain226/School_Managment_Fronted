import '../../utils/constants.dart';

class AttendanceHistory {
  final int studentId;
  final String studentName;
  final DateTime fromDate;
  final DateTime toDate;
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final double attendancePercentage;
  final List<AttendanceRecord> attendanceRecords;

  AttendanceHistory({
    required this.studentId,
    required this.studentName,
    required this.fromDate,
    required this.toDate,
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.attendancePercentage,
    required this.attendanceRecords,
  });

  factory AttendanceHistory.fromJson(Map<String, dynamic> json) {
    return AttendanceHistory(
      studentId: json[AppConstants.keyStudentId] ?? 0,
      studentName: json[AppConstants.keyStudentName] ?? '',
      fromDate: DateTime.parse(json[AppConstants.keyFromDate] ?? DateTime.now().toIso8601String()),
      toDate: DateTime.parse(json[AppConstants.keyToDate] ?? DateTime.now().toIso8601String()),
      totalDays: json[AppConstants.keyTotalDays] ?? 0,
      presentDays: json[AppConstants.keyPresentDays] ?? 0,
      absentDays: json[AppConstants.keyAbsentDays] ?? 0,
      lateDays: json[AppConstants.keyLateDays] ?? 0,
      attendancePercentage: (json[AppConstants.keyAttendancePercentage] ?? 0.0).toDouble(),
      attendanceRecords: (json[AppConstants.keyAttendanceRecords] as List<dynamic>?)
          ?.map((record) => AttendanceRecord.fromJson(record))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConstants.keyStudentId: studentId,
      AppConstants.keyStudentName: studentName,
      AppConstants.keyFromDate: fromDate.toIso8601String(),
      AppConstants.keyToDate: toDate.toIso8601String(),
      AppConstants.keyTotalDays: totalDays,
      AppConstants.keyPresentDays: presentDays,
      AppConstants.keyAbsentDays: absentDays,
      AppConstants.keyLateDays: lateDays,
      AppConstants.keyAttendancePercentage: attendancePercentage,
      AppConstants.keyAttendanceRecords: attendanceRecords.map((record) => record.toJson()).toList(),
    };
  }
}

class AttendanceRecord {
  final DateTime date;
  final String dayOfWeek;
  final bool isPresent;
  final bool isAbsent;
  final bool isLate;
  final String? arrivalTime;
  final String? departureTime;
  final String? remarks;

  AttendanceRecord({
    required this.date,
    required this.dayOfWeek,
    required this.isPresent,
    required this.isAbsent,
    required this.isLate,
    this.arrivalTime,
    this.departureTime,
    this.remarks,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: DateTime.parse(json[AppConstants.keyDate] ?? DateTime.now().toIso8601String()),
      dayOfWeek: json[AppConstants.keyDayOfWeek] ?? '',
      isPresent: json[AppConstants.keyIsPresent] ?? false,
      isAbsent: json[AppConstants.keyIsAbsent] ?? false,
      isLate: json[AppConstants.keyIsLate] ?? false,
      arrivalTime: json[AppConstants.keyArrivalTime],
      departureTime: json[AppConstants.keyDepartureTime],
      remarks: json[AppConstants.keyRemarks],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConstants.keyDate: date.toIso8601String(),
      AppConstants.keyDayOfWeek: dayOfWeek,
      AppConstants.keyIsPresent: isPresent,
      AppConstants.keyIsAbsent: isAbsent,
      AppConstants.keyIsLate: isLate,
      AppConstants.keyArrivalTime: arrivalTime,
      AppConstants.keyDepartureTime: departureTime,
      AppConstants.keyRemarks: remarks,
    };
  }
}

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
      studentId: json['studentId'] ?? 0,
      studentName: json['studentName'] ?? '',
      fromDate: DateTime.parse(json['fromDate'] ?? DateTime.now().toIso8601String()),
      toDate: DateTime.parse(json['toDate'] ?? DateTime.now().toIso8601String()),
      totalDays: json['totalDays'] ?? 0,
      presentDays: json['presentDays'] ?? 0,
      absentDays: json['absentDays'] ?? 0,
      lateDays: json['lateDays'] ?? 0,
      attendancePercentage: (json['attendancePercentage'] ?? 0.0).toDouble(),
      attendanceRecords: (json['attendanceRecords'] as List<dynamic>?)
          ?.map((record) => AttendanceRecord.fromJson(record))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'fromDate': fromDate.toIso8601String(),
      'toDate': toDate.toIso8601String(),
      'totalDays': totalDays,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'lateDays': lateDays,
      'attendancePercentage': attendancePercentage,
      'attendanceRecords': attendanceRecords.map((record) => record.toJson()).toList(),
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
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      dayOfWeek: json['dayOfWeek'] ?? '',
      isPresent: json['isPresent'] ?? false,
      isAbsent: json['isAbsent'] ?? false,
      isLate: json['isLate'] ?? false,
      arrivalTime: json['arrivalTime'],
      departureTime: json['departureTime'],
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'dayOfWeek': dayOfWeek,
      'isPresent': isPresent,
      'isAbsent': isAbsent,
      'isLate': isLate,
      'arrivalTime': arrivalTime,
      'departureTime': departureTime,
      'remarks': remarks,
    };
  }
}

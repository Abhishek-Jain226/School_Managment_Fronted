class ParentDashboard {
  final int userId;
  final String userName;
  final String email;
  final String contactNumber;
  final int studentId;
  final String studentName;
  final String? studentPhoto;
  final String className;
  final String sectionName;
  final String schoolName;
  final String todayAttendanceStatus;
  final String? todayArrivalTime;
  final String? todayDepartureTime;
  final int totalPresentDays;
  final int totalAbsentDays;
  final int totalLateDays;
  final double attendancePercentage;
  final List<Map<String, dynamic>> recentNotifications;
  final List<Map<String, dynamic>> recentTrips;
  final DateTime lastUpdated;

  ParentDashboard({
    required this.userId,
    required this.userName,
    required this.email,
    required this.contactNumber,
    required this.studentId,
    required this.studentName,
    this.studentPhoto,
    required this.className,
    required this.sectionName,
    required this.schoolName,
    required this.todayAttendanceStatus,
    this.todayArrivalTime,
    this.todayDepartureTime,
    required this.totalPresentDays,
    required this.totalAbsentDays,
    required this.totalLateDays,
    required this.attendancePercentage,
    required this.recentNotifications,
    required this.recentTrips,
    required this.lastUpdated,
  });

  factory ParentDashboard.fromJson(Map<String, dynamic> json) {
    return ParentDashboard(
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      email: json['email'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
      studentId: json['studentId'] ?? 0,
      studentName: json['studentName'] ?? '',
      studentPhoto: json['studentPhoto'],
      className: json['className'] ?? 'N/A',
      sectionName: json['sectionName'] ?? 'N/A',
      schoolName: json['schoolName'] ?? 'N/A',
      todayAttendanceStatus: json['todayAttendanceStatus'] ?? 'Not Marked',
      todayArrivalTime: json['todayArrivalTime'],
      todayDepartureTime: json['todayDepartureTime'],
      totalPresentDays: json['totalPresentDays'] ?? 0,
      totalAbsentDays: json['totalAbsentDays'] ?? 0,
      totalLateDays: json['totalLateDays'] ?? 0,
      attendancePercentage: (json['attendancePercentage'] ?? 0.0).toDouble(),
      recentNotifications: List<Map<String, dynamic>>.from(json['recentNotifications'] ?? []),
      recentTrips: List<Map<String, dynamic>>.from(json['recentTrips'] ?? []),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'email': email,
      'contactNumber': contactNumber,
      'studentId': studentId,
      'studentName': studentName,
      'studentPhoto': studentPhoto,
      'className': className,
      'sectionName': sectionName,
      'schoolName': schoolName,
      'todayAttendanceStatus': todayAttendanceStatus,
      'todayArrivalTime': todayArrivalTime,
      'todayDepartureTime': todayDepartureTime,
      'totalPresentDays': totalPresentDays,
      'totalAbsentDays': totalAbsentDays,
      'totalLateDays': totalLateDays,
      'attendancePercentage': attendancePercentage,
      'recentNotifications': recentNotifications,
      'recentTrips': recentTrips,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

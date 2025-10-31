import '../../utils/constants.dart';

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
      userId: json[AppConstants.keyUserId] ?? 0,
      userName: json[AppConstants.keyUserName] ?? '',
      email: json[AppConstants.keyEmail] ?? '',
      contactNumber: json[AppConstants.keyContactNumber] ?? '',
      studentId: json[AppConstants.keyStudentId] ?? 0,
      studentName: json[AppConstants.keyStudentName] ?? '',
      studentPhoto: json[AppConstants.keyStudentPhoto],
      className: json[AppConstants.keyClassName] ?? 'N/A',
      sectionName: json[AppConstants.keySectionName] ?? 'N/A',
      schoolName: json[AppConstants.keySchoolName] ?? 'N/A',
      todayAttendanceStatus: json[AppConstants.keyTodayAttendanceStatus] ?? 'Not Marked',
      todayArrivalTime: json[AppConstants.keyTodayArrivalTime],
      todayDepartureTime: json[AppConstants.keyTodayDepartureTime],
      totalPresentDays: json[AppConstants.keyPresentDays] ?? 0,
      totalAbsentDays: json[AppConstants.keyAbsentDays] ?? 0,
      totalLateDays: json[AppConstants.keyLateDays] ?? 0,
      attendancePercentage: (json[AppConstants.keyAttendancePercentage] ?? 0.0).toDouble(),
      recentNotifications: List<Map<String, dynamic>>.from(json[AppConstants.keyRecentNotifications] ?? []),
      recentTrips: List<Map<String, dynamic>>.from(json[AppConstants.keyRecentTrips] ?? []),
      lastUpdated: DateTime.parse(json[AppConstants.keyLastUpdated] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConstants.keyUserId: userId,
      AppConstants.keyUserName: userName,
      AppConstants.keyEmail: email,
      AppConstants.keyContactNumber: contactNumber,
      AppConstants.keyStudentId: studentId,
      AppConstants.keyStudentName: studentName,
      AppConstants.keyStudentPhoto: studentPhoto,
      AppConstants.keyClassName: className,
      AppConstants.keySectionName: sectionName,
      AppConstants.keySchoolName: schoolName,
      AppConstants.keyTodayAttendanceStatus: todayAttendanceStatus,
      AppConstants.keyTodayArrivalTime: todayArrivalTime,
      AppConstants.keyTodayDepartureTime: todayDepartureTime,
      AppConstants.keyPresentDays: totalPresentDays,
      AppConstants.keyAbsentDays: totalAbsentDays,
      AppConstants.keyLateDays: totalLateDays,
      AppConstants.keyAttendancePercentage: attendancePercentage,
      AppConstants.keyRecentNotifications: recentNotifications,
      AppConstants.keyRecentTrips: recentTrips,
      AppConstants.keyLastUpdated: lastUpdated.toIso8601String(),
    };
  }
}

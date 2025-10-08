class DriverDashboard {
  final int driverId;
  final String driverName;
  final String driverContactNumber;
  final String? driverPhoto;
  
  // Vehicle Information
  final int vehicleId;
  final String vehicleNumber;
  final String vehicleType;
  final int? vehicleCapacity;
  
  // School Information
  final int schoolId;
  final String schoolName;
  
  // Dashboard Statistics
  final int totalTripsToday;
  final int completedTrips;
  final int pendingTrips;
  final int totalStudentsToday;
  final int studentsPickedUp;
  final int studentsDropped;
  
  // Current Trip Information
  final int? currentTripId;
  final String? currentTripName;
  final String? currentTripStatus;
  final DateTime? currentTripStartTime;
  final int currentTripStudentCount;
  
  // Recent Activity
  final List<RecentActivity> recentActivities;

  DriverDashboard({
    required this.driverId,
    required this.driverName,
    required this.driverContactNumber,
    this.driverPhoto,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.vehicleCapacity,
    required this.schoolId,
    required this.schoolName,
    required this.totalTripsToday,
    required this.completedTrips,
    required this.pendingTrips,
    required this.totalStudentsToday,
    required this.studentsPickedUp,
    required this.studentsDropped,
    this.currentTripId,
    this.currentTripName,
    this.currentTripStatus,
    this.currentTripStartTime,
    required this.currentTripStudentCount,
    required this.recentActivities,
  });

  factory DriverDashboard.fromJson(Map<String, dynamic> json) {
    return DriverDashboard(
      driverId: json['driverId'],
      driverName: json['driverName'],
      driverContactNumber: json['driverContactNumber'],
      driverPhoto: json['driverPhoto'],
      vehicleId: json['vehicleId'],
      vehicleNumber: json['vehicleNumber'],
      vehicleType: json['vehicleType'],
      vehicleCapacity: json['vehicleCapacity'],
      schoolId: json['schoolId'],
      schoolName: json['schoolName'],
      totalTripsToday: json['totalTripsToday'],
      completedTrips: json['completedTrips'],
      pendingTrips: json['pendingTrips'],
      totalStudentsToday: json['totalStudentsToday'],
      studentsPickedUp: json['studentsPickedUp'],
      studentsDropped: json['studentsDropped'],
      currentTripId: json['currentTripId'],
      currentTripName: json['currentTripName'],
      currentTripStatus: json['currentTripStatus'],
      currentTripStartTime: json['currentTripStartTime'] != null 
          ? DateTime.parse(json['currentTripStartTime']) 
          : null,
      currentTripStudentCount: json['currentTripStudentCount'],
      recentActivities: (json['recentActivities'] as List<dynamic>?)
          ?.map((activity) => RecentActivity.fromJson(activity))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'driverContactNumber': driverContactNumber,
      'driverPhoto': driverPhoto,
      'vehicleId': vehicleId,
      'vehicleNumber': vehicleNumber,
      'vehicleType': vehicleType,
      'vehicleCapacity': vehicleCapacity,
      'schoolId': schoolId,
      'schoolName': schoolName,
      'totalTripsToday': totalTripsToday,
      'completedTrips': completedTrips,
      'pendingTrips': pendingTrips,
      'totalStudentsToday': totalStudentsToday,
      'studentsPickedUp': studentsPickedUp,
      'studentsDropped': studentsDropped,
      'currentTripId': currentTripId,
      'currentTripName': currentTripName,
      'currentTripStatus': currentTripStatus,
      'currentTripStartTime': currentTripStartTime?.toIso8601String(),
      'currentTripStudentCount': currentTripStudentCount,
      'recentActivities': recentActivities.map((activity) => activity.toJson()).toList(),
    };
  }

  DriverDashboard copyWith({
    int? driverId,
    String? driverName,
    String? driverContactNumber,
    String? driverPhoto,
    int? vehicleId,
    String? vehicleNumber,
    String? vehicleType,
    int? vehicleCapacity,
    int? schoolId,
    String? schoolName,
    int? totalTripsToday,
    int? completedTrips,
    int? pendingTrips,
    int? totalStudentsToday,
    int? studentsPickedUp,
    int? studentsDropped,
    int? currentTripId,
    String? currentTripName,
    String? currentTripStatus,
    DateTime? currentTripStartTime,
    int? currentTripStudentCount,
    List<RecentActivity>? recentActivities,
  }) {
    return DriverDashboard(
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverContactNumber: driverContactNumber ?? this.driverContactNumber,
      driverPhoto: driverPhoto ?? this.driverPhoto,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleCapacity: vehicleCapacity ?? this.vehicleCapacity,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      totalTripsToday: totalTripsToday ?? this.totalTripsToday,
      completedTrips: completedTrips ?? this.completedTrips,
      pendingTrips: pendingTrips ?? this.pendingTrips,
      totalStudentsToday: totalStudentsToday ?? this.totalStudentsToday,
      studentsPickedUp: studentsPickedUp ?? this.studentsPickedUp,
      studentsDropped: studentsDropped ?? this.studentsDropped,
      currentTripId: currentTripId ?? this.currentTripId,
      currentTripName: currentTripName ?? this.currentTripName,
      currentTripStatus: currentTripStatus ?? this.currentTripStatus,
      currentTripStartTime: currentTripStartTime ?? this.currentTripStartTime,
      currentTripStudentCount: currentTripStudentCount ?? this.currentTripStudentCount,
      recentActivities: recentActivities ?? this.recentActivities,
    );
  }
}

class RecentActivity {
  final int activityId;
  final String activityType;
  final String description;
  final DateTime activityTime;
  final String studentName;
  final String? location;

  RecentActivity({
    required this.activityId,
    required this.activityType,
    required this.description,
    required this.activityTime,
    required this.studentName,
    this.location,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      activityId: json['activityId'],
      activityType: json['activityType'],
      description: json['description'],
      activityTime: DateTime.parse(json['activityTime']),
      studentName: json['studentName'],
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activityId': activityId,
      'activityType': activityType,
      'description': description,
      'activityTime': activityTime.toIso8601String(),
      'studentName': studentName,
      'location': location,
    };
  }

  RecentActivity copyWith({
    int? activityId,
    String? activityType,
    String? description,
    DateTime? activityTime,
    String? studentName,
    String? location,
  }) {
    return RecentActivity(
      activityId: activityId ?? this.activityId,
      activityType: activityType ?? this.activityType,
      description: description ?? this.description,
      activityTime: activityTime ?? this.activityTime,
      studentName: studentName ?? this.studentName,
      location: location ?? this.location,
    );
  }
}

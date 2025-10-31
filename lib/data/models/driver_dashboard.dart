import '../../utils/constants.dart';

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
      driverId: json[AppConstants.keyDriverId],
      driverName: json[AppConstants.keyDriverName],
      driverContactNumber: json[AppConstants.keyDriverContactNumber],
      driverPhoto: json[AppConstants.keyDriverPhoto],
      vehicleId: json[AppConstants.keyVehicleId],
      vehicleNumber: json[AppConstants.keyVehicleNumber],
      vehicleType: json[AppConstants.keyVehicleType],
      vehicleCapacity: json[AppConstants.keyVehicleCapacity],
      schoolId: json[AppConstants.keySchoolId],
      schoolName: json[AppConstants.keySchoolName],
      totalTripsToday: json[AppConstants.keyTotalTripsToday],
      completedTrips: json[AppConstants.keyCompletedTrips],
      pendingTrips: json[AppConstants.keyPendingTrips],
      totalStudentsToday: json[AppConstants.keyTotalStudentsToday],
      studentsPickedUp: json[AppConstants.keyStudentsPickedUp],
      studentsDropped: json[AppConstants.keyStudentsDropped],
      currentTripId: json[AppConstants.keyCurrentTripId],
      currentTripName: json[AppConstants.keyCurrentTripName],
      currentTripStatus: json[AppConstants.keyCurrentTripStatus],
      currentTripStartTime: json[AppConstants.keyCurrentTripStartTime] != null 
          ? DateTime.parse(json[AppConstants.keyCurrentTripStartTime]) 
          : null,
      currentTripStudentCount: json[AppConstants.keyCurrentTripStudentCount],
      recentActivities: (json[AppConstants.keyRecentActivities] as List<dynamic>?)
          ?.map((activity) => RecentActivity.fromJson(activity))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConstants.keyDriverId: driverId,
      AppConstants.keyDriverName: driverName,
      AppConstants.keyDriverContactNumber: driverContactNumber,
      AppConstants.keyDriverPhoto: driverPhoto,
      AppConstants.keyVehicleId: vehicleId,
      AppConstants.keyVehicleNumber: vehicleNumber,
      AppConstants.keyVehicleType: vehicleType,
      AppConstants.keyVehicleCapacity: vehicleCapacity,
      AppConstants.keySchoolId: schoolId,
      AppConstants.keySchoolName: schoolName,
      AppConstants.keyTotalTripsToday: totalTripsToday,
      AppConstants.keyCompletedTrips: completedTrips,
      AppConstants.keyPendingTrips: pendingTrips,
      AppConstants.keyTotalStudentsToday: totalStudentsToday,
      AppConstants.keyStudentsPickedUp: studentsPickedUp,
      AppConstants.keyStudentsDropped: studentsDropped,
      AppConstants.keyCurrentTripId: currentTripId,
      AppConstants.keyCurrentTripName: currentTripName,
      AppConstants.keyCurrentTripStatus: currentTripStatus,
      AppConstants.keyCurrentTripStartTime: currentTripStartTime?.toIso8601String(),
      AppConstants.keyCurrentTripStudentCount: currentTripStudentCount,
      AppConstants.keyRecentActivities: recentActivities.map((activity) => activity.toJson()).toList(),
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
      activityId: json[AppConstants.keyActivityId],
      activityType: json[AppConstants.keyActivityType],
      description: json[AppConstants.keyDescription],
      activityTime: DateTime.parse(json[AppConstants.keyActivityTime]),
      studentName: json[AppConstants.keyStudentName],
      location: json[AppConstants.keyLocation],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConstants.keyActivityId: activityId,
      AppConstants.keyActivityType: activityType,
      AppConstants.keyDescription: description,
      AppConstants.keyActivityTime: activityTime.toIso8601String(),
      AppConstants.keyStudentName: studentName,
      AppConstants.keyLocation: location,
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

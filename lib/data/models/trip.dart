import '../../utils/constants.dart';

class Trip {
  final int tripId;
  final String tripName;
  final int tripNumber;
  final String? tripType; // MORNING, AFTERNOON
  final String? scheduledTime;
  final int? estimatedDurationMinutes;
  final bool isActive;
  
  // Vehicle Information
  final int vehicleId;
  final String vehicleNumber;
  final String vehicleType;
  final int? vehicleCapacity;
  
  // School Information
  final int schoolId;
  final String schoolName;
  
  // Driver Information
  final int? driverId;
  final String? driverName;
  final String? driverContactNumber;
  
  // Trip Status
  final String? tripStatus; // NOT_STARTED, IN_PROGRESS, COMPLETED, CANCELLED
  final DateTime? tripStartTime;
  final DateTime? tripEndTime;
  
  // Student Information
  final int totalStudents;
  final int studentsPickedUp;
  final int studentsDropped;
  final int studentsAbsent;
  
  // Student List
  final List<TripStudent> students;
  
  // Metadata
  final String? createdBy;
  final DateTime? createdDate;
  final String? updatedBy;
  final DateTime? updatedDate;

  Trip({
    required this.tripId,
    required this.tripName,
    required this.tripNumber,
    this.tripType,
    this.scheduledTime,
    this.estimatedDurationMinutes,
    required this.isActive,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.vehicleCapacity,
    required this.schoolId,
    required this.schoolName,
    this.driverId,
    this.driverName,
    this.driverContactNumber,
    this.tripStatus,
    this.tripStartTime,
    this.tripEndTime,
    required this.totalStudents,
    required this.studentsPickedUp,
    required this.studentsDropped,
    required this.studentsAbsent,
    required this.students,
    this.createdBy,
    this.createdDate,
    this.updatedBy,
    this.updatedDate,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      tripId: json[AppConstants.keyTripId],
      tripName: json[AppConstants.keyTripName],
      tripNumber: json[AppConstants.keyTripNumber],
      tripType: json[AppConstants.keyTripType],
      scheduledTime: json[AppConstants.keyScheduledTime],
      estimatedDurationMinutes: json[AppConstants.keyEstimatedDurationMinutes],
      isActive: json[AppConstants.keyIsActive],
      vehicleId: json[AppConstants.keyVehicleId],
      vehicleNumber: json[AppConstants.keyVehicleNumber],
      vehicleType: json[AppConstants.keyVehicleType],
      vehicleCapacity: json[AppConstants.keyVehicleCapacity],
      schoolId: json[AppConstants.keySchoolId],
      schoolName: json[AppConstants.keySchoolName],
      driverId: json[AppConstants.keyDriverId],
      driverName: json[AppConstants.keyDriverName],
      driverContactNumber: json[AppConstants.keyDriverContactNumber],
      tripStatus: json[AppConstants.keyTripStatus],
      tripStartTime: json[AppConstants.keyTripStartTime] != null 
          ? DateTime.parse(json[AppConstants.keyTripStartTime]) 
          : null,
      tripEndTime: json[AppConstants.keyTripEndTime] != null 
          ? DateTime.parse(json[AppConstants.keyTripEndTime]) 
          : null,
      totalStudents: json[AppConstants.keyTotalStudents] ?? 0,
      studentsPickedUp: json[AppConstants.keyStudentsPickedUp] ?? 0,
      studentsDropped: json[AppConstants.keyStudentsDropped] ?? 0,
      studentsAbsent: json[AppConstants.keyStudentsAbsent] ?? 0,
      students: (json[AppConstants.keyStudents] as List<dynamic>?)
          ?.map((student) => TripStudent.fromJson(student))
          .toList() ?? [],
      createdBy: json[AppConstants.keyCreatedBy],
      createdDate: json[AppConstants.keyCreatedDate] != null 
          ? DateTime.parse(json[AppConstants.keyCreatedDate]) 
          : null,
      updatedBy: json[AppConstants.keyUpdatedBy],
      updatedDate: json[AppConstants.keyUpdatedDate] != null 
          ? DateTime.parse(json[AppConstants.keyUpdatedDate]) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConstants.keyTripId: tripId,
      AppConstants.keyTripName: tripName,
      AppConstants.keyTripNumber: tripNumber,
      AppConstants.keyTripType: tripType,
      AppConstants.keyScheduledTime: scheduledTime,
      AppConstants.keyEstimatedDurationMinutes: estimatedDurationMinutes,
      AppConstants.keyIsActive: isActive,
      AppConstants.keyVehicleId: vehicleId,
      AppConstants.keyVehicleNumber: vehicleNumber,
      AppConstants.keyVehicleType: vehicleType,
      AppConstants.keyVehicleCapacity: vehicleCapacity,
      AppConstants.keySchoolId: schoolId,
      AppConstants.keySchoolName: schoolName,
      AppConstants.keyDriverId: driverId,
      AppConstants.keyDriverName: driverName,
      AppConstants.keyDriverContactNumber: driverContactNumber,
      AppConstants.keyTripStatus: tripStatus,
      AppConstants.keyTripStartTime: tripStartTime?.toIso8601String(),
      AppConstants.keyTripEndTime: tripEndTime?.toIso8601String(),
      AppConstants.keyTotalStudents: totalStudents,
      AppConstants.keyStudentsPickedUp: studentsPickedUp,
      AppConstants.keyStudentsDropped: studentsDropped,
      AppConstants.keyStudentsAbsent: studentsAbsent,
      AppConstants.keyStudents: students.map((student) => student.toJson()).toList(),
      AppConstants.keyCreatedBy: createdBy,
      AppConstants.keyCreatedDate: createdDate?.toIso8601String(),
      AppConstants.keyUpdatedBy: updatedBy,
      AppConstants.keyUpdatedDate: updatedDate?.toIso8601String(),
    };
  }

  Trip copyWith({
    int? tripId,
    String? tripName,
    int? tripNumber,
    String? tripType,
    String? scheduledTime,
    int? estimatedDurationMinutes,
    bool? isActive,
    int? vehicleId,
    String? vehicleNumber,
    String? vehicleType,
    int? vehicleCapacity,
    int? schoolId,
    String? schoolName,
    int? driverId,
    String? driverName,
    String? driverContactNumber,
    String? tripStatus,
    DateTime? tripStartTime,
    DateTime? tripEndTime,
    int? totalStudents,
    int? studentsPickedUp,
    int? studentsDropped,
    int? studentsAbsent,
    List<TripStudent>? students,
    String? createdBy,
    DateTime? createdDate,
    String? updatedBy,
    DateTime? updatedDate,
  }) {
    return Trip(
      tripId: tripId ?? this.tripId,
      tripName: tripName ?? this.tripName,
      tripNumber: tripNumber ?? this.tripNumber,
      tripType: tripType ?? this.tripType,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      isActive: isActive ?? this.isActive,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleCapacity: vehicleCapacity ?? this.vehicleCapacity,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverContactNumber: driverContactNumber ?? this.driverContactNumber,
      tripStatus: tripStatus ?? this.tripStatus,
      tripStartTime: tripStartTime ?? this.tripStartTime,
      tripEndTime: tripEndTime ?? this.tripEndTime,
      totalStudents: totalStudents ?? this.totalStudents,
      studentsPickedUp: studentsPickedUp ?? this.studentsPickedUp,
      studentsDropped: studentsDropped ?? this.studentsDropped,
      studentsAbsent: studentsAbsent ?? this.studentsAbsent,
      students: students ?? this.students,
      createdBy: createdBy ?? this.createdBy,
      createdDate: createdDate ?? this.createdDate,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }
}

class TripStudent {
  final int studentId;
  final String studentName;
  final String? studentPhoto;
  final String className;
  final String sectionName;
  final String pickupLocation;
  final String dropLocation;
  final int pickupOrder;
  final int dropOrder;
  final String attendanceStatus; // PENDING, PICKED_UP, DROPPED, ABSENT
  final DateTime? pickupTime;
  final DateTime? dropTime;
  final String? remarks;
  
  // Parent Information
  final String parentName;
  final String parentContactNumber;
  final String? parentEmail;

  TripStudent({
    required this.studentId,
    required this.studentName,
    this.studentPhoto,
    required this.className,
    required this.sectionName,
    required this.pickupLocation,
    required this.dropLocation,
    required this.pickupOrder,
    required this.dropOrder,
    required this.attendanceStatus,
    this.pickupTime,
    this.dropTime,
    this.remarks,
    required this.parentName,
    required this.parentContactNumber,
    this.parentEmail,
  });

  factory TripStudent.fromJson(Map<String, dynamic> json) {
    return TripStudent(
      studentId: json[AppConstants.keyStudentId],
      studentName: json[AppConstants.keyStudentName],
      studentPhoto: json[AppConstants.keyStudentPhoto],
      className: json[AppConstants.keyClassName],
      sectionName: json[AppConstants.keySectionName],
      pickupLocation: json[AppConstants.keyPickupLocation],
      dropLocation: json[AppConstants.keyDropLocation],
      pickupOrder: json[AppConstants.keyPickupOrder],
      dropOrder: json[AppConstants.keyDropOrder],
      attendanceStatus: json[AppConstants.keyAttendanceStatus],
      pickupTime: json[AppConstants.keyPickupTime] != null 
          ? DateTime.parse(json[AppConstants.keyPickupTime]) 
          : null,
      dropTime: json[AppConstants.keyDropTime] != null 
          ? DateTime.parse(json[AppConstants.keyDropTime]) 
          : null,
      remarks: json[AppConstants.keyRemarks],
      parentName: json[AppConstants.keyParentName],
      parentContactNumber: json[AppConstants.keyParentContactNumber],
      parentEmail: json[AppConstants.keyParentEmail],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConstants.keyStudentId: studentId,
      AppConstants.keyStudentName: studentName,
      AppConstants.keyStudentPhoto: studentPhoto,
      AppConstants.keyClassName: className,
      AppConstants.keySectionName: sectionName,
      AppConstants.keyPickupLocation: pickupLocation,
      AppConstants.keyDropLocation: dropLocation,
      AppConstants.keyPickupOrder: pickupOrder,
      AppConstants.keyDropOrder: dropOrder,
      AppConstants.keyAttendanceStatus: attendanceStatus,
      AppConstants.keyPickupTime: pickupTime?.toIso8601String(),
      AppConstants.keyDropTime: dropTime?.toIso8601String(),
      AppConstants.keyRemarks: remarks,
      AppConstants.keyParentName: parentName,
      AppConstants.keyParentContactNumber: parentContactNumber,
      AppConstants.keyParentEmail: parentEmail,
    };
  }

  TripStudent copyWith({
    int? studentId,
    String? studentName,
    String? studentPhoto,
    String? className,
    String? sectionName,
    String? pickupLocation,
    String? dropLocation,
    int? pickupOrder,
    int? dropOrder,
    String? attendanceStatus,
    DateTime? pickupTime,
    DateTime? dropTime,
    String? remarks,
    String? parentName,
    String? parentContactNumber,
    String? parentEmail,
  }) {
    return TripStudent(
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentPhoto: studentPhoto ?? this.studentPhoto,
      className: className ?? this.className,
      sectionName: sectionName ?? this.sectionName,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropLocation: dropLocation ?? this.dropLocation,
      pickupOrder: pickupOrder ?? this.pickupOrder,
      dropOrder: dropOrder ?? this.dropOrder,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      pickupTime: pickupTime ?? this.pickupTime,
      dropTime: dropTime ?? this.dropTime,
      remarks: remarks ?? this.remarks,
      parentName: parentName ?? this.parentName,
      parentContactNumber: parentContactNumber ?? this.parentContactNumber,
      parentEmail: parentEmail ?? this.parentEmail,
    );
  }
}

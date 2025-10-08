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
      tripId: json['tripId'],
      tripName: json['tripName'],
      tripNumber: json['tripNumber'],
      tripType: json['tripType'],
      scheduledTime: json['scheduledTime'],
      estimatedDurationMinutes: json['estimatedDurationMinutes'],
      isActive: json['isActive'],
      vehicleId: json['vehicleId'],
      vehicleNumber: json['vehicleNumber'],
      vehicleType: json['vehicleType'],
      vehicleCapacity: json['vehicleCapacity'],
      schoolId: json['schoolId'],
      schoolName: json['schoolName'],
      driverId: json['driverId'],
      driverName: json['driverName'],
      driverContactNumber: json['driverContactNumber'],
      tripStatus: json['tripStatus'],
      tripStartTime: json['tripStartTime'] != null 
          ? DateTime.parse(json['tripStartTime']) 
          : null,
      tripEndTime: json['tripEndTime'] != null 
          ? DateTime.parse(json['tripEndTime']) 
          : null,
      totalStudents: json['totalStudents'] ?? 0,
      studentsPickedUp: json['studentsPickedUp'] ?? 0,
      studentsDropped: json['studentsDropped'] ?? 0,
      studentsAbsent: json['studentsAbsent'] ?? 0,
      students: (json['students'] as List<dynamic>?)
          ?.map((student) => TripStudent.fromJson(student))
          .toList() ?? [],
      createdBy: json['createdBy'],
      createdDate: json['createdDate'] != null 
          ? DateTime.parse(json['createdDate']) 
          : null,
      updatedBy: json['updatedBy'],
      updatedDate: json['updatedDate'] != null 
          ? DateTime.parse(json['updatedDate']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'tripName': tripName,
      'tripNumber': tripNumber,
      'tripType': tripType,
      'scheduledTime': scheduledTime,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'isActive': isActive,
      'vehicleId': vehicleId,
      'vehicleNumber': vehicleNumber,
      'vehicleType': vehicleType,
      'vehicleCapacity': vehicleCapacity,
      'schoolId': schoolId,
      'schoolName': schoolName,
      'driverId': driverId,
      'driverName': driverName,
      'driverContactNumber': driverContactNumber,
      'tripStatus': tripStatus,
      'tripStartTime': tripStartTime?.toIso8601String(),
      'tripEndTime': tripEndTime?.toIso8601String(),
      'totalStudents': totalStudents,
      'studentsPickedUp': studentsPickedUp,
      'studentsDropped': studentsDropped,
      'studentsAbsent': studentsAbsent,
      'students': students.map((student) => student.toJson()).toList(),
      'createdBy': createdBy,
      'createdDate': createdDate?.toIso8601String(),
      'updatedBy': updatedBy,
      'updatedDate': updatedDate?.toIso8601String(),
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
      studentId: json['studentId'],
      studentName: json['studentName'],
      studentPhoto: json['studentPhoto'],
      className: json['className'],
      sectionName: json['sectionName'],
      pickupLocation: json['pickupLocation'],
      dropLocation: json['dropLocation'],
      pickupOrder: json['pickupOrder'],
      dropOrder: json['dropOrder'],
      attendanceStatus: json['attendanceStatus'],
      pickupTime: json['pickupTime'] != null 
          ? DateTime.parse(json['pickupTime']) 
          : null,
      dropTime: json['dropTime'] != null 
          ? DateTime.parse(json['dropTime']) 
          : null,
      remarks: json['remarks'],
      parentName: json['parentName'],
      parentContactNumber: json['parentContactNumber'],
      parentEmail: json['parentEmail'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentPhoto': studentPhoto,
      'className': className,
      'sectionName': sectionName,
      'pickupLocation': pickupLocation,
      'dropLocation': dropLocation,
      'pickupOrder': pickupOrder,
      'dropOrder': dropOrder,
      'attendanceStatus': attendanceStatus,
      'pickupTime': pickupTime?.toIso8601String(),
      'dropTime': dropTime?.toIso8601String(),
      'remarks': remarks,
      'parentName': parentName,
      'parentContactNumber': parentContactNumber,
      'parentEmail': parentEmail,
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

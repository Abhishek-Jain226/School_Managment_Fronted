// lib/data/models/class_master.dart
import '../../utils/constants.dart';

class ClassMaster {
  final int? classId;
  final String className;
  final int classOrder;
  final String? description;
  final int? schoolId;
  final String? schoolName;
  final bool isActive;
  final String? createdBy;
  final DateTime? createdDate;
  final String? updatedBy;
  final DateTime? updatedDate;

  ClassMaster({
    this.classId,
    required this.className,
    required this.classOrder,
    this.description,
    this.schoolId,
    this.schoolName,
    this.isActive = true,
    this.createdBy,
    this.createdDate,
    this.updatedBy,
    this.updatedDate,
  });

  factory ClassMaster.fromJson(Map<String, dynamic> json) {
    return ClassMaster(
      classId: json[AppConstants.keyClassId],
      className: json[AppConstants.keyClassName],
      classOrder: json[AppConstants.keyClassOrder],
      description: json[AppConstants.keyDescription],
      schoolId: json[AppConstants.keySchoolId],
      schoolName: json[AppConstants.keySchoolName],
      isActive: json[AppConstants.keyIsActive] ?? true,
      createdBy: json[AppConstants.keyCreatedBy],
      createdDate: json[AppConstants.keyCreatedDate] != null ? DateTime.parse(json[AppConstants.keyCreatedDate]) : null,
      updatedBy: json[AppConstants.keyUpdatedBy],
      updatedDate: json[AppConstants.keyUpdatedDate] != null ? DateTime.parse(json[AppConstants.keyUpdatedDate]) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConstants.keyClassId: classId,
      AppConstants.keyClassName: className,
      AppConstants.keyClassOrder: classOrder,
      AppConstants.keyDescription: description,
      AppConstants.keySchoolId: schoolId,
      AppConstants.keySchoolName: schoolName,
      AppConstants.keyIsActive: isActive,
      AppConstants.keyCreatedBy: createdBy,
      AppConstants.keyCreatedDate: createdDate?.toIso8601String(),
      AppConstants.keyUpdatedBy: updatedBy,
      AppConstants.keyUpdatedDate: updatedDate?.toIso8601String(),
    };
  }

  ClassMaster copyWith({
    int? classId,
    String? className,
    int? classOrder,
    String? description,
    int? schoolId,
    String? schoolName,
    bool? isActive,
    String? createdBy,
    DateTime? createdDate,
    String? updatedBy,
    DateTime? updatedDate,
  }) {
    return ClassMaster(
      classId: classId ?? this.classId,
      className: className ?? this.className,
      classOrder: classOrder ?? this.classOrder,
      description: description ?? this.description,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdDate: createdDate ?? this.createdDate,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }
}

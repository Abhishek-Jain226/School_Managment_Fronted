// lib/data/models/section_master.dart
import '../../utils/constants.dart';

class SectionMaster {
  final int? sectionId;
  final String sectionName;
  final String? description;
  final int? schoolId;
  final String? schoolName;
  final bool isActive;
  final String? createdBy;
  final DateTime? createdDate;
  final String? updatedBy;
  final DateTime? updatedDate;

  SectionMaster({
    this.sectionId,
    required this.sectionName,
    this.description,
    this.schoolId,
    this.schoolName,
    this.isActive = true,
    this.createdBy,
    this.createdDate,
    this.updatedBy,
    this.updatedDate,
  });

  factory SectionMaster.fromJson(Map<String, dynamic> json) {
    return SectionMaster(
      sectionId: json[AppConstants.keySectionId],
      sectionName: json[AppConstants.keySectionName],
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
      AppConstants.keySectionId: sectionId,
      AppConstants.keySectionName: sectionName,
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

  SectionMaster copyWith({
    int? sectionId,
    String? sectionName,
    String? description,
    int? schoolId,
    String? schoolName,
    bool? isActive,
    String? createdBy,
    DateTime? createdDate,
    String? updatedBy,
    DateTime? updatedDate,
  }) {
    return SectionMaster(
      sectionId: sectionId ?? this.sectionId,
      sectionName: sectionName ?? this.sectionName,
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


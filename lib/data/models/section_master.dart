// lib/data/models/section_master.dart
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
      sectionId: json['sectionId'],
      sectionName: json['sectionName'],
      description: json['description'],
      schoolId: json['schoolId'],
      schoolName: json['schoolName'],
      isActive: json['isActive'] ?? true,
      createdBy: json['createdBy'],
      createdDate: json['createdDate'] != null ? DateTime.parse(json['createdDate']) : null,
      updatedBy: json['updatedBy'],
      updatedDate: json['updatedDate'] != null ? DateTime.parse(json['updatedDate']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sectionId': sectionId,
      'sectionName': sectionName,
      'description': description,
      'schoolId': schoolId,
      'schoolName': schoolName,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdDate': createdDate?.toIso8601String(),
      'updatedBy': updatedBy,
      'updatedDate': updatedDate?.toIso8601String(),
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


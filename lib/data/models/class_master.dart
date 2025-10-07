// lib/data/models/class_master.dart
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
      classId: json['classId'],
      className: json['className'],
      classOrder: json['classOrder'],
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
      'classId': classId,
      'className': className,
      'classOrder': classOrder,
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

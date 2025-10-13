class Role {
  final int roleId;
  final String roleName;
  final String description;
  final bool isActive;
  final String? createdBy;
  final DateTime? createdDate;
  final String? updatedBy;
  final DateTime? updatedDate;

  Role({
    required this.roleId,
    required this.roleName,
    required this.description,
    required this.isActive,
    this.createdBy,
    this.createdDate,
    this.updatedBy,
    this.updatedDate,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      roleId: json['roleId'] ?? 0,
      roleName: json['roleName'] ?? '',
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? true,
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
      'roleId': roleId,
      'roleName': roleName,
      'description': description,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdDate': createdDate?.toIso8601String(),
      'updatedBy': updatedBy,
      'updatedDate': updatedDate?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Role(roleId: $roleId, roleName: $roleName, description: $description, isActive: $isActive)';
  }
}

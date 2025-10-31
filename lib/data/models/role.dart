import '../../utils/constants.dart';

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
      roleId: json[AppConstants.keyRoleId] ?? 0,
      roleName: json[AppConstants.keyRoleName] ?? '',
      description: json[AppConstants.keyDescription] ?? '',
      isActive: json[AppConstants.keyIsActive] ?? true,
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
      AppConstants.keyRoleId: roleId,
      AppConstants.keyRoleName: roleName,
      AppConstants.keyDescription: description,
      AppConstants.keyIsActive: isActive,
      AppConstants.keyCreatedBy: createdBy,
      AppConstants.keyCreatedDate: createdDate?.toIso8601String(),
      AppConstants.keyUpdatedBy: updatedBy,
      AppConstants.keyUpdatedDate: updatedDate?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Role(roleId: $roleId, roleName: $roleName, description: $description, isActive: $isActive)';
  }
}

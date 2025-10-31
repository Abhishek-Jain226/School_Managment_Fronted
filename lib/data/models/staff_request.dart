import 'dart:convert';

import '../../utils/constants.dart';

class StaffRequest {
  final String userName;
  final String password;
  final String? email;         
  final String? contactNumber;
  final int schoolId;
  final int roleId;
  final String createdBy;

  StaffRequest({
    required this.userName,
    required this.password,
    this.email,
    this.contactNumber,
    required this.schoolId,
    required this.roleId,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() {
    return {
      AppConstants.keyUserName: userName,
      AppConstants.keyPassword: password,
      AppConstants.keyEmail: email ?? "",
      AppConstants.keyContactNumber: contactNumber ?? "",
      AppConstants.keySchoolId: schoolId,
      AppConstants.keyRoleId: roleId,
      AppConstants.keyCreatedBy: createdBy,
    };
  }

  String toRawJson() => jsonEncode(toJson());
}

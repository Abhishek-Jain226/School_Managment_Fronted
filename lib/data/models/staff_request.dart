import 'dart:convert';

class StaffRequest {
  final String userName;
  final String password;
  final String? email;         // optional
  final String? contactNumber; // optional
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
      "userName": userName,
      "password": password,
      "email": email ?? "",            // ✅ null safe (backend me agar optional hoga to empty bhej do)
      "contactNumber": contactNumber ?? "",
      "schoolId": schoolId,
      "roleId": roleId,
      "createdBy": createdBy,
    };
  }

  String toRawJson() => jsonEncode(toJson());
}

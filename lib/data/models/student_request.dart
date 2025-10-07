class StudentRequest {
  final String firstName;
  final String? middleName;
  final String lastName;
  final String gender;
  final int classId;
  final int sectionId;
  final String? studentPhotoBase64;
  final int schoolId;
  final String motherName;
  final String fatherName;
  final String primaryContactNumber;
  final String? alternateContactNumber;
  final String? email;
  final String createdBy;
  final String relation; // Hidden field with default value

  StudentRequest({
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.gender,
    required this.classId,
    required this.sectionId,
    this.studentPhotoBase64,
    required this.schoolId,
    required this.motherName,
    required this.fatherName,
    required this.primaryContactNumber,
    this.alternateContactNumber,
    this.email,
    required this.createdBy,
    required this.relation,
  });

  Map<String, dynamic> toJson() => {
        "firstName": firstName,
        "middleName": middleName,
        "lastName": lastName,
        "gender": gender,
        "classId": classId,
        "sectionId": sectionId,
        "studentPhoto": studentPhotoBase64,
        "schoolId": schoolId,
        "motherName": motherName,
        "fatherName": fatherName,
        "primaryContactNumber": primaryContactNumber,
        "alternateContactNumber": alternateContactNumber,
        "email": email,
        "createdBy": createdBy,
        "parentRelation": relation,
      };
}

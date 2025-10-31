import '../../utils/constants.dart';

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
        AppConstants.keyFirstName: firstName,
        AppConstants.keyMiddleName: middleName,
        AppConstants.keyLastName: lastName,
        AppConstants.keyGender: gender,
        AppConstants.keyClassId: classId,
        AppConstants.keySectionId: sectionId,
        AppConstants.keyStudentPhoto: studentPhotoBase64,
        AppConstants.keySchoolId: schoolId,
        AppConstants.keyMotherName: motherName,
        AppConstants.keyFatherName: fatherName,
        AppConstants.keyPrimaryContact: primaryContactNumber,
        AppConstants.keyAlternateContact: alternateContactNumber,
        AppConstants.keyEmail: email,
        AppConstants.keyCreatedBy: createdBy,
        AppConstants.keyParentRelation: relation,
      };
}

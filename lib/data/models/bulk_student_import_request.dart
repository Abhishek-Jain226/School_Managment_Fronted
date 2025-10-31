import '../../utils/constants.dart';

class BulkStudentImportRequest {
  final List<StudentRequest> students;
  final int schoolId;
  final String createdBy;
  final String? schoolDomain;
  final bool sendActivationEmails;
  final String emailGenerationStrategy;

  BulkStudentImportRequest({
    required this.students,
    required this.schoolId,
    required this.createdBy,
    this.schoolDomain,
    this.sendActivationEmails = true,
    this.emailGenerationStrategy = 'USE_PROVIDED',
  });

  Map<String, dynamic> toJson() => {
    AppConstants.keyStudents: students.map((s) => s.toJson()).toList(),
    AppConstants.keySchoolId: schoolId,
    AppConstants.keyCreatedBy: createdBy,
    if (schoolDomain != null) AppConstants.keySchoolDomain: schoolDomain,
    AppConstants.keySendActivationEmails: sendActivationEmails,
    AppConstants.keyEmailGenerationStrategy: emailGenerationStrategy,
  };
}

class StudentRequest {
  final String firstName;
  final String lastName;
  final String fatherName;
  final String? motherName;
  final String primaryContactNumber;
  final String? alternateContactNumber;
  final String email; // ✅ Made email required
  final String? dateOfBirth;
  final String? gender;
  final String? studentPhoto;
  final int? classId;
  final int? sectionId;
  final String createdBy;

  StudentRequest({
    required this.firstName,
    required this.lastName,
    required this.fatherName,
    this.motherName,
    required this.primaryContactNumber,
    this.alternateContactNumber,
    required this.email, // ✅ Made email required
    this.dateOfBirth,
    this.gender,
    this.studentPhoto,
    this.classId,
    this.sectionId,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() => {
    AppConstants.keyFirstName: firstName,
    AppConstants.keyLastName: lastName,
    AppConstants.keyFatherName: fatherName,
    if (motherName != null) AppConstants.keyMotherName: motherName,
    AppConstants.keyPrimaryContact: primaryContactNumber,
    if (alternateContactNumber != null) AppConstants.keyAlternateContact: alternateContactNumber,
    AppConstants.keyEmail: email, // ✅ Email is now required
    if (dateOfBirth != null) AppConstants.keyDateOfBirth: dateOfBirth,
    if (gender != null) AppConstants.keyGender: gender,
    if (studentPhoto != null) AppConstants.keyStudentPhoto: studentPhoto,
    if (classId != null) AppConstants.keyClassId: classId,
    if (sectionId != null) AppConstants.keySectionId: sectionId,
    AppConstants.keyCreatedBy: createdBy,
  };
}

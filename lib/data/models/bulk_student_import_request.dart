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
    'students': students.map((s) => s.toJson()).toList(),
    'schoolId': schoolId,
    'createdBy': createdBy,
    if (schoolDomain != null) 'schoolDomain': schoolDomain,
    'sendActivationEmails': sendActivationEmails,
    'emailGenerationStrategy': emailGenerationStrategy,
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
    'firstName': firstName,
    'lastName': lastName,
    'fatherName': fatherName,
    if (motherName != null) 'motherName': motherName,
    'primaryContactNumber': primaryContactNumber,
    if (alternateContactNumber != null) 'alternateContactNumber': alternateContactNumber,
    'email': email, // ✅ Email is now required
    if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
    if (gender != null) 'gender': gender,
    if (studentPhoto != null) 'studentPhoto': studentPhoto,
    if (classId != null) 'classId': classId,
    if (sectionId != null) 'sectionId': sectionId,
    'createdBy': createdBy,
  };
}

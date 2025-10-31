import '../../utils/constants.dart';

class BulkImportResult {
  final int totalRows;
  final int successfulImports;
  final int failedImports;
  final List<StudentImportResult> results;
  final List<String> errors;
  final String message;
  final bool success;

  BulkImportResult({
    required this.totalRows,
    required this.successfulImports,
    required this.failedImports,
    required this.results,
    required this.errors,
    required this.message,
    required this.success,
  });

  factory BulkImportResult.fromJson(Map<String, dynamic> json) {
    return BulkImportResult(
      totalRows: json[AppConstants.keyTotalRows] ?? 0,
      successfulImports: json[AppConstants.keySuccessfulImports] ?? 0,
      failedImports: json[AppConstants.keyFailedImports] ?? 0,
      results: (json[AppConstants.keyResults] as List<dynamic>?)
          ?.map((item) => StudentImportResult.fromJson(item))
          .toList() ?? [],
      errors: (json[AppConstants.keyErrors] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList() ?? [],
      message: json[AppConstants.keyMessage] ?? '',
      success: json[AppConstants.keySuccess] ?? false,
    );
  }
}

class StudentImportResult {
  final int? studentId;
  final String studentName;
  final String? parentEmail;
  final String status; // SUCCESS, ERROR, VALID, INVALID
  final String? errorMessage;
  final int? rowNumber;

  StudentImportResult({
    this.studentId,
    required this.studentName,
    this.parentEmail,
    required this.status,
    this.errorMessage,
    this.rowNumber,
  });

  factory StudentImportResult.fromJson(Map<String, dynamic> json) {
    return StudentImportResult(
      studentId: json[AppConstants.keyStudentId],
      studentName: json[AppConstants.keyStudentName] ?? '',
      parentEmail: json[AppConstants.keyParentEmail],
      status: json[AppConstants.keyStatus] ?? '',
      errorMessage: json[AppConstants.keyErrorMessage],
      rowNumber: json[AppConstants.keyRowNumber],
    );
  }
}

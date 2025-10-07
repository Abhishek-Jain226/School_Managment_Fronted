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
      totalRows: json['totalRows'] ?? 0,
      successfulImports: json['successfulImports'] ?? 0,
      failedImports: json['failedImports'] ?? 0,
      results: (json['results'] as List<dynamic>?)
          ?.map((item) => StudentImportResult.fromJson(item))
          .toList() ?? [],
      errors: (json['errors'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList() ?? [],
      message: json['message'] ?? '',
      success: json['success'] ?? false,
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
      studentId: json['studentId'],
      studentName: json['studentName'] ?? '',
      parentEmail: json['parentEmail'],
      status: json['status'] ?? '',
      errorMessage: json['errorMessage'],
      rowNumber: json['rowNumber'],
    );
  }
}

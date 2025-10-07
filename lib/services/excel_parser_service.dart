import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../data/models/bulk_student_import_request.dart';

class ExcelParserService {
  
  /// Parse Excel file and extract student data
  Future<List<StudentRequest>> parseStudentExcel(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      if (excel.tables.isEmpty) {
        throw Exception("No sheets found in Excel file");
      }
      
      final sheet = excel.tables[excel.tables.keys.first]!;
      final students = <StudentRequest>[];
      
      // Skip header row (row 0)
      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty || _isRowEmpty(row)) continue;
        
        try {
          final student = _parseStudentRow(row, i + 1);
          if (student != null) {
            students.add(student);
          }
        } catch (e) {
          print("Error parsing row ${i + 1}: $e");
          // Continue with other rows
        }
      }
      
      return students;
    } catch (e) {
      throw Exception("Error parsing Excel file: $e");
    }
  }
  
  /// Parse a single row from Excel
  StudentRequest? _parseStudentRow(List<Data?> row, int rowNumber) {
    try {
      // Expected columns: First Name, Last Name, Father Name, Mother Name, 
      // Primary Contact, Alternate Contact, Email, Date of Birth, Gender, Class, Section
      
      // ✅ Enhanced column validation
      if (row.length < 7) {
        throw Exception("Row $rowNumber has insufficient columns. Expected at least 7 columns (up to Email)");
      }
      
      final firstName = _getStringValue(row, 0);
      final lastName = _getStringValue(row, 1);
      final fatherName = _getStringValue(row, 2);
      final motherName = _getStringValue(row, 3);
      final primaryContact = _getStringValue(row, 4);
      final alternateContact = _getStringValue(row, 5);
      final email = _getStringValue(row, 6);
      final dateOfBirth = _getStringValue(row, 7);
      final gender = _getStringValue(row, 8);
      final className = _getStringValue(row, 9);
      final sectionName = _getStringValue(row, 10);
      
      // Validate required fields
      if (firstName == null || firstName.isEmpty) {
        throw Exception("First name is required at row $rowNumber");
      }
      if (lastName == null || lastName.isEmpty) {
        throw Exception("Last name is required at row $rowNumber");
      }
      if (fatherName == null || fatherName.isEmpty) {
        throw Exception("Father name is required at row $rowNumber");
      }
      if (primaryContact == null || primaryContact.isEmpty) {
        throw Exception("Primary contact is required at row $rowNumber");
      }
      // ✅ MANDATORY EMAIL VALIDATION
      if (email == null || email.isEmpty) {
        throw Exception("Parent email is required at row $rowNumber for account activation");
      }
      
      return StudentRequest(
        firstName: firstName,
        lastName: lastName,
        fatherName: fatherName,
        motherName: motherName,
        primaryContactNumber: primaryContact,
        alternateContactNumber: alternateContact,
        email: email,
        dateOfBirth: dateOfBirth,
        gender: gender,
        classId: _parseClassId(className),
        sectionId: _parseSectionId(sectionName),
        createdBy: "BulkImport",
      );
    } catch (e) {
      print("Error parsing row $rowNumber: $e");
      return null;
    }
  }
  
  /// Get string value from Excel cell
  String? _getStringValue(List<Data?> row, int index) {
    if (index >= row.length || row[index] == null) return null;
    
    final cell = row[index]!;
    if (cell.value == null) return null;
    
    return cell.value.toString().trim();
  }
  
  /// Check if row is empty
  bool _isRowEmpty(List<Data?> row) {
    return row.every((cell) => cell == null || cell.value == null || cell.value.toString().trim().isEmpty);
  }
  
  /// Parse class ID from class name (you may need to map this to actual class IDs)
  int? _parseClassId(String? className) {
    if (className == null || className.isEmpty) return null;
    
    // Simple mapping - you may need to enhance this based on your class structure
    final classMap = {
      '1': 1, '2': 2, '3': 3, '4': 4, '5': 5,
      '6': 6, '7': 7, '8': 8, '9': 9, '10': 10,
      '11': 11, '12': 12,
    };
    
    return classMap[className.trim()];
  }
  
  /// Parse section ID from section name (you may need to map this to actual section IDs)
  int? _parseSectionId(String? sectionName) {
    if (sectionName == null || sectionName.isEmpty) return null;
    
    // Simple mapping - you may need to enhance this based on your section structure
    final sectionMap = {
      'A': 1, 'B': 2, 'C': 3, 'D': 4, 'E': 5,
      'a': 1, 'b': 2, 'c': 3, 'd': 4, 'e': 5,
    };
    
    return sectionMap[sectionName.trim()];
  }
  
  /// Generate Excel template
  Future<Uint8List> generateExcelTemplate() async {
    final excel = Excel.createExcel();
    final sheet = excel['Students'];
    
    // Add headers
    final headers = [
      'First Name',
      'Last Name', 
      'Father Name',
      'Mother Name',
      'Primary Contact',
      'Alternate Contact',
      'Parent Email (Required)', // ✅ Made email mandatory
      'Date of Birth (YYYY-MM-DD)',
      'Gender (Male/Female)',
      'Class',
      'Section'
    ];
    
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
    }
    
    // Add sample data
    final sampleData = [
      ['John', 'Doe', 'Robert Doe', 'Jane Doe', '9876543210', '9876543211', 'robert@email.com', '2010-05-15', 'Male', '1', 'A'],
      ['Jane', 'Smith', 'Mike Smith', 'Lisa Smith', '9876543212', '', 'mike@email.com', '2010-06-20', 'Female', '1', 'B'],
    ];
    
    for (int row = 0; row < sampleData.length; row++) {
      for (int col = 0; col < sampleData[row].length; col++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1)).value = TextCellValue(sampleData[row][col]);
      }
    }
    
    final encodedData = excel.encode();
    if (encodedData == null) {
      throw Exception("Failed to encode Excel file");
    }
    return Uint8List.fromList(encodedData);
  }
}

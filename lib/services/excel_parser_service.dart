import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import '../data/models/bulk_student_import_request.dart';
import '../utils/constants.dart';

class ExcelParserService {
  // Column name mapping (index to name)
  // Matches Excel template headers (simplified, without format hints)
  // Note: Date of Birth column has been removed
  static const Map<int, String> _columnNames = {
    0: 'First Name',
    1: 'Last Name',
    2: 'Father Name',
    3: 'Mother Name',
    4: 'Primary Contact',
    5: 'Alternate Contact',
    6: 'Parent Email',
    7: 'Gender',
    8: 'Class',
    9: 'Section',
  };
  
  /// Get column name by index
  /// Returns column name or "Column ${index + 1}" if not found
  static String _getColumnName(int index) {
    return _columnNames[index] ?? 'Column ${index + 1}';
  }
  
  /// Parse Excel file and extract student data
  /// [classes] and [sections] are optional lists for dynamic class/section mapping
  /// If provided, class/section names will be looked up dynamically instead of using hardcoded mappings
  /// Returns a map with 'students' list and 'errors' list
  Future<Map<String, dynamic>> parseStudentExcel(
    File file, {
    List<Map<String, dynamic>>? classes,
    List<Map<String, dynamic>>? sections,
  }) async {
    final bytes = await file.readAsBytes();
    return parseStudentExcelFromBytes(bytes, classes: classes, sections: sections);
  }
  
  /// Parse Excel file from bytes and extract student data
  /// [classes] and [sections] are optional lists for dynamic class/section mapping
  /// If provided, class/section names will be looked up dynamically instead of using hardcoded mappings
  /// Returns a map with 'students' list and 'errors' list
  Future<Map<String, dynamic>> parseStudentExcelFromBytes(
    List<int> bytes, {
    List<Map<String, dynamic>>? classes,
    List<Map<String, dynamic>>? sections,
  }) async {
    try {
      debugPrint('📄 Decoding Excel file, size: ${bytes.length} bytes');
      final excel = Excel.decodeBytes(bytes);
      
      if (excel.tables.isEmpty) {
        throw Exception(AppConstants.errorNoSheetsFound);
      }
      
      debugPrint('📊 Found ${excel.tables.length} sheet(s)');
      final allSheetNames = excel.tables.keys.toList();
      debugPrint('📊 Sheet names: $allSheetNames');
      
      // Try to find the first non-empty sheet
      Sheet? sheet;
      String? sheetName;
      
      for (final name in allSheetNames) {
        final currentSheet = excel.tables[name]!;
        debugPrint('🔍 Checking sheet "$name": rows=${currentSheet.rows.length}');
        
        // Check if sheet has any data by trying to access rows
        if (currentSheet.rows.isNotEmpty) {
          sheet = currentSheet;
          sheetName = name;
          debugPrint('✅ Using sheet "$name" with ${currentSheet.rows.length} rows');
          break;
        } else {
          // Try accessing cells directly to see if data exists
          bool hasData = false;
          for (int rowIdx = 0; rowIdx < 10; rowIdx++) {
            for (int colIdx = 0; colIdx < 10; colIdx++) {
              try {
                final cell = currentSheet.cell(CellIndex.indexByColumnRow(columnIndex: colIdx, rowIndex: rowIdx));
                if (cell.value != null) {
                  hasData = true;
                  debugPrint('✅ Found data in sheet "$name" at row $rowIdx, col $colIdx: ${cell.value}');
                  break;
                }
              } catch (e) {
                // Cell doesn't exist, continue
              }
            }
            if (hasData) break;
          }
          
          if (hasData) {
            sheet = currentSheet;
            sheetName = name;
            debugPrint('✅ Using sheet "$name" (has data in cells)');
            break;
          }
        }
      }
      
      if (sheet == null) {
        // Fallback to first sheet
        sheetName = allSheetNames.first;
        sheet = excel.tables[sheetName]!;
        debugPrint('⚠️ No sheet with data found, using first sheet: $sheetName');
      }
      
      debugPrint('📊 Using sheet: $sheetName');
      
      final students = <StudentRequest>[];
      final errors = <String>[];
      
      // Try to get rows - if rows is empty, try accessing cells directly
      List<List<Data?>> rows = [];
      
      if (sheet.rows.isNotEmpty) {
        rows = sheet.rows;
        debugPrint('📊 Using sheet.rows: ${rows.length} rows found');
      } else {
        debugPrint('⚠️ sheet.rows is empty, trying to read cells directly...');
        // Try to read rows by accessing cells
        // Iterate through possible rows (up to 100 rows)
        for (int rowIdx = 0; rowIdx < 100; rowIdx++) {
          List<Data?> row = [];
          bool rowHasData = false;
          
          // Check up to 15 columns
          for (int colIdx = 0; colIdx < 15; colIdx++) {
            try {
              final cellIndex = CellIndex.indexByColumnRow(columnIndex: colIdx, rowIndex: rowIdx);
              final cell = sheet.cell(cellIndex);
              final cellValue = cell.value;
              if (cellValue != null) {
                // Create a Data object from the cell value
                row.add(cell);
                rowHasData = true;
              } else {
                row.add(null);
              }
            } catch (e) {
              // Cell doesn't exist or error accessing it
              row.add(null);
            }
          }
          
          // Trim trailing nulls to get actual row length
          while (row.isNotEmpty && row.last == null) {
            row.removeLast();
          }
          
          if (rowHasData) {
            rows.add(row);
            debugPrint('📊 Found row $rowIdx with data: ${row.take(5).map((c) => c?.value?.toString() ?? 'null').join(', ')}');
          } else if (rows.isNotEmpty) {
            // If we've found rows before and now we hit an empty row, we might be done
            // But continue a bit more to handle cases where there might be gaps
            if (rowIdx > rows.length + 5) {
              break; // Stop if we've gone too far without finding data
            }
          }
        }
        debugPrint('📊 Read ${rows.length} rows by accessing cells directly');
      }
      
      // Check if we found any rows
      if (rows.isEmpty) {
        throw Exception('Excel sheet appears to be empty. Please ensure the file contains data and is in .xlsx format.');
      }
      
      debugPrint('📊 Total rows to process: ${rows.length}');
      
      // Auto-detect the data start row by finding the header row
      int dataStartRow = _findDataStartRowFromList(rows);
      debugPrint('📊 Data start row detected at index: $dataStartRow (Excel row ${dataStartRow + 1})');
      debugPrint('📊 Total rows to process: ${rows.length}');
      
      // Start parsing from the row after headers
      // Note: rows is 0-indexed List, so index 0 = Excel row 1, index 1 = Excel row 2, etc.
      int rowsProcessed = 0;
      int rowsSkipped = 0;
      
      // Iterate through all rows starting from dataStartRow
      final totalRows = rows.length;
      debugPrint('📊 Will iterate from index $dataStartRow to ${totalRows - 1} (Excel rows ${dataStartRow + 1} to $totalRows)');
      
      for (int rowIndex = dataStartRow; rowIndex < totalRows; rowIndex++) {
        // rows is 0-indexed, so rowIndex 0 = Excel row 1, rowIndex 1 = Excel row 2, etc.
        final row = rows[rowIndex];
        final excelRowNum = rowIndex + 1; // Convert to 1-based for user display
        
        // Check if row exists
        if (row.isEmpty) {
          debugPrint('⏭️ Excel row $excelRowNum (index $rowIndex) is empty, skipping');
          rowsSkipped++;
          continue;
        }
        
        // Debug: Show first few cells of each row
        final firstCells = row.take(5).map((c) => c?.value?.toString() ?? 'null').join(', ');
        debugPrint('🔍 Excel row $excelRowNum (index $rowIndex) - First 5 cells: [$firstCells]');
        
        if (_isRowEmpty(row)) {
          debugPrint('⏭️ Excel row $excelRowNum is empty (all cells null/empty), skipping');
          rowsSkipped++;
          continue;
        }
        
        // Skip header row if we encounter it
        if (_isHeaderRow(row)) {
          debugPrint('⏭️ Skipping header row at Excel row $excelRowNum (index $rowIndex)');
          rowsSkipped++;
          continue;
        }
        
        rowsProcessed++;
        try {
          debugPrint('🔍 Parsing Excel row $excelRowNum (index $rowIndex)...');
          final student = _parseStudentRow(row, excelRowNum, classes: classes, sections: sections);
          if (student != null) {
            students.add(student);
            debugPrint('✅ Excel row $excelRowNum parsed successfully: ${student.firstName} ${student.lastName}');
          } else {
            debugPrint('⚠️ Excel row $excelRowNum returned null (parsing failed silently)');
            errors.add('Row $excelRowNum: Failed to parse student data');
          }
        } catch (e) {
          final errorMessage = e.toString().replaceFirst('Exception: ', '');
          debugPrint("❌ ${AppConstants.errorParsingRow} $excelRowNum: $errorMessage");
          errors.add(errorMessage);
          // Continue with other rows
        }
      }
      
      debugPrint('📊 Summary: ${rowsProcessed} rows processed, ${rowsSkipped} rows skipped');
      debugPrint('✅ Parsed ${students.length} students, ${errors.length} errors');
      
      return {
        'students': students,
        'errors': errors,
      };
    } catch (e) {
      throw Exception("${AppConstants.errorParsingExcel}: $e");
    }
  }
  
  /// Parse a single row from Excel
  /// [classes] and [sections] are optional lists for dynamic class/section mapping
  StudentRequest? _parseStudentRow(
    List<Data?> row,
    int rowNumber, {
    List<Map<String, dynamic>>? classes,
    List<Map<String, dynamic>>? sections,
  }) {
    try {
      // Expected columns: First Name, Last Name, Father Name, Mother Name, 
      // Primary Contact, Alternate Contact, Email, Gender, Class, Section
      // Note: Date of Birth column has been removed
      
      // ✅ Enhanced column validation (minimum 7 columns required: up to Email)
      if (row.length < 7) {
        throw Exception("Row $rowNumber: ${AppConstants.errorInsufficientColumns}");
      }
      
      final firstName = _getStringValue(row, 0);
      final lastName = _getStringValue(row, 1);
      final fatherName = _getStringValue(row, 2);
      final motherName = _getStringValue(row, 3);
      final primaryContactRaw = _getStringValue(row, 4);
      final alternateContactRaw = _getStringValue(row, 5);
      final email = _getStringValue(row, 6);
      // Date of Birth column removed - set to null
      final dateOfBirth = null;
      final gender = _getStringValue(row, 7); // Shifted from index 8 to 7
      final className = _getStringValue(row, 8); // Shifted from index 9 to 8
      final sectionName = _getStringValue(row, 9); // Shifted from index 10 to 9
      
      // Validate required fields with column names
      if (firstName == null || firstName.isEmpty) {
        throw Exception("Row $rowNumber, Column ${_getColumnName(0)}: First name is required.");
      }
      if (lastName == null || lastName.isEmpty) {
        throw Exception("Row $rowNumber, Column ${_getColumnName(1)}: Last name is required.");
      }
      if (fatherName == null || fatherName.isEmpty) {
        throw Exception("Row $rowNumber, Column ${_getColumnName(2)}: Father name is required.");
      }
      if (primaryContactRaw == null || primaryContactRaw.isEmpty) {
        throw Exception("Row $rowNumber, Column ${_getColumnName(4)}: Primary contact number is required.");
      }
      // ✅ MANDATORY EMAIL VALIDATION
      if (email == null || email.isEmpty) {
        throw Exception("Row $rowNumber, Column ${_getColumnName(6)}: Parent email is required for account activation.");
      }
      
      // ✅ CONTACT NUMBER VALIDATION (clean and validate)
      // Primary contact is required, alternate contact is optional
      final primaryContact = _validateContactNumber(primaryContactRaw, rowNumber, _getColumnName(4), isRequired: true);
      final alternateContact = _validateContactNumber(alternateContactRaw, rowNumber, _getColumnName(5), isRequired: false);
      
      // ✅ DATE FORMAT VALIDATION - Date of Birth column removed, so skip validation
      // _validateDateFormat(dateOfBirth, rowNumber); // Removed - Date of Birth column no longer exists
      
      // ✅ GENDER NORMALIZATION
      final normalizedGender = _normalizeGender(gender, rowNumber);
      
      // Parse class and section IDs
      debugPrint('📚 Parsing class: "$className", section: "$sectionName" for row $rowNumber');
      final classId = _parseClassId(className, classes: classes, rowNumber: rowNumber);
      final sectionId = _parseSectionId(sectionName, sections: sections, rowNumber: rowNumber);
      
      debugPrint('✅ Class ID: $classId, Section ID: $sectionId');
      
      return StudentRequest(
        firstName: firstName,
        lastName: lastName,
        fatherName: fatherName,
        motherName: motherName,
        primaryContactNumber: primaryContact!, // Required, so should not be null after validation
        alternateContactNumber: alternateContact, // Can be null (optional)
        email: email,
        dateOfBirth: dateOfBirth,
        gender: normalizedGender, // Normalized to "Male" or "Female" or null
        classId: classId,
        sectionId: sectionId,
        createdBy: AppConstants.keyBulkImport, // This will be overridden by backend with actual creator
        parentRelation: AppConstants.relationGuardian, // ✅ Set default to "GUARDIAN" (matches normal registration)
      );
    } catch (e) {
      debugPrint("${AppConstants.errorParsingRow} $rowNumber: $e");
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
  
  /// Clean contact number by removing spaces, dashes, parentheses, and other special characters
  String? _cleanContactNumber(String? contactNumber) {
    if (contactNumber == null || contactNumber.isEmpty) {
      return null;
    }
    
    // Remove spaces, dashes, parentheses, plus signs, and other common formatting characters
    return contactNumber
        .replaceAll(RegExp(r'[\s\-\(\)\+\.]'), '') // Remove spaces, dashes, parentheses, plus, dots
        .trim();
  }
  
  /// Normalize gender value to "Male" or "Female"
  /// Accepts: "Male", "male", "MALE", "M", "m", "Female", "female", "FEMALE", "F", "f"
  /// Returns: "Male" or "Female" (standardized, capitalized)
  /// Throws exception if gender value is invalid
  String? _normalizeGender(String? gender, int rowNumber) {
    if (gender == null || gender.isEmpty) {
      // Gender is optional, so empty is allowed
      return null;
    }
    
    final trimmedGender = gender.trim();
    
    // Case-insensitive matching
    final lowerGender = trimmedGender.toLowerCase();
    
    // Map valid inputs to standardized values
    if (lowerGender == 'male' || lowerGender == 'm') {
      return 'Male';
    } else if (lowerGender == 'female' || lowerGender == 'f') {
      return 'Female';
    } else {
      // Invalid gender value
      throw Exception(
        'Row $rowNumber, Column ${_getColumnName(8)}: Invalid gender "$gender". '
        'Must be Male or Female (case-insensitive: Male, male, M, Female, female, F).'
      );
    }
  }
  
  /// Validate contact number format (exactly 10 digits for Indian mobile)
  /// [isRequired] indicates if the contact number is mandatory (true for primary, false for alternate)
  /// Throws exception if format is invalid
  String? _validateContactNumber(String? contactNumber, int rowNumber, String contactType, {bool isRequired = false}) {
    if (contactNumber == null || contactNumber.isEmpty) {
      if (isRequired) {
        throw Exception(
          'Row $rowNumber, Column $contactType: Contact number is required.'
        );
      }
      // Contact is optional (for alternate contact), so empty is allowed
      return null;
    }
    
    // Clean the contact number first
    final cleaned = _cleanContactNumber(contactNumber);
    
    if (cleaned == null || cleaned.isEmpty) {
      if (isRequired) {
        throw Exception(
          'Row $rowNumber, Column $contactType: Contact number is required. '
          'After removing spaces and special characters, the number is empty.'
        );
      }
      // After cleaning, if it's empty, return null (optional)
      return null;
    }
    
    // Validate: Must be exactly 10 digits
    final digitPattern = RegExp(r'^\d{10}$');
    
    if (!digitPattern.hasMatch(cleaned)) {
      throw Exception(
        'Row $rowNumber, Column $contactType: Invalid contact number "$contactNumber". '
        'Must be exactly 10 digits (Indian mobile format). '
        'Example: 9876543210'
      );
    }
    
    // Return cleaned contact number
    return cleaned;
  }
  
  /// Validate date format (YYYY-MM-DD)
  /// Throws exception if format is invalid
  void _validateDateFormat(String? dateString, int rowNumber) {
    if (dateString == null || dateString.isEmpty) {
      // Date is optional, so empty is allowed
      return;
    }
    
    final columnName = _getColumnName(7); // Date of Birth
    
    // Expected format: YYYY-MM-DD (e.g., 2010-05-15)
    final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    
    if (!datePattern.hasMatch(dateString)) {
      throw Exception(
        'Row $rowNumber, Column $columnName: Invalid date format "$dateString". '
        'Expected YYYY-MM-DD format (e.g., 2010-05-15).'
      );
    }
    
    // Additional validation: Check if it's a valid date
    try {
      final parts = dateString.split('-');
      if (parts.length != 3) {
        throw Exception(
          'Row $rowNumber, Column $columnName: Invalid date format "$dateString". '
          'Expected YYYY-MM-DD format (e.g., 2010-05-15).'
        );
      }
      
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      // Basic range validation
      if (year < 1900 || year > 2100) {
        throw Exception(
          'Row $rowNumber, Column $columnName: Invalid year "$year". '
          'Year must be between 1900 and 2100.'
        );
      }
      
      if (month < 1 || month > 12) {
        throw Exception(
          'Row $rowNumber, Column $columnName: Invalid month "$month". '
          'Month must be between 1 and 12.'
        );
      }
      
      if (day < 1 || day > 31) {
        throw Exception(
          'Row $rowNumber, Column $columnName: Invalid day "$day". '
          'Day must be between 1 and 31.'
        );
      }
      
      // Try to create a DateTime to validate the actual date
      final date = DateTime(year, month, day);
      
      // Check if the parsed date matches the input (catches invalid dates like 2010-02-30)
      if (date.year != year || date.month != month || date.day != day) {
        throw Exception(
          'Row $rowNumber, Column $columnName: Invalid date "$dateString". '
          'The date does not exist (e.g., February 30th).'
        );
      }
      
    } catch (e) {
      // If parsing fails, it's already an invalid format
      if (e.toString().contains('Row $rowNumber')) {
        rethrow; // Re-throw our custom exceptions
      }
      throw Exception(
        'Row $rowNumber, Column $columnName: Invalid date format "$dateString". '
        'Expected YYYY-MM-DD format (e.g., 2010-05-15).'
      );
    }
  }
  
  /// Check if row is empty
  bool _isRowEmpty(List<Data?> row) {
    return row.every((cell) => cell == null || cell.value == null || cell.value.toString().trim().isEmpty);
  }
  
  /// Check if a row is a header row by looking for header keywords
  bool _isHeaderRow(List<Data?> row) {
    if (row.isEmpty) return false;
    
    // Check if first few cells contain header keywords
    // Expanded list to handle various header formats and abbreviations
    final headerKeywords = [
      'first name', 'firstname', 'first', 'fname',
      'last name', 'lastname', 'last', 'lname',
      'father name', 'fathername', 'father', 'father\'s name',
      'mother name', 'mothername', 'mother', 'mother\'s name',
      'primary contact', 'primary con', 'primary', 'contact', 'phone', 'mobile',
      'alternate contact', 'alternate con', 'alter', 'alt contact', 'alt',
      'parent email', 'email', 'e-mail', 'parent\'s email',
      'gender', 'sex',
      'class', 'grade', 'standard',
      'section', 'sec',
      'date of birth', 'dob', 'birth date', 'date', 'birth'
    ];
    
    // Count how many cells match header keywords (need at least 3 matches to be confident)
    int matchCount = 0;
    
    // Check first 10 cells for header keywords
    for (int i = 0; i < row.length && i < 10; i++) {
      if (row[i]?.value != null) {
        final cellValue = row[i]!.value.toString().toLowerCase().trim();
        for (final keyword in headerKeywords) {
          if (cellValue.contains(keyword) || keyword.contains(cellValue)) {
            matchCount++;
            debugPrint('✅ Header keyword match at column $i: "$cellValue" matches "$keyword"');
            break; // Count each cell only once
          }
        }
      }
    }
    
    // Consider it a header row if at least 3 columns match header keywords
    final isHeader = matchCount >= 3;
    if (isHeader) {
      debugPrint('📋 Header row detected with $matchCount matching columns');
    }
    
    return isHeader;
  }
  
  /// Find the row index where data starts (after header row)
  /// Returns the 0-based index (rows is a List, so 0-indexed)
  /// Note: rows[0] = Excel row 1, rows[1] = Excel row 2, etc.
  int _findDataStartRowFromList(List<List<Data?>> rows) {
    debugPrint('🔍 Searching for header row...');
    
    if (rows.isEmpty) {
      debugPrint('⚠️ No rows found');
      return 1; // Default to index 1 (Excel row 2)
    }
    
    final maxRowToCheck = rows.length > 10 ? 10 : rows.length;
    debugPrint('🔍 Checking first $maxRowToCheck rows (indices 0 to ${maxRowToCheck - 1})');
    
    // Look for header row in first 10 rows (0-indexed list)
    for (int rowIndex = 0; rowIndex < maxRowToCheck; rowIndex++) {
      final row = rows[rowIndex];
      final excelRowNum = rowIndex + 1; // Convert to 1-based for display
      
      if (row.isNotEmpty) {
        final firstCells = row.take(5).map((c) => c?.value?.toString() ?? '').join(', ');
        debugPrint('🔍 Checking Excel row $excelRowNum (index $rowIndex): [$firstCells]');
        
        if (_isHeaderRow(row)) {
          // Data starts at the next row after header
          // Return 0-indexed: if header is at index 0 (Excel row 1), return 1 (Excel row 2)
          debugPrint('✅ Header row found at Excel row $excelRowNum (index $rowIndex), data will start at Excel row ${excelRowNum + 1} (index ${rowIndex + 1})');
          return rowIndex + 1; // Return next index (0-indexed)
        }
      }
    }
    
    // If header not found, check if row 0 (Excel row 1) looks like data (has names, not headers)
    if (rows.isNotEmpty) {
      final firstRow = rows[0];
      if (firstRow.isNotEmpty && !_isHeaderRow(firstRow) && !_isRowEmpty(firstRow)) {
        // Check if first cell looks like a name (not a header)
        final firstCell = firstRow[0]?.value?.toString() ?? '';
        // Names usually don't contain common header words
        if (!firstCell.toLowerCase().contains('first') && 
            !firstCell.toLowerCase().contains('name') &&
            firstCell.trim().length > 0) {
          debugPrint('⚠️ No header row detected, but Excel row 1 (index 0) looks like data. Starting from index 0');
          return 0; // Start from index 0
        }
      }
    }
    
    // Default: assume headers at index 0 (Excel row 1), data starts at index 1 (Excel row 2)
    debugPrint('⚠️ Header row not detected, using default start row (index 1, Excel row 2)');
    return 1; // Index 1 = Excel row 2
  }
  
  /// Parse class ID from class name using dynamic lookup
  /// If [classes] list is provided, performs case-insensitive lookup by className
  /// Otherwise, returns null (class is optional)
  int? _parseClassId(
    String? className, {
    List<Map<String, dynamic>>? classes,
    int? rowNumber,
  }) {
    if (className == null || className.isEmpty) return null;
    
    // If classes list is provided, use dynamic lookup
    if (classes != null && classes.isNotEmpty) {
      final trimmedName = className.trim();
      
      // Try exact match first (case-insensitive)
      for (var classData in classes) {
        final classId = classData['classId'] as int?;
        final classNameFromData = classData['className']?.toString().trim();
        
        if (classNameFromData != null && 
            classNameFromData.toLowerCase() == trimmedName.toLowerCase()) {
          debugPrint('✅ Found class "$trimmedName" → ID: $classId');
          return classId;
        }
      }
      
      // If not found, throw error with available class names
      final availableClasses = classes
          .map((c) => c['className']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .join(', ');
      
      throw Exception(
        'Row $rowNumber, Column ${_getColumnName(9)}: Class "$trimmedName" not found. '
        'Available classes: ${availableClasses.isNotEmpty ? availableClasses : "None configured"}. '
        'Please use one of the valid class names.'
      );
    }
    
    // Fallback: return null if no classes list provided (class is optional)
    debugPrint('⚠️ No classes list provided, class "$className" will be ignored');
    return null;
  }
  
  /// Parse section ID from section name using dynamic lookup
  /// If [sections] list is provided, performs case-insensitive lookup by sectionName
  /// Otherwise, returns null (section is optional)
  int? _parseSectionId(
    String? sectionName, {
    List<Map<String, dynamic>>? sections,
    int? rowNumber,
  }) {
    if (sectionName == null || sectionName.isEmpty) return null;
    
    // If sections list is provided, use dynamic lookup
    if (sections != null && sections.isNotEmpty) {
      final trimmedName = sectionName.trim();
      
      // Try exact match first (case-insensitive)
      for (var sectionData in sections) {
        final sectionId = sectionData['sectionId'] as int?;
        final sectionNameFromData = sectionData['sectionName']?.toString().trim();
        
        if (sectionNameFromData != null && 
            sectionNameFromData.toLowerCase() == trimmedName.toLowerCase()) {
          debugPrint('✅ Found section "$trimmedName" → ID: $sectionId');
          return sectionId;
        }
      }
      
      // If not found, throw error with available section names
      final availableSections = sections
          .map((s) => s['sectionName']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .join(', ');
      
      throw Exception(
        'Row $rowNumber, Column ${_getColumnName(9)}: Section "$trimmedName" not found. '
        'Available sections: ${availableSections.isNotEmpty ? availableSections : "None configured"}. '
        'Please use one of the valid section names.'
      );
    }
    
    // Fallback: return null if no sections list provided (section is optional)
    debugPrint('⚠️ No sections list provided, section "$sectionName" will be ignored');
    return null;
  }
  
  /// Generate Excel template
  /// [classes] and [sections] are optional lists to show available options in template
  Future<Uint8List> generateExcelTemplate({
    List<Map<String, dynamic>>? classes,
    List<Map<String, dynamic>>? sections,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Students'];
    
    // Build available classes/sections info
    String classInfo = '';
    if (classes != null && classes.isNotEmpty) {
      final classNames = classes
          .map((c) => c['className']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .join(', ');
      classInfo = 'Available: $classNames';
    } else {
      classInfo = 'Note: Use class name from your school (e.g., "1", "2", "Class 1")';
    }
    
    String sectionInfo = '';
    if (sections != null && sections.isNotEmpty) {
      final sectionNames = sections
          .map((s) => s['sectionName']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .join(', ');
      sectionInfo = 'Available: $sectionNames';
    } else {
      sectionInfo = 'Note: Use section name from your school (e.g., "A", "B", "Section A")';
    }
    
    // Row 0: Headers (with format hints)
    // Note: Date of Birth column has been removed
    final headers = [
      'First Name',
      'Last Name', 
      'Father Name',
      'Mother Name',
      'Primary Contact',
      'Alternate Contact',
      'Parent Email',
      'Gender',
      'Class',
      'Section'
    ];
    
    // Row 1: Detailed hints/notes for each column
    // Note: Date of Birth hint removed
    final hintsRow = [
      'Required, max 100 characters',
      'Required, max 100 characters',
      'Required',
      'Optional',
      'Required, exactly 10 digits (e.g., 9876543210)',
      'Optional, exactly 10 digits (e.g., 9876543211)',
      'Required, valid email format (e.g., parent@email.com)',
      'Male or Female (case-insensitive: Male, male, M, Female, female, F)',
      classInfo,
      sectionInfo,
    ];
    
    // Add headers (Row 0)
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      // Try to apply bold formatting if supported
      try {
        cell.cellStyle = CellStyle(
          bold: true,
        );
      } catch (e) {
        // CellStyle might not be available in all versions, continue without styling
        debugPrint('⚠️ CellStyle not available: $e');
      }
    }
    
    // Add hints row (Row 1) - italic style if possible
    for (int col = 0; col < hintsRow.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 1));
      cell.value = TextCellValue(hintsRow[col]);
      // Try to apply italic formatting if supported
      try {
        cell.cellStyle = CellStyle(
          italic: true,
        );
      } catch (e) {
        // CellStyle might not be available, continue without styling
        debugPrint('⚠️ CellStyle not available: $e');
      }
    }
    
    // Get sample class and section
    String sampleClass1 = classes != null && classes.isNotEmpty 
        ? (classes.first['className']?.toString() ?? '1')
        : '1';
    String sampleClass2 = classes != null && classes.length > 1
        ? (classes[1]['className']?.toString() ?? '2')
        : (classes != null && classes.isNotEmpty ? sampleClass1 : '2');
    String sampleSection1 = sections != null && sections.isNotEmpty 
        ? (sections.first['sectionName']?.toString() ?? 'A')
        : 'A';
    String sampleSection2 = sections != null && sections.length > 1
        ? (sections[1]['sectionName']?.toString() ?? 'B')
        : (sections != null && sections.isNotEmpty ? sampleSection1 : 'B');
    
    // Row 2-4: Sample data with different scenarios
    // Note: Date of Birth removed from all samples
    final sampleData = [
      // Sample 1: Complete data with alternate contact, Male
      [
        'Rahul', 
        'Kumar', 
        'Rajesh Kumar', 
        'Priya Kumar', 
        '9876543210', 
        '9876543211', 
        'rajesh.kumar@email.com', 
        'Male', 
        sampleClass1, 
        sampleSection1
      ],
      // Sample 2: Complete data without alternate contact, Female
      [
        'Priya', 
        'Sharma', 
        'Amit Sharma', 
        'Sunita Sharma', 
        '9876543212', 
        '', // No alternate contact
        'amit.sharma@email.com', 
        'Female', 
        sampleClass1, 
        sampleSection2
      ],
      // Sample 3: Different class/section, lowercase gender
      [
        'Arjun', 
        'Patel', 
        'Vikram Patel', 
        'Meera Patel', 
        '9876543213', 
        '9876543214', 
        'vikram.patel@email.com', 
        'male', // lowercase to show case-insensitive
        sampleClass2, 
        sampleSection1
      ],
    ];
    
    // Add sample data (starting from row 2)
    for (int row = 0; row < sampleData.length; row++) {
      for (int col = 0; col < sampleData[row].length; col++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 2)).value = TextCellValue(sampleData[row][col]);
      }
    }
    
    // Add instruction note at the top (if we can add a row before headers)
    // Note: Excel package might not support inserting rows easily, so we'll add instructions as a comment
    // Users should start entering data from row 3 (after headers, hints, and sample data)
    
    // Set column widths (approximate, Excel will auto-adjust)
    // Note: Column width setting might not be available in all versions
    
    final encodedData = excel.encode();
    if (encodedData == null) {
      throw Exception(AppConstants.errorFailedToEncodeExcel);
    }
    return Uint8List.fromList(encodedData);
  }
}


# Bulk Import Fix - Step-by-Step Prompts

## 📋 Overview

This document contains **sequential prompts** to fix all issues found in the bulk student import functionality. Please provide these prompts **one by one** in the order listed.

---

## 🔴 **PROMPT 1: Fix Critical Class/Section Mapping Issue** (HIGHEST PRIORITY)

**Copy and paste this prompt:**

```
Please fix the critical class/section mapping issue in the bulk student import functionality. 

Current Problem:
- Frontend uses hardcoded mappings (Class '1' → ID 1, Section 'A' → ID 1)
- Backend expects actual database IDs that may not match
- This causes students to be assigned to wrong classes/sections

Solution Required:
1. Add backend API endpoints to fetch classes and sections for a school:
   - GET /api/schools/{schoolId}/classes - Returns list of classes with ID and name
   - GET /api/schools/{schoolId}/sections - Returns list of sections with ID and name

2. Create frontend service methods:
   - Add methods in school_service.dart to fetch classes and sections
   - Cache the results for the current school

3. Update bulk_student_import_page.dart:
   - Fetch classes and sections when page loads (using schoolId from SharedPreferences)
   - Store them in state variables
   - Pass them to ExcelParserService

4. Update excel_parser_service.dart:
   - Accept class and section lists as parameters
   - Replace hardcoded mappings with dynamic lookup:
     - Find class by name (case-insensitive) and return its ID
     - Find section by name (case-insensitive) and return its ID
   - If class/section not found, throw clear error with row number

5. Update Excel template generation:
   - Keep class/section as names (not IDs) in template
   - Add comment/note about valid class/section names

Please implement this solution and ensure:
- Error messages show which class/section name was not found
- Validation happens before sending to backend
- Template still uses names (user-friendly)
```

---

## 🟡 **PROMPT 2: Add Date Format Validation**

**Copy and paste this prompt:**

```
Please add date format validation in the bulk student import functionality.

Requirements:
1. In excel_parser_service.dart, add a method to validate date format:
   - Expected format: YYYY-MM-DD (e.g., 2010-05-15)
   - Validate before parsing the date
   - Throw clear error if format is invalid: "Invalid date format at row X. Expected YYYY-MM-DD format."

2. Update _parseStudentRow method:
   - Call date validation before using dateOfBirth
   - Show row number in error message

3. Update Excel template:
   - Keep format hint: "Date of Birth (YYYY-MM-DD)"
   - Add example: "Example: 2010-05-15"

4. Add validation in bulk_student_import_page.dart:
   - Show date format errors in validation results
   - Highlight which rows have invalid dates

Please ensure:
- Date validation happens during Excel parsing (before sending to backend)
- Error messages are clear and include row number
- Invalid dates are caught early
```

---

## 🟡 **PROMPT 3: Add Contact Number Format Validation**

**Copy and paste this prompt:**

```
Please add contact number format validation in the bulk student import functionality.

Requirements:
1. In excel_parser_service.dart, add validation for contact numbers:
   - Primary contact: Must be exactly 10 digits (Indian mobile format)
   - Alternate contact: If provided, must be exactly 10 digits
   - Remove any spaces, dashes, or special characters before validation
   - Throw clear error: "Invalid contact number at row X. Must be exactly 10 digits."

2. Update _parseStudentRow method:
   - Clean contact numbers (remove spaces, dashes, parentheses)
   - Validate format before using
   - Show row number in error message

3. Update Excel template:
   - Add format hint: "Primary Contact (10 digits, e.g., 9876543210)"
   - Add example in sample data

4. Add validation in bulk_student_import_page.dart:
   - Show contact number errors in validation results
   - Highlight which rows have invalid contact numbers

Please ensure:
- Contact numbers are cleaned (spaces/dashes removed) before validation
- Validation happens during Excel parsing (before sending to backend)
- Error messages are clear and include row number
- Both primary and alternate contacts are validated if provided
```

---

## 🟢 **PROMPT 4: Add Gender Normalization**

**Copy and paste this prompt:**

```
Please add gender normalization in the bulk student import functionality.

Requirements:
1. In excel_parser_service.dart, add a method to normalize gender:
   - Accept: "Male", "male", "MALE", "M", "m", "Female", "female", "FEMALE", "F", "f"
   - Return: "Male" or "Female" (standardized)
   - Throw error for invalid values: "Invalid gender at row X. Must be Male or Female."

2. Update _parseStudentRow method:
   - Normalize gender before using
   - Show row number in error message if invalid

3. Update Excel template:
   - Keep format hint: "Gender (Male/Female)"
   - Add note: "Case-insensitive (Male, male, M, Female, female, F)"

4. Add validation in bulk_student_import_page.dart:
   - Show gender errors in validation results
   - Highlight which rows have invalid gender

Please ensure:
- Gender is normalized to "Male" or "Female" (capitalized)
- Case-insensitive input is accepted
- Invalid values are caught during Excel parsing
- Error messages are clear and include row number
```

---

## 🟢 **PROMPT 5: Improve Error Messages with Column Names**

**Copy and paste this prompt:**

```
Please improve error messages in the bulk student import functionality to include column names and better context.

Requirements:
1. In excel_parser_service.dart:
   - Update all error messages to include column name
   - Format: "Row X, Column [ColumnName]: [Error Message]"
   - Example: "Row 3, Column First Name: First name is required"
   - Example: "Row 5, Column Primary Contact: Invalid contact number. Must be exactly 10 digits."

2. Create a column name mapping:
   - Map column index to column name
   - Use in all error messages

3. Update bulk_student_import_page.dart:
   - Display errors with column names in validation results
   - Make it easier to identify which cell has the error

4. Update Excel template:
   - Ensure column headers match the column names used in error messages

Please ensure:
- All error messages include row number AND column name
- Error messages are user-friendly and actionable
- Column names match Excel template headers
- Users can easily identify which cell needs to be fixed
```

---

## 🟢 **PROMPT 6: Enhance Excel Template with Data Validation**

**Copy and paste this prompt:**

```
Please enhance the Excel template generation to include better formatting and hints.

Requirements:
1. In excel_parser_service.dart, update generateExcelTemplate method:
   - Add formatting to header row (bold, background color)
   - Add data validation hints in second row (optional, as comments)
   - Improve sample data with realistic examples
   - Add instructions row (optional) or separate sheet with instructions

2. Column-specific improvements:
   - First Name/Last Name: Add note "Required, max 100 characters"
   - Father Name: Add note "Required"
   - Primary Contact: Add note "Required, exactly 10 digits"
   - Parent Email: Add note "Required, valid email format"
   - Date of Birth: Add note "Format: YYYY-MM-DD"
   - Gender: Add note "Male or Female (case-insensitive)"
   - Class: Add note "Use class name (e.g., '1', '2', 'Class 1')"
   - Section: Add note "Use section name (e.g., 'A', 'B', 'Section A')"

3. Add sample data:
   - Include 2-3 sample rows with valid data
   - Show different scenarios (with/without alternate contact, different genders, etc.)

Please ensure:
- Template is user-friendly and self-explanatory
- Format hints are clear
- Sample data demonstrates correct format
- Users can easily understand what to enter in each column
```

---

## 📝 **Usage Instructions**

1. **Start with PROMPT 1** (Critical - Class/Section Mapping)
2. **Test the fix** before moving to next prompt
3. **Continue with PROMPT 2, 3, 4, 5, 6** in order
4. **Test after each fix** to ensure it works correctly

---

## ✅ **Testing Checklist**

After implementing all prompts, test:

- [ ] Download template and verify format
- [ ] Fill Excel with valid data and import successfully
- [ ] Test with invalid class/section names (should show error)
- [ ] Test with invalid date format (should show error)
- [ ] Test with invalid contact number (should show error)
- [ ] Test with invalid gender (should show error)
- [ ] Test with missing required fields (should show error)
- [ ] Verify error messages include row and column information
- [ ] Verify students are assigned to correct classes/sections
- [ ] Verify activation emails are sent (if enabled)

---

## 📌 **Notes**

- Each prompt is independent but builds on previous fixes
- Test after each prompt to catch issues early
- If any prompt fails, let me know and I'll help debug
- All prompts assume you're working in the correct workspace

---

**Ready to start? Copy PROMPT 1 and paste it to begin!**


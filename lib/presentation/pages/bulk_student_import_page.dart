import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/bulk_student_import_request.dart';
import '../../data/models/bulk_import_result.dart';
import '../../services/bulk_student_import_service.dart';
import '../../services/excel_parser_service.dart';
import '../../services/master_data_service.dart';

class BulkStudentImportPage extends StatefulWidget {
  const BulkStudentImportPage({Key? key}) : super(key: key);

  @override
  State<BulkStudentImportPage> createState() => _BulkStudentImportPageState();
}

class _BulkStudentImportPageState extends State<BulkStudentImportPage> {
  final _formKey = GlobalKey<FormState>();
  final _bulkImportService = BulkStudentImportService();
  final _excelParserService = ExcelParserService();
  final _masterDataService = MasterDataService();
  
  File? _selectedFile;
  bool _isLoading = false;
  bool _isValidating = false;
  bool _isImporting = false;
  BulkImportResult? _validationResult;
  BulkImportResult? _importResult;
  
  // Configuration
  String _schoolDomain = '';
  bool _sendActivationEmails = true;
  String _emailStrategy = 'AUTO_GENERATE';
  
  // School info
  int? _schoolId;
  String? _schoolName;
  
  @override
  void initState() {
    super.initState();
    _loadSchoolInfo();
  }
  
  Future<void> _loadSchoolInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _schoolId = prefs.getInt('schoolId');
      _schoolName = prefs.getString('schoolName');
    });
  }
  
  Future<void> _pickExcelFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _validationResult = null;
          _importResult = null;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking file: $e');
    }
  }
  
  Future<void> _downloadTemplate() async {
    try {
      setState(() => _isLoading = true);
      
      final templateBytes = await _excelParserService.generateExcelTemplate();
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/student_import_template.xlsx');
      await file.writeAsBytes(templateBytes);
      
      _showSuccessSnackBar('Template downloaded to: ${file.path}');
    } catch (e) {
      _showErrorSnackBar('Error downloading template: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _validateData() async {
    if (_selectedFile == null) {
      _showErrorSnackBar('Please select an Excel file first');
      return;
    }
    
    if (!_formKey.currentState!.validate()) return;
    
    try {
      setState(() => _isValidating = true);
      
      // Parse Excel file
      final students = await _excelParserService.parseStudentExcel(_selectedFile!);
      
      if (students.isEmpty) {
        _showErrorSnackBar('No valid student data found in Excel file');
        return;
      }
      
      // Create validation request
      final request = BulkStudentImportRequest(
        students: students,
        schoolId: _schoolId!,
        createdBy: 'SchoolAdmin',
        schoolDomain: _schoolDomain.isNotEmpty ? _schoolDomain : null,
        sendActivationEmails: _sendActivationEmails,
        emailGenerationStrategy: _emailStrategy,
      );
      
      // Validate data
      final result = await _bulkImportService.validateStudents(request);
      
      setState(() {
        _validationResult = result;
      });
      
      if (result.success) {
        _showSuccessSnackBar('Validation successful! ${result.successfulImports} students are ready for import.');
      } else {
        _showErrorSnackBar('Validation failed. ${result.failedImports} students have errors.');
      }
      
    } catch (e) {
      _showErrorSnackBar('Error validating data: $e');
    } finally {
      setState(() => _isValidating = false);
    }
  }
  
  Future<void> _importData() async {
    if (_selectedFile == null) {
      _showErrorSnackBar('Please select an Excel file first');
      return;
    }
    
    if (_validationResult == null || !_validationResult!.success) {
      _showErrorSnackBar('Please validate data first');
      return;
    }
    
    try {
      setState(() => _isImporting = true);
      
      // Parse Excel file
      final students = await _excelParserService.parseStudentExcel(_selectedFile!);
      
      // Create import request
      final request = BulkStudentImportRequest(
        students: students,
        schoolId: _schoolId!,
        createdBy: 'SchoolAdmin',
        schoolDomain: _schoolDomain.isNotEmpty ? _schoolDomain : null,
        sendActivationEmails: _sendActivationEmails,
        emailGenerationStrategy: _emailStrategy,
      );
      
      // Import data
      final result = await _bulkImportService.importStudents(request);
      
      setState(() {
        _importResult = result;
      });
      
      if (result.success) {
        _showSuccessSnackBar('Import successful! ${result.successfulImports} students imported.');
        _showImportSummaryDialog(result);
      } else {
        _showErrorSnackBar('Import completed with errors. ${result.successfulImports} successful, ${result.failedImports} failed.');
        _showImportSummaryDialog(result);
      }
      
    } catch (e) {
      _showErrorSnackBar('Error importing data: $e');
    } finally {
      setState(() => _isImporting = false);
    }
  }
  
  void _showImportSummaryDialog(BulkImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Import Summary'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Rows: ${result.totalRows}'),
              Text('Successful: ${result.successfulImports}'),
              Text('Failed: ${result.failedImports}'),
              SizedBox(height: 16),
              if (result.errors.isNotEmpty) ...[
                Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ...result.errors.take(5).map((error) => Text('• $error')),
                if (result.errors.length > 5)
                  Text('... and ${result.errors.length - 5} more errors'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bulk Student Import'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // School Info Card
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'School Information',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text('School: $_schoolName'),
                            Text('School ID: $_schoolId'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Configuration Card
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Import Configuration',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 16),
                            
                            // School Domain
                            TextFormField(
                              initialValue: _schoolDomain,
                              decoration: InputDecoration(
                                labelText: 'School Email Domain',
                                hintText: 'e.g., schoolname.edu',
                                prefixText: '@',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) => _schoolDomain = value,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (!value.contains('.')) {
                                    return 'Please enter a valid domain (e.g., schoolname.edu)';
                                  }
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            
                            // ✅ Email Strategy - Updated for mandatory emails
                            Text('Email Strategy:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                border: Border.all(color: Colors.blue),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.info, color: Colors.blue, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Parent Email is Required',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '• All parent emails must be provided in the Excel file\n'
                                    '• Emails are used to send activation links for parent accounts\n'
                                    '• Invalid or missing emails will cause import to fail',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                            
                            // Send Activation Emails
                            CheckboxListTile(
                              title: Text('Send Activation Emails'),
                              subtitle: Text('Send activation emails to parents'),
                              value: _sendActivationEmails,
                              onChanged: (value) => setState(() => _sendActivationEmails = value!),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // File Selection Card
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Excel File',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickExcelFile,
                                    icon: Icon(Icons.upload_file),
                                    label: Text('Select Excel File'),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _downloadTemplate,
                                    icon: Icon(Icons.download),
                                    label: Text('Download Template'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            
                            if (_selectedFile != null) ...[
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  border: Border.all(color: Colors.green),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Selected: ${_selectedFile!.path.split('/').last}',
                                        style: TextStyle(color: Colors.green[800]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isValidating ? null : _validateData,
                            icon: _isValidating 
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(Icons.check_circle),
                            label: Text(_isValidating ? 'Validating...' : 'Validate Data'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (_isImporting || _validationResult == null || !_validationResult!.success) 
                                ? null 
                                : _importData,
                            icon: _isImporting 
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(Icons.upload),
                            label: Text(_isImporting ? 'Importing...' : 'Import Students'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Validation Results
                    if (_validationResult != null) ...[
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Validation Results',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 16),
                              _buildResultSummary(_validationResult!),
                              if (_validationResult!.results.isNotEmpty) ...[
                                SizedBox(height: 16),
                                Text('Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 8),
                                ..._validationResult!.results.take(10).map((result) => 
                                  _buildResultItem(result)
                                ),
                                if (_validationResult!.results.length > 10)
                                  Text('... and ${_validationResult!.results.length - 10} more'),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    // Import Results
                    if (_importResult != null) ...[
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Import Results',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 16),
                              _buildResultSummary(_importResult!),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildResultSummary(BulkImportResult result) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total',
            result.totalRows.toString(),
            Colors.blue,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            'Success',
            result.successfulImports.toString(),
            Colors.green,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            'Failed',
            result.failedImports.toString(),
            Colors.red,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultItem(StudentImportResult result) {
    Color statusColor = result.status == 'SUCCESS' || result.status == 'VALID' 
        ? Colors.green 
        : Colors.red;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        border: Border.all(color: statusColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.status == 'SUCCESS' || result.status == 'VALID' 
                    ? Icons.check_circle 
                    : Icons.error,
                color: statusColor,
                size: 16,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Row ${result.rowNumber}: ${result.studentName}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (result.parentEmail != null) ...[
            SizedBox(height: 4),
            Text(
              'Email: ${result.parentEmail}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
          if (result.errorMessage != null) ...[
            SizedBox(height: 4),
            Text(
              'Error: ${result.errorMessage}',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }
}

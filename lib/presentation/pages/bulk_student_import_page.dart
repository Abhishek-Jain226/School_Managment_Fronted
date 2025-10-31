import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import '../../data/models/bulk_student_import_request.dart';
import '../../data/models/bulk_import_result.dart';
import '../../services/bulk_student_import_service.dart';
import '../../services/excel_parser_service.dart';

class BulkStudentImportPage extends StatefulWidget {
  const BulkStudentImportPage({Key? key}) : super(key: key);

  @override
  State<BulkStudentImportPage> createState() => _BulkStudentImportPageState();
}

class _BulkStudentImportPageState extends State<BulkStudentImportPage> {
  final _formKey = GlobalKey<FormState>();
  final _bulkImportService = BulkStudentImportService();
  final _excelParserService = ExcelParserService();
  
  File? _selectedFile;
  bool _isLoading = false;
  bool _isValidating = false;
  bool _isImporting = false;
  BulkImportResult? _validationResult;
  BulkImportResult? _importResult;
  
  // Configuration
  String _schoolDomain = '';
  bool _sendActivationEmails = true;
  final String _emailStrategy = 'AUTO_GENERATE';
  
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
      _showErrorSnackBar('${AppConstants.msgErrorPickingFile}$e');
    }
  }
  
  Future<void> _downloadTemplate() async {
    try {
      setState(() => _isLoading = true);
      
      final templateBytes = await _excelParserService.generateExcelTemplate();
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${AppConstants.fileNameStudentTemplate}');
      await file.writeAsBytes(templateBytes);
      
      _showSuccessSnackBar('${AppConstants.msgTemplateDownloaded}${file.path}');
    } catch (e) {
      _showErrorSnackBar('${AppConstants.msgErrorDownloadingTemplate}$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _validateData() async {
    if (_selectedFile == null) {
      _showErrorSnackBar(AppConstants.msgPleaseSelectExcelFile);
      return;
    }
    
    if (!_formKey.currentState!.validate()) return;
    
    try {
      setState(() => _isValidating = true);
      
      // Parse Excel file
      final students = await _excelParserService.parseStudentExcel(_selectedFile!);
      
      if (students.isEmpty) {
        _showErrorSnackBar(AppConstants.msgNoValidStudentData);
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
        _showSuccessSnackBar('${AppConstants.msgValidationSuccessful}${result.successfulImports}${AppConstants.msgStudentsReadyForImport}');
      } else {
        _showErrorSnackBar('${AppConstants.msgValidationFailed}${result.failedImports}${AppConstants.msgStudentsHaveErrors}');
      }
      
    } catch (e) {
      _showErrorSnackBar('${AppConstants.msgErrorValidatingData}$e');
    } finally {
      setState(() => _isValidating = false);
    }
  }
  
  Future<void> _importData() async {
    if (_selectedFile == null) {
      _showErrorSnackBar(AppConstants.msgPleaseSelectExcelFile);
      return;
    }
    
    if (_validationResult == null || !_validationResult!.success) {
      _showErrorSnackBar(AppConstants.msgPleaseValidateFirst);
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
        _showSuccessSnackBar('${AppConstants.msgImportSuccessful}${result.successfulImports}${AppConstants.msgStudentsImported}');
        _showImportSummaryDialog(result);
      } else {
        _showErrorSnackBar('${AppConstants.msgImportCompletedWithErrors}${result.successfulImports}${AppConstants.msgSuccessful}${result.failedImports}${AppConstants.msgFailed}');
        _showImportSummaryDialog(result);
      }
      
    } catch (e) {
      _showErrorSnackBar('${AppConstants.msgErrorImportingData}$e');
    } finally {
      setState(() => _isImporting = false);
    }
  }
  
  void _showImportSummaryDialog(BulkImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppConstants.labelImportSummary),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${AppConstants.labelTotalRows}: ${result.totalRows}'),
              Text('${AppConstants.labelSuccessful}: ${result.successfulImports}'),
              Text('${AppConstants.labelFailed}: ${result.failedImports}'),
              const SizedBox(height: AppSizes.bulkImportSpacingMD),
              if (result.errors.isNotEmpty) ...[
                const Text('${AppConstants.labelError}:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSizes.bulkImportSpacingSM),
                ...result.errors.take(5).map((error) => Text('• $error')),
                if (result.errors.length > 5)
                  Text('${AppConstants.msgAndMoreErrors}${result.errors.length - 5}${AppConstants.msgMoreErrors}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppConstants.labelOk),
          ),
        ],
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.bulkImportErrorColor,
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.bulkImportSuccessColor,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.labelBulkImport),
        backgroundColor: AppColors.bulkImportPrimaryColor[700],
        foregroundColor: AppColors.bulkImportTextWhite,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.bulkImportPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // School Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.bulkImportPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              AppConstants.labelSchoolInformation,
                              style: TextStyle(fontSize: AppSizes.bulkImportHeaderFontSize, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: AppSizes.bulkImportSpacingSM),
                            Text('${AppConstants.labelSchool}: $_schoolName'),
                            Text('${AppConstants.labelSchoolID}: $_schoolId'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.bulkImportSpacingMD),
                    
                    // Configuration Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.bulkImportPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              AppConstants.labelImportConfiguration,
                              style: TextStyle(fontSize: AppSizes.bulkImportHeaderFontSize, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: AppSizes.bulkImportSpacingMD),
                            
                            // School Domain
                            TextFormField(
                              initialValue: _schoolDomain,
                              decoration: const InputDecoration(
                                labelText: AppConstants.labelSchoolEmailDomain,
                                hintText: AppConstants.hintSchoolDomain,
                                prefixText: AppConstants.hintEmailPrefix,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) => _schoolDomain = value,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (!value.contains('.')) {
                                    return AppConstants.validationInvalidDomain;
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSizes.bulkImportSpacingMD),
                            
                            // ✅ Email Strategy - Updated for mandatory emails
                            const Text(AppConstants.labelEmailStrategy, style: TextStyle(fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.all(AppSizes.bulkImportCardPadding),
                              decoration: BoxDecoration(
                                color: AppColors.bulkImportInfoColor[50],
                                border: Border.all(color: AppColors.bulkImportInfoColor),
                                borderRadius: BorderRadius.circular(AppSizes.bulkImportBorderRadius),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.info, color: AppColors.bulkImportInfoColor, size: AppSizes.bulkImportIconSize),
                                      SizedBox(width: AppSizes.bulkImportSpacingSM),
                                      Text(
                                        AppConstants.labelParentEmailRequired,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.bulkImportInfoColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSizes.bulkImportSpacingSM),
                                  const Text(
                                    AppConstants.infoAllParentEmailsRequired,
                                    style: TextStyle(
                                      fontSize: AppSizes.bulkImportInfoFontSize,
                                      color: AppColors.bulkImportInfoColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSizes.bulkImportSpacingMD),
                            
                            // Send Activation Emails
                            CheckboxListTile(
                              title: const Text(AppConstants.labelSendActivationEmails),
                              subtitle: const Text(AppConstants.infoSendActivationToParents),
                              value: _sendActivationEmails,
                              onChanged: (value) => setState(() => _sendActivationEmails = value!),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.bulkImportSpacingMD),
                    
                    // File Selection Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.bulkImportPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              AppConstants.labelExcelFile,
                              style: TextStyle(fontSize: AppSizes.bulkImportHeaderFontSize, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: AppSizes.bulkImportSpacingMD),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickExcelFile,
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text(AppConstants.labelSelectExcelFile),
                                  ),
                                ),
                                const SizedBox(width: AppSizes.bulkImportSpacingMD),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _downloadTemplate,
                                    icon: const Icon(Icons.download),
                                    label: const Text(AppConstants.labelDownloadTemplate),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.bulkImportSuccessColor,
                                      foregroundColor: AppColors.bulkImportTextWhite,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.bulkImportSpacingMD),
                            
                            if (_selectedFile != null) ...[
                              Container(
                                padding: const EdgeInsets.all(AppSizes.bulkImportCardPadding),
                                decoration: BoxDecoration(
                                  color: AppColors.bulkImportSuccessColor[50],
                                  border: Border.all(color: AppColors.bulkImportSuccessColor),
                                  borderRadius: BorderRadius.circular(AppSizes.bulkImportBorderRadius),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: AppColors.bulkImportSuccessColor),
                                    const SizedBox(width: AppSizes.bulkImportSpacingSM),
                                    Expanded(
                                      child: Text(
                                        '${AppConstants.labelSelected}: ${_selectedFile!.path.split('/').last}',
                                        style: const TextStyle(color: AppColors.bulkImportSuccessColor),
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
                    const SizedBox(height: AppSizes.bulkImportSpacingMD),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isValidating ? null : _validateData,
                            icon: _isValidating 
                                ? const SizedBox(
                                    width: AppSizes.bulkImportProgressSize,
                                    height: AppSizes.bulkImportProgressSize,
                                    child: CircularProgressIndicator(strokeWidth: AppSizes.bulkImportProgressStroke),
                                  )
                                : const Icon(Icons.check_circle),
                            label: Text(_isValidating ? AppConstants.labelValidating : AppConstants.labelValidateData),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.bulkImportWarningColor,
                              foregroundColor: AppColors.bulkImportTextWhite,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.bulkImportSpacingMD),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (_isImporting || _validationResult == null || !_validationResult!.success) 
                                ? null 
                                : _importData,
                            icon: _isImporting 
                                ? const SizedBox(
                                    width: AppSizes.bulkImportProgressSize,
                                    height: AppSizes.bulkImportProgressSize,
                                    child: CircularProgressIndicator(strokeWidth: AppSizes.bulkImportProgressStroke),
                                  )
                                : const Icon(Icons.upload),
                            label: Text(_isImporting ? AppConstants.labelImporting : AppConstants.labelImportStudents),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.bulkImportPrimaryColor,
                              foregroundColor: AppColors.bulkImportTextWhite,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.bulkImportSpacingMD),
                    
                    // Validation Results
                    if (_validationResult != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.bulkImportPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                AppConstants.labelValidationResults,
                                style: TextStyle(fontSize: AppSizes.bulkImportHeaderFontSize, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: AppSizes.bulkImportSpacingMD),
                              _buildResultSummary(_validationResult!),
                              if (_validationResult!.results.isNotEmpty) ...[
                                const SizedBox(height: AppSizes.bulkImportSpacingMD),
                                const Text('${AppConstants.labelDetails}:', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: AppSizes.bulkImportSpacingSM),
                                ..._validationResult!.results.take(10).map((result) => 
                                  _buildResultItem(result)
                                ),
                                if (_validationResult!.results.length > 10)
                                  Text('${AppConstants.msgAndMore}${_validationResult!.results.length - 10}${AppConstants.msgMore}'),
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
                          padding: const EdgeInsets.all(AppSizes.bulkImportPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                AppConstants.labelImportResults,
                                style: TextStyle(fontSize: AppSizes.bulkImportHeaderFontSize, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: AppSizes.bulkImportSpacingMD),
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
            AppConstants.labelTotal,
            result.totalRows.toString(),
            AppColors.bulkImportPrimaryColor,
          ),
        ),
        const SizedBox(width: AppSizes.bulkImportSpacingSM),
        Expanded(
          child: _buildSummaryCard(
            AppConstants.labelSuccess,
            result.successfulImports.toString(),
            AppColors.bulkImportSuccessColor,
          ),
        ),
        const SizedBox(width: AppSizes.bulkImportSpacingSM),
        Expanded(
          child: _buildSummaryCard(
            AppConstants.labelFailed,
            result.failedImports.toString(),
            AppColors.bulkImportErrorColor,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.bulkImportCardPadding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppSizes.bulkImportBgOpacity),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(AppSizes.bulkImportBorderRadius),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: AppSizes.bulkImportSummaryValueFontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: AppSizes.bulkImportSummaryTitleFontSize,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultItem(StudentImportResult result) {
    Color statusColor = result.status == 'SUCCESS' || result.status == 'VALID' 
        ? AppColors.bulkImportSuccessColor 
        : AppColors.bulkImportErrorColor;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.bulkImportSpacingSM),
      padding: const EdgeInsets.all(AppSizes.bulkImportResultPadding),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: AppSizes.bulkImportBgOpacity),
        border: Border.all(color: statusColor),
        borderRadius: BorderRadius.circular(AppSizes.bulkImportBorderRadius),
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
                size: AppSizes.bulkImportIconSizeSM,
              ),
              const SizedBox(width: AppSizes.bulkImportSpacingSM),
              Expanded(
                child: Text(
                  '${AppConstants.labelRow} ${result.rowNumber}: ${result.studentName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (result.parentEmail != null) ...[
            const SizedBox(height: AppSizes.bulkImportSpacingXS),
            Text(
              '${AppConstants.labelEmail}: ${result.parentEmail}',
              style: const TextStyle(fontSize: AppSizes.bulkImportInfoFontSize, color: AppColors.textSecondary),
            ),
          ],
          if (result.errorMessage != null) ...[
            const SizedBox(height: AppSizes.bulkImportSpacingXS),
            Text(
              '${AppConstants.labelError}: ${result.errorMessage}',
              style: const TextStyle(fontSize: AppSizes.bulkImportInfoFontSize, color: AppColors.bulkImportErrorColor),
            ),
          ],
        ],
      ),
    );
  }
}

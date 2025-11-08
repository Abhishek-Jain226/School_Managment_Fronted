import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Conditional imports for web vs non-web
// Import dart:io on non-web, stub on web
import 'dart:io' if (dart.library.html) 'stub_io.dart' as io;
// Import dart:html on web, stub on non-web
import 'dart:html' if (dart.library.io) 'stub_html.dart' as html;
import '../../utils/constants.dart';
import '../../data/models/bulk_student_import_request.dart';
import '../../data/models/bulk_import_result.dart';
import '../../services/bulk_student_import_service.dart';
import '../../services/excel_parser_service.dart';
import '../../services/school_service.dart';

class BulkStudentImportPage extends StatefulWidget {
  const BulkStudentImportPage({Key? key}) : super(key: key);

  @override
  State<BulkStudentImportPage> createState() => _BulkStudentImportPageState();
}

class _BulkStudentImportPageState extends State<BulkStudentImportPage> {
  final _formKey = GlobalKey<FormState>();
  final _bulkImportService = BulkStudentImportService();
  final _excelParserService = ExcelParserService();
  final _schoolService = SchoolService();
  
  dynamic _selectedFile; // FilePickerResult on web, File path (String) or File object on mobile/desktop
  String? _selectedFilePath; // Store file path separately for non-web platforms
  bool _isLoading = false;
  bool _isValidating = false;
  bool _isImporting = false;
  BulkImportResult? _validationResult;
  BulkImportResult? _importResult;
  List<String> _parsingErrors = []; // Store parsing errors (e.g., date format errors)
  
  // Configuration
  String _schoolDomain = '';
  bool _sendActivationEmails = true;
  final String _emailStrategy = 'AUTO_GENERATE';
  
  // School info
  int? _schoolId;
  String? _schoolName;
  
  // Classes and Sections (for dynamic mapping)
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _sections = [];
  bool _isLoadingClassesSections = false;
  
  @override
  void initState() {
    super.initState();
    _loadSchoolInfo();
  }
  
  Future<void> _loadSchoolInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final schoolId = prefs.getInt('schoolId');
    final schoolName = prefs.getString('schoolName');
    
    setState(() {
      _schoolId = schoolId;
      _schoolName = schoolName;
    });
    
    // Fetch classes and sections for the school
    if (schoolId != null) {
      await _loadClassesAndSections(schoolId);
    }
  }
  
  Future<void> _loadClassesAndSections(int schoolId) async {
    setState(() {
      _isLoadingClassesSections = true;
    });
    
    try {
      // Fetch classes
      final classesResponse = await _schoolService.getSchoolClasses(schoolId);
      if (classesResponse[AppConstants.keySuccess] == true && 
          classesResponse[AppConstants.keyData] != null) {
        final classesList = classesResponse[AppConstants.keyData] as List<dynamic>;
        setState(() {
          _classes = classesList.cast<Map<String, dynamic>>();
        });
        debugPrint('✅ Loaded ${_classes.length} classes');
      } else {
        debugPrint('⚠️ Failed to load classes: ${classesResponse[AppConstants.keyMessage]}');
      }
      
      // Fetch sections
      final sectionsResponse = await _schoolService.getSchoolSections(schoolId);
      if (sectionsResponse[AppConstants.keySuccess] == true && 
          sectionsResponse[AppConstants.keyData] != null) {
        final sectionsList = sectionsResponse[AppConstants.keyData] as List<dynamic>;
        setState(() {
          _sections = sectionsList.cast<Map<String, dynamic>>();
        });
        debugPrint('✅ Loaded ${_sections.length} sections');
      } else {
        debugPrint('⚠️ Failed to load sections: ${sectionsResponse[AppConstants.keyMessage]}');
      }
    } catch (e) {
      debugPrint('❌ Error loading classes/sections: $e');
      // Show error but don't block the page
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Failed to load classes/sections. Please ensure they are configured. Error: $e'),
            backgroundColor: AppColors.bulkImportWarningColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingClassesSections = false;
      });
    }
  }
  
  Future<void> _pickExcelFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );
      
      if (result != null) {
        setState(() {
          if (kIsWeb) {
            // On web, store the FilePickerResult
            _selectedFile = result;
            _selectedFilePath = null;
          } else {
            // On mobile/desktop, store the file path
            if (result.files.single.path != null) {
              _selectedFilePath = result.files.single.path!;
              _selectedFile = result.files.single.path; // Store path for display
            } else {
              _selectedFile = null;
              _selectedFilePath = null;
            }
          }
          _validationResult = null;
          _importResult = null;
          _parsingErrors = []; // Clear parsing errors when new file is selected
        });
      }
    } catch (e) {
      _showErrorSnackBar('${AppConstants.msgErrorPickingFile}$e');
    }
  }
  
  Future<void> _downloadTemplate() async {
    try {
      setState(() => _isLoading = true);
      
      final templateBytes = await _excelParserService.generateExcelTemplate(
        classes: _classes,
        sections: _sections,
      );
      
      if (kIsWeb) {
        // For web: Use dart:html to trigger browser download
        _downloadFileWeb(templateBytes, AppConstants.fileNameStudentTemplate);
        _showSuccessSnackBar('Template download started');
      } else {
        // For mobile/desktop: Use file_picker's saveFile method
        const fileName = AppConstants.fileNameStudentTemplate;
        final result = await FilePicker.platform.saveFile(
          fileName: fileName,
          bytes: templateBytes,
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );
        
        if (result != null) {
          _showSuccessSnackBar('${AppConstants.msgTemplateDownloaded}$result');
        } else {
          // User cancelled, don't show error
          debugPrint('Template download cancelled by user');
        }
      }
    } catch (e) {
      _showErrorSnackBar('${AppConstants.msgErrorDownloadingTemplate}$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  /// Download file on web platform using dart:html
  void _downloadFileWeb(Uint8List bytes, String fileName) {
    if (kIsWeb) {
      // Use dart:html for web download (html is dart:html on web)
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }
  
  /// Get file name for display
  String _getFileName() {
    if (_selectedFile == null) return '';
    if (kIsWeb) {
      final result = _selectedFile as FilePickerResult;
      return result.files.single.name;
    } else {
      // On non-web, _selectedFile is a file path (String)
      if (_selectedFile is String) {
        return (_selectedFile as String).split('/').last.split('\\').last;
      }
      return '';
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
      
      // Get file bytes - handle both web (FilePickerResult) and mobile/desktop (File)
      Uint8List fileBytes;
      if (kIsWeb) {
        // On web, read bytes from FilePickerResult
        final result = _selectedFile as FilePickerResult;
        fileBytes = result.files.single.bytes!;
      } else {
        // On mobile/desktop, read bytes from File using stored path
        if (_selectedFilePath != null) {
          final file = io.File(_selectedFilePath!);
          fileBytes = await file.readAsBytes();
        } else {
          throw Exception('Invalid file path on mobile/desktop');
        }
      }
      
      // Parse Excel file with classes and sections for dynamic mapping
      final parseResult = await _excelParserService.parseStudentExcelFromBytes(
        fileBytes,
        classes: _classes,
        sections: _sections,
      );
      
      final students = parseResult['students'] as List<StudentRequest>;
      final parsingErrors = parseResult['errors'] as List<String>;
      
      // Store parsing errors for display
      setState(() {
        _parsingErrors = parsingErrors;
      });
      
      // Show parsing errors if any (e.g., date format errors)
      if (parsingErrors.isNotEmpty && mounted) {
        final errorMessage = 'Found ${parsingErrors.length} parsing error(s). Please check the details below.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.bulkImportWarningColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
      if (students.isEmpty) {
        if (parsingErrors.isNotEmpty) {
          _showErrorSnackBar('${AppConstants.msgNoValidStudentData} Parsing errors: ${parsingErrors.join("; ")}');
        } else {
          _showErrorSnackBar(AppConstants.msgNoValidStudentData);
        }
        return;
      }
      
      // Get actual admin username for createdBy
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString(AppConstants.keyUserName) ?? 'SchoolAdmin';
      
      // Create validation request
      final request = BulkStudentImportRequest(
        students: students,
        schoolId: _schoolId!,
        createdBy: userName, // ✅ Use actual admin username (same as normal registration)
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
      
      // Get file bytes - handle both web (FilePickerResult) and mobile/desktop (File)
      Uint8List fileBytes;
      if (kIsWeb) {
        // On web, read bytes from FilePickerResult
        final result = _selectedFile as FilePickerResult;
        fileBytes = result.files.single.bytes!;
      } else {
        // On mobile/desktop, read bytes from File using stored path
        if (_selectedFilePath != null) {
          final file = io.File(_selectedFilePath!);
          fileBytes = await file.readAsBytes();
        } else {
          throw Exception('Invalid file path on mobile/desktop');
        }
      }
      
      // Parse Excel file with classes and sections for dynamic mapping
      final parseResult = await _excelParserService.parseStudentExcelFromBytes(
        fileBytes,
        classes: _classes,
        sections: _sections,
      );
      
      final students = parseResult['students'] as List<StudentRequest>;
      final parsingErrors = parseResult['errors'] as List<String>;
      
      // Show parsing errors if any (e.g., date format errors)
      if (parsingErrors.isNotEmpty && mounted) {
        final errorMessage = 'Found ${parsingErrors.length} parsing error(s) before import.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.bulkImportWarningColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
      // Get actual admin username for createdBy
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString(AppConstants.keyUserName) ?? 'SchoolAdmin';
      
      // Create import request
      final request = BulkStudentImportRequest(
        students: students,
        schoolId: _schoolId!,
        createdBy: userName, // ✅ Use actual admin username (same as normal registration)
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
      body: (_isLoading || _isLoadingClassesSections)
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
                                        '${AppConstants.labelSelected}: ${_getFileName()}',
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
                    
                    // Parsing Errors (e.g., date format errors)
                    if (_parsingErrors.isNotEmpty) ...[
                      Card(
                        color: AppColors.bulkImportWarningColor[50],
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.bulkImportPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning, color: AppColors.bulkImportWarningColor),
                                  const SizedBox(width: AppSizes.bulkImportSpacingSM),
                                  const Text(
                                    'Parsing Errors (Date Format, etc.)',
                                    style: TextStyle(
                                      fontSize: AppSizes.bulkImportHeaderFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.bulkImportWarningColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.bulkImportSpacingMD),
                              ..._parsingErrors.take(10).map((error) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSizes.bulkImportSpacingSM),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: AppColors.bulkImportErrorColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: AppSizes.bulkImportSpacingSM),
                                    Expanded(
                                      child: Text(
                                        error,
                                        style: const TextStyle(
                                          fontSize: AppSizes.bulkImportInfoFontSize,
                                          color: AppColors.bulkImportErrorColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                              if (_parsingErrors.length > 10)
                                Text(
                                  '${AppConstants.msgAndMore}${_parsingErrors.length - 10}${AppConstants.msgMore} parsing errors',
                                  style: const TextStyle(
                                    fontSize: AppSizes.bulkImportInfoFontSize,
                                    color: AppColors.bulkImportWarningColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.bulkImportSpacingMD),
                    ],
                    
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

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/app_admin_service.dart';
import '../../utils/constants.dart';

class AppAdminSchoolManagementPage extends StatefulWidget {
  const AppAdminSchoolManagementPage({super.key});

  @override
  State<AppAdminSchoolManagementPage> createState() => _AppAdminSchoolManagementPageState();
}

class _AppAdminSchoolManagementPageState extends State<AppAdminSchoolManagementPage> {
  List<dynamic> schools = [];
  Map<String, dynamic> statistics = {};
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      // Load schools and statistics in parallel
      final schoolsResponse = await AppAdminService.getAllSchools();
      final statsResponse = await AppAdminService.getSchoolStatistics();
      
      if (schoolsResponse[AppConstants.keySuccess] == true) {
        setState(() {
          schools = List<dynamic>.from(
            schoolsResponse[AppConstants.keyData][AppConstants.keySchools] ?? [],
          );
        });
      }
      
      if (statsResponse[AppConstants.keySuccess] == true) {
        setState(() {
          statistics = statsResponse[AppConstants.keyData] ?? {};
        });
      }
    } catch (e) {
      _showSnackBar(
        '${AppConstants.msgErrorLoadingData}$e',
        AppColors.schoolMgmtErrorColor,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _searchSchools() async {
    if (_searchController.text.trim().isEmpty) {
      _loadData();
      return;
    }

    setState(() => isLoading = true);
    
    try {
      final response = await AppAdminService.searchSchools(_searchController.text.trim());
      
      if (response[AppConstants.keySuccess] == true) {
        setState(() {
          schools = List<dynamic>.from(
            response[AppConstants.keyData][AppConstants.keySchools] ?? [],
          );
          searchQuery = _searchController.text.trim();
        });
      } else {
        _showSnackBar(
          response[AppConstants.keyMessage] ?? AppConstants.msgSearchFailed,
          AppColors.schoolMgmtErrorColor,
        );
      }
    } catch (e) {
      _showSnackBar(
        '${AppConstants.msgErrorSearchingSchools}$e',
        AppColors.schoolMgmtErrorColor,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateSchoolStatus(int schoolId, bool isActive, String schoolName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedBy = prefs.getString(AppConstants.keyUserName) ?? 
          AppConstants.defaultAppAdminName;
      
      final response = await AppAdminService.updateSchoolStatus(
        schoolId,
        isActive,
        updatedBy,
      );
      
      if (response[AppConstants.keySuccess] == true) {
        _showSnackBar(
          response[AppConstants.keyMessage] ?? 
              AppConstants.msgStatusUpdatedSuccessfully,
          AppColors.schoolMgmtSuccessColor,
        );
        _loadData(); // Refresh data
      } else {
        _showSnackBar(
          response[AppConstants.keyMessage] ?? 
              AppConstants.msgFailedToUpdateStatus,
          AppColors.schoolMgmtErrorColor,
        );
      }
    } catch (e) {
      _showSnackBar(
        '${AppConstants.msgErrorUpdatingStatus}$e',
        AppColors.schoolMgmtErrorColor,
      );
    }
  }

  Future<void> _updateSchoolDates(int schoolId, String? startDate, String? endDate, String schoolName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedBy = prefs.getString(AppConstants.keyUserName) ?? 
          AppConstants.defaultAppAdminName;
      
      final response = await AppAdminService.updateSchoolDates(
        schoolId,
        startDate,
        endDate,
        updatedBy,
      );
      
      if (response[AppConstants.keySuccess] == true) {
        _showSnackBar(
          response[AppConstants.keyMessage] ?? 
              AppConstants.msgDatesUpdatedSuccessfully,
          AppColors.schoolMgmtSuccessColor,
        );
        _loadData(); // Refresh data
      } else {
        _showSnackBar(
          response[AppConstants.keyMessage] ?? 
              AppConstants.msgFailedToUpdateDates,
          AppColors.schoolMgmtErrorColor,
        );
      }
    } catch (e) {
      _showSnackBar(
        '${AppConstants.msgErrorUpdatingDates}$e',
        AppColors.schoolMgmtErrorColor,
      );
    }
  }


  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  void _showDatePickerDialog(int schoolId, String schoolName, String? currentStartDate, String? currentEndDate) {
    DateTime? startDate;
    DateTime? endDate;
    
    // Parse current dates if they exist
    if (currentStartDate != null) {
      startDate = DateTime.tryParse(currentStartDate);
    }
    if (currentEndDate != null) {
      endDate = DateTime.tryParse(currentEndDate);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${AppConstants.labelUpdateDatesFor} $schoolName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text(AppConstants.labelStartDate),
                subtitle: Text(
                  startDate != null 
                      ? '${startDate!.day}/${startDate!.month}/${startDate!.year}' 
                      : AppConstants.labelNotSet,
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now(),
                    firstDate: DateTime(AppConstants.defaultDatePickerFirstYear),
                    lastDate: DateTime(AppConstants.defaultDatePickerLastYear),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      startDate = picked;
                    });
                  }
                },
              ),
              ListTile(
                title: const Text(AppConstants.labelEndDate),
                subtitle: Text(
                  endDate != null 
                      ? '${endDate!.day}/${endDate!.month}/${endDate!.year}' 
                      : AppConstants.labelNotSet,
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? DateTime.now(),
                    firstDate: startDate ?? DateTime(AppConstants.defaultDatePickerFirstYear),
                    lastDate: DateTime(AppConstants.defaultDatePickerLastYear),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      endDate = picked;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppConstants.labelCancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                final startDateStr = startDate != null 
                    ? startDate!.toIso8601String().split('T')[0] 
                    : null;
                final endDateStr = endDate != null 
                    ? endDate!.toIso8601String().split('T')[0] 
                    : null;
                _updateSchoolDates(schoolId, startDateStr, endDateStr, schoolName);
              },
              child: const Text(AppConstants.labelUpdate),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.labelSchoolManagement),
        backgroundColor: AppColors.schoolMgmtAppBarColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistics Cards
                if (statistics.isNotEmpty) _buildStatisticsCards(),
                
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(AppSizes.schoolMgmtPadding),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: AppConstants.hintSearchSchools,
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _searchSchools(),
                        ),
                      ),
                      const SizedBox(width: AppSizes.schoolMgmtSpacingSM),
                      ElevatedButton(
                        onPressed: _searchSchools,
                        child: const Text(AppConstants.labelSearch),
                      ),
                      if (searchQuery.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _loadData();
                            setState(() => searchQuery = '');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                    ],
                  ),
                ),
                
                // Schools List
                Expanded(
                  child: schools.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school,
                                size: AppSizes.schoolMgmtEmptyIconSize,
                                color: AppColors.schoolMgmtAppBarColor.shade400,
                              ),
                              const SizedBox(height: AppSizes.schoolMgmtPadding),
                              Text(
                                searchQuery.isNotEmpty
                                    ? '${AppConstants.msgNoSchoolsFoundFor} "$searchQuery"'
                                    : AppConstants.msgNoSchoolsFound,
                                style: TextStyle(
                                  fontSize: AppSizes.schoolMgmtEmptyTextFontSize,
                                  color: AppColors.schoolMgmtAppBarColor.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: schools.length,
                          itemBuilder: (context, index) {
                            final school = schools[index];
                            return _buildSchoolCard(school);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatisticsCards() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.schoolMgmtPadding),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              AppConstants.labelTotalSchools,
              '${statistics[AppConstants.keyTotalSchools] ?? 0}',
              Icons.school,
              AppColors.schoolMgmtPrimaryColor,
            ),
          ),
          const SizedBox(width: AppSizes.schoolMgmtSpacingSM),
          Expanded(
            child: _buildStatCard(
              AppConstants.labelActive,
              '${statistics[AppConstants.keyActiveSchools] ?? 0}',
              Icons.check_circle,
              AppColors.schoolMgmtSuccessColor,
            ),
          ),
          const SizedBox(width: AppSizes.schoolMgmtSpacingSM),
          Expanded(
            child: _buildStatCard(
              AppConstants.labelInactive,
              '${statistics[AppConstants.keyInactiveSchools] ?? 0}',
              Icons.cancel,
              AppColors.schoolMgmtErrorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: AppSizes.schoolMgmtCardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.schoolMgmtPadding),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: AppSizes.schoolMgmtStatIconSize,
            ),
            const SizedBox(height: AppSizes.schoolMgmtSpacingSM),
            Text(
              value,
              style: TextStyle(
                fontSize: AppSizes.schoolMgmtStatValueFontSize,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppSizes.schoolMgmtStatTitleFontSize,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolCard(Map<String, dynamic> school) {
    final isActive = school[AppConstants.keyIsActive] == true;
    final startDate = school[AppConstants.keyStartDate];
    final endDate = school[AppConstants.keyEndDate];
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.schoolMgmtCardMarginH,
        vertical: AppSizes.schoolMgmtCardMarginV,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.schoolMgmtPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        school[AppConstants.keySchoolName] ?? 
                            AppConstants.defaultUnknownSchool,
                        style: const TextStyle(
                          fontSize: AppSizes.schoolMgmtSchoolNameFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSizes.schoolMgmtSpacingXS),
                      Text(
                        '${school[AppConstants.keyCity] ?? ''}, ${school[AppConstants.keyState] ?? ''}',
                        style: TextStyle(
                          color: AppColors.schoolMgmtAppBarColor.shade600,
                          fontSize: AppSizes.schoolMgmtSchoolLocationFontSize,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.schoolMgmtStatusPaddingH,
                    vertical: AppSizes.schoolMgmtStatusPaddingV,
                  ),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? AppColors.schoolMgmtSuccessColor 
                        : AppColors.schoolMgmtErrorColor,
                    borderRadius: BorderRadius.circular(
                      AppSizes.schoolMgmtStatusRadius,
                    ),
                  ),
                  child: Text(
                    isActive 
                        ? AppConstants.labelActive 
                        : AppConstants.labelInactive,
                    style: const TextStyle(
                      color: AppColors.schoolMgmtTextWhite,
                      fontSize: AppSizes.schoolMgmtStatusFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSizes.schoolMgmtSpacingMD),
            
            // Date Information
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: AppSizes.schoolMgmtDateIconSize,
                  color: AppColors.schoolMgmtAppBarColor.shade600,
                ),
                const SizedBox(width: AppSizes.schoolMgmtSpacingSM),
                Expanded(
                  child: Text(
                    startDate != null && endDate != null
                        ? '${AppConstants.labelSession} ${_formatDate(startDate)} to ${_formatDate(endDate)}'
                        : startDate != null
                            ? '${AppConstants.labelStarts} ${_formatDate(startDate)}'
                            : endDate != null
                                ? '${AppConstants.labelEnds} ${_formatDate(endDate)}'
                                : AppConstants.labelNoDatesSet,
                    style: TextStyle(
                      color: AppColors.schoolMgmtAppBarColor.shade600,
                      fontSize: AppSizes.schoolMgmtSchoolLocationFontSize,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSizes.schoolMgmtSpacingMD),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateSchoolStatus(
                      school[AppConstants.keySchoolId],
                      !isActive,
                      school[AppConstants.keySchoolName] ?? 
                          AppConstants.defaultSchoolName,
                    ),
                    icon: Icon(isActive ? Icons.pause : Icons.play_arrow),
                    label: Text(
                      isActive 
                          ? AppConstants.labelDeactivate 
                          : AppConstants.labelActivate,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive 
                          ? AppColors.schoolMgmtWarningColor 
                          : AppColors.schoolMgmtSuccessColor,
                      foregroundColor: AppColors.schoolMgmtTextWhite,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.schoolMgmtSpacingSM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDatePickerDialog(
                      school[AppConstants.keySchoolId],
                      school[AppConstants.keySchoolName] ?? 
                          AppConstants.defaultSchoolName,
                      startDate,
                      endDate,
                    ),
                    icon: const Icon(Icons.edit_calendar),
                    label: const Text(AppConstants.labelSetDates),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.schoolMgmtPrimaryColor,
                      foregroundColor: AppColors.schoolMgmtTextWhite,
                    ),
                  ),
                ),
              ],
            ),
            
            // Resend Activation Link Button (only for schools without active users)
            if (school[AppConstants.keyHasActiveUser] != true) ...[
              const SizedBox(height: AppSizes.schoolMgmtSpacingSM),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _resendActivationLink(
                    school[AppConstants.keySchoolId],
                    school[AppConstants.keySchoolName] ?? 
                        AppConstants.defaultSchoolName,
                  ),
                  icon: const Icon(Icons.email),
                  label: const Text(AppConstants.labelResendActivationLink),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.schoolMgmtAccentColor,
                    foregroundColor: AppColors.schoolMgmtTextWhite,
                  ),
                ),
              ),
            ],
            
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _resendActivationLink(int schoolId, String schoolName) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppConstants.labelResendActivationLink),
        content: Text(
          '${AppConstants.msgConfirmResendActivationLink} $schoolName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppConstants.labelCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppConstants.labelResend),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Store context for later use to avoid async gaps
    if (!mounted) return;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: AppSizes.schoolMgmtPadding),
            Text(AppConstants.msgSendingActivationLink),
          ],
        ),
      ),
    );

    try {
      // Get current user info for updatedBy parameter
      final prefs = await SharedPreferences.getInstance();
      final currentUser = prefs.getString(AppConstants.keyUserName) ?? 
          AppConstants.defaultAppAdminName;

      final response = await AppAdminService.resendActivationLink(
        schoolId,
        currentUser,
      );

      // Close loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      if (response[AppConstants.keySuccess] == true) {
        _showSnackBar(
          response[AppConstants.keyMessage] ?? 
              AppConstants.msgActivationLinkSentSuccessfully,
          AppColors.schoolMgmtSuccessColor,
        );
      } else {
        _showSnackBar(
          response[AppConstants.keyMessage] ?? 
              AppConstants.msgFailedToSendActivationLink,
          AppColors.schoolMgmtErrorColor,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();
      _showSnackBar(
        '${AppConstants.msgErrorSendingActivationLink}$e',
        AppColors.schoolMgmtErrorColor,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

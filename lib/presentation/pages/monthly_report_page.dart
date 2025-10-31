import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/parent_service.dart';
import '../../data/models/monthly_report.dart';
import '../../utils/constants.dart';

class MonthlyReportPage extends StatefulWidget {
  const MonthlyReportPage({super.key});

  @override
  State<MonthlyReportPage> createState() => _MonthlyReportPageState();
}

class _MonthlyReportPageState extends State<MonthlyReportPage> {
  final ParentService _parentService = ParentService();
  
  int? _userId;
  bool _isLoading = true;
  MonthlyReport? _monthlyReport;
  String _error = '';
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt(AppConstants.keyUserId);
    });
    
    if (_userId != null) {
      _loadMonthlyReport();
    } else {
      setState(() {
        _error = AppConstants.msgUserIdNotFoundLogin;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMonthlyReport() async {
    if (_userId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final report = await _parentService.getMonthlyReport(
        _userId!, 
        year: _selectedYear, 
        month: _selectedMonth
      );
      
      setState(() {
        _monthlyReport = report;
        _error = '';
      });
    } catch (e) {
      debugPrint('🔍 Error loading monthly report: $e');
      setState(() {
        _error = '${AppConstants.msgErrorLoadingReport}$e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMonthYearPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(AppConstants.labelSelectMonthYear),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Year Picker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(AppConstants.labelYear),
                  DropdownButton<int>(
                    value: _selectedYear,
                    items: List.generate(AppSizes.monthlyReportYearRange, (index) {
                      final year = DateTime.now().year - index;
                      return DropdownMenuItem(value: year, child: Text(year.toString()));
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedYear = value);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.monthlyReportSpacingLG),
              // Month Picker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(AppConstants.labelMonth),
                  DropdownButton<int>(
                    value: _selectedMonth,
                    items: List.generate(AppSizes.monthlyReportMonthCount, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text(AppConstants.monthNames[index]),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedMonth = value);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppConstants.actionCancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadMonthlyReport();
              },
              child: const Text(AppConstants.labelLoadReport),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.assessment, size: AppSizes.monthlyReportIconSize),
            SizedBox(width: AppSizes.monthlyReportIconSpacing),
            Text(AppConstants.labelMonthlyReport),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _showMonthYearPicker,
            tooltip: AppConstants.labelSelectMonthYear,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMonthlyReport,
            tooltip: AppConstants.labelRefresh,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error, style: const TextStyle(color: AppColors.errorColor, fontSize: AppSizes.monthlyReportErrorFontSize)),
                      const SizedBox(height: AppSizes.monthlyReportErrorSpacing),
                      ElevatedButton(
                        onPressed: _loadMonthlyReport,
                        child: const Text(AppConstants.labelRetry),
                      ),
                    ],
                  ),
                )
              : _monthlyReport == null
                  ? const Center(child: Text(AppConstants.labelNoReportData))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSizes.monthlyReportPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Report Header
                          Card(
                            elevation: AppSizes.monthlyReportCardElevation,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSizes.monthlyReportPadding),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${AppConstants.monthNames[_selectedMonth - 1]} $_selectedYear${AppConstants.labelReportSuffix}',
                                    style: const TextStyle(fontSize: AppSizes.monthlyReportHeaderFontSize, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: AppSizes.monthlyReportSpacing),
                                  Text('${AppConstants.labelStudent}${AppConstants.labelColon} ${_monthlyReport!.studentName}'),
                                  Text('${AppConstants.labelClass}${AppConstants.labelColon} ${_monthlyReport!.className} - ${_monthlyReport!.sectionName}'),
                                  Text('${AppConstants.labelSchool}${AppConstants.labelColon} ${_monthlyReport!.schoolName}'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSizes.monthlyReportSpacingLG),
                          
                          // Attendance Summary
                          const Text(
                            AppConstants.labelAttendanceSummary,
                            style: TextStyle(fontSize: AppSizes.monthlyReportSectionFontSize, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: AppSizes.monthlyReportSpacing),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  AppConstants.labelSchoolDays,
                                  _monthlyReport!.totalSchoolDays.toString(),
                                  AppColors.primaryColor,
                                  Icons.school,
                                ),
                              ),
                              const SizedBox(width: AppSizes.monthlyReportSpacing),
                              Expanded(
                                child: _buildStatCard(
                                  AppConstants.labelPresent,
                                  _monthlyReport!.presentDays.toString(),
                                  AppColors.statusSuccess,
                                  Icons.check_circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.monthlyReportSpacing),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  AppConstants.labelAbsent,
                                  _monthlyReport!.absentDays.toString(),
                                  AppColors.errorColor,
                                  Icons.cancel,
                                ),
                              ),
                              const SizedBox(width: AppSizes.monthlyReportSpacing),
                              Expanded(
                                child: _buildStatCard(
                                  AppConstants.labelLate,
                                  _monthlyReport!.lateDays.toString(),
                                  AppColors.statusWarning,
                                  Icons.schedule,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.monthlyReportSpacingLG),
                          
                          // Attendance Percentage
                          Card(
                            elevation: AppSizes.monthlyReportCardElevation,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSizes.monthlyReportPadding),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    AppConstants.labelAttendancePercentage,
                                    style: TextStyle(fontSize: AppSizes.monthlyReportSectionFontSize, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "${_monthlyReport!.attendancePercentage.toStringAsFixed(1)}%",
                                    style: TextStyle(
                                      fontSize: AppSizes.monthlyReportPercentFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: _getAttendanceColor(_monthlyReport!.attendancePercentage),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSizes.monthlyReportSpacingLG),
                          
                          // Trip Summary
                          const Text(
                            AppConstants.labelTripSummary,
                            style: TextStyle(fontSize: AppSizes.monthlyReportSectionFontSize, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: AppSizes.monthlyReportSpacing),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  AppConstants.labelTotalTrips,
                                  _monthlyReport!.totalTrips.toString(),
                                  AppColors.accentColor,
                                  Icons.directions_bus,
                                ),
                              ),
                              const SizedBox(width: AppSizes.monthlyReportSpacing),
                              Expanded(
                                child: _buildStatCard(
                                  AppConstants.labelCompleted,
                                  _monthlyReport!.completedTrips.toString(),
                                  AppColors.statusSuccess,
                                  Icons.check_circle_outline,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.monthlyReportSpacing),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  AppConstants.labelMissed,
                                  _monthlyReport!.missedTrips.toString(),
                                  AppColors.errorColor,
                                  Icons.cancel_outlined,
                                ),
                              ),
                              const SizedBox(width: AppSizes.monthlyReportSpacing),
                              Expanded(
                                child: _buildStatCard(
                                  AppConstants.labelCompletionRate,
                                  "${_monthlyReport!.tripCompletionRate.toStringAsFixed(1)}%",
                                  AppColors.primaryColor,
                                  Icons.trending_up,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.monthlyReportSpacingLG),
                          
                          // Performance Chart (Simple)
                          Card(
                            elevation: AppSizes.monthlyReportCardElevation,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSizes.monthlyReportPadding),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    AppConstants.labelPerformanceOverview,
                                    style: TextStyle(fontSize: AppSizes.monthlyReportSectionFontSize, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: AppSizes.monthlyReportSpacingLG),
                                  _buildProgressBar(
                                    AppConstants.labelAttendance,
                                    _monthlyReport!.attendancePercentage,
                                    AppColors.primaryColor,
                                  ),
                                  const SizedBox(height: AppSizes.monthlyReportProgressSpacingLG),
                                  _buildProgressBar(
                                    AppConstants.labelTripCompletion,
                                    _monthlyReport!.tripCompletionRate,
                                    AppColors.statusSuccess,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: AppSizes.monthlyReportStatCardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.monthlyReportStatCardPadding),
        child: Column(
          children: [
            Icon(icon, color: color, size: AppSizes.monthlyReportStatIconSize),
            const SizedBox(height: AppSizes.monthlyReportStatSpacing),
            Text(
              value,
              style: TextStyle(fontSize: AppSizes.monthlyReportStatValueFontSize, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: AppSizes.monthlyReportStatLabelFontSize, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${percentage.toStringAsFixed(1)}%'),
          ],
        ),
        const SizedBox(height: AppSizes.monthlyReportProgressSpacing),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: color.withValues(alpha: AppSizes.monthlyReportPercentOpacity),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= AppSizes.monthlyReportAttendanceGood) return AppColors.statusSuccess;
    if (percentage >= AppSizes.monthlyReportAttendanceFair) return AppColors.statusWarning;
    return AppColors.errorColor;
  }
}

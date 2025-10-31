import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/parent_service.dart';
import '../../data/models/attendance_history.dart';
import '../../utils/constants.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  final ParentService _parentService = ParentService();
  
  int? _userId;
  bool _isLoading = true;
  AttendanceHistory? _attendanceHistory;
  String _error = '';
  DateTime _fromDate = DateTime.now().subtract(
    const Duration(days: AppConstants.attendanceDefaultDaysBack),
  );
  DateTime _toDate = DateTime.now();

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
      _loadAttendanceHistory();
    } else {
      setState(() {
        _error = AppConstants.msgUserIdNotFound;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAttendanceHistory() async {
    if (_userId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final fromDateStr = _fromDate.toIso8601String().split('T')[0];
      final toDateStr = _toDate.toIso8601String().split('T')[0];
      
      final history = await _parentService.getAttendanceHistory(
        _userId!, 
        fromDate: fromDateStr, 
        toDate: toDateStr
      );
      
      setState(() {
        _attendanceHistory = history;
        _error = '';
      });
    } catch (e) {
      debugPrint('🔍 ${AppConstants.msgErrorLoadingAttendanceHistory}$e');
      setState(() {
        _error = '${AppConstants.msgErrorLoadingAttendanceHistory}$e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(AppConstants.attendanceDatePickerFirstYear),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
    );
    
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _loadAttendanceHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.history, size: AppSizes.attendanceIconSize),
            SizedBox(width: AppSizes.attendanceSpacingSM),
            Text(AppConstants.labelAttendanceHistory),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: AppConstants.tooltipSelectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAttendanceHistory,
            tooltip: AppConstants.tooltipRefresh,
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
                      Text(
                        _error,
                        style: const TextStyle(
                          color: AppColors.attendanceErrorColor,
                          fontSize: AppSizes.attendanceErrorFontSize,
                        ),
                      ),
                      const SizedBox(height: AppSizes.attendanceSpacingXXS),
                      ElevatedButton(
                        onPressed: _loadAttendanceHistory,
                        child: const Text(AppConstants.labelRetry),
                      ),
                    ],
                  ),
                )
              : _attendanceHistory == null
                  ? const Center(
                      child: Text(AppConstants.msgNoAttendanceData),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSizes.attendanceSpacingMD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary Cards
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  AppConstants.labelTotalDays,
                                  _attendanceHistory!.totalDays.toString(),
                                  AppColors.attendancePrimaryColor,
                                  Icons.calendar_today,
                                ),
                              ),
                              const SizedBox(width: AppSizes.attendanceSpacingSM),
                              Expanded(
                                child: _buildStatCard(
                                  AppConstants.labelPresent,
                                  _attendanceHistory!.presentDays.toString(),
                                  AppColors.attendancePresentColor,
                                  Icons.check_circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.attendanceSpacingSM),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  AppConstants.labelAbsent,
                                  _attendanceHistory!.absentDays.toString(),
                                  AppColors.attendanceAbsentColor,
                                  Icons.cancel,
                                ),
                              ),
                              const SizedBox(width: AppSizes.attendanceSpacingSM),
                              Expanded(
                                child: _buildStatCard(
                                  AppConstants.labelLate,
                                  _attendanceHistory!.lateDays.toString(),
                                  AppColors.attendanceLateColor,
                                  Icons.schedule,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.attendanceSpacingMD),
                          
                          // Attendance Percentage
                          Card(
                            elevation: AppSizes.attendancePercentageCardElevation,
                            child: Padding(
                              padding: const EdgeInsets.all(
                                AppSizes.attendancePercentageCardPadding,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    AppConstants.labelAttendancePercentage,
                                    style: TextStyle(
                                      fontSize: AppSizes.attendancePercentageTitleFontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "${_attendanceHistory!.attendancePercentage.toStringAsFixed(1)}%",
                                    style: TextStyle(
                                      fontSize: AppSizes.attendancePercentageValueFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: _getAttendanceColor(
                                        _attendanceHistory!.attendancePercentage,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSizes.attendanceSpacingMD),
                          
                          // Date Range Info
                          Card(
                            elevation: AppSizes.attendanceDateRangeCardElevation,
                            child: Padding(
                              padding: const EdgeInsets.all(
                                AppSizes.attendanceDateRangeCardPadding,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${AppConstants.labelFrom} ${_formatDate(_fromDate)}",
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    "${AppConstants.labelTo} ${_formatDate(_toDate)}",
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSizes.attendanceSpacingMD),
                          
                          // Attendance Records
                          const Text(
                            AppConstants.labelDailyRecords,
                            style: TextStyle(
                              fontSize: AppSizes.attendanceDailyRecordsTitleFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSizes.attendanceSpacingSM),
                          
                          if (_attendanceHistory!.attendanceRecords.isEmpty)
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.all(AppSizes.attendanceSpacingMD),
                                child: Text(AppConstants.msgNoAttendanceRecords),
                              ),
                            )
                          else
                            ..._attendanceHistory!.attendanceRecords.map((record) => 
                              Card(
                                margin: const EdgeInsets.only(
                                  bottom: AppSizes.attendanceRecordCardMargin,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getStatusColor(record),
                                    child: Icon(
                                      _getStatusIcon(record),
                                      color: AppColors.attendanceTextWhite,
                                    ),
                                  ),
                                  title: Text(_formatDate(record.date)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("${record.dayOfWeek} - ${_getStatusText(record)}"),
                                      if (record.arrivalTime != null)
                                        Text("${AppConstants.labelArrival} ${record.arrivalTime}"),
                                      if (record.departureTime != null)
                                        Text("${AppConstants.labelDeparture} ${record.departureTime}"),
                                      if (record.remarks != null && record.remarks!.isNotEmpty)
                                        Text("${AppConstants.labelRemarks} ${record.remarks}"),
                                    ],
                                  ),
                                ),
                              ),
                            ).toList(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: AppSizes.attendanceCardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.attendanceStatCardPadding),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: AppSizes.attendanceStatIconSize,
            ),
            const SizedBox(height: AppSizes.attendanceSpacingXS),
            Text(
              value,
              style: TextStyle(
                fontSize: AppSizes.attendanceStatValueFontSize,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppSizes.attendanceStatTitleFontSize,
                color: AppColors.attendanceUnknownColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= AppConstants.attendanceExcellentThreshold) {
      return AppColors.attendanceExcellentColor;
    }
    if (percentage >= AppConstants.attendanceGoodThreshold) {
      return AppColors.attendanceGoodColor;
    }
    return AppColors.attendancePoorColor;
  }

  Color _getStatusColor(AttendanceRecord record) {
    if (record.isPresent) return AppColors.attendancePresentColor;
    if (record.isAbsent) return AppColors.attendanceAbsentColor;
    if (record.isLate) return AppColors.attendanceLateColor;
    return AppColors.attendanceUnknownColor;
  }

  IconData _getStatusIcon(AttendanceRecord record) {
    if (record.isPresent) return Icons.check_circle;
    if (record.isAbsent) return Icons.cancel;
    if (record.isLate) return Icons.schedule;
    return Icons.help_outline;
  }

  String _getStatusText(AttendanceRecord record) {
    if (record.isPresent) return AppConstants.labelPresent;
    if (record.isAbsent) return AppConstants.labelAbsent;
    if (record.isLate) return AppConstants.labelLate;
    return AppConstants.labelUnknown;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

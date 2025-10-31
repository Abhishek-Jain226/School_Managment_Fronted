import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../data/models/driver_reports.dart';

class DriverReportsPage extends StatefulWidget {
  final DriverReports reports;

  const DriverReportsPage({super.key, required this.reports});

  @override
  State<DriverReportsPage> createState() => _DriverReportsPageState();
}

class _DriverReportsPageState extends State<DriverReportsPage> {
  String _selectedPeriod = 'today';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.labelDriverReports),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'today',
                child: Text(AppConstants.labelToday),
              ),
              const PopupMenuItem<String>(
                value: 'week',
                child: Text(AppConstants.labelThisWeek),
              ),
              const PopupMenuItem<String>(
                value: 'month',
                child: Text(AppConstants.labelThisMonth),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.driverReportsPadding),
        child: Column(
          children: [
            // Period Selector
            _buildPeriodSelector(),
            const SizedBox(height: AppSizes.driverReportsSpacingLG),

            // Overall Statistics
            _buildOverallStatsCard(),
            const SizedBox(height: AppSizes.driverReportsSpacingLG),

            // Selected Period Statistics
            _buildPeriodStatsCard(),
            const SizedBox(height: AppSizes.driverReportsSpacingLG),

            // Performance Metrics
            _buildPerformanceCard(),
            const SizedBox(height: AppSizes.driverReportsSpacingLG),

            // Recent Activity
            if (widget.reports.recentTrips.isNotEmpty) ...[
              _buildRecentTripsCard(),
              const SizedBox(height: AppSizes.driverReportsSpacingLG),
            ],

            // Attendance Records
            if (widget.reports.attendanceRecords.isNotEmpty) ...[
              _buildAttendanceCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      elevation: AppSizes.driverReportsCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.driverReportsCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.driverReportsSelectorPadding),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.driverReportsBlueColor, size: AppSizes.driverReportsSelectorIconSize),
            const SizedBox(width: AppSizes.driverReportsSpacingSM),
            const Text(
              AppConstants.labelViewing,
              style: TextStyle(fontSize: AppSizes.driverReportsPeriodFontSize, fontWeight: FontWeight.w500),
            ),
            Text(
              _getPeriodDisplayName(),
              style: const TextStyle(
                fontSize: AppSizes.driverReportsPeriodFontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.driverReportsBlueColor,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // Refresh data
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getPeriodDisplayName() {
    switch (_selectedPeriod) {
      case 'today':
        return AppConstants.labelToday;
      case 'week':
        return AppConstants.labelThisWeek;
      case 'month':
        return AppConstants.labelThisMonth;
      default:
        return AppConstants.labelToday;
    }
  }

  Widget _buildOverallStatsCard() {
    return Card(
      elevation: AppSizes.driverReportsCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.driverReportsCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.driverReportsCardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.labelOverallStatistics,
              style: TextStyle(fontSize: AppSizes.driverReportsTitleFontSize, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.driverReportsSpacingMD),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    AppConstants.labelTotalTrips,
                    widget.reports.totalTripsCompleted.toString(),
                    Icons.route,
                    AppColors.driverReportsBlueColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    AppConstants.labelStudentsTransported,
                    widget.reports.totalStudentsTransported.toString(),
                    Icons.people,
                    AppColors.driverReportsGreenColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.driverReportsSpacingMD),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    AppConstants.labelDistanceCovered,
                    '${widget.reports.totalDistanceCovered}${AppConstants.labelKm}',
                    Icons.straighten,
                    AppColors.driverReportsOrangeColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    AppConstants.labelAverageRating,
                    widget.reports.averageRating.toStringAsFixed(1),
                    Icons.star,
                    AppColors.driverReportsAmberColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodStatsCard() {
    final stats = _getPeriodStats();
    
    return Card(
      elevation: AppSizes.driverReportsCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.driverReportsCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.driverReportsCardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getPeriodDisplayName()}${AppConstants.labelStatistics}',
              style: const TextStyle(fontSize: AppSizes.driverReportsTitleFontSize, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.driverReportsSpacingMD),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    AppConstants.labelTrips,
                    stats['trips'].toString(),
                    Icons.route,
                    AppColors.driverReportsBlueColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    AppConstants.labelStudents,
                    stats['students'].toString(),
                    Icons.people,
                    AppColors.driverReportsGreenColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.driverReportsSpacingMD),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    AppConstants.labelPickups,
                    stats['pickups'].toString(),
                    Icons.person_add,
                    AppColors.driverReportsOrangeColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    AppConstants.labelDrops,
                    stats['drops'].toString(),
                    Icons.person_remove,
                    AppColors.driverReportsPurpleColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _getPeriodStats() {
    switch (_selectedPeriod) {
      case 'today':
        return {
          'trips': widget.reports.todayTrips,
          'students': widget.reports.todayStudents,
          'pickups': widget.reports.todayPickups,
          'drops': widget.reports.todayDrops,
        };
      case 'week':
        return {
          'trips': widget.reports.weekTrips,
          'students': widget.reports.weekStudents,
          'pickups': widget.reports.weekPickups,
          'drops': widget.reports.weekDrops,
        };
      case 'month':
        return {
          'trips': widget.reports.monthTrips,
          'students': widget.reports.monthStudents,
          'pickups': widget.reports.monthPickups,
          'drops': widget.reports.monthDrops,
        };
      default:
        return {
          'trips': 0,
          'students': 0,
          'pickups': 0,
          'drops': 0,
        };
    }
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.driverReportsStatPadding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.driverReportsStatRadius),
        border: Border.all(color: color, width: AppSizes.driverReportsStatBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: AppSizes.driverReportsStatIconSize),
          const SizedBox(height: AppSizes.driverReportsSpacingXS),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSizes.driverReportsStatValueFontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppSizes.driverReportsSpacingXS / 2),
          Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.driverReportsStatLabelFontSize,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard() {
    return Card(
      elevation: AppSizes.driverReportsCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.driverReportsCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.driverReportsCardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.labelPerformanceMetrics,
              style: TextStyle(fontSize: AppSizes.driverReportsTitleFontSize, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.driverReportsSpacingMD),
            
            // Completion Rate
            _buildPerformanceItem(
              AppConstants.labelTripCompletionRate,
              _calculateCompletionRate(),
              Icons.check_circle,
              AppColors.driverReportsGreenColor,
            ),
            const SizedBox(height: AppSizes.driverReportsSpacingSM),
            
            // Punctuality
            _buildPerformanceItem(
              AppConstants.labelPunctualityScore,
              '${widget.reports.averageRating.toStringAsFixed(1)}/5.0',
              Icons.schedule,
              AppColors.driverReportsBlueColor,
            ),
            const SizedBox(height: AppSizes.driverReportsSpacingSM),
            
            // Safety Record
            _buildPerformanceItem(
              AppConstants.labelSafetyRecord,
              '100%',
              Icons.security,
              AppColors.driverReportsGreenColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: AppSizes.driverReportsPerformanceIconSize),
        const SizedBox(width: AppSizes.driverReportsSpacingSM),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: AppSizes.driverReportsPerformanceFontSize, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: AppSizes.driverReportsPerformanceFontSize,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _calculateCompletionRate() {
    if (widget.reports.totalTripsCompleted == 0) return '0%';
    
    // This is a simplified calculation
    // In a real app, you'd calculate based on completed vs assigned trips
    final completionRate = (widget.reports.totalTripsCompleted / 
        (widget.reports.totalTripsCompleted + 2)) * 100;
    return '${completionRate.toStringAsFixed(1)}%';
  }

  Widget _buildRecentTripsCard() {
    return Card(
      elevation: AppSizes.driverReportsCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.driverReportsCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.driverReportsCardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.labelRecentTrips,
              style: TextStyle(fontSize: AppSizes.driverReportsTitleFontSize, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.driverReportsSpacingMD),
            ...widget.reports.recentTrips.take(5).map((trip) => 
              _buildRecentTripItem(trip)
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTripItem(RecentTrip trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.driverReportsRecentTripMargin),
      padding: const EdgeInsets.all(AppSizes.driverReportsRecentTripPadding),
      decoration: BoxDecoration(
        color: AppColors.driverReportsBackgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.driverReportsRecentTripRadius),
        border: Border.all(color: AppColors.driverReportsBorderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: AppSizes.driverReportsRecentTripAvatarRadius,
            backgroundColor: _getStatusColor(trip.status),
            child: Icon(
              _getStatusIcon(trip.status),
              color: AppColors.driverReportsWhiteColor,
              size: AppSizes.driverReportsRecentTripIconSize,
            ),
          ),
          const SizedBox(width: AppSizes.driverReportsSpacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.tripName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${trip.tripType}${AppConstants.labelStudentsBullet}',
                  style: const TextStyle(
                    fontSize: AppSizes.driverReportsStatLabelFontSize,
                    color: AppColors.driverReportsGreyColor,
                  ),
                ),
                Text(
                  '${trip.startTime} - ${trip.endTime}',
                  style: const TextStyle(
                    fontSize: AppSizes.driverReportsStatLabelFontSize,
                    color: AppColors.driverReportsGreyColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.driverReportsRecentTripBadgePaddingH,
              vertical: AppSizes.driverReportsRecentTripBadgePaddingV,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(trip.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.driverReportsRecentTripBadgeRadius),
            ),
            child: Text(
              trip.status,
              style: TextStyle(
                fontSize: AppSizes.driverReportsRecentTripFontSizeSM,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(trip.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard() {
    return Card(
      elevation: AppSizes.driverReportsCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.driverReportsCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.driverReportsCardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.labelAttendanceRecords,
              style: TextStyle(fontSize: AppSizes.driverReportsTitleFontSize, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.driverReportsSpacingMD),
            ...widget.reports.attendanceRecords.take(7).map((record) => 
              _buildAttendanceItem(record)
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceItem(AttendanceRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.driverReportsAttendanceMargin),
      padding: const EdgeInsets.all(AppSizes.driverReportsAttendancePadding),
      decoration: BoxDecoration(
        color: AppColors.driverReportsBackgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.driverReportsAttendanceRadius),
        border: Border.all(color: AppColors.driverReportsBorderColor),
      ),
      child: Row(
        children: [
          Container(
            width: AppSizes.driverReportsAttendanceDotSize,
            height: AppSizes.driverReportsAttendanceDotSize,
            decoration: BoxDecoration(
              color: _getAttendanceStatusColor(record.status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSizes.driverReportsSpacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(record.date),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${record.completedTrips}/${record.totalTrips}${AppConstants.labelTripsSlash}${record.studentsPickedUp}${AppConstants.labelPickupsText}${record.studentsDropped}${AppConstants.labelDropsText}',
                  style: const TextStyle(
                    fontSize: AppSizes.driverReportsStatLabelFontSize,
                    color: AppColors.driverReportsGreyColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.driverReportsRecentTripBadgePaddingH,
              vertical: AppSizes.driverReportsRecentTripBadgePaddingV,
            ),
            decoration: BoxDecoration(
              color: _getAttendanceStatusColor(record.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.driverReportsRecentTripBadgeRadius),
            ),
            child: Text(
              record.status,
              style: TextStyle(
                fontSize: AppSizes.driverReportsRecentTripFontSizeSM,
                fontWeight: FontWeight.bold,
                color: _getAttendanceStatusColor(record.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.driverReportsGreenColor;
      case 'in_progress':
        return AppColors.driverReportsBlueColor;
      case 'cancelled':
        return AppColors.driverReportsRedColor;
      default:
        return AppColors.driverReportsGreyColor;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.play_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _getAttendanceStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return AppColors.driverReportsGreenColor;
      case 'absent':
        return AppColors.driverReportsRedColor;
      case 'late':
        return AppColors.driverReportsOrangeColor;
      default:
        return AppColors.driverReportsGreyColor;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

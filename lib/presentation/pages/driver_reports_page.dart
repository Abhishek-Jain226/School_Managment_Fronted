import 'package:flutter/material.dart';
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
        title: const Text('Driver Reports'),
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
                child: Text('Today'),
              ),
              const PopupMenuItem<String>(
                value: 'week',
                child: Text('This Week'),
              ),
              const PopupMenuItem<String>(
                value: 'month',
                child: Text('This Month'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Period Selector
            _buildPeriodSelector(),
            const SizedBox(height: 20),

            // Overall Statistics
            _buildOverallStatsCard(),
            const SizedBox(height: 20),

            // Selected Period Statistics
            _buildPeriodStatsCard(),
            const SizedBox(height: 20),

            // Performance Metrics
            _buildPerformanceCard(),
            const SizedBox(height: 20),

            // Recent Activity
            if (widget.reports.recentTrips.isNotEmpty) ...[
              _buildRecentTripsCard(),
              const SizedBox(height: 20),
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
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.blue),
            const SizedBox(width: 12),
            const Text(
              'Viewing: ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Text(
              _getPeriodDisplayName(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
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
        return 'Today';
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      default:
        return 'Today';
    }
  }

  Widget _buildOverallStatsCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Trips',
                    widget.reports.totalTripsCompleted.toString(),
                    Icons.route,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Students Transported',
                    widget.reports.totalStudentsTransported.toString(),
                    Icons.people,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Distance Covered',
                    '${widget.reports.totalDistanceCovered} km',
                    Icons.straighten,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Average Rating',
                    widget.reports.averageRating.toStringAsFixed(1),
                    Icons.star,
                    Colors.amber,
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
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getPeriodDisplayName()} Statistics',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Trips',
                    stats['trips'].toString(),
                    Icons.route,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Students',
                    stats['students'].toString(),
                    Icons.people,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Pickups',
                    stats['pickups'].toString(),
                    Icons.person_add,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Drops',
                    stats['drops'].toString(),
                    Icons.person_remove,
                    Colors.purple,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
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
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Completion Rate
            _buildPerformanceItem(
              'Trip Completion Rate',
              _calculateCompletionRate(),
              Icons.check_circle,
              Colors.green,
            ),
            const SizedBox(height: 12),
            
            // Punctuality
            _buildPerformanceItem(
              'Punctuality Score',
              '${widget.reports.averageRating.toStringAsFixed(1)}/5.0',
              Icons.schedule,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            
            // Safety Record
            _buildPerformanceItem(
              'Safety Record',
              '100%',
              Icons.security,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
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
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Trips',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _getStatusColor(trip.status),
            child: Icon(
              _getStatusIcon(trip.status),
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.tripName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${trip.tripType} • ${trip.studentsCount} students',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${trip.startTime} - ${trip.endTime}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(trip.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              trip.status,
              style: TextStyle(
                fontSize: 10,
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
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Records',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getAttendanceStatusColor(record.status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(record.date),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${record.completedTrips}/${record.totalTrips} trips • ${record.studentsPickedUp} pickups • ${record.studentsDropped} drops',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getAttendanceStatusColor(record.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              record.status,
              style: TextStyle(
                fontSize: 10,
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
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
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
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

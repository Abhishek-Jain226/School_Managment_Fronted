import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/parent_service.dart';
import '../../data/models/attendance_history.dart';

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
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId');
    });
    
    if (_userId != null) {
      _loadAttendanceHistory();
    } else {
      setState(() {
        _error = 'User ID not found. Please login again.';
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
      print('🔍 Error loading attendance history: $e');
      setState(() {
        _error = 'Error loading attendance history: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
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
            Icon(Icons.history, size: 28),
            SizedBox(width: 8),
            Text("Attendance History"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAttendanceHistory,
            tooltip: 'Refresh',
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
                      Text(_error, style: const TextStyle(color: Colors.red, fontSize: 16)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadAttendanceHistory,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _attendanceHistory == null
                  ? const Center(child: Text('No attendance data found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary Cards
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  "Total Days",
                                  _attendanceHistory!.totalDays.toString(),
                                  Colors.blue,
                                  Icons.calendar_today,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatCard(
                                  "Present",
                                  _attendanceHistory!.presentDays.toString(),
                                  Colors.green,
                                  Icons.check_circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  "Absent",
                                  _attendanceHistory!.absentDays.toString(),
                                  Colors.red,
                                  Icons.cancel,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatCard(
                                  "Late",
                                  _attendanceHistory!.lateDays.toString(),
                                  Colors.orange,
                                  Icons.schedule,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Attendance Percentage
                          Card(
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Attendance Percentage",
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "${_attendanceHistory!.attendancePercentage.toStringAsFixed(1)}%",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: _getAttendanceColor(_attendanceHistory!.attendancePercentage),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Date Range Info
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "From: ${_formatDate(_fromDate)}",
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    "To: ${_formatDate(_toDate)}",
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Attendance Records
                          const Text(
                            "Daily Records",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          
                          if (_attendanceHistory!.attendanceRecords.isEmpty)
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No attendance records found for the selected period'),
                              ),
                            )
                          else
                            ..._attendanceHistory!.attendanceRecords.map((record) => 
                              Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getStatusColor(record),
                                    child: Icon(
                                      _getStatusIcon(record),
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(_formatDate(record.date)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("${record.dayOfWeek} - ${_getStatusText(record)}"),
                                      if (record.arrivalTime != null)
                                        Text("Arrival: ${record.arrivalTime}"),
                                      if (record.departureTime != null)
                                        Text("Departure: ${record.departureTime}"),
                                      if (record.remarks != null && record.remarks!.isNotEmpty)
                                        Text("Remarks: ${record.remarks}"),
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
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }

  Color _getStatusColor(AttendanceRecord record) {
    if (record.isPresent) return Colors.green;
    if (record.isAbsent) return Colors.red;
    if (record.isLate) return Colors.orange;
    return Colors.grey;
  }

  IconData _getStatusIcon(AttendanceRecord record) {
    if (record.isPresent) return Icons.check_circle;
    if (record.isAbsent) return Icons.cancel;
    if (record.isLate) return Icons.schedule;
    return Icons.help_outline;
  }

  String _getStatusText(AttendanceRecord record) {
    if (record.isPresent) return 'Present';
    if (record.isAbsent) return 'Absent';
    if (record.isLate) return 'Late';
    return 'Unknown';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

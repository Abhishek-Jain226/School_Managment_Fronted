import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/parent_service.dart';
import '../../data/models/monthly_report.dart';

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

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

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
      _loadMonthlyReport();
    } else {
      setState(() {
        _error = 'User ID not found. Please login again.';
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
      print('🔍 Error loading monthly report: $e');
      setState(() {
        _error = 'Error loading monthly report: $e';
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
          title: const Text('Select Month & Year'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Year Picker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Year:'),
                  DropdownButton<int>(
                    value: _selectedYear,
                    items: List.generate(5, (index) {
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
              const SizedBox(height: 16),
              // Month Picker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Month:'),
                  DropdownButton<int>(
                    value: _selectedMonth,
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text(_months[index]),
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
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadMonthlyReport();
              },
              child: const Text('Load Report'),
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
            Icon(Icons.assessment, size: 28),
            SizedBox(width: 8),
            Text("Monthly Report"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _showMonthYearPicker,
            tooltip: 'Select Month & Year',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMonthlyReport,
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
                        onPressed: _loadMonthlyReport,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _monthlyReport == null
                  ? const Center(child: Text('No report data found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Report Header
                          Card(
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_months[_selectedMonth - 1]} $_selectedYear Report',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Student: ${_monthlyReport!.studentName}'),
                                  Text('Class: ${_monthlyReport!.className} - ${_monthlyReport!.sectionName}'),
                                  Text('School: ${_monthlyReport!.schoolName}'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Attendance Summary
                          const Text(
                            'Attendance Summary',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  "School Days",
                                  _monthlyReport!.totalSchoolDays.toString(),
                                  Colors.blue,
                                  Icons.school,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatCard(
                                  "Present",
                                  _monthlyReport!.presentDays.toString(),
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
                                  _monthlyReport!.absentDays.toString(),
                                  Colors.red,
                                  Icons.cancel,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatCard(
                                  "Late",
                                  _monthlyReport!.lateDays.toString(),
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
                                    "${_monthlyReport!.attendancePercentage.toStringAsFixed(1)}%",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: _getAttendanceColor(_monthlyReport!.attendancePercentage),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Trip Summary
                          const Text(
                            'Trip Summary',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  "Total Trips",
                                  _monthlyReport!.totalTrips.toString(),
                                  Colors.purple,
                                  Icons.directions_bus,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatCard(
                                  "Completed",
                                  _monthlyReport!.completedTrips.toString(),
                                  Colors.green,
                                  Icons.check_circle_outline,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  "Missed",
                                  _monthlyReport!.missedTrips.toString(),
                                  Colors.red,
                                  Icons.cancel_outlined,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatCard(
                                  "Completion Rate",
                                  "${_monthlyReport!.tripCompletionRate.toStringAsFixed(1)}%",
                                  Colors.blue,
                                  Icons.trending_up,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Performance Chart (Simple)
                          Card(
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Performance Overview',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildProgressBar(
                                    'Attendance',
                                    _monthlyReport!.attendancePercentage,
                                    Colors.blue,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildProgressBar(
                                    'Trip Completion',
                                    _monthlyReport!.tripCompletionRate,
                                    Colors.green,
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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: color.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }
}

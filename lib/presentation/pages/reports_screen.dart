import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/student_service.dart';
import '../../services/vehicle_service.dart';
import '../../services/trip_service.dart';
import '../../services/report_service.dart';
import '../../services/websocket_notification_service.dart';
import '../../data/models/websocket_notification.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WebSocketNotificationService _webSocketService = WebSocketNotificationService();
  
  // Real data variables
  int totalStudents = 0;
  int totalVehicles = 0;
  int totalTrips = 0;
  int notificationsSent = 0;
  bool _loading = true;
  int? schoolId;
  
  // Report data
  List<dynamic> attendanceData = [];
  List<dynamic> dispatchLogsData = [];
  List<dynamic> notificationLogsData = [];
  String _selectedAttendanceFilter = 'student-wise';
  String _selectedDispatchFilter = 'all';
  String _selectedNotificationFilter = 'all';
  
  // Real-time updates
  bool _isConnected = false;
  StreamSubscription<WebSocketNotification>? _notificationSubscription;
  Timer? _autoRefreshTimer;
  
  final ReportService _reportService = ReportService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReportData();
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notificationSubscription?.cancel();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _initializeWebSocket() {
    _webSocketService.initialize().then((_) {
      setState(() {
        _isConnected = _webSocketService.isConnected;
      });
      _notificationSubscription = _webSocketService.notificationStream.listen(
        _handleWebSocketNotification,
        onError: (error) {
          debugPrint('WebSocket error: $error');
          setState(() {
            _isConnected = false;
          });
        },
      );
      _startAutoRefresh();
    });
  }

  void _handleWebSocketNotification(WebSocketNotification notification) {
    debugPrint('🔔 Reports - Received notification: ${notification.type} - ${notification.message}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${notification.title}: ${notification.message}'),
          duration: const Duration(seconds: AppSizes.registerSchoolSnackBarDurationShort),
          backgroundColor: AppColors.infoColor,
        ),
      );
    }
    if (_isRelevantNotification(notification)) {
      _loadReportData();
    }
  }

  bool _isRelevantNotification(WebSocketNotification notification) {
    return notification.type == NotificationType.attendanceUpdate ||
           notification.type == NotificationType.tripUpdate ||
           notification.type == NotificationType.vehicleAssignmentRequest ||
           notification.type == NotificationType.arrivalNotification;
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadReportData();
      }
    });
  }

  Future<void> _loadReportData() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      schoolId = prefs.getInt(AppConstants.keySchoolId);
      
      debugPrint('═══════════════════════════════════════');
      debugPrint('🔍 REPORTS DASHBOARD - Loading Data');
      debugPrint('🔍 schoolId from SharedPreferences: $schoolId');
      debugPrint('═══════════════════════════════════════');
      
      if (schoolId == null) {
        debugPrint('❌ ERROR: schoolId is NULL in SharedPreferences!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppConstants.msgSchoolIdNotFoundLogin),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
        setState(() => _loading = false);
        return;
      }
      
      if (schoolId != null) {
        debugPrint('🔍 Loading report data for schoolId: $schoolId');
        
        // Load real data from services
        try {
          debugPrint('📊 Fetching student count...');
          final studentCount = await StudentService().getStudentCount(schoolId!.toString());
          debugPrint('✅ Student count: $studentCount');
          
          debugPrint('📊 Fetching vehicle count...');
          final vehicleCount = await VehicleService().getVehicleCount(schoolId!.toString());
          debugPrint('✅ Vehicle count: $vehicleCount');
          
          debugPrint('📊 Fetching trips...');
          final trips = await TripService().getTripsBySchool(schoolId!);
          debugPrint('✅ Trips count: ${trips.length}');
          
          // Load report data
          debugPrint('📊 Loading attendance report...');
          await _loadAttendanceReport();
          
          debugPrint('📊 Loading dispatch logs report...');
          await _loadDispatchLogsReport();
          
          debugPrint('📊 Loading notification logs report...');
          await _loadNotificationLogsReport();
          
          setState(() {
            totalStudents = studentCount;
            totalVehicles = vehicleCount;
            totalTrips = trips.length;
            notificationsSent = notificationLogsData.length;
            _loading = false;
          });
          
          debugPrint('═══════════════════════════════════════');
          debugPrint('✅ REPORTS DASHBOARD - Data Loaded Successfully');
          debugPrint('📊 Total Students: $totalStudents');
          debugPrint('📊 Total Vehicles: $totalVehicles');
          debugPrint('📊 Total Trips: $totalTrips');
          debugPrint('📊 Notifications Sent: $notificationsSent');
          debugPrint('📊 Attendance Records: ${attendanceData.length}');
          debugPrint('📊 Dispatch Logs: ${dispatchLogsData.length}');
          debugPrint('📊 Notification Logs: ${notificationLogsData.length}');
          debugPrint('═══════════════════════════════════════');
        } catch (e) {
          debugPrint('❌ ERROR loading specific data: $e');
          debugPrint('Stack trace: ${StackTrace.current}');
          setState(() => _loading = false);
        }
      } else {
        debugPrint('❌ schoolId is still null after check');
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('❌ CRITICAL ERROR loading report data: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      debugPrint('═══════════════════════════════════════');
      setState(() => _loading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppConstants.msgErrorLoadingReports}$e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }
  
  Future<void> _loadAttendanceReport() async {
    try {
      final response = await _reportService.getAttendanceReport(schoolId!, _selectedAttendanceFilter);
      if (response[AppConstants.keySuccess] == true) {
        setState(() {
          attendanceData = response[AppConstants.keyData] is List ? response[AppConstants.keyData] : [];
        });
        print('🔍 Attendance report loaded: ${attendanceData.length} records');
      }
    } catch (e) {
      print('🔍 Error loading attendance report: $e');
    }
  }
  
  Future<void> _loadDispatchLogsReport() async {
    try {
      final response = await _reportService.getDispatchLogsReport(schoolId!, _selectedDispatchFilter);
      if (response[AppConstants.keySuccess] == true) {
        setState(() {
          dispatchLogsData = response[AppConstants.keyData] is List ? response[AppConstants.keyData] : [];
        });
        print('🔍 Dispatch logs report loaded: ${dispatchLogsData.length} records');
      }
    } catch (e) {
      print('🔍 Error loading dispatch logs report: $e');
    }
  }
  
  Future<void> _loadNotificationLogsReport() async {
    try {
      final response = await _reportService.getNotificationLogsReport(schoolId!, _selectedNotificationFilter);
      if (response[AppConstants.keySuccess] == true) {
        setState(() {
          notificationLogsData = response[AppConstants.keyData] is List ? response[AppConstants.keyData] : [];
        });
        print('🔍 Notification logs report loaded: ${notificationLogsData.length} records');
      }
    } catch (e) {
      print('🔍 Error loading notification logs report: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.labelReportsDashboard),
        actions: [
          // WebSocket connection status
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? AppColors.successColor : AppColors.errorColor,
              size: AppSizes.iconSM,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: AppConstants.labelAttendanceTab),
            Tab(text: AppConstants.labelDispatchLogsTab),
            Tab(text: AppConstants.labelNotificationsTab),
          ],
        ),
      ),
      body: Column(
        children: [
          // 🔹 Summary Cards Row
          Padding(
            padding: const EdgeInsets.all(AppConstants.reportsHeaderPadding),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(AppConstants.labelTotalStudents, totalStudents.toString(), AppColors.infoColor),
                      _buildStatCard(AppConstants.labelTotalVehicles, totalVehicles.toString(), AppColors.successColor),
                      _buildStatCard(AppConstants.labelTotalTrips, totalTrips.toString(), AppColors.warningColor),
                      _buildStatCard(AppConstants.labelNotifications, notificationsSent.toString(), AppColors.adminColor),
                    ],
                  ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAttendanceReport(),
                _buildDispatchLogs(),
                _buildNotificationLogs(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Attendance Report Tab
  Widget _buildAttendanceReport() {
    return Column(
      children: [
        // Filter buttons
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilterChip(
                label: Text(AppConstants.labelStudentWise),
                selected: _selectedAttendanceFilter == 'student-wise',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedAttendanceFilter = 'student-wise');
                    _loadAttendanceReport();
                  }
                },
              ),
              SizedBox(width: AppSizes.spaceSM),
              FilterChip(
                label: Text(AppConstants.labelClassWise),
                selected: _selectedAttendanceFilter == 'class-wise',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedAttendanceFilter = 'class-wise');
                    _loadAttendanceReport();
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: attendanceData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school, size: AppConstants.reportsIconSizeLG, color: AppColors.textHint),
                      SizedBox(height: AppConstants.reportsGapLG),
                      Text(AppConstants.msgNoAttendanceData, style: TextStyle(color: AppColors.textHint)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: attendanceData.length,
                  itemBuilder: (context, index) {
                    final record = attendanceData[index];
                    final presentDays = record['presentDays'] ?? 0;
                    final absentDays = record['absentDays'] ?? 0;
                    final totalDays = record['totalDays'] ?? 0;
                    final percentage = record['attendancePercentage'] ?? 0.0;
                    
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: AppSizes.spaceMD, vertical: AppSizes.spaceXS + 2),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: percentage >= 75 ? AppColors.successColor : percentage >= 50 ? AppColors.warningColor : AppColors.errorColor,
                          child: Text(
                            percentage.toStringAsFixed(0) + '%',
                            style: TextStyle(color: AppColors.textWhite, fontSize: AppConstants.reportsTitleFontSize),
                          ),
                        ),
                        title: Text(record['studentName'] ?? AppConstants.msgUnknown),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Class: ${record['className']} - ${record['sectionName']}"),
                            Text("Present: $presentDays | Absent: $absentDays | Total: $totalDays"),
                          ],
                        ),
                        trailing: Icon(
                          percentage >= 75 ? Icons.check_circle : percentage >= 50 ? Icons.warning : Icons.error,
                          color: percentage >= 75 ? AppColors.successColor : percentage >= 50 ? AppColors.warningColor : AppColors.errorColor,
                        ),
                      ),
                    );
                  },
                ),
        ),
        _buildExportButtons('attendance'),
      ],
    );
  }

  // 🔹 Dispatch Logs Tab
  Widget _buildDispatchLogs() {
    return Column(
      children: [
        // Filter buttons
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilterChip(
                label: Text(AppConstants.labelAll),
                selected: _selectedDispatchFilter == 'all',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedDispatchFilter = 'all');
                    _loadDispatchLogsReport();
                  }
                },
              ),
              SizedBox(width: AppSizes.spaceSM),
              FilterChip(
                label: Text(AppConstants.labelTripWise),
                selected: _selectedDispatchFilter == 'trip-wise',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedDispatchFilter = 'trip-wise');
                    _loadDispatchLogsReport();
                  }
                },
              ),
              SizedBox(width: AppSizes.spaceSM),
              FilterChip(
                label: Text(AppConstants.labelVehicleWise),
                selected: _selectedDispatchFilter == 'vehicle-wise',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedDispatchFilter = 'vehicle-wise');
                    _loadDispatchLogsReport();
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: dispatchLogsData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_bus, size: AppConstants.reportsIconSizeLG, color: AppColors.textHint),
                      SizedBox(height: AppConstants.reportsGapLG),
                      Text(AppConstants.msgNoDispatchLogs, style: TextStyle(color: AppColors.textHint)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: dispatchLogsData.length,
                  itemBuilder: (context, index) {
                    final log = dispatchLogsData[index];
                    final eventType = log['eventType'] ?? 'Unknown';
                    final createdDate = log['createdDate'] ?? '';
                    
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getEventTypeColor(eventType),
                          child: Icon(
                            _getEventTypeIcon(eventType),
                            color: AppColors.textWhite,
                            size: AppConstants.reportsIconSizeMD,
                          ),
                        ),
                        title: Text(log['tripName'] ?? AppConstants.msgUnknown),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Vehicle: ${log['vehicleNumber']} | Student: ${log['studentName']}"),
                            Text("Event: $eventType | Date: $createdDate"),
                            if (log['remarks'] != null && log['remarks'].isNotEmpty)
                              Text("Remarks: ${log['remarks']}", style: TextStyle(fontStyle: FontStyle.italic)),
                          ],
                        ),
                        trailing: Text(
                          eventType,
                          style: TextStyle(
                            color: _getEventTypeColor(eventType),
                            fontWeight: FontWeight.bold,
                            fontSize: AppConstants.reportsTitleFontSize,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        _buildExportButtons('dispatch'),
      ],
    );
  }
  
  Color _getEventTypeColor(String eventType) {
    switch (eventType.toUpperCase()) {
      case 'PICKUP_FROM_PARENT':
      case 'PICKUP_FROM_SCHOOL':
        return Colors.blue;
      case 'DROP_TO_SCHOOL':
      case 'DROP_TO_PARENT':
        return Colors.green;
      case 'ABSENT':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getEventTypeIcon(String eventType) {
    switch (eventType.toUpperCase()) {
      case 'PICKUP_FROM_PARENT':
      case 'PICKUP_FROM_SCHOOL':
        return Icons.arrow_upward;
      case 'DROP_TO_SCHOOL':
      case 'DROP_TO_PARENT':
        return Icons.arrow_downward;
      case 'ABSENT':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  // 🔹 Notification Logs Tab
  Widget _buildNotificationLogs() {
    return Column(
      children: [
        // Filter buttons
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilterChip(
                label: Text(AppConstants.labelAll),
                selected: _selectedNotificationFilter == 'all',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedNotificationFilter = 'all');
                    _loadNotificationLogsReport();
                  }
                },
              ),
              SizedBox(width: AppSizes.spaceSM),
              FilterChip(
                label: Text(AppConstants.labelSent),
                selected: _selectedNotificationFilter == 'sent',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedNotificationFilter = 'sent');
                    _loadNotificationLogsReport();
                  }
                },
              ),
              SizedBox(width: AppSizes.spaceSM),
              FilterChip(
                label: Text(AppConstants.labelFailed),
                selected: _selectedNotificationFilter == 'failed',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedNotificationFilter = 'failed');
                    _loadNotificationLogsReport();
                  }
                },
              ),
              SizedBox(width: AppSizes.spaceSM),
              FilterChip(
                label: Text(AppConstants.labelPending),
                selected: _selectedNotificationFilter == 'pending',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedNotificationFilter = 'pending');
                    _loadNotificationLogsReport();
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: notificationLogsData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications, size: AppConstants.reportsIconSizeLG, color: AppColors.textHint),
                      SizedBox(height: AppConstants.reportsGapLG),
                      Text(AppConstants.msgNoNotificationLogs, style: TextStyle(color: AppColors.textHint)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: notificationLogsData.length,
                  itemBuilder: (context, index) {
                    final notification = notificationLogsData[index];
                    final status = notification['status'] ?? 'Unknown';
                    final sentDate = notification['sentDate'] ?? '';
                    final message = notification['message'] ?? 'No message';
                    
                    Color color = _getNotificationStatusColor(status);
                    
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color,
                          child: Icon(
                            _getNotificationStatusIcon(status),
                            color: AppColors.textWhite,
                            size: AppConstants.reportsIconSizeMD,
                          ),
                        ),
                        title: Text(message.length > 50 ? message.substring(0, 50) + '...' : message),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Trip: ${notification['tripName']} | Student: ${notification['studentName']}"),
                            Text("Vehicle: ${notification['vehicleNumber']} | Date: $sentDate"),
                            Text("Type: ${notification['notificationType']} | Sent to: ${notification['sentTo']}"),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              status,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            if (notification['deliveryStatus'] != null)
                              Text(
                                notification['deliveryStatus'],
                                style: TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        _buildExportButtons('notifications'),
      ],
    );
  }
  
  Color _getNotificationStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SENT':
        return Colors.green;
      case 'FAILED':
        return Colors.red;
      case 'PENDING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getNotificationStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'SENT':
        return Icons.check_circle;
      case 'FAILED':
        return Icons.error;
      case 'PENDING':
        return Icons.schedule;
      default:
        return Icons.notifications;
    }
  }

  // 🔹 Summary Card Widget
  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Container(
        width: 100,
        height: 80,
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            SizedBox(height: 4),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  // 🔹 Export Buttons
  Widget _buildExportButtons(String reportType) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.reportsHeaderPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: () => _exportReport(reportType, 'pdf'),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text(AppConstants.labelDownloadPDF),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorColor),
          ),
          SizedBox(width: AppConstants.reportsGapMD),
          ElevatedButton.icon(
            onPressed: () => _exportReport(reportType, 'csv'),
            icon: const Icon(Icons.table_chart),
            label: const Text(AppConstants.labelExportCSV),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.infoColor),
          ),
        ],
      ),
    );
  }
  
  Future<void> _exportReport(String type, String format) async {
    try {
      if (schoolId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.msgSchoolIdNotFoundLogin)),
        );
        return;
      }
      
      // Check permissions first
      if (Platform.isAndroid) {
        final hasPermission = await _checkStoragePermission();
        if (!hasPermission) {
          // Show permission dialog
          final shouldRequest = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(AppConstants.labelStoragePermissionRequired),
              content: const Text(AppConstants.msgStoragePermissionExplain),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(AppConstants.labelCancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(AppConstants.labelGrantPermission),
                ),
              ],
            ),
          );
          
          if (shouldRequest != true) {
            return;
          }
          
          // Try to request permission again
          final permissionGranted = await _checkStoragePermission();
          if (!permissionGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(AppConstants.msgStoragePermissionDenied),
                backgroundColor: AppColors.errorColor,
              ),
            );
            return;
          }
        }
      }
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              SizedBox(width: AppConstants.reportsGapLG),
              Text('${AppConstants.msgDownloadingReportPrefix}$type report...'),
            ],
          ),
        ),
      );
      
      // Download the actual file
      final fileBytes = await _reportService.downloadReport(schoolId!, type, format);
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Save file to device
      await _saveFileToDevice(fileBytes, type, format);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppConstants.msgReportDownloaded),
          backgroundColor: AppColors.successColor,
          duration: const Duration(seconds: AppConstants.reportsSnackbarDuration),
        ),
      );
      
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppConstants.msgDownloadError}$e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }
  
  Future<bool> _checkStoragePermission() async {
    if (Platform.isAndroid) {
      // Check for Android 13+ (API 33+) - use different permissions
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }
      
      // For Android 13+, request manage external storage permission
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }
      
      // Fallback to storage permission for older Android versions
      final status = await Permission.storage.status;
      if (status.isGranted) {
        return true;
      }
      
      final result = await Permission.storage.request();
      return result.isGranted;
    }
    return true; // iOS doesn't need explicit storage permission
  }
  
  Future<void> _saveFileToDevice(Uint8List fileBytes, String type, String format) async {
    try {
      debugPrint('🔍 File downloaded: ${fileBytes.length} bytes');
      debugPrint('🔍 File type: $type.$format');
      
      // Get the downloads directory with better handling
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        // Try multiple Android download directories
        final possibleDirs = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Downloads',
          '/sdcard/Download',
          '/sdcard/Downloads',
        ];
        
        for (final dirPath in possibleDirs) {
          final dir = Directory(dirPath);
          if (await dir.exists()) {
            downloadsDir = dir;
            break;
          }
        }
        
        // Fallback to external storage
        if (downloadsDir == null) {
          downloadsDir = await getExternalStorageDirectory();
        }
        
        // Final fallback to app documents
        if (downloadsDir == null) {
          downloadsDir = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      } else {
        downloadsDir = await getDownloadsDirectory();
      }
      
      if (downloadsDir == null) {
        throw Exception(AppConstants.msgCouldNotAccessDownloads);
      }
      
      // Create filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${type}_report_$timestamp.$format';
      final filePath = '${downloadsDir.path}/$filename';
      
      // Write file to device
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      
      debugPrint('🔍 File saved to: $filePath');
      
      // Show success dialog with file path
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(AppConstants.msgFileDownloadedTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('File Type: $type.$format'),
              Text('File Size: ${fileBytes.length} bytes'),
              SizedBox(height: AppSizes.spaceSM),
              const Text(AppConstants.msgSavedTo, style: TextStyle(fontWeight: FontWeight.bold)),
              Text(filePath, style: const TextStyle(fontSize: 12, color: AppColors.infoColor)),
              SizedBox(height: AppSizes.spaceMD),
              Container(
                padding: const EdgeInsets.all(AppSizes.spaceSM),
                decoration: BoxDecoration(
                  color: AppColors.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.successColor, size: 20),
                    SizedBox(width: AppSizes.spaceSM),
                    Expanded(
                      child: Text(
                        AppConstants.msgFileSavedInfo,
                        style: const TextStyle(color: AppColors.successColor, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppConstants.buttonOk),
            ),
          ],
        ),
      );
      
    } catch (e) {
      debugPrint('🔍 Error saving file: $e');
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(AppConstants.msgDownloadFailedTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Error: $e'),
              SizedBox(height: AppSizes.spaceMD),
              Container(
                padding: const EdgeInsets.all(AppSizes.spaceSM),
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: AppColors.errorColor, size: 20),
                    SizedBox(width: AppSizes.spaceSM),
                    Expanded(
                      child: Text(
                        AppConstants.msgCheckPermissionsTryAgain,
                        style: const TextStyle(color: AppColors.errorColor, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppConstants.buttonOk),
            ),
          ],
        ),
      );
      
      throw Exception('Failed to save file: $e');
    }
  }
}

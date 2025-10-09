import 'package:flutter/material.dart';
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
          print('WebSocket error: $error');
          setState(() {
            _isConnected = false;
          });
        },
      );
      _startAutoRefresh();
    });
  }

  void _handleWebSocketNotification(WebSocketNotification notification) {
    print('🔔 Reports - Received notification: ${notification.type} - ${notification.message}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${notification.title}: ${notification.message}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.blue,
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
      schoolId = prefs.getInt("schoolId");
      
      if (schoolId != null) {
        print('🔍 Loading report data for schoolId: $schoolId');
        
        // Load real data from services
        final studentCount = await StudentService().getStudentCount(schoolId!.toString());
        final vehicleCount = await VehicleService().getVehicleCount(schoolId!.toString());
        final trips = await TripService().getTripsBySchool(schoolId!);
        
        // Load report data
        await _loadAttendanceReport();
        await _loadDispatchLogsReport();
        await _loadNotificationLogsReport();
        
        setState(() {
          totalStudents = studentCount;
          totalVehicles = vehicleCount;
          totalTrips = trips.length;
          notificationsSent = notificationLogsData.length;
          _loading = false;
        });
        
        print('🔍 Report data loaded successfully');
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      print('🔍 Error loading report data: $e');
      setState(() => _loading = false);
    }
  }
  
  Future<void> _loadAttendanceReport() async {
    try {
      final response = await _reportService.getAttendanceReport(schoolId!, _selectedAttendanceFilter);
      if (response['success'] == true) {
        setState(() {
          attendanceData = response['data'] is List ? response['data'] : [];
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
      if (response['success'] == true) {
        setState(() {
          dispatchLogsData = response['data'] is List ? response['data'] : [];
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
      if (response['success'] == true) {
        setState(() {
          notificationLogsData = response['data'] is List ? response['data'] : [];
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
        title: const Text("Reports Dashboard"),
        actions: [
          // WebSocket connection status
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? Colors.green : Colors.red,
              size: 20,
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
            Tab(text: "Attendance"),
            Tab(text: "Dispatch Logs"),
            Tab(text: "Notifications"),
          ],
        ),
      ),
      body: Column(
        children: [
          // 🔹 Summary Cards Row
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard("Total Students", totalStudents.toString(), Colors.blue),
                      _buildStatCard("Total Vehicles", totalVehicles.toString(), Colors.green),
                      _buildStatCard("Total Trips", totalTrips.toString(), Colors.orange),
                      _buildStatCard("Notifications", notificationsSent.toString(), Colors.purple),
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
                label: Text('Student-wise'),
                selected: _selectedAttendanceFilter == 'student-wise',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedAttendanceFilter = 'student-wise');
                    _loadAttendanceReport();
                  }
                },
              ),
              SizedBox(width: 8),
              FilterChip(
                label: Text('Class-wise'),
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
                      Icon(Icons.school, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No attendance data available', style: TextStyle(color: Colors.grey)),
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
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: percentage >= 75 ? Colors.green : percentage >= 50 ? Colors.orange : Colors.red,
                          child: Text(
                            percentage.toStringAsFixed(0) + '%',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        title: Text(record['studentName'] ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Class: ${record['className']} - ${record['sectionName']}"),
                            Text("Present: $presentDays | Absent: $absentDays | Total: $totalDays"),
                          ],
                        ),
                        trailing: Icon(
                          percentage >= 75 ? Icons.check_circle : percentage >= 50 ? Icons.warning : Icons.error,
                          color: percentage >= 75 ? Colors.green : percentage >= 50 ? Colors.orange : Colors.red,
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
                label: Text('All'),
                selected: _selectedDispatchFilter == 'all',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedDispatchFilter = 'all');
                    _loadDispatchLogsReport();
                  }
                },
              ),
              SizedBox(width: 8),
              FilterChip(
                label: Text('Trip-wise'),
                selected: _selectedDispatchFilter == 'trip-wise',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedDispatchFilter = 'trip-wise');
                    _loadDispatchLogsReport();
                  }
                },
              ),
              SizedBox(width: 8),
              FilterChip(
                label: Text('Vehicle-wise'),
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
                      Icon(Icons.directions_bus, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No dispatch logs available', style: TextStyle(color: Colors.grey)),
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
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(log['tripName'] ?? 'Unknown Trip'),
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
                            fontSize: 12,
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
                label: Text('All'),
                selected: _selectedNotificationFilter == 'all',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedNotificationFilter = 'all');
                    _loadNotificationLogsReport();
                  }
                },
              ),
              SizedBox(width: 8),
              FilterChip(
                label: Text('Sent'),
                selected: _selectedNotificationFilter == 'sent',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedNotificationFilter = 'sent');
                    _loadNotificationLogsReport();
                  }
                },
              ),
              SizedBox(width: 8),
              FilterChip(
                label: Text('Failed'),
                selected: _selectedNotificationFilter == 'failed',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedNotificationFilter = 'failed');
                    _loadNotificationLogsReport();
                  }
                },
              ),
              SizedBox(width: 8),
              FilterChip(
                label: Text('Pending'),
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
                      Icon(Icons.notifications, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No notification logs available', style: TextStyle(color: Colors.grey)),
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
                            color: Colors.white,
                            size: 20,
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
                                  color: Colors.grey,
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
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: () => _exportReport(reportType, 'pdf'),
            icon: Icon(Icons.picture_as_pdf),
            label: Text("Download PDF"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
          SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _exportReport(reportType, 'csv'),
            icon: Icon(Icons.table_chart),
            label: Text("Export CSV"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          ),
        ],
      ),
    );
  }
  
  Future<void> _exportReport(String type, String format) async {
    try {
      if (schoolId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('School ID not found')),
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
              title: const Text('Storage Permission Required'),
              content: const Text(
                'This app needs storage permission to download reports. '
                'Please grant permission in the next dialog.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Grant Permission'),
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
              SnackBar(
                content: Text('Storage permission denied. Cannot download files.'),
                backgroundColor: Colors.red,
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
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Downloading $type report...'),
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
          content: Text('Report downloaded successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download error: $e'),
          backgroundColor: Colors.red,
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
      print('🔍 File downloaded: ${fileBytes.length} bytes');
      print('🔍 File type: $type.$format');
      
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
        throw Exception('Could not access downloads directory');
      }
      
      // Create filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${type}_report_$timestamp.$format';
      final filePath = '${downloadsDir.path}/$filename';
      
      // Write file to device
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      
      print('🔍 File saved to: $filePath');
      
      // Show success dialog with file path
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('File Downloaded Successfully!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('File Type: $type.$format'),
              Text('File Size: ${fileBytes.length} bytes'),
              SizedBox(height: 8),
              Text('Saved to:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(filePath, style: TextStyle(fontSize: 12, color: Colors.blue)),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'File has been saved to your device\'s download folder.',
                        style: TextStyle(color: Colors.green, fontSize: 12),
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
              child: Text('OK'),
            ),
          ],
        ),
      );
      
    } catch (e) {
      print('🔍 Error saving file: $e');
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Download Failed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Error: $e'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please check your device permissions and try again.',
                        style: TextStyle(color: Colors.red, fontSize: 12),
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
              child: Text('OK'),
            ),
          ],
        ),
      );
      
      throw Exception('Failed to save file: $e');
    }
  }
}

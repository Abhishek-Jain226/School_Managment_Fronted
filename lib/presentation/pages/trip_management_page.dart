import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/trip.dart';
import '../../services/driver_service.dart';
import 'student_attendance_page.dart';
import 'notification_page.dart';

class TripManagementPage extends StatefulWidget {
  const TripManagementPage({super.key});

  @override
  State<TripManagementPage> createState() => _TripManagementPageState();
}

class _TripManagementPageState extends State<TripManagementPage> {
  final DriverService _driverService = DriverService();
  List<Trip> _trips = [];
  bool _isLoading = true;
  String? _error;
  int? _driverId;
  String _selectedFilter = 'All';

  final List<String> _filterOptions = ['All', 'Morning', 'Afternoon', 'Not Started', 'In Progress', 'Completed'];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      _driverId = prefs.getInt('driverId');
      
      if (_driverId == null) {
        setState(() {
          _error = 'Driver ID not found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final trips = await _driverService.getAssignedTrips(_driverId!);
      setState(() {
        _trips = trips;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load trips: $e';
        _isLoading = false;
      });
    }
  }

  List<Trip> get _filteredTrips {
    if (_selectedFilter == 'All') return _trips;
    
    return _trips.where((trip) {
      switch (_selectedFilter) {
        case 'Morning':
          return trip.tripType == 'MORNING';
        case 'Afternoon':
          return trip.tripType == 'AFTERNOON';
        case 'Not Started':
          return trip.tripStatus == 'NOT_STARTED';
        case 'In Progress':
          return trip.tripStatus == 'IN_PROGRESS';
        case 'Completed':
          return trip.tripStatus == 'COMPLETED';
        default:
          return true;
      }
    }).toList();
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'NOT_STARTED':
        return Colors.orange;
      case 'IN_PROGRESS':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'NOT_STARTED':
        return Icons.schedule;
      case 'IN_PROGRESS':
        return Icons.play_circle;
      case 'COMPLETED':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Future<void> _startTrip(Trip trip) async {
    try {
      await _driverService.startTrip(_driverId!, trip.tripId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trip "${trip.tripName}" started successfully!')),
      );
      _loadTrips();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start trip: $e')),
      );
    }
  }

  Future<void> _endTrip(Trip trip) async {
    try {
      await _driverService.endTrip(_driverId!, trip.tripId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trip "${trip.tripName}" ended successfully!')),
      );
      _loadTrips();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to end trip: $e')),
      );
    }
  }

  void _navigateToTripDetails(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripDetailsPage(trip: trip),
      ),
    );
  }

  Widget _buildTripCard(Trip trip) {
    final statusColor = _getStatusColor(trip.tripStatus);
    final statusIcon = _getStatusIcon(trip.tripStatus);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToTripDetails(trip),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.tripName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${trip.tripType} - ${trip.scheduledTime ?? 'No time set'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Text(
                      trip.tripStatus ?? 'Unknown',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.directions_bus,
                      'Vehicle',
                      trip.vehicleNumber,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.school,
                      'School',
                      trip.schoolName,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.group,
                      'Students',
                      '${trip.totalStudents}',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.person_add,
                      'Picked',
                      '${trip.studentsPickedUp}',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.person_remove,
                      'Dropped',
                      '${trip.studentsDropped}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (trip.tripStatus == 'NOT_STARTED') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _startTrip(trip),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Trip'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (trip.tripStatus == 'IN_PROGRESS') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _endTrip(trip),
                        icon: const Icon(Icons.stop),
                        label: const Text('End Trip'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateToTripDetails(trip),
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Details'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrips,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTrips,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filter Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text(
                            'Filter:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedFilter,
                              isExpanded: true,
                              items: _filterOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedFilter = newValue!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Trips List
                    Expanded(
                      child: _filteredTrips.isEmpty
                          ? const Center(
                              child: Text(
                                'No trips found for the selected filter',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadTrips,
                              child: ListView.builder(
                                itemCount: _filteredTrips.length,
                                itemBuilder: (context, index) {
                                  return _buildTripCard(_filteredTrips[index]);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class TripDetailsPage extends StatefulWidget {
  final Trip trip;

  const TripDetailsPage({super.key, required this.trip});

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  final DriverService _driverService = DriverService();
  Trip? _tripDetails;
  bool _isLoading = true;
  String? _error;
  int? _driverId;

  @override
  void initState() {
    super.initState();
    _loadTripDetails();
  }

  Future<void> _loadTripDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      _driverId = prefs.getInt('driverId');
      
      if (_driverId == null) {
        setState(() {
          _error = 'Driver ID not found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final tripDetails = await _driverService.getTripStudents(_driverId!, widget.trip.tripId);
      setState(() {
        _tripDetails = tripDetails;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load trip details: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip.tripName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTripDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTripDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _tripDetails == null
                  ? const Center(child: Text('No trip details available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Trip Information Card
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Trip Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDetailRow('Trip Name', _tripDetails!.tripName),
                                  _buildDetailRow('Trip Type', _tripDetails!.tripType ?? 'N/A'),
                                  _buildDetailRow('Scheduled Time', _tripDetails!.scheduledTime ?? 'N/A'),
                                  _buildDetailRow('Status', _tripDetails!.tripStatus ?? 'Unknown'),
                                  _buildDetailRow('Vehicle', _tripDetails!.vehicleNumber),
                                  _buildDetailRow('School', _tripDetails!.schoolName),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Student Statistics
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Student Statistics',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          'Total',
                                          '${_tripDetails!.totalStudents}',
                                          Icons.group,
                                          Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildStatCard(
                                          'Picked Up',
                                          '${_tripDetails!.studentsPickedUp}',
                                          Icons.person_add,
                                          Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          'Dropped',
                                          '${_tripDetails!.studentsDropped}',
                                          Icons.person_remove,
                                          Colors.orange,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildStatCard(
                                          'Absent',
                                          '${_tripDetails!.studentsAbsent}',
                                          Icons.person_off,
                                          Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Students List
                          const Text(
                            'Students',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StudentAttendancePage(trip: _tripDetails!),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.checklist),
                                  label: const Text('Mark Attendance'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const NotificationPage(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.notifications),
                                  label: const Text('Send Notification'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          if (_tripDetails!.students.isEmpty)
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No students assigned to this trip'),
                              ),
                            )
                          else
                            ..._tripDetails!.students.map((student) => _buildStudentCard(student)),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(TripStudent student) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.schedule;
    
    switch (student.attendanceStatus) {
      case 'PENDING':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'PICKED_UP':
        statusColor = Colors.blue;
        statusIcon = Icons.person_add;
        break;
      case 'DROPPED':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'ABSENT':
        statusColor = Colors.red;
        statusIcon = Icons.person_off;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(student.studentName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${student.className} - ${student.sectionName}'),
            Text('Pickup: ${student.pickupLocation}'),
            Text('Drop: ${student.dropLocation}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              student.attendanceStatus,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              'Order: ${student.pickupOrder}',
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentAttendancePage(
                trip: _tripDetails!,
                selectedStudent: student,
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/vehicle_owner_service.dart';

class VehicleOwnerTripAssignmentPage extends StatefulWidget {
  const VehicleOwnerTripAssignmentPage({super.key});

  @override
  State<VehicleOwnerTripAssignmentPage> createState() => _VehicleOwnerTripAssignmentPageState();
}

class _VehicleOwnerTripAssignmentPageState extends State<VehicleOwnerTripAssignmentPage> {
  final VehicleOwnerService _vehicleOwnerService = VehicleOwnerService();
  
  int? _ownerId;
  bool _isLoading = true;
  bool _isLoadingStudents = false;
  bool _isLoadingTrips = false;
  
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _tripStudents = [];
  
  int? _selectedTripId;
  String? _selectedTripName;

  @override
  void initState() {
    super.initState();
    _loadOwnerId();
  }

  Future<void> _loadOwnerId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ownerId = prefs.getInt('ownerId');
    });
    
    if (_ownerId != null) {
      _loadData();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
    if (_ownerId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await Future.wait([
        _loadStudents(),
        _loadTrips(),
      ]);
    } catch (e) {
      print('🔍 Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudents() async {
    if (_ownerId == null) return;
    
    setState(() => _isLoadingStudents = true);
    
    try {
      final response = await _vehicleOwnerService.getStudentsForTripAssignment(_ownerId!);
      print('🔍 Students response: $response');
      
      if (response['success'] == true) {
        setState(() {
          _students = List<Map<String, dynamic>>.from(response['data'] ?? []);
        });
        print('🔍 Loaded ${_students.length} students');
      }
    } catch (e) {
      print('🔍 Error loading students: $e');
    } finally {
      setState(() => _isLoadingStudents = false);
    }
  }

  Future<void> _loadTrips() async {
    if (_ownerId == null) return;
    
    setState(() => _isLoadingTrips = true);
    
    try {
      final response = await _vehicleOwnerService.getTripsByOwner(_ownerId!);
      print('🔍 Trips response: $response');
      
      if (response['success'] == true) {
        setState(() {
          _trips = List<Map<String, dynamic>>.from(response['data'] ?? []);
        });
        print('🔍 Loaded ${_trips.length} trips');
      } else {
        print('🔍 Trips API failed: ${response['message']}');
        setState(() {
          _trips = [];
        });
      }
    } catch (e) {
      print('🔍 Error loading trips: $e');
      setState(() {
        _trips = [];
      });
    } finally {
      setState(() => _isLoadingTrips = false);
    }
  }

  Future<void> _loadTripStudents(int tripId) async {
    if (_ownerId == null) return;
    
    try {
      final response = await _vehicleOwnerService.getTripStudents(_ownerId!, tripId);
      print('🔍 Trip students response: $response');
      
      if (response['success'] == true) {
        setState(() {
          _tripStudents = List<Map<String, dynamic>>.from(response['data'] ?? []);
        });
        print('🔍 Loaded ${_tripStudents.length} students for trip $tripId');
      }
    } catch (e) {
      print('🔍 Error loading trip students: $e');
    }
  }

  Future<void> _assignStudentToTrip(int studentId) async {
    if (_ownerId == null || _selectedTripId == null) return;
    
    try {
      final response = await _vehicleOwnerService.assignStudentToTrip(_ownerId!, _selectedTripId!, studentId);
      print('🔍 Assign student response: $response');
      
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student assigned to trip successfully!')),
        );
        
        // Reload trip students
        await _loadTripStudents(_selectedTripId!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response['message']}')),
        );
      }
    } catch (e) {
      print('🔍 Error assigning student: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error assigning student: $e')),
      );
    }
  }

  Future<void> _removeStudentFromTrip(int studentId) async {
    if (_ownerId == null || _selectedTripId == null) return;
    
    try {
      final response = await _vehicleOwnerService.removeStudentFromTrip(_ownerId!, _selectedTripId!, studentId);
      print('🔍 Remove student response: $response');
      
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student removed from trip successfully!')),
        );
        
        // Reload trip students
        await _loadTripStudents(_selectedTripId!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response['message']}')),
        );
      }
    } catch (e) {
      print('🔍 Error removing student: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing student: $e')),
      );
    }
  }

  void _showAssignStudentDialog() {
    if (_selectedTripId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a trip first')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Student to $_selectedTripName'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _isLoadingStudents
              ? const Center(child: CircularProgressIndicator())
              : _students.isEmpty
                  ? const Center(child: Text('No students available'))
                  : ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final studentName = '${student['firstName']} ${student['middleName'] ?? ''} ${student['lastName']}'.trim();
                        final isAssigned = _tripStudents.any((ts) => ts['studentId'] == student['studentId']);
                        
                        return ListTile(
                          title: Text(studentName),
                          subtitle: Text('Grade: ${student['grade']} - ${student['section']}'),
                          trailing: isAssigned
                              ? const Icon(Icons.check, color: Colors.green)
                              : IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _assignStudentToTrip(student['studentId']);
                                  },
                                ),
                        );
                      },
                    ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Trip Assignment'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ownerId == null
              ? const Center(child: Text('Owner ID not found'))
              : Column(
                  children: [
                    // Trip Selection
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Trip:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _isLoadingTrips
                              ? const CircularProgressIndicator()
                              : _trips.isEmpty
                                  ? const Text('No trips available. Please create trips first.')
                                  : DropdownButtonFormField<int>(
                                      value: _selectedTripId,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: 'Select a trip',
                                      ),
                                      items: _trips.map((trip) {
                                        return DropdownMenuItem<int>(
                                          value: trip['tripId'],
                                          child: Text('${trip['tripName']} - ${trip['vehicleNumber']}'),
                                        );
                                      }).toList(),
                                      onChanged: (tripId) {
                                        if (tripId != null) {
                                          final trip = _trips.firstWhere((t) => t['tripId'] == tripId);
                                          setState(() {
                                            _selectedTripId = tripId;
                                            _selectedTripName = trip['tripName'];
                                          });
                                          _loadTripStudents(tripId);
                                        }
                                      },
                                    ),
                        ],
                      ),
                    ),
                    
                    // Trip Students List
                    if (_selectedTripId != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Students in $_selectedTripName:',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showAssignStudentDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Assign Student'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _tripStudents.isEmpty
                            ? const Center(child: Text('No students assigned to this trip'))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _tripStudents.length,
                                itemBuilder: (context, index) {
                                  final tripStudent = _tripStudents[index];
                                  final studentName = '${tripStudent['firstName']} ${tripStudent['middleName'] ?? ''} ${tripStudent['lastName']}'.trim();
                                  
                                  return Card(
                                    child: ListTile(
                                      title: Text(studentName),
                                      subtitle: Text('Grade: ${tripStudent['grade']} - ${tripStudent['section']}'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                                        onPressed: () => _removeStudentFromTrip(tripStudent['studentId']),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ] else ...[
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Please select a trip to manage student assignments',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}

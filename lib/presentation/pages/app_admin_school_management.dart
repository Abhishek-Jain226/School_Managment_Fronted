import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/app_admin_service.dart';

class AppAdminSchoolManagementPage extends StatefulWidget {
  const AppAdminSchoolManagementPage({super.key});

  @override
  State<AppAdminSchoolManagementPage> createState() => _AppAdminSchoolManagementPageState();
}

class _AppAdminSchoolManagementPageState extends State<AppAdminSchoolManagementPage> {
  List<dynamic> schools = [];
  Map<String, dynamic> statistics = {};
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      // Load schools and statistics in parallel
      final schoolsResponse = await AppAdminService.getAllSchools();
      final statsResponse = await AppAdminService.getSchoolStatistics();
      
      if (schoolsResponse['success'] == true) {
        setState(() {
          schools = List<dynamic>.from(schoolsResponse['data']['schools'] ?? []);
        });
      }
      
      if (statsResponse['success'] == true) {
        setState(() {
          statistics = statsResponse['data'] ?? {};
        });
      }
    } catch (e) {
      _showSnackBar('Error loading data: $e', Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _searchSchools() async {
    if (_searchController.text.trim().isEmpty) {
      _loadData();
      return;
    }

    setState(() => isLoading = true);
    
    try {
      final response = await AppAdminService.searchSchools(_searchController.text.trim());
      
      if (response['success'] == true) {
        setState(() {
          schools = List<dynamic>.from(response['data']['schools'] ?? []);
          searchQuery = _searchController.text.trim();
        });
      } else {
        _showSnackBar(response['message'] ?? 'Search failed', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error searching schools: $e', Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateSchoolStatus(int schoolId, bool isActive, String schoolName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedBy = prefs.getString('userName') ?? 'AppAdmin';
      
      final response = await AppAdminService.updateSchoolStatus(schoolId, isActive, updatedBy);
      
      if (response['success'] == true) {
        _showSnackBar(response['message'] ?? 'Status updated successfully', Colors.green);
        _loadData(); // Refresh data
      } else {
        _showSnackBar(response['message'] ?? 'Failed to update status', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error updating status: $e', Colors.red);
    }
  }

  Future<void> _updateSchoolDates(int schoolId, String? startDate, String? endDate, String schoolName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedBy = prefs.getString('userName') ?? 'AppAdmin';
      
      final response = await AppAdminService.updateSchoolDates(schoolId, startDate, endDate, updatedBy);
      
      if (response['success'] == true) {
        _showSnackBar(response['message'] ?? 'Dates updated successfully', Colors.green);
        _loadData(); // Refresh data
      } else {
        _showSnackBar(response['message'] ?? 'Failed to update dates', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error updating dates: $e', Colors.red);
    }
  }


  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  void _showDatePickerDialog(int schoolId, String schoolName, String? currentStartDate, String? currentEndDate) {
    DateTime? startDate;
    DateTime? endDate;
    
    // Parse current dates if they exist
    if (currentStartDate != null) {
      startDate = DateTime.tryParse(currentStartDate);
    }
    if (currentEndDate != null) {
      endDate = DateTime.tryParse(currentEndDate);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Update Dates for $schoolName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Start Date'),
                subtitle: Text(startDate != null ? '${startDate!.day}/${startDate!.month}/${startDate!.year}' : 'Not set'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      startDate = picked;
                    });
                  }
                },
              ),
              ListTile(
                title: const Text('End Date'),
                subtitle: Text(endDate != null ? '${endDate!.day}/${endDate!.month}/${endDate!.year}' : 'Not set'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? DateTime.now(),
                    firstDate: startDate ?? DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      endDate = picked;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                final startDateStr = startDate != null ? startDate!.toIso8601String().split('T')[0] : null;
                final endDateStr = endDate != null ? endDate!.toIso8601String().split('T')[0] : null;
                _updateSchoolDates(schoolId, startDateStr, endDateStr, schoolName);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Management'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistics Cards
                if (statistics.isNotEmpty) _buildStatisticsCards(),
                
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search schools by name, city, or state...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _searchSchools(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _searchSchools,
                        child: const Text('Search'),
                      ),
                      if (searchQuery.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _loadData();
                            setState(() => searchQuery = '');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                    ],
                  ),
                ),
                
                // Schools List
                Expanded(
                  child: schools.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                searchQuery.isNotEmpty
                                    ? 'No schools found for "$searchQuery"'
                                    : 'No schools found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: schools.length,
                          itemBuilder: (context, index) {
                            final school = schools[index];
                            return _buildSchoolCard(school);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatisticsCards() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Schools',
              '${statistics['totalSchools'] ?? 0}',
              Icons.school,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Active',
              '${statistics['activeSchools'] ?? 0}',
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Inactive',
              '${statistics['inactiveSchools'] ?? 0}',
              Icons.cancel,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolCard(Map<String, dynamic> school) {
    final isActive = school['isActive'] == true;
    final startDate = school['startDate'];
    final endDate = school['endDate'];
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        school['schoolName'] ?? 'Unknown School',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${school['city'] ?? ''}, ${school['state'] ?? ''}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Date Information
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    startDate != null && endDate != null
                        ? 'Session: ${_formatDate(startDate)} to ${_formatDate(endDate)}'
                        : startDate != null
                            ? 'Starts: ${_formatDate(startDate)}'
                            : endDate != null
                                ? 'Ends: ${_formatDate(endDate)}'
                                : 'No dates set',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateSchoolStatus(
                      school['schoolId'],
                      !isActive,
                      school['schoolName'] ?? 'School',
                    ),
                    icon: Icon(isActive ? Icons.pause : Icons.play_arrow),
                    label: Text(isActive ? 'Deactivate' : 'Activate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? Colors.orange : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDatePickerDialog(
                      school['schoolId'],
                      school['schoolName'] ?? 'School',
                      startDate,
                      endDate,
                    ),
                    icon: const Icon(Icons.edit_calendar),
                    label: const Text('Set Dates'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            // Resend Activation Link Button (only for schools without active users)
            if (school['hasActiveUser'] != true) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _resendActivationLink(
                    school['schoolId'],
                    school['schoolName'] ?? 'School',
                  ),
                  icon: const Icon(Icons.email),
                  label: const Text('Resend Activation Link'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _resendActivationLink(int schoolId, String schoolName) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resend Activation Link'),
        content: Text('Are you sure you want to resend the activation link for $schoolName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Resend'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Sending activation link...'),
          ],
        ),
      ),
    );

    try {
      // Get current user info for updatedBy parameter
      final prefs = await SharedPreferences.getInstance();
      final currentUser = prefs.getString('userName') ?? 'AppAdmin';

      final response = await AppAdminService.resendActivationLink(
        schoolId,
        currentUser,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (response['success'] == true) {
        _showSnackBar(
          response['message'] ?? 'Activation link sent successfully',
          Colors.green,
        );
      } else {
        _showSnackBar(
          response['message'] ?? 'Failed to send activation link',
          Colors.red,
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      _showSnackBar('Error sending activation link: $e', Colors.red);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

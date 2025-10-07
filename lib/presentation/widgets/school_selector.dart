import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/vehicle_owner_service.dart';

class SchoolSelector extends StatefulWidget {
  final Function(int? schoolId, String? schoolName) onSchoolSelected;
  final int? currentSchoolId;

  const SchoolSelector({
    super.key,
    required this.onSchoolSelected,
    this.currentSchoolId,
  });

  @override
  State<SchoolSelector> createState() => _SchoolSelectorState();
}

class _SchoolSelectorState extends State<SchoolSelector> {
  final VehicleOwnerService _vehicleOwnerService = VehicleOwnerService();
  List<Map<String, dynamic>> _schools = [];
  bool _isLoading = false;
  int? _selectedSchoolId;
  String? _selectedSchoolName;

  @override
  void initState() {
    super.initState();
    _selectedSchoolId = widget.currentSchoolId;
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("userId");
      
      if (userId == null) {
        _showError("User not found. Please login again.");
        return;
      }

      // Get vehicle owner by user ID
      final ownerResponse = await _vehicleOwnerService.getOwnerByUserId(userId);
      
      if (ownerResponse['success'] == true) {
        final ownerData = ownerResponse['data'];
        final ownerId = ownerData['ownerId'];
        
        // Get associated schools
        final schoolsResponse = await _vehicleOwnerService.getAssociatedSchools(ownerId);
        
        if (schoolsResponse['success'] == true) {
          final schoolsData = schoolsResponse['data'];
          setState(() {
            _schools = List<Map<String, dynamic>>.from(schoolsData['schools'] ?? []);
            if (_schools.isNotEmpty && _selectedSchoolId == null) {
              _selectedSchoolId = _schools.first['schoolId'];
              _selectedSchoolName = _schools.first['schoolName'];
              widget.onSchoolSelected(_selectedSchoolId, _selectedSchoolName);
            }
          });
        } else {
          _showError("Failed to load schools: ${schoolsResponse['message']}");
        }
      } else {
        _showError("Failed to load owner data: ${ownerResponse['message']}");
      }
    } catch (e) {
      _showError("Error loading schools: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSchoolSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Select School",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Schools List
            if (_schools.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    "No schools associated with your account",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                itemCount: _schools.length,
                itemBuilder: (context, index) {
                  final school = _schools[index];
                  final schoolId = school['schoolId'];
                  final schoolName = school['schoolName'];
                  final schoolAddress = school['schoolAddress'];
                  final isSelected = _selectedSchoolId == schoolId;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isSelected ? Colors.blue.shade50 : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected ? Colors.blue : Colors.grey,
                        child: Text(
                          schoolName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        schoolName,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.blue : Colors.black,
                        ),
                      ),
                      subtitle: Text(schoolAddress ?? ''),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.blue)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedSchoolId = schoolId;
                          _selectedSchoolName = schoolName;
                        });
                        
                        // Save to SharedPreferences
                        SharedPreferences.getInstance().then((prefs) {
                          prefs.setInt('currentSchoolId', schoolId);
                          prefs.setString('currentSchoolName', schoolName);
                        });
                        
                        widget.onSchoolSelected(schoolId, schoolName);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_schools.isEmpty) {
      return const Text(
        "No Schools",
        style: TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return GestureDetector(
      onTap: _showSchoolSelector,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school,
              size: 16,
              color: Colors.blue.shade700,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _selectedSchoolName ?? "Select School",
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: Colors.blue.shade700,
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import '../../services/vehicle_service.dart';

class RequestVehicleAssignmentPage extends StatefulWidget {
  const RequestVehicleAssignmentPage({super.key});

  @override
  State<RequestVehicleAssignmentPage> createState() =>
      _RequestVehicleAssignmentPageState();
}

class _RequestVehicleAssignmentPageState
    extends State<RequestVehicleAssignmentPage> {
  String? _selectedVehicle;
  List<Map<String, dynamic>> _vehicles = [];
  bool _loading = true;
  final _service = VehicleService();

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final ownerId = prefs.getInt(AppConstants.keyOwnerId); // Vehicle Owner's ID
    final schoolId = prefs.getInt(AppConstants.keySchoolId); // Current School ID

    debugPrint("🔹 Fetching vehicles for ownerId: $ownerId, schoolId: $schoolId");

    if (ownerId == null || schoolId == null) {
      debugPrint("❌ Owner ID or School ID not found in SharedPreferences");
      setState(() => _loading = false);
      return;
    }

    // 🔹 Fetch ALL vehicles by ownerId
    final res = await _service.getVehiclesByOwner(ownerId);

    debugPrint("🔹 Vehicles API Response: $res");

    if (res[AppConstants.keySuccess] == true && res[AppConstants.keyData] != null) {
      // Handle both direct list and nested list response
      List vehiclesList;
      if (res[AppConstants.keyData] is List) {
        vehiclesList = res[AppConstants.keyData];
      } else if (res[AppConstants.keyData] is Map && res[AppConstants.keyData]['vehicles'] != null) {
        vehiclesList = res[AppConstants.keyData]['vehicles'];
      } else {
        vehiclesList = [];
      }

      debugPrint("🔹 Total vehicles found: ${vehiclesList.length}");

      // 🔹 Fetch ALL requests (PENDING + APPROVED + REJECTED) to filter out already assigned vehicles
      final requestsRes = await VehicleService().getAllRequestsBySchool(schoolId);
      List<int> assignedVehicleIds = [];
      
      if (requestsRes[AppConstants.keySuccess] == true && requestsRes[AppConstants.keyData] != null) {
        final requests = requestsRes[AppConstants.keyData] as List;
        
        debugPrint("🔹 Total requests found: ${requests.length}");
        debugPrint("🔹 Request statuses: ${requests.map((r) => r['status']).toList()}");
        
        // Filter vehicles that have PENDING or APPROVED requests for this school
        for (var req in requests) {
          final status = req['status'] as String?;
          final vehicleData = req['vehicle']; // Backend sends nested 'vehicle' object
          
          debugPrint("🔹 Request: vehicleData=$vehicleData, status=$status");
          
          if (status == 'PENDING' || status == 'APPROVED') {
            if (vehicleData is Map && vehicleData['vehicleId'] != null) {
              final vehicleId = vehicleData['vehicleId'] as int;
              assignedVehicleIds.add(vehicleId);
              debugPrint("🔹 Added to filter list: vehicleId=$vehicleId");
            }
          }
        }
        
        debugPrint("🔹 Already assigned/pending vehicle IDs: $assignedVehicleIds");
      }

      // Filter out already assigned vehicles
      final unassignedVehicles = vehiclesList.where((v) {
        final vehicleId = v['vehicleId'] as int;
        return !assignedVehicleIds.contains(vehicleId);
      }).toList();

      debugPrint("🔹 Unassigned vehicles: ${unassignedVehicles.length}");

      setState(() {
        _vehicles = List<Map<String, dynamic>>.from(unassignedVehicles);
        _loading = false;
      });
    } else {
      debugPrint("❌ Failed to fetch vehicles: ${res[AppConstants.keyMessage]}");
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.msgPleaseSelectVehicle)),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final schoolId = prefs.getInt(AppConstants.keySchoolId);
    final ownerId = prefs.getInt(AppConstants.keyOwnerId);

    if (schoolId == null || ownerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.msgMissingSchoolOrOwner)),
      );
      return;
    }

    final req = {
      "schoolId": schoolId,
      "vehicleId": int.parse(_selectedVehicle!),
      "ownerId": ownerId,
      "createdBy": prefs.getString(AppConstants.keyUserName) ?? "owner"
    };

    debugPrint("📤 Sending Request Body: $req");

    final res = await _service.assignVehicleRequest(req);

    debugPrint("✅ Request API Response: $res");

    if (!mounted) return;
    if (res[AppConstants.keySuccess] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res[AppConstants.keyMessage] ?? AppConstants.msgRequestSubmitted)),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res[AppConstants.keyMessage] ?? AppConstants.msgFailedToSubmitRequest)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.labelRequestVehicleAssignment)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? const Center(child: Text(AppConstants.msgNoVehiclesFound))
              : Padding(
                  padding: const EdgeInsets.all(AppConstants.requestVehiclePadding),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedVehicle,
                        items: _vehicles
                            .map(
                              (v) => DropdownMenuItem(
                                value: v['vehicleId'].toString(),
                                child: Text(v['vehicleNumber'] ??
                                    "Vehicle ${v['vehicleId']}"),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedVehicle = val),
                        decoration: const InputDecoration(
                          labelText: AppConstants.labelSelectVehicle,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppConstants.requestVehicleSpacingLG),
                      ElevatedButton(
                        onPressed: _submit,
                        child: const Text(AppConstants.labelSubmitRequest),
                      ),
                    ],
                  ),
                ),
    );
  }
}

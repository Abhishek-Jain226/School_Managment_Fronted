import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/vehicle_service.dart';

class PendingVehicleRequestsPage extends StatefulWidget {
  const PendingVehicleRequestsPage({super.key});

  @override
  State<PendingVehicleRequestsPage> createState() =>
      _PendingVehicleRequestsPageState();
}

class _PendingVehicleRequestsPageState
    extends State<PendingVehicleRequestsPage> {
  final _service = VehicleService();
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final schoolId = prefs.getInt("schoolId");
    if (schoolId == null) return;

    final res = await _service.getPendingRequests(schoolId);
    if (res['success'] == true && res['data'] != null) {
      setState(() {
        _requests = List<Map<String, dynamic>>.from(res['data']);
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(int requestId, String action) async {
    final prefs = await SharedPreferences.getInstance();
    final adminName = prefs.getString("userName") ?? "Admin";

    final res = await _service.updateRequestStatus(requestId, action, adminName);

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(res['message'] ?? "Error")));
    _fetchRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pending Vehicle Requests")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text("No pending requests"))
              : ListView.builder(
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text("Vehicle: ${req['vehicle']['vehicleNumber']}"),
                        subtitle: Text(
                            "Owner: ${req['owner']['name']} | Status: ${req['status']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () =>
                                  _updateStatus(req['requestId'], "approve"),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () =>
                                  _updateStatus(req['requestId'], "reject"),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

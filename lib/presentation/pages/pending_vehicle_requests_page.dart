import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import '../../services/vehicle_service.dart';

class PendingVehicleRequestsPage extends StatefulWidget {
  const PendingVehicleRequestsPage({Key? key}) : super(key: key);

  @override
  State<PendingVehicleRequestsPage> createState() =>
      _PendingVehicleRequestsPageState();
}

class _PendingVehicleRequestsPageState
    extends State<PendingVehicleRequestsPage> {
  final VehicleService _service = VehicleService();
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final schoolId = prefs.getInt(AppConstants.keySchoolId);

    if (schoolId == null) {
      setState(() => _loading = false);
      return;
    }

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

  Future<void> _handleAction(int requestId, String action) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString(AppConstants.keyUserName) ?? AppConstants.labelAdmin;

    final res =
        await _service.updateRequestStatus(requestId, action, userName);

    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                action == 'approve' ? AppConstants.msgRequestApproved : AppConstants.msgRequestRejected)),
      );
      _loadRequests(); // Reload list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? AppConstants.msgActionFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.labelPendingVehicleRequests)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(
                  child: Text(AppConstants.labelNoPendingRequests),
                )
              : RefreshIndicator(
                  onRefresh: _loadRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.pendingRequestsPadding),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final req = _requests[index];
                      final vehicleInfo = req['vehicle'] as Map<String, dynamic>?;
                      final ownerInfo = req['owner'] as Map<String, dynamic>?;
                      final status = req['status'] as String? ?? 'PENDING';

                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSizes.pendingRequestsCardMargin),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.pendingRequestsCardPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Vehicle Info
                              Row(
                                children: [
                                  const Icon(Icons.directions_bus,
                                      color: AppColors.primaryColor),
                                  const SizedBox(width: AppSizes.pendingRequestsSpacing),
                                  Expanded(
                                    child: Text(
                                      "${AppConstants.labelVehiclePrefix}${vehicleInfo?['vehicleNumber'] ?? AppConstants.labelNA} (${vehicleInfo?['registrationNumber'] ?? AppConstants.labelNA})",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: AppSizes.pendingRequestsTitleFontSize,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.pendingRequestsSpacing),

                              // Owner Info
                              Row(
                                children: [
                                  const Icon(Icons.person,
                                      color: AppColors.statusSuccess),
                                  const SizedBox(width: AppSizes.pendingRequestsSpacing),
                                  Expanded(
                                    child: Text(
                                      "${AppConstants.labelOwnerPrefix}${ownerInfo?['name'] ?? AppConstants.labelNA}",
                                      style: const TextStyle(fontSize: AppSizes.pendingRequestsTextFontSize),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.pendingRequestsSpacing),

                              // Vehicle Type
                              Row(
                                children: [
                                  const Icon(Icons.category,
                                      color: AppColors.statusWarning, size: AppSizes.pendingRequestsIconSize),
                                  const SizedBox(width: AppSizes.pendingRequestsSpacing),
                                  Text(
                                    "${AppConstants.labelTypePrefix}${vehicleInfo?['vehicleType'] ?? AppConstants.labelNA}",
                                    style: const TextStyle(fontSize: AppSizes.pendingRequestsTextFontSize),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.pendingRequestsSpacing),

                              // Status Badge
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSizes.pendingRequestsBadgePaddingH, vertical: AppSizes.pendingRequestsBadgePaddingV),
                                    decoration: BoxDecoration(
                                      color: status == AppConstants.statusPending
                                          ? AppColors.statusWarning.withValues(alpha: AppSizes.pendingRequestsBadgeOpacity)
                                          : status == AppConstants.statusApproved
                                              ? AppColors.statusSuccess.withValues(alpha: AppSizes.pendingRequestsBadgeOpacity)
                                              : AppColors.errorColor.withValues(alpha: AppSizes.pendingRequestsBadgeOpacity),
                                      borderRadius: BorderRadius.circular(AppSizes.pendingRequestsBadgeRadius),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: status == AppConstants.statusPending
                                            ? AppColors.statusWarning
                                            : status == AppConstants.statusApproved
                                                ? AppColors.statusSuccess
                                                : AppColors.errorColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.pendingRequestsSpacingSM),

                              // Action Buttons (only for PENDING)
                              if (status == AppConstants.statusPending)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _handleAction(
                                          req['requestId'], 'reject'),
                                      icon: const Icon(Icons.close,
                                          color: AppColors.errorColor),
                                      label: const Text(AppConstants.labelReject,
                                          style: TextStyle(color: AppColors.errorColor)),
                                    ),
                                    const SizedBox(width: AppSizes.pendingRequestsButtonSpacing),
                                    ElevatedButton.icon(
                                      onPressed: () => _handleAction(
                                          req['requestId'], 'approve'),
                                      icon: const Icon(Icons.check),
                                      label: const Text(AppConstants.labelApprove),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.statusSuccess,
                                        foregroundColor: AppColors.textWhite,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

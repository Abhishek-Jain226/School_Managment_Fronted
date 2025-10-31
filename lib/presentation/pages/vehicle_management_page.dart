import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import '../../data/models/vehicle.dart';
import '../../services/vehicle_service.dart';

class VehicleManagementPage extends StatefulWidget {
  const VehicleManagementPage({super.key});

  @override
  State<VehicleManagementPage> createState() => _VehicleManagementPageState();
}

class _VehicleManagementPageState extends State<VehicleManagementPage> {
  final VehicleService _vehicleService = VehicleService();
  List<Vehicle> vehicles = [];
  bool _loading = true;
  int? schoolId;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      schoolId = prefs.getInt(AppConstants.keySchoolId);
      
      if (schoolId != null) {
        final result = await _vehicleService.getVehiclesBySchool(schoolId!);
        setState(() {
          vehicles = result;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        _showErrorSnackBar(AppConstants.msgSchoolIdNotFoundPrefs);
      }
    } catch (e) {
      setState(() => _loading = false);
      _showErrorSnackBar('${AppConstants.msgErrorLoadingVehicles}: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.errorColor,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.labelVehicleReports),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVehicles,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Information Card
                Card(
                  margin: const EdgeInsets.all(AppSizes.marginMD),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(AppConstants.labelVehicleInformation, style: TextStyle(fontSize: AppSizes.textXL, fontWeight: FontWeight.bold)),
                        SizedBox(height: AppSizes.marginSM),
                        Text(AppConstants.textVehicleInfoDescription, style: TextStyle(fontSize: AppSizes.textSM, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
                
                // Statistics Card
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: AppSizes.marginMD),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMD),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(AppConstants.labelTotalVehicles, vehicles.length.toString(), Icons.directions_bus),
                        _buildStatItem(AppConstants.labelActiveVehicles, vehicles.where((v) => v.isActive ?? false).length.toString(), Icons.check_circle),
                        _buildStatItem(AppConstants.labelInTransit, '0', Icons.local_shipping),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: AppSizes.marginMD),
                
                // Vehicles List
                Expanded(
                  child: vehicles.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_bus, size: AppSizes.iconXL, color: AppColors.textMuted),
                              SizedBox(height: AppSizes.marginMD),
                              Text(AppConstants.emptyStateNoVehicles, style: TextStyle(fontSize: AppSizes.textXL, color: AppColors.textMuted)),
                              SizedBox(height: AppSizes.marginSM),
                              Text(AppConstants.emptyStateNoVehiclesSub, style: TextStyle(color: AppColors.textMuted)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMD),
                          itemCount: vehicles.length,
                          itemBuilder: (context, index) {
                            final vehicle = vehicles[index];
                            final isActive = vehicle.isActive ?? false;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: AppSizes.marginSM),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isActive ? AppColors.successColor : AppColors.textMuted,
                                  child: const Icon(
                                    Icons.directions_bus,
                                    color: AppColors.textWhite,
                                  ),
                                ),
                                title: Text(
                                  '${AppConstants.labelVehiclePrefix}${vehicle.vehicleNumber ?? AppConstants.labelNA}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${AppConstants.labelRegistrationNumber}: ${vehicle.registrationNumber ?? AppConstants.labelNA}'),
                                    Text('${AppConstants.labelVehicleType}: ${vehicle.vehicleType ?? AppConstants.labelNA}'),
                                    Row(
                                      children: [
                                        Icon(
                                          isActive ? Icons.check_circle : Icons.cancel,
                                          size: AppSizes.iconXS,
                                          color: isActive ? AppColors.successColor : AppColors.errorColor,
                                        ),
                                        const SizedBox(width: AppSizes.marginXS),
                                        Text(
                                          isActive ? AppConstants.labelActive : AppConstants.labelInactive,
                                          style: TextStyle(
                                            color: isActive ? AppColors.successColor : AppColors.errorColor,
                                            fontSize: AppSizes.textXS,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'view':
                                        _showVehicleDetails(vehicle);
                                        break;
                                      case 'reports':
                                        // TODO: Navigate to vehicle reports
                                        _showErrorSnackBar(AppConstants.msgVehicleReportsComingSoon);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'view',
                                      child: Row(
                                        children: [
                                          Icon(Icons.visibility),
                                          SizedBox(width: AppSizes.marginSM),
                                          Text(AppConstants.labelViewDetails),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'reports',
                                      child: Row(
                                        children: [
                                          Icon(Icons.analytics),
                                          SizedBox(width: AppSizes.marginSM),
                                          Text(AppConstants.labelViewReports),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: AppSizes.iconMD),
        const SizedBox(height: AppSizes.marginXS),
        Text(
          value,
          style: const TextStyle(fontSize: AppSizes.textXL, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: AppSizes.textXS, color: AppColors.textMuted),
        ),
      ],
    );
  }

  void _showVehicleDetails(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${AppConstants.labelVehiclePrefix}${vehicle.vehicleNumber ?? AppConstants.labelNA}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppConstants.labelRegistrationNumber}: ${vehicle.registrationNumber ?? AppConstants.labelNA}'),
            const SizedBox(height: AppSizes.marginSM),
            Text('${AppConstants.labelVehicleType}: ${vehicle.vehicleType ?? AppConstants.labelNA}'),
            const SizedBox(height: AppSizes.marginSM),
            Text('${AppConstants.labelStatus}: ${(vehicle.isActive ?? false) ? AppConstants.labelActive : AppConstants.labelInactive}'),
            const SizedBox(height: AppSizes.marginSM),
            Text('${AppConstants.labelOwner}: ${vehicle.ownerName ?? AppConstants.labelNA}'),
            const SizedBox(height: AppSizes.marginSM),
            Text('${AppConstants.labelDriver}: ${vehicle.driverName ?? AppConstants.labelNA}'),
            const SizedBox(height: AppSizes.marginSM),
            Text('${AppConstants.labelCapacity}: ${vehicle.capacity?.toString() ?? AppConstants.labelNA}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppConstants.actionClose),
          ),
        ],
      ),
    );
  }
}

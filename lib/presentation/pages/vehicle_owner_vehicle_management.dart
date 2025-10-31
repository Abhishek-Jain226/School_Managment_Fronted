import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/vehicle_owner_service.dart';
import '../../app_routes.dart';
import '../../utils/constants.dart';

class VehicleOwnerVehicleManagementPage extends StatefulWidget {
  const VehicleOwnerVehicleManagementPage({super.key});

  @override
  State<VehicleOwnerVehicleManagementPage> createState() => _VehicleOwnerVehicleManagementPageState();
}

class _VehicleOwnerVehicleManagementPageState extends State<VehicleOwnerVehicleManagementPage> {
  final VehicleOwnerService _vehicleOwnerService = VehicleOwnerService();
  
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;
  Map<String, dynamic>? _ownerData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(AppConstants.keyUserId);
      
      if (userId != null) {
        // Load owner data
        final ownerResponse = await _vehicleOwnerService.getOwnerByUserId(userId);
        if (ownerResponse[AppConstants.keySuccess] == true) {
          _ownerData = ownerResponse[AppConstants.keyData];
          final ownerId = _ownerData![AppConstants.keyOwnerId];
          
          // Load vehicles
          final vehiclesResponse = await _vehicleOwnerService.getVehiclesByOwner(ownerId);
          if (vehiclesResponse[AppConstants.keySuccess] == true) {
            setState(() {
              _vehicles = List<Map<String, dynamic>>.from(vehiclesResponse[AppConstants.keyData][AppConstants.keyVehicles] ?? []);
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
      _showError('${AppConstants.msgErrorLoadingVehicles}: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.successColor,
        ),
      );
    }
  }

  Future<void> _deleteVehicle(int vehicleId, String vehicleNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppConstants.titleDeleteVehicle),
        content: Text('${AppConstants.msgConfirmDeleteVehicle} $vehicleNumber?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppConstants.actionCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppConstants.actionDelete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // TODO: Implement delete vehicle API call
        _showSuccess(AppConstants.msgVehicleDeletedSuccess);
        _loadData(); // Refresh the list
      } catch (e) {
        _showError('${AppConstants.msgErrorDeletingVehicle}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.labelVehicleManagement),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Card
                Card(
                  margin: const EdgeInsets.all(AppSizes.marginMD),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMD),
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions_bus,
                          size: AppSizes.iconXL,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: AppSizes.marginMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppConstants.labelTotalVehicles,
                                style: TextStyle(
                                  fontSize: AppSizes.textSM,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                _vehicles.length.toString(),
                                style: const TextStyle(fontSize: AppSizes.textXXL, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.registerVehicle)
                                .then((_) => _loadData());
                          },
                          icon: const Icon(Icons.add),
                          label: const Text(AppConstants.labelAddVehicle),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Vehicles List
                Expanded(
                  child: _vehicles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.directions_bus_outlined,
                                size: AppSizes.iconXL,
                                color: AppColors.grey200,
                              ),
                              const SizedBox(height: AppSizes.marginMD),
                              Text(
                                AppConstants.emptyStateNoVehiclesSub,
                                style: const TextStyle(fontSize: AppSizes.textXL, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: AppSizes.marginSM),
                              Text(
                                AppConstants.emptyStateAddFirstVehicle,
                                style: const TextStyle(fontSize: AppSizes.textSM, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: AppSizes.marginLG),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, AppRoutes.registerVehicle)
                                      .then((_) => _loadData());
                                },
                                icon: const Icon(Icons.add),
                                label: const Text(AppConstants.labelRegisterVehicle),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMD),
                          itemCount: _vehicles.length,
                          itemBuilder: (context, index) {
                            final vehicle = _vehicles[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: AppSizes.marginSM),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: (vehicle[AppConstants.keyIsActive] == true) 
                                      ? AppColors.successColor 
                                      : AppColors.textSecondary,
                                  child: Icon(
                                    Icons.directions_bus,
                                    color: AppColors.textWhite,
                                  ),
                                ),
                                title: Text(
                                  vehicle[AppConstants.keyVehicleNumber] ?? AppConstants.labelUnknownVehicle,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${AppConstants.labelTypePrefix}${vehicle[AppConstants.keyVehicleType] ?? AppConstants.labelNA}')
                                    ,
                                    Text('${AppConstants.labelRegistrationNumber}: ${vehicle[AppConstants.keyRegistrationNumber] ?? AppConstants.labelNA}')
                                    ,
                                    Text('${AppConstants.labelCapacity}: ${vehicle[AppConstants.keyCapacity] ?? AppConstants.labelNA}')
                                    ,
                                    Row(
                                      children: [
                                        Icon(
                                          (vehicle[AppConstants.keyIsActive] == true) 
                                              ? Icons.check_circle 
                                              : Icons.cancel,
                                          size: AppSizes.iconXS,
                                          color: (vehicle[AppConstants.keyIsActive] == true) 
                                              ? AppColors.successColor 
                                              : AppColors.errorColor,
                                        ),
                                        const SizedBox(width: AppSizes.marginXS),
                                        Text(
                                          (vehicle[AppConstants.keyIsActive] == true) ? AppConstants.labelActive : AppConstants.labelInactive,
                                          style: TextStyle(
                                            color: (vehicle[AppConstants.keyIsActive] == true) 
                                                ? AppColors.successColor 
                                                : AppColors.errorColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        // TODO: Navigate to edit vehicle page
                                        _showSuccess(AppConstants.msgEditFunctionalityComingSoon);
                                        break;
                                      case 'delete':
                                        _deleteVehicle(
                                          vehicle[AppConstants.keyVehicleId],
                                          vehicle[AppConstants.keyVehicleNumber] ?? AppConstants.labelUnknown,
                                        );
                                        break;
                                      case 'assign':
                                        // Navigate to school assignment
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.requestVehicle,
                                        );
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 20),
                                          SizedBox(width: AppSizes.marginSM),
                                          Text(AppConstants.actionEdit),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'assign',
                                      child: Row(
                                        children: [
                                          Icon(Icons.school, size: 20),
                                          SizedBox(width: AppSizes.marginSM),
                                          Text(AppConstants.actionAssignToSchool),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 20, color: AppColors.errorColor),
                                          SizedBox(width: AppSizes.marginSM),
                                          Text(AppConstants.actionDelete, style: TextStyle(color: AppColors.errorColor)),
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
}

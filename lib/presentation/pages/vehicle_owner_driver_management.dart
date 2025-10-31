import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/vehicle_owner_service.dart';
import '../../app_routes.dart';
import '../../utils/constants.dart';

class VehicleOwnerDriverManagementPage extends StatefulWidget {
  const VehicleOwnerDriverManagementPage({super.key});

  @override
  State<VehicleOwnerDriverManagementPage> createState() => _VehicleOwnerDriverManagementPageState();
}

class _VehicleOwnerDriverManagementPageState extends State<VehicleOwnerDriverManagementPage> {
  final VehicleOwnerService _vehicleOwnerService = VehicleOwnerService();
  
  List<Map<String, dynamic>> _drivers = [];
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
          // Load drivers by owner
          final driversResponse = await _vehicleOwnerService.getDriversByOwner(ownerId);
          if (driversResponse[AppConstants.keySuccess] == true) {
            setState(() {
              _drivers = List<Map<String, dynamic>>.from(driversResponse[AppConstants.keyData][AppConstants.keyDrivers] ?? []);
            });
          } else {
            // If no drivers found, set empty list
            setState(() {
              _drivers = [];
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
      _showError('${AppConstants.msgErrorLoadingDrivers}: $e');
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

  Future<void> _deleteDriver(int driverId, String driverName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppConstants.titleDeleteDriver),
        content: Text('${AppConstants.msgConfirmDeleteDriver} $driverName?'),
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
        // TODO: Implement delete driver API call
        _showSuccess(AppConstants.msgDriverDeletedSuccess);
        _loadData(); // Refresh the list
      } catch (e) {
        _showError('${AppConstants.msgErrorDeletingDriver}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.labelDriverManagement),
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
                          Icons.person,
                          size: AppSizes.iconXL,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: AppSizes.marginMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppConstants.labelTotalDrivers,
                                style: TextStyle(
                                  fontSize: AppSizes.textSM,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                _drivers.length.toString(),
                                style: const TextStyle(fontSize: AppSizes.textXXL, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.registerDriver)
                                .then((_) => _loadData());
                          },
                          icon: const Icon(Icons.add),
                          label: const Text(AppConstants.labelAddDriver),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Drivers List
                Expanded(
                  child: _drivers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: AppSizes.iconXL,
                                color: AppColors.grey200,
                              ),
                              const SizedBox(height: AppSizes.marginMD),
                              Text(
                                AppConstants.emptyStateNoDrivers,
                                style: TextStyle(
                                  fontSize: AppSizes.textXL,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSizes.marginSM),
                              Text(
                                AppConstants.emptyStateAddFirstDriver,
                                style: TextStyle(
                                  fontSize: AppSizes.textSM,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSizes.marginLG),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, AppRoutes.registerDriver)
                                      .then((_) => _loadData());
                                },
                                icon: const Icon(Icons.add),
                                label: const Text(AppConstants.labelRegisterDriver),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMD),
                          itemCount: _drivers.length,
                          itemBuilder: (context, index) {
                            final driver = _drivers[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: AppSizes.marginSM),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: (driver[AppConstants.keyIsActive] == true) 
                                      ? AppColors.successColor 
                                      : AppColors.textSecondary,
                                  child: Icon(
                                    Icons.person,
                                    color: AppColors.textWhite,
                                  ),
                                ),
                                title: Text(
                                  driver[AppConstants.keyDriverName] ?? AppConstants.labelUnknownDriver,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${AppConstants.labelContactPrefix}${driver[AppConstants.keyDriverContactNumber] ?? AppConstants.labelNA}')
                                    ,
                                    Text('${AppConstants.labelAddressPrefix}${driver[AppConstants.keyDriverAddress] ?? AppConstants.labelNA}')
                                    ,
                                    if (driver[AppConstants.keyEmail] != null)
                                      Text('${AppConstants.labelEmailPrefix}${driver[AppConstants.keyEmail]}')
                                    ,
                                    const SizedBox(height: AppSizes.marginXS),
                                    Row(
                                      children: [
                                        Icon(
                                          (driver[AppConstants.keyIsActive] == true) 
                                              ? Icons.check_circle 
                                              : Icons.cancel,
                                          size: AppSizes.iconXS,
                                          color: (driver[AppConstants.keyIsActive] == true) 
                                              ? AppColors.successColor 
                                              : AppColors.errorColor,
                                        ),
                                        const SizedBox(width: AppSizes.marginXS),
                                        Text(
                                          (driver[AppConstants.keyIsActive] == true) ? AppConstants.labelActive : AppConstants.labelInactive,
                                          style: TextStyle(
                                            color: (driver[AppConstants.keyIsActive] == true) 
                                                ? AppColors.successColor 
                                                : AppColors.errorColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (driver[AppConstants.keyAssignedVehicle] != null) ...[
                                          const SizedBox(width: AppSizes.marginMD),
                                          Icon(
                                            Icons.directions_bus,
                                            size: AppSizes.iconXS,
                                            color: AppColors.primaryColor,
                                          ),
                                          const SizedBox(width: AppSizes.marginXS),
                                          Text(
                                            '${AppConstants.labelAssignedToPrefix}${driver[AppConstants.keyAssignedVehicle]}',
                                            style: TextStyle(
                                              color: AppColors.primaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        // TODO: Navigate to edit driver page
                                        _showSuccess(AppConstants.msgEditFunctionalityComingSoon);
                                        break;
                                      case 'assign':
                                        // TODO: Navigate to driver-vehicle assignment
                                        _showSuccess(AppConstants.msgAssignmentFunctionalityComingSoon);
                                        break;
                                      case 'delete':
                                        _deleteDriver(
                                          driver[AppConstants.keyDriverId],
                                          driver[AppConstants.keyDriverName] ?? AppConstants.labelUnknown,
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
                                          Icon(Icons.assignment, size: 20),
                                          SizedBox(width: AppSizes.marginSM),
                                          Text(AppConstants.actionAssignToVehicle),
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

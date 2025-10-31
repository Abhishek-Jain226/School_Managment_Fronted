import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/vehicle_owner_service.dart';
import '../../app_routes.dart';
import '../../utils/constants.dart';

class VehicleOwnerDriverAssignmentPage extends StatefulWidget {
  const VehicleOwnerDriverAssignmentPage({super.key});

  @override
  State<VehicleOwnerDriverAssignmentPage> createState() => _VehicleOwnerDriverAssignmentPageState();
}

class _VehicleOwnerDriverAssignmentPageState extends State<VehicleOwnerDriverAssignmentPage> {
  final VehicleOwnerService _vehicleOwnerService = VehicleOwnerService();
  
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _assignments = [];
  bool _isLoading = true;
  Map<String, dynamic>? _ownerData;
  int? _currentSchoolId;

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
      _currentSchoolId = prefs.getInt(AppConstants.keyCurrentSchoolId);
      
      if (userId != null) {
        // Load owner data
        final ownerResponse = await _vehicleOwnerService.getOwnerByUserId(userId);
        if (ownerResponse[AppConstants.keySuccess] == true) {
          _ownerData = ownerResponse[AppConstants.keyData];
          final ownerId = _ownerData![AppConstants.keyOwnerId];
          
          // Load vehicles, drivers, and assignments in parallel
          debugPrint("🔍 _loadData: ownerId = $ownerId");
          await Future.wait([
            _loadVehicles(ownerId),
            _loadDrivers(ownerId),
            _loadAssignments(ownerId),
          ]);
          debugPrint("🔍 _loadData: After loading, _vehicles.length = ${_vehicles.length}");
        }
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
      _showError('${AppConstants.msgErrorLoadingData}: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadVehicles(int ownerId) async {
    try {
      debugPrint("🔍 Loading vehicles for owner ID: $ownerId");
      final vehiclesResponse = await _vehicleOwnerService.getVehiclesByOwner(ownerId);
      debugPrint("🔍 Vehicles response: $vehiclesResponse");
      
      if (vehiclesResponse[AppConstants.keySuccess] == true) {
        final vehiclesData = vehiclesResponse[AppConstants.keyData];
        debugPrint("🔍 Vehicles data: $vehiclesData");
        
        setState(() {
          _vehicles = List<Map<String, dynamic>>.from(vehiclesData[AppConstants.keyVehicles] ?? []);
        });
        debugPrint("🔍 Loaded ${_vehicles.length} vehicles");
        debugPrint("🔍 _vehicles content: $_vehicles");
        debugPrint("🔍 _vehicles.isEmpty: ${_vehicles.isEmpty}");
      } else {
        debugPrint("🔍 Failed to load vehicles: ${vehiclesResponse[AppConstants.keyMessage]}");
        setState(() {
          _vehicles = [];
        });
      }
    } catch (e) {
      debugPrint("🔍 Error loading vehicles: $e");
      setState(() {
        _vehicles = [];
      });
    }
    debugPrint("🔍 _loadVehicles: Final _vehicles.length = ${_vehicles.length}");
  }

  Future<void> _loadDrivers(int ownerId) async {
    try {
      final driversResponse = await _vehicleOwnerService.getDriversByOwner(ownerId);
      if (driversResponse[AppConstants.keySuccess] == true) {
        setState(() {
          _drivers = List<Map<String, dynamic>>.from(driversResponse[AppConstants.keyData][AppConstants.keyDrivers] ?? []);
        });
      }
    } catch (e) {
      debugPrint("Error loading drivers: $e");
    }
  }

  Future<void> _loadAssignments(int ownerId) async {
    try {
      final assignmentsResponse = await _vehicleOwnerService.getDriverAssignments(ownerId);
      if (assignmentsResponse[AppConstants.keySuccess] == true) {
        setState(() {
          _assignments = List<Map<String, dynamic>>.from(assignmentsResponse[AppConstants.keyData] ?? []);
        });
      } else {
        setState(() {
          _assignments = [];
        });
      }
    } catch (e) {
      debugPrint("Error loading assignments: $e");
      setState(() {
        _assignments = [];
      });
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

  Future<void> _showAssignDriverDialog() async {
    debugPrint("🔍 _showAssignDriverDialog: Starting dialog");
    debugPrint("🔍 _showAssignDriverDialog: _vehicles.length = ${_vehicles.length}");
    debugPrint("🔍 _showAssignDriverDialog: _drivers.length = ${_drivers.length}");
    debugPrint("🔍 _showAssignDriverDialog: _currentSchoolId = $_currentSchoolId");
    debugPrint("🔍 _showAssignDriverDialog: _vehicles = $_vehicles");
    debugPrint("🔍 _showAssignDriverDialog: _drivers = $_drivers");
    
    if (_vehicles.isEmpty) {
      debugPrint("🔍 _showAssignDriverDialog: No vehicles available");
      _showError(AppConstants.msgNoVehiclesAvailableRegisterFirst);
      return;
    }
    
    if (_drivers.isEmpty) {
      debugPrint("🔍 _showAssignDriverDialog: No drivers available");
      _showError(AppConstants.msgNoDriversAvailableRegisterFirst);
      return;
    }

    if (_currentSchoolId == null) {
      debugPrint("🔍 _showAssignDriverDialog: No school selected");
      _showError(AppConstants.msgNoSchoolSelected);
      return;
    }

    debugPrint("🔍 _showAssignDriverDialog: All validations passed, showing dialog");

    Map<String, dynamic>? selectedVehicle;
    Map<String, dynamic>? selectedDriver;
    bool isPrimary = false;

    try {
      debugPrint("🔍 _showAssignDriverDialog: About to show dialog");
      
      // Test with a working dialog that has the actual functionality
      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text(AppConstants.labelAssignDriverToVehicle),
            content: SizedBox(
              width: double.maxFinite,
              height: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Vehicle Selection
                  DropdownButtonFormField<Map<String, dynamic>>(
                    decoration: const InputDecoration(
                      labelText: AppConstants.labelSelectVehicle,
                      border: OutlineInputBorder(),
                    ),
                    value: selectedVehicle,
                    items: _vehicles.map((vehicle) {
                      final vehicleNumber = vehicle[AppConstants.keyVehicleNumber] ?? AppConstants.labelUnknown;
                      final vehicleType = vehicle[AppConstants.keyVehicleType] ?? AppConstants.labelUnknown;
                      return DropdownMenuItem(
                        value: vehicle,
                        child: Text("$vehicleNumber ($vehicleType)"),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedVehicle = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppSizes.marginMD),
                  
                  // Driver Selection
                  const Text(AppConstants.textOnlyActivatedDriversShown, style: TextStyle(fontSize: AppSizes.textXS, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                  const SizedBox(height: AppSizes.marginSM),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    decoration: const InputDecoration(
                      labelText: AppConstants.labelSelectDriver,
                      border: OutlineInputBorder(),
                    ),
                    value: selectedDriver,
                    items: _drivers.map((driver) {
                      final driverName = driver[AppConstants.keyDriverName] ?? AppConstants.labelUnknown;
                      final driverContact = driver[AppConstants.keyDriverContact] ?? AppConstants.labelUnknown;
                      return DropdownMenuItem(
                        value: driver,
                        child: Text("$driverName ($driverContact)"),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedDriver = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppSizes.marginMD),
                  
                  // Primary Driver Checkbox
                  CheckboxListTile(
                    title: const Text(AppConstants.labelPrimaryDriver),
                    subtitle: const Text(AppConstants.labelMarkAsPrimaryDriver),
                    value: isPrimary,
                    onChanged: (value) {
                      setDialogState(() {
                        isPrimary = value ?? false;
                      });
                    },
                  ),
                ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(AppConstants.actionCancel),
              ),
              ElevatedButton(
                onPressed: selectedVehicle != null && selectedDriver != null
                    ? () async {
                        Navigator.pop(ctx);
                        await _assignDriverToVehicle(
                          selectedVehicle!,
                          selectedDriver!,
                          isPrimary,
                        );
                      }
                    : null,
                child: const Text(AppConstants.actionAssign),
              ),
            ],
          ),
        ),
      );
    debugPrint("🔍 _showAssignDriverDialog: Dialog closed");
    } catch (e) {
      debugPrint("🔍 _showAssignDriverDialog: Error showing dialog: $e");
      _showError('${AppConstants.msgErrorOpeningDialog}: $e');
    }
  }

  Future<void> _assignDriverToVehicle(
    Map<String, dynamic> vehicle,
    Map<String, dynamic> driver,
    bool isPrimary,
  ) async {
    try {
      // Validate required data
      if (_currentSchoolId == null) {
        _showError(AppConstants.msgNoSchoolSelected);
        return;
      }
      
      if (_ownerData == null) {
        _showError(AppConstants.msgOwnerDataNotAvailable);
        return;
      }
      
      final createdBy = _ownerData![AppConstants.keyName] ?? AppConstants.labelVehicleOwner;
      if (createdBy.length < 3) {
        _showError(AppConstants.msgOwnerNameTooShort);
        return;
      }

      final assignmentData = {
        AppConstants.keyVehicleId: vehicle[AppConstants.keyVehicleId],
        AppConstants.keyDriverId: driver[AppConstants.keyDriverId],
        AppConstants.keySchoolId: _currentSchoolId,
        AppConstants.keyIsPrimary: isPrimary,
        AppConstants.keyIsActive: true,
        AppConstants.keyCreatedBy: createdBy,
      };

      debugPrint("🔍 _assignDriverToVehicle: assignmentData = $assignmentData");
      debugPrint("🔍 _assignDriverToVehicle: vehicle = $vehicle");
      debugPrint("🔍 _assignDriverToVehicle: driver = $driver");
      debugPrint("🔍 _assignDriverToVehicle: _currentSchoolId = $_currentSchoolId");
      debugPrint("🔍 _assignDriverToVehicle: createdBy = $createdBy");

      final response = await _vehicleOwnerService.assignDriverToVehicle(assignmentData);
      debugPrint("🔍 _assignDriverToVehicle: response = $response");
      
      if (response[AppConstants.keySuccess] == true) {
        _showSuccess(AppConstants.msgDriverAssignedSuccess);
      } else {
        _showError('${AppConstants.msgFailedToAssignDriver}: ${response[AppConstants.keyMessage]}');
      }
      
      // Reload assignments
      if (_ownerData != null) {
        await _loadAssignments(_ownerData![AppConstants.keyOwnerId]);
      }
    } catch (e) {
      debugPrint("🔍 _assignDriverToVehicle: error = $e");
      _showError('${AppConstants.msgFailedToAssignDriver}: $e');
    }
  }

  Future<void> _removeAssignment(Map<String, dynamic> assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppConstants.titleRemoveAssignment),
        content: Text(AppConstants.msgConfirmRemoveAssignment),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppConstants.actionCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppConstants.actionRemove),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final assignmentId = assignment[AppConstants.keyVehicleDriverId];
        final response = await _vehicleOwnerService.removeDriverAssignment(assignmentId);
        if (response[AppConstants.keySuccess] == true) {
          _showSuccess(AppConstants.msgAssignmentRemovedSuccess);
        } else {
          _showError('${AppConstants.msgFailedToRemoveAssignment}: ${response[AppConstants.keyMessage]}');
        }
        
        // Reload assignments
        if (_ownerData != null) {
          await _loadAssignments(_ownerData![AppConstants.keyOwnerId]);
        }
      } catch (e) {
        _showError('${AppConstants.msgFailedToRemoveAssignment}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.labelDriverAssignment),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          AppConstants.labelVehicles,
                          _vehicles.length.toString(),
                          Icons.directions_bus,
                          AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(width: AppSizes.marginSM),
                      Expanded(
                        child: _buildSummaryCard(
                          AppConstants.labelActivatedDrivers,
                          _drivers.length.toString(),
                          Icons.person,
                          AppColors.successColor,
                        ),
                      ),
                      const SizedBox(width: AppSizes.marginSM),
                      Expanded(
                        child: _buildSummaryCard(
                          AppConstants.labelAssignments,
                          _assignments.length.toString(),
                          Icons.assignment_ind,
                          AppColors.warningColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.marginLG),

                  // Quick Actions
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingMD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(AppConstants.labelQuickActions, style: TextStyle(fontSize: AppSizes.textXL, fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppSizes.marginSM),
                          Container(
                            padding: const EdgeInsets.all(AppSizes.paddingSM),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                              border: Border.all(color: AppColors.primaryLight),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: AppColors.primaryDark, size: AppSizes.iconSM),
                                const SizedBox(width: AppSizes.marginSM),
                                Expanded(
                                  child: Text(
                                    AppConstants.textOnlyActivatedDriversAssign,
                                    style: const TextStyle(color: AppColors.primaryDark, fontSize: AppSizes.textXS),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSizes.marginSM),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    debugPrint("🔍 Assign Driver button clicked");
                                    _showAssignDriverDialog();
                                  },
                                  icon: const Icon(Icons.assignment_ind),
                                  label: const Text(AppConstants.labelAssignDriver),
                                ),
                              ),
                              const SizedBox(width: AppSizes.marginSM),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(context, AppRoutes.registerDriver);
                                  },
                                  icon: const Icon(Icons.person_add),
                                  label: const Text(AppConstants.labelAddDriver),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.successColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.marginLG),

                  // Current Assignments
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingMD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(AppConstants.labelCurrentAssignments, style: TextStyle(fontSize: AppSizes.textXL, fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppSizes.marginSM),
                          if (_assignments.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(AppSizes.paddingLG),
                              child: Center(
                                child: Text(AppConstants.emptyStateNoAssignments, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: AppSizes.textMD)),
                              ),
                            )
                          else
                            ..._assignments.map((assignment) => _buildAssignmentCard(assignment)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        child: Column(
          children: [
            Icon(icon, color: color, size: AppSizes.iconLG),
            const SizedBox(height: AppSizes.marginSM),
            Text(
              value,
              style: TextStyle(
                fontSize: AppSizes.textXXL,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: AppSizes.textSM, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: AppSizes.marginSM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSM),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: assignment[AppConstants.keyIsPrimary] == true ? AppColors.warningColor : AppColors.primaryColor,
          child: Icon(
            assignment[AppConstants.keyIsPrimary] == true ? Icons.star : Icons.person,
            color: AppColors.textWhite,
          ),
        ),
        title: Text(
          assignment[AppConstants.keyDriverName] ?? AppConstants.labelUnknownDriver,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppConstants.labelVehiclePrefix}${assignment[AppConstants.keyVehicleNumber] ?? AppConstants.labelUnknown}'),
            Text('${AppConstants.labelStatus}: ${assignment[AppConstants.keyIsActive] == true ? AppConstants.labelActive : AppConstants.labelInactive}'),
            if (assignment[AppConstants.keyIsPrimary] == true)
              const Text(AppConstants.labelPrimaryDriver, style: TextStyle(color: AppColors.warningColor, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppColors.errorColor),
                  SizedBox(width: AppSizes.marginSM),
                  Text(AppConstants.actionRemoveAssignment),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'remove') {
              _removeAssignment(assignment);
            }
          },
        ),
      ),
    );
  }
}

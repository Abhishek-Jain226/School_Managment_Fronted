import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/vehicle_owner_service.dart';
import '../../services/trip_service.dart';
import '../../utils/constants.dart';

class VehicleOwnerTripAssignmentPage extends StatefulWidget {
  const VehicleOwnerTripAssignmentPage({super.key});

  @override
  State<VehicleOwnerTripAssignmentPage> createState() => _VehicleOwnerTripAssignmentPageState();
}

class _VehicleOwnerTripAssignmentPageState extends State<VehicleOwnerTripAssignmentPage> {
  final VehicleOwnerService _vehicleOwnerService = VehicleOwnerService();
  
  // Data variables
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _availableVehicles = [];
  Map<String, dynamic>? _ownerData;
  int? _currentSchoolId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      _currentSchoolId = prefs.getInt(AppConstants.keyCurrentSchoolId);
      final ownerId = prefs.getInt(AppConstants.keyOwnerId);
      final ownerName = prefs.getString(AppConstants.keyOwnerName);

      if (_currentSchoolId == null || ownerId == null) {
        setState(() {
          _errorMessage = AppConstants.msgSchoolOrOwnerInfoNotFound;
          _isLoading = false;
        });
        return;
      }

      // Set owner data
      _ownerData = {
        AppConstants.keyOwnerId: ownerId,
        AppConstants.keyOwnerName: ownerName ?? AppConstants.labelVehicleOwner,
      };

      // Load trips and available vehicles in parallel
      await Future.wait([
        _loadTrips(ownerId),
        _loadAvailableVehicles(ownerId, _currentSchoolId!),
      ]);

    } catch (e) {
      debugPrint("Error loading data: $e");
      setState(() {
        _errorMessage = '${AppConstants.msgErrorLoadingData}$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTrips(int ownerId) async {
    try {
      debugPrint("🔍 Loading trips for owner: $ownerId");
      final response = await _vehicleOwnerService.getTripsByOwner(ownerId);
      
      if (response[AppConstants.keySuccess] == true) {
        setState(() {
          _trips = List<Map<String, dynamic>>.from(response[AppConstants.keyData] ?? []);
        });
        debugPrint("🔍 Loaded ${_trips.length} trips");
      } else {
        debugPrint("🔍 Failed to load trips: ${response[AppConstants.keyMessage]}");
        setState(() {
          _errorMessage = response[AppConstants.keyMessage] ?? AppConstants.msgFailedToLoadTrips;
        });
      }
    } catch (e) {
      debugPrint("🔍 Error loading trips: $e");
      setState(() {
        _errorMessage = '${AppConstants.msgErrorLoadingTrips}$e';
      });
    }
  }

  Future<void> _loadAvailableVehicles(int ownerId, int schoolId) async {
    try {
      debugPrint("🔍 Loading available vehicles for owner: $ownerId, school: $schoolId");
      final response = await _vehicleOwnerService.getAvailableVehiclesForTrip(ownerId, schoolId);
      
      if (response[AppConstants.keySuccess] == true) {
        setState(() {
          _availableVehicles = List<Map<String, dynamic>>.from(response[AppConstants.keyData] ?? []);
        });
        debugPrint("🔍 Loaded ${_availableVehicles.length} available vehicles");
      } else {
        debugPrint("🔍 Failed to load vehicles: ${response[AppConstants.keyMessage]}");
        setState(() {
          _errorMessage = response[AppConstants.keyMessage] ?? AppConstants.msgFailedToLoadVehicles;
        });
      }
    } catch (e) {
      debugPrint("🔍 Error loading vehicles: $e");
      setState(() {
        _errorMessage = '${AppConstants.msgErrorLoadingVehicles}: $e';
      });
    }
  }

  Future<void> _assignTripToVehicle(Map<String, dynamic> trip, Map<String, dynamic> vehicle) async {
    try {
      if (_ownerData == null) {
        _showErrorSnackBar(AppConstants.msgOwnerDataNotAvailable);
        return;
      }

      final ownerId = _ownerData![AppConstants.keyOwnerId] as int;
      final tripId = trip[AppConstants.keyTripId] as int;
      final vehicleId = vehicle[AppConstants.keyVehicleId] as int;
      final updatedBy = _ownerData![AppConstants.keyOwnerName] as String;

      debugPrint("🔍 Assigning trip $tripId to vehicle $vehicleId by $updatedBy");

      final response = await _vehicleOwnerService.assignTripToVehicle(
        ownerId, tripId, vehicleId, updatedBy
      );

      if (response[AppConstants.keySuccess] == true) {
        _showSuccessSnackBar(AppConstants.msgTripAssignedToVehicleSuccess);
        await _loadData(); // Refresh data
      } else {
        _showErrorSnackBar(response[AppConstants.keyMessage] ?? AppConstants.msgFailedToAssignTrip);
      }
    } catch (e) {
      debugPrint("🔍 Error assigning trip: $e");
      _showErrorSnackBar('${AppConstants.msgErrorAssigningTrip}: $e');
    }
  }

  void _showAssignTripDialog(Map<String, dynamic> trip) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(AppConstants.labelAssignTripToVehicle),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // Trip Information
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingSM),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppConstants.labelTripPrefix}${trip[AppConstants.keyTripName] ?? AppConstants.labelUnknown}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppSizes.textLG),
                      ),
                      const SizedBox(height: AppSizes.marginXS),
                      Text('${AppConstants.labelRoutePrefix}${trip[AppConstants.keyRouteName] ?? AppConstants.labelUnknown}')
                      ,
                      Text('${AppConstants.labelTypePrefix}${trip[AppConstants.keyTripTypeDisplay] ?? AppConstants.labelUnknown}')
                      ,
                      if (trip[AppConstants.keyVehicle] != null)
                        Text('${AppConstants.labelCurrentVehiclePrefix}${trip[AppConstants.keyVehicle][AppConstants.keyVehicleNumber] ?? AppConstants.labelUnknown}')
                      ,
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.marginMD),
                
                // Vehicle Selection
                DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: const InputDecoration(
                    labelText: AppConstants.labelSelectVehicle,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_bus),
                  ),
                  items: _availableVehicles.map((vehicle) {
                    final vehicleNumber = vehicle[AppConstants.keyVehicleNumber] ?? AppConstants.labelUnknown;
                    final vehicleType = vehicle[AppConstants.keyVehicleType] ?? AppConstants.labelUnknown;
                    final driverName = vehicle[AppConstants.keyAssignedDriverName] ?? AppConstants.labelNoDriver;
                    final hasDriver = vehicle[AppConstants.keyHasAssignedDriver] == true;
                    
                    return DropdownMenuItem(
                      value: vehicle,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("$vehicleNumber ($vehicleType)"),
                          Row(
                            children: [
                              Icon(
                                hasDriver ? Icons.person : Icons.person_off,
                                size: AppSizes.iconXS,
                                color: hasDriver ? AppColors.successColor : AppColors.warningColor,
                              ),
                              const SizedBox(width: AppSizes.marginXS),
                              Text(
                                driverName,
                                style: TextStyle(fontSize: AppSizes.textXS, color: hasDriver ? AppColors.successColor : AppColors.warningColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (selectedVehicle) {
                    if (selectedVehicle != null) {
                      _assignTripToVehicle(trip, selectedVehicle);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppConstants.actionCancel),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.successColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.labelTripAssignment),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.textWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: AppSizes.iconXL, color: AppColors.errorColor),
                      const SizedBox(height: AppSizes.marginMD),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: AppSizes.textMD, color: AppColors.errorColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizes.marginMD),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text(AppConstants.labelRetry),
                      ),
                    ],
                  ),
                )
              : _trips.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment, size: AppSizes.iconXL, color: AppColors.grey200),
                          const SizedBox(height: AppSizes.marginMD),
                          Text(
                            AppConstants.emptyStateNoTrips,
                            style: const TextStyle(fontSize: AppSizes.textXL, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSizes.marginSM),
                          Text(
                            AppConstants.emptyStateTripsAppearOnceCreated,
                            style: const TextStyle(fontSize: AppSizes.textSM, color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Summary Cards
                        Container(
                          padding: const EdgeInsets.all(AppSizes.paddingMD),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  AppConstants.labelTotalTrips,
                                  _trips.length.toString(),
                                  Icons.assignment,
                                  AppColors.primaryColor,
                                ),
                              ),
                              const SizedBox(width: AppSizes.marginSM),
                              Expanded(
                                child: _buildSummaryCard(
                                  AppConstants.labelAvailableVehicles,
                                  _availableVehicles.length.toString(),
                                  Icons.directions_bus,
                                  AppColors.successColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Trips List
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(AppSizes.paddingMD),
                            itemCount: _trips.length,
                            itemBuilder: (context, index) {
                              final trip = _trips[index];
                              return _buildTripCard(trip);
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
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
            style: TextStyle(
              fontSize: AppSizes.textSM,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final tripName = trip[AppConstants.keyTripName] ?? AppConstants.labelUnknownTrip;
    final routeName = trip[AppConstants.keyRouteName] ?? AppConstants.labelUnknownRoute;
    final tripType = trip[AppConstants.keyTripTypeDisplay] ?? AppConstants.labelUnknownType;
    final tripStatus = trip[AppConstants.keyTripStatus] ?? AppConstants.labelTripNotStarted;
    final vehicle = trip[AppConstants.keyVehicle];
    final driver = trip[AppConstants.keyDriver];
    
    Color statusColor = Colors.grey;
    switch (tripStatus.toLowerCase()) {
      case 'not_started':
        statusColor = Colors.grey;
        break;
      case 'in_progress':
        statusColor = AppColors.infoColor;
        break;
      case 'completed':
        statusColor = AppColors.successColor;
        break;
      case 'cancelled':
        statusColor = AppColors.errorColor;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.marginSM),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
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
                        tripName,
                        style: const TextStyle(
                          fontSize: AppSizes.textXL,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSizes.marginXS),
                      Text(
                        '${AppConstants.labelRoutePrefix}$routeName',
                        style: const TextStyle(fontSize: AppSizes.textMD, color: AppColors.textSecondary),
                      ),
                      Text(
                        '${AppConstants.labelTypePrefix}$tripType',
                        style: const TextStyle(fontSize: AppSizes.textMD, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingSM, vertical: AppSizes.paddingXS),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    tripStatus.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: AppSizes.textXS,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSizes.marginSM),
            
            // Vehicle and Driver Info
            if (vehicle != null || driver != null)
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingSM),
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                ),
                child: Column(
                  children: [
                    if (vehicle != null)
                      Row(
                        children: [
                          Icon(Icons.directions_bus, size: AppSizes.iconXS, color: AppColors.primaryDark),
                          const SizedBox(width: AppSizes.marginSM),
                          Text('${AppConstants.labelVehiclePrefix}${vehicle[AppConstants.keyVehicleNumber] ?? AppConstants.labelUnknown}')
                        ],
                      ),
                    if (driver != null) ...[
                      const SizedBox(height: AppSizes.marginXS),
                      Row(
                        children: [
                          Icon(
                            driver[AppConstants.keyIsActivated] == true ? Icons.person : Icons.person_off,
                            size: AppSizes.iconXS,
                            color: driver[AppConstants.keyIsActivated] == true ? AppColors.successColor : AppColors.warningColor,
                          ),
                          const SizedBox(width: AppSizes.marginSM),
                          Text('${AppConstants.labelDriverPrefix}${driver[AppConstants.keyDriverName] ?? AppConstants.labelUnknown}')
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            
            const SizedBox(height: AppSizes.marginSM),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAssignTripDialog(trip),
                icon: const Icon(Icons.assignment),
                label: const Text(AppConstants.actionAssignToVehicle),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSM),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

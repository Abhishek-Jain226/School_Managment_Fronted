import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import '../../data/models/trip_request.dart';
import '../../data/models/trip_type.dart';
import '../../data/models/vehicle.dart';
import '../../services/trip_service.dart';
import '../../services/vehicle_service.dart';

class CreateTripPage extends StatefulWidget {
  const CreateTripPage({super.key});

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final _formKey = GlobalKey<FormState>();
  final _tripNameController = TextEditingController();
  final _tripNumberController = TextEditingController();
  final _routeNameController = TextEditingController();
  final _routeDescriptionController = TextEditingController();
  
  Vehicle? _selectedVehicle;
  String _selectedTripType = TripType.morningPickup.value;

  final TripService _tripService = TripService();
  final VehicleService _vehicleService = VehicleService();

  List<Vehicle> vehicles = [];
  bool _loading = false;
  bool _loadingVehicles = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    _tripNameController.dispose();
    _tripNumberController.dispose();
    _routeNameController.dispose();
    _routeDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final schoolId = prefs.getInt(AppConstants.keySchoolId) ?? 1;

    debugPrint('${AppConstants.debugLoadingVehicles}$schoolId');
    
    final list = await _vehicleService.getVehiclesBySchool(schoolId);
    
    debugPrint('${AppConstants.debugLoadedVehicles}${list.length}${AppConstants.debugVehiclesText}');
    if (list.isEmpty) {
      debugPrint(AppConstants.debugNoVehiclesWarning);
      debugPrint(AppConstants.debugVehicleStep1);
      debugPrint(AppConstants.debugVehicleStep2);
      debugPrint(AppConstants.debugVehicleStep3);
    }
    
    setState(() {
      vehicles = list;
      _loadingVehicles = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.msgFillAllRequiredFields)),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final schoolId = prefs.getInt(AppConstants.keySchoolId);
      final userName = prefs.getString(AppConstants.keyUserName);

      debugPrint('${AppConstants.debugSchoolIdUserName}$schoolId${AppConstants.debugUserNameSuffix}$userName');
      debugPrint('${AppConstants.debugSelectedVehicle}${_selectedVehicle!.vehicleId}');
      
      if (schoolId == null) {
        throw Exception(AppConstants.msgSchoolIdNotFoundLoginAgain);
      }

      final tripRequest = TripRequest(
        schoolId: schoolId,
        vehicleId: _selectedVehicle!.vehicleId!,
        tripName: _tripNameController.text.trim(),
        tripNumber: int.parse(_tripNumberController.text.trim()),
        tripType: _selectedTripType,
        routeName: _routeNameController.text.trim(),
        routeDescription: _routeDescriptionController.text.trim(),
        createdBy: userName ?? AppConstants.roleSchoolAdmin,
      );

      debugPrint(AppConstants.debugSubmittingTrip);
      final success = await _tripService.createTrip(tripRequest);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.msgTripCreatedSuccessfully),
            backgroundColor: AppColors.createTripSuccessColor,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.msgFailedToCreateTrip),
            backgroundColor: AppColors.createTripErrorColor,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('${AppConstants.debugTripCreationException}$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppConstants.labelError}: ${e.toString()}'),
            backgroundColor: AppColors.createTripErrorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.labelCreateTrip)),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.createTripPadding),
        child: _loadingVehicles
            ? const Center(child: CircularProgressIndicator())
            : vehicles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_bus_outlined, size: AppSizes.createTripIconSize, color: AppColors.createTripGreyColor),
                        const SizedBox(height: AppSizes.createTripSpacingMD),
                        const Text(
                          AppConstants.labelNoVehiclesAvailable,
                          style: TextStyle(fontSize: AppSizes.createTripTitleFontSize, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSizes.createTripSpacingXS),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSizes.createTripPaddingH),
                          child: Text(
                            AppConstants.msgNoVehiclesInfo,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.createTripGreyColor),
                          ),
                        ),
                        const SizedBox(height: AppSizes.createTripSpacingMD),
                        const Text(
                          AppConstants.labelStepsToAddVehicles,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSizes.createTripSpacingXS),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSizes.createTripPaddingH),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppConstants.msgVehicleStepOne),
                              Text(AppConstants.msgVehicleStepTwo),
                              Text(AppConstants.msgVehicleStepThree),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text(AppConstants.labelGoBack),
                        ),
                      ],
                    ),
                  )
                : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                    TextFormField(
                      controller: _tripNameController,
                      decoration: const InputDecoration(
                        labelText: AppConstants.labelTripName,
                        hintText: AppConstants.hintTripName,
                      ),
                      validator: (v) => v == null || v.isEmpty ? AppConstants.validationEnterTripName : null,
                    ),
                    const SizedBox(height: AppSizes.createTripSpacingSM),
                    TextFormField(
                      controller: _tripNumberController,
                      decoration: const InputDecoration(
                        labelText: AppConstants.labelTripNumber,
                        hintText: AppConstants.hintTripNumber,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? AppConstants.validationEnterTripNumber : null,
                    ),
                    const SizedBox(height: AppSizes.createTripSpacingSM),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTripType,
                      items: TripType.getDropdownItems()
                          .map((item) => DropdownMenuItem(
                                value: item['value'],
                                child: Text(item['label']!),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedTripType = val!),
                      decoration: const InputDecoration(labelText: AppConstants.labelTripType),
                      validator: (v) => v == null ? AppConstants.validationSelectTripType : null,
                    ),
                    const SizedBox(height: AppSizes.createTripSpacingSM),
                    DropdownButtonFormField<Vehicle>(
                      initialValue: _selectedVehicle,
                      items: vehicles
                          .map((v) => DropdownMenuItem(
                                value: v,
                                child: Text(v.vehicleNumber ?? AppConstants.labelUnknownVehicle),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedVehicle = val),
                      decoration: const InputDecoration(labelText: AppConstants.labelSelectVehicle),
                      validator: (v) => v == null ? AppConstants.validationSelectVehicle : null,
                    ),
                    const SizedBox(height: AppSizes.createTripSpacingSM),
                    TextFormField(
                      controller: _routeNameController,
                      decoration: const InputDecoration(
                        labelText: AppConstants.labelRouteName,
                        hintText: AppConstants.hintRouteName,
                      ),
                      validator: (v) => v == null || v.isEmpty ? AppConstants.validationEnterRouteName : null,
                    ),
                    const SizedBox(height: AppSizes.createTripSpacingSM),
                    TextFormField(
                      controller: _routeDescriptionController,
                      decoration: const InputDecoration(
                        labelText: AppConstants.labelRouteDescription,
                        hintText: AppConstants.hintRouteDescription,
                      ),
                      maxLines: 3,
                      validator: (v) => v == null || v.isEmpty ? AppConstants.validationEnterRouteDescription : null,
                    ),
                    const SizedBox(height: AppSizes.createTripSpacingMD),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSizes.createTripButtonPaddingV),
                      ),
                      child: _loading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: AppSizes.createTripProgressSize,
                                  height: AppSizes.createTripProgressSize,
                                  child: CircularProgressIndicator(strokeWidth: AppSizes.createTripProgressStroke),
                                ),
                                SizedBox(width: AppSizes.createTripSpacingSM),
                                Text(AppConstants.labelCreatingTrip),
                              ],
                            )
                          : const Text(AppConstants.labelCreateTrip),
                    ),
                  ],
                  ),
                ),
              ),
      ),
    );
  }
}

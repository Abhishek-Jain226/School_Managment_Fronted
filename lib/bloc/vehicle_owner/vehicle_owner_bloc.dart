import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/constants.dart';
import '../../services/vehicle_owner_service.dart';
import 'vehicle_owner_event.dart';
import 'vehicle_owner_state.dart';

class VehicleOwnerBloc extends Bloc<VehicleOwnerEvent, VehicleOwnerState> {
  final VehicleOwnerService _vehicleOwnerService;
  Timer? _refreshTimer;

  VehicleOwnerBloc({required VehicleOwnerService vehicleOwnerService})
      : _vehicleOwnerService = vehicleOwnerService,
        super(const VehicleOwnerInitial()) {
    on<VehicleOwnerDashboardRequested>(_onDashboardRequested);
    on<VehicleOwnerProfileRequested>(_onProfileRequested);
    on<VehicleOwnerUpdateRequested>(_onUpdateRequested);
    on<VehicleOwnerVehiclesRequested>(_onVehiclesRequested);
    on<VehicleOwnerDriversRequested>(_onDriversRequested);
    on<VehicleOwnerTripsRequested>(_onTripsRequested);
    on<VehicleOwnerReportsRequested>(_onReportsRequested);
    on<VehicleOwnerAddVehicleRequested>(_onAddVehicleRequested);
    on<VehicleOwnerAddDriverRequested>(_onAddDriverRequested);
    on<VehicleOwnerAssignDriverRequested>(_onAssignDriverRequested);
    on<VehicleOwnerRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onDashboardRequested(
    VehicleOwnerDashboardRequested event,
    Emitter<VehicleOwnerState> emit,
  ) async {
    emit(const VehicleOwnerLoading());
    
    try {
      // Load dashboard data
      final dashboard = await _vehicleOwnerService.getVehicleOwnerDashboard(event.ownerId);
      
      // Load related data
      final vehicles = await _vehicleOwnerService.getVehicleOwnerVehicles(event.ownerId);
      final drivers = await _vehicleOwnerService.getVehicleOwnerDrivers(event.ownerId);
      final trips = await _vehicleOwnerService.getVehicleOwnerTrips(event.ownerId);
      
      emit(VehicleOwnerDashboardLoaded(
        dashboard: dashboard,
        vehicles: vehicles,
        drivers: drivers,
        trips: trips,
      ));
      
      // Start auto-refresh timer
      _startRefreshTimer(event.ownerId);
      
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadVehicleOwnerDashboard}: ${e.toString()}');
      emit(VehicleOwnerError(
        message: '${AppConstants.errorFailedToLoadVehicleOwnerDashboard}: ${e.toString()}',
        errorCode: AppConstants.errorCodeVehicleOwnerDashboard,
        actionType: AppConstants.actionTypeLoadDashboard,
      ));
    }
  }

  Future<void> _onProfileRequested(
    VehicleOwnerProfileRequested event,
    Emitter<VehicleOwnerState> emit,
  ) async {
    // Don't emit loading state to preserve dashboard UI
    try {
      final profile = await _vehicleOwnerService.getVehicleOwnerProfile(event.ownerId);
      emit(VehicleOwnerProfileLoaded(profile: profile));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadVehicleOwnerProfile}: ${e.toString()}');
      emit(VehicleOwnerError(
        message: '${AppConstants.errorFailedToLoadVehicleOwnerProfile}: ${e.toString()}',
        errorCode: AppConstants.errorCodeVehicleOwnerProfile,
        actionType: AppConstants.actionTypeLoadProfile,
      ));
    }
  }

  Future<void> _onUpdateRequested(
    VehicleOwnerUpdateRequested event,
    Emitter<VehicleOwnerState> emit,
  ) async {
    try {
      final response = await _vehicleOwnerService.updateVehicleOwnerProfile(
        event.ownerId,
        event.ownerData,
      );
      
      emit(VehicleOwnerActionSuccess(
        message: response[AppConstants.keyMessage] ?? AppConstants.msgProfileUpdated,
        actionType: AppConstants.actionTypeUpdateProfile,
      ));
      
      // Refresh profile after update
      add(VehicleOwnerProfileRequested(ownerId: event.ownerId));
      
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToUpdateVehicleOwnerProfile}: ${e.toString()}');
      emit(VehicleOwnerError(
        message: '${AppConstants.errorFailedToUpdateVehicleOwnerProfile}: ${e.toString()}',
        errorCode: AppConstants.errorCodeVehicleOwnerUpdate,
        actionType: AppConstants.actionTypeUpdateProfile,
      ));
    }
  }

  Future<void> _onVehiclesRequested(
    VehicleOwnerVehiclesRequested event,
    Emitter<VehicleOwnerState> emit,
  ) async {
    try {
      final vehicles = await _vehicleOwnerService.getVehicleOwnerVehicles(event.ownerId);
      emit(VehicleOwnerVehiclesLoaded(vehicles: vehicles));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadVehicleOwnerVehicles}: ${e.toString()}');
      emit(VehicleOwnerError(
        message: '${AppConstants.errorFailedToLoadVehicleOwnerVehicles}: ${e.toString()}',
        errorCode: AppConstants.errorCodeVehicleOwnerVehicles,
        actionType: AppConstants.actionTypeLoadVehicles,
      ));
    }
  }

  Future<void> _onDriversRequested(
    VehicleOwnerDriversRequested event,
    Emitter<VehicleOwnerState> emit,
  ) async {
    try {
      final drivers = await _vehicleOwnerService.getVehicleOwnerDrivers(event.ownerId);
      emit(VehicleOwnerDriversLoaded(drivers: drivers));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadVehicleOwnerDrivers}: ${e.toString()}');
      emit(VehicleOwnerError(
        message: '${AppConstants.errorFailedToLoadVehicleOwnerDrivers}: ${e.toString()}',
        errorCode: AppConstants.errorCodeVehicleOwnerDrivers,
        actionType: AppConstants.actionTypeLoadDrivers,
      ));
    }
  }

  Future<void> _onTripsRequested(
    VehicleOwnerTripsRequested event,
    Emitter<VehicleOwnerState> emit,
  ) async {
    try {
      final trips = await _vehicleOwnerService.getVehicleOwnerTrips(event.ownerId);
      emit(VehicleOwnerTripsLoaded(trips: trips));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadVehicleOwnerTrips}: ${e.toString()}');
      emit(VehicleOwnerError(
        message: '${AppConstants.errorFailedToLoadVehicleOwnerTrips}: ${e.toString()}',
        errorCode: AppConstants.errorCodeVehicleOwnerTrips,
        actionType: AppConstants.actionTypeLoadTrips,
      ));
    }
  }

  Future<void> _onReportsRequested(
    VehicleOwnerReportsRequested event,
    Emitter<VehicleOwnerState> emit,
  ) async {
    try {
      final reports = await _vehicleOwnerService.getVehicleOwnerReports(event.ownerId);
      emit(VehicleOwnerReportsLoaded(reports: reports));
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToLoadVehicleOwnerReports}: ${e.toString()}');
      emit(VehicleOwnerError(
        message: '${AppConstants.errorFailedToLoadVehicleOwnerReports}: ${e.toString()}',
        errorCode: AppConstants.errorCodeVehicleOwnerReports,
        actionType: AppConstants.actionTypeLoadReports,
      ));
    }
  }

  Future<void> _onAddVehicleRequested(
    VehicleOwnerAddVehicleRequested event,
    Emitter<VehicleOwnerState> emit,
  ) async {
    try {
      final response = await _vehicleOwnerService.addVehicle(
        event.ownerId,
        event.vehicleData,
      );
      
      emit(VehicleOwnerActionSuccess(
        message: response[AppConstants.keyMessage] ?? AppConstants.msgVehicleAdded,
        actionType: AppConstants.actionTypeAddVehicle,
      ));
      
      // Refresh vehicles after adding
      add(VehicleOwnerVehiclesRequested(ownerId: event.ownerId));
      
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToAddVehicle}: ${e.toString()}');
      emit(VehicleOwnerError(
        message: '${AppConstants.errorFailedToAddVehicle}: ${e.toString()}',
        errorCode: AppConstants.errorCodeAddVehicle,
        actionType: AppConstants.actionTypeAddVehicle,
      ));
    }
  }

  Future<void> _onAddDriverRequested(
    VehicleOwnerAddDriverRequested event,
    Emitter<VehicleOwnerState> emit,
  ) async {
    try {
      final response = await _vehicleOwnerService.addDriver(
        event.ownerId,
        event.driverData,
      );
      
      emit(VehicleOwnerActionSuccess(
        message: response[AppConstants.keyMessage] ?? AppConstants.msgDriverAdded,
        actionType: AppConstants.actionTypeAddDriver,
      ));
      
      // Refresh drivers after adding
      add(VehicleOwnerDriversRequested(ownerId: event.ownerId));
      
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToAddDriver}: ${e.toString()}');
      emit(VehicleOwnerError(
        message: '${AppConstants.errorFailedToAddDriver}: ${e.toString()}',
        errorCode: AppConstants.errorCodeAddDriver,
        actionType: AppConstants.actionTypeAddDriver,
      ));
    }
  }

  Future<void> _onAssignDriverRequested(
    VehicleOwnerAssignDriverRequested event,
    Emitter<VehicleOwnerState> emit,
  ) async {
    try {
      final response = await _vehicleOwnerService.assignDriver(
        event.ownerId,
        {
          AppConstants.keyVehicleId: event.vehicleId,
          AppConstants.keyDriverId: event.driverId,
        },
      );
      
      emit(VehicleOwnerActionSuccess(
        message: response[AppConstants.keyMessage] ?? AppConstants.msgDriverAssigned,
        actionType: AppConstants.actionTypeAssignDriver,
      ));
      
      // Refresh dashboard after assignment
      add(VehicleOwnerDashboardRequested(ownerId: event.ownerId));
      
    } catch (e) {
      debugPrint('${AppConstants.errorFailedToAssignDriver}: ${e.toString()}');
      emit(VehicleOwnerError(
        message: '${AppConstants.errorFailedToAssignDriver}: ${e.toString()}',
        errorCode: AppConstants.errorCodeAssignDriver,
        actionType: AppConstants.actionTypeAssignDriver,
      ));
    }
  }

  Future<void> _onRefreshRequested(
    VehicleOwnerRefreshRequested event,
    Emitter<VehicleOwnerState> emit,
  ) async {
    // Emit refreshing state to show loading indicator
    if (state is VehicleOwnerDashboardLoaded) {
      final currentState = state as VehicleOwnerDashboardLoaded;
      emit(VehicleOwnerRefreshing(
        dashboard: currentState.dashboard,
        vehicles: currentState.vehicles,
        drivers: currentState.drivers,
        trips: currentState.trips,
      ));
    }
    
    // Refresh dashboard data
    add(VehicleOwnerDashboardRequested(ownerId: event.ownerId));
  }

  void _startRefreshTimer(int ownerId) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(AppDurations.autoRefreshVehicleOwner, (timer) {
      add(VehicleOwnerRefreshRequested(ownerId: ownerId));
    });
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }
}

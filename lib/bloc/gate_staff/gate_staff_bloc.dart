import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/constants.dart';
import '../../services/gate_staff_service.dart';
import 'gate_staff_event.dart';
import 'gate_staff_state.dart';

class GateStaffBloc extends Bloc<GateStaffEvent, GateStaffState> {
  final GateStaffService _gateStaffService;
  Timer? _refreshTimer;

  GateStaffBloc({required GateStaffService gateStaffService})
      : _gateStaffService = gateStaffService,
        super(const GateStaffInitial()) {
    on<GateStaffDashboardRequested>(_onDashboardRequested);
    on<GateStaffMarkEntryRequested>(_onMarkEntryRequested);
    on<GateStaffMarkExitRequested>(_onMarkExitRequested);
    on<GateStaffRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onDashboardRequested(
    GateStaffDashboardRequested event,
    Emitter<GateStaffState> emit,
  ) async {
    emit(const GateStaffLoading());

    try {
      final dashboard = await _gateStaffService.getGateStaffDashboard(event.userId);

      if (dashboard[AppConstants.keySuccess] == true) {
        final dashboardData = dashboard[AppConstants.keyData] ?? dashboard;
        emit(GateStaffDashboardLoaded(dashboard: dashboardData));

        // Start auto-refresh timer
        _startRefreshTimer(event.userId);
      } else {
        emit(GateStaffError(
          message: dashboard[AppConstants.keyMessage] ?? AppConstants.msgFailedToLoadDashboard,
          errorCode: AppConstants.errorCodeDashboardLoad,
          actionType: AppConstants.actionTypeLoadDashboard,
        ));
      }
    } catch (e) {
      debugPrint('${AppConstants.msgErrorLoadingDashboard}: ${e.toString()}');
      emit(GateStaffError(
        message: '${AppConstants.msgErrorLoadingDashboard}: ${e.toString()}',
        errorCode: AppConstants.errorCodeDashboardLoad,
        actionType: AppConstants.actionTypeLoadDashboard,
      ));
    }
  }

  Future<void> _onMarkEntryRequested(
    GateStaffMarkEntryRequested event,
    Emitter<GateStaffState> emit,
  ) async {
    try {
      final response = await _gateStaffService.markGateEntry(
        event.userId,
        event.studentId,
        event.tripId,
        event.remarks,
      );

      if (response[AppConstants.keySuccess] == true) {
        emit(GateStaffActionSuccess(
          message: response[AppConstants.keyMessage] ?? 
                  '${AppConstants.msgGateEventMarkedSuccess}${AppConstants.labelEntry.toLowerCase()}${AppConstants.msgMarkedSuccessfully}',
          actionType: AppConstants.actionTypeMarkGateEntry,
        ));

        // Refresh dashboard after marking entry
        add(GateStaffDashboardRequested(userId: event.userId));
      } else {
        emit(GateStaffError(
          message: response[AppConstants.keyMessage] ?? AppConstants.msgFailedToMarkGateEvent,
          errorCode: AppConstants.errorCodeGateEntry,
          actionType: AppConstants.actionTypeMarkGateEntry,
        ));
      }
    } catch (e) {
      debugPrint('${AppConstants.msgErrorMarkingGateEvent}: ${e.toString()}');
      emit(GateStaffError(
        message: '${AppConstants.msgErrorMarkingGateEvent}${AppConstants.labelEntry.toLowerCase()}: ${e.toString()}',
        errorCode: AppConstants.errorCodeGateEntry,
        actionType: AppConstants.actionTypeMarkGateEntry,
      ));
    }
  }

  Future<void> _onMarkExitRequested(
    GateStaffMarkExitRequested event,
    Emitter<GateStaffState> emit,
  ) async {
    try {
      final response = await _gateStaffService.markGateExit(
        event.userId,
        event.studentId,
        event.tripId,
        event.remarks,
      );

      if (response[AppConstants.keySuccess] == true) {
        emit(GateStaffActionSuccess(
          message: response[AppConstants.keyMessage] ?? 
                  '${AppConstants.msgGateEventMarkedSuccess}${AppConstants.labelExit.toLowerCase()}${AppConstants.msgMarkedSuccessfully}',
          actionType: AppConstants.actionTypeMarkGateExit,
        ));

        // Refresh dashboard after marking exit
        add(GateStaffDashboardRequested(userId: event.userId));
      } else {
        emit(GateStaffError(
          message: response[AppConstants.keyMessage] ?? AppConstants.msgFailedToMarkGateEvent,
          errorCode: AppConstants.errorCodeGateExit,
          actionType: AppConstants.actionTypeMarkGateExit,
        ));
      }
    } catch (e) {
      debugPrint('${AppConstants.msgErrorMarkingGateEvent}: ${e.toString()}');
      emit(GateStaffError(
        message: '${AppConstants.msgErrorMarkingGateEvent}${AppConstants.labelExit.toLowerCase()}: ${e.toString()}',
        errorCode: AppConstants.errorCodeGateExit,
        actionType: AppConstants.actionTypeMarkGateExit,
      ));
    }
  }

  Future<void> _onRefreshRequested(
    GateStaffRefreshRequested event,
    Emitter<GateStaffState> emit,
  ) async {
    // Emit refreshing state to show loading indicator
    if (state is GateStaffDashboardLoaded) {
      final currentState = state as GateStaffDashboardLoaded;
      emit(GateStaffRefreshing(dashboard: currentState.dashboard));
    }

    // Refresh dashboard data
    add(GateStaffDashboardRequested(userId: event.userId));
  }

  void _startRefreshTimer(int userId) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(AppDurations.autoRefresh, (timer) {
      add(GateStaffRefreshRequested(userId: userId));
    });
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }
}


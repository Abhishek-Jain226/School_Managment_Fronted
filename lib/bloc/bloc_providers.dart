import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/auth_service.dart';
import '../services/driver_service.dart';
import '../services/school_service.dart';
import '../services/vehicle_owner_service.dart';
import '../services/parent_service.dart';
import '../services/app_admin_service.dart';
import '../services/gate_staff_service.dart';
import '../services/websocket_notification_service.dart';
import 'auth/auth_bloc.dart';
import 'driver/driver_bloc.dart';
import 'school/school_bloc.dart';
import 'vehicle_owner/vehicle_owner_bloc.dart';
import 'parent/parent_bloc.dart';
import 'app_admin/app_admin_bloc.dart';
import 'gate_staff/gate_staff_bloc.dart';
import 'notification/notification_bloc.dart';

class BlocProviders extends StatelessWidget {
  final Widget child;

  const BlocProviders({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Auth BLoC
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authService: AuthService(),
          ),
        ),
        
        // Driver BLoC
        BlocProvider<DriverBloc>(
          create: (context) => DriverBloc(
            driverService: DriverService(),
            webSocketService: WebSocketNotificationService(),
          ),
        ),
        
        // School BLoC
        BlocProvider<SchoolBloc>(
          create: (context) => SchoolBloc(
            schoolService: SchoolService(),
            webSocketService: WebSocketNotificationService(),
          ),
        ),
        
        // Vehicle Owner BLoC
        BlocProvider<VehicleOwnerBloc>(
          create: (context) => VehicleOwnerBloc(
            vehicleOwnerService: VehicleOwnerService(),
            webSocketService: WebSocketNotificationService(),
          ),
        ),
        
        // Parent BLoC
        BlocProvider<ParentBloc>(
          create: (context) => ParentBloc(
            parentService: ParentService(),
            webSocketService: WebSocketNotificationService(),
          ),
        ),
        
        // App Admin BLoC
        BlocProvider<AppAdminBloc>(
          create: (context) => AppAdminBloc(
            appAdminService: AppAdminService(),
            webSocketService: WebSocketNotificationService(),
          ),
        ),
        
        // Gate Staff BLoC
        BlocProvider<GateStaffBloc>(
          create: (context) => GateStaffBloc(
            gateStaffService: GateStaffService(),
            webSocketService: WebSocketNotificationService(),
          ),
        ),
        
        // Notification BLoC
        BlocProvider<NotificationBloc>(
          create: (context) => NotificationBloc(
            webSocketService: WebSocketNotificationService(),
          ),
        ),
      ],
      child: child,
    );
  }
}

// Helper class to access BLoCs easily
class BlocHelper {
  static AuthBloc getAuthBloc(BuildContext context) {
    return context.read<AuthBloc>();
  }

  static DriverBloc getDriverBloc(BuildContext context) {
    return context.read<DriverBloc>();
  }

  static SchoolBloc getSchoolBloc(BuildContext context) {
    return context.read<SchoolBloc>();
  }

  static VehicleOwnerBloc getVehicleOwnerBloc(BuildContext context) {
    return context.read<VehicleOwnerBloc>();
  }

  static ParentBloc getParentBloc(BuildContext context) {
    return context.read<ParentBloc>();
  }

  static AppAdminBloc getAppAdminBloc(BuildContext context) {
    return context.read<AppAdminBloc>();
  }

  static NotificationBloc getNotificationBloc(BuildContext context) {
    return context.read<NotificationBloc>();
  }

  // Listen to BLoC states
  static BlocBuilder<AuthBloc, dynamic> buildAuthBloc({
    required Widget Function(BuildContext, dynamic) builder,
  }) {
    return BlocBuilder<AuthBloc, dynamic>(builder: builder);
  }

  static BlocBuilder<DriverBloc, dynamic> buildDriverBloc({
    required Widget Function(BuildContext, dynamic) builder,
  }) {
    return BlocBuilder<DriverBloc, dynamic>(builder: builder);
  }

  static BlocBuilder<NotificationBloc, dynamic> buildNotificationBloc({
    required Widget Function(BuildContext, dynamic) builder,
  }) {
    return BlocBuilder<NotificationBloc, dynamic>(builder: builder);
  }

  // Listen to BLoC states with listener
  static BlocListener<AuthBloc, dynamic> listenToAuthBloc({
    required void Function(BuildContext, dynamic) listener,
    required Widget child,
  }) {
    return BlocListener<AuthBloc, dynamic>(
      listener: listener,
      child: child,
    );
  }

  static BlocListener<DriverBloc, dynamic> listenToDriverBloc({
    required void Function(BuildContext, dynamic) listener,
    required Widget child,
  }) {
    return BlocListener<DriverBloc, dynamic>(
      listener: listener,
      child: child,
    );
  }

  static BlocListener<NotificationBloc, dynamic> listenToNotificationBloc({
    required void Function(BuildContext, dynamic) listener,
    required Widget child,
  }) {
    return BlocListener<NotificationBloc, dynamic>(
      listener: listener,
      child: child,
    );
  }
}

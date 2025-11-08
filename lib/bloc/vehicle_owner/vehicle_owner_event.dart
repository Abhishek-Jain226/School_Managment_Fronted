import 'package:equatable/equatable.dart';
import '../../data/models/websocket_notification.dart';


abstract class VehicleOwnerEvent extends Equatable {
  const VehicleOwnerEvent();

  @override
  List<Object?> get props => [];
}

class VehicleOwnerDashboardRequested extends VehicleOwnerEvent {
  final int ownerId;

  const VehicleOwnerDashboardRequested({required this.ownerId});

  @override
  List<Object> get props => [ownerId];
}

class VehicleOwnerProfileRequested extends VehicleOwnerEvent {
  final int ownerId;

  const VehicleOwnerProfileRequested({required this.ownerId});

  @override
  List<Object> get props => [ownerId];
}

class VehicleOwnerUpdateRequested extends VehicleOwnerEvent {
  final int ownerId;
  final Map<String, dynamic> ownerData;

  const VehicleOwnerUpdateRequested({
    required this.ownerId,
    required this.ownerData,
  });

  @override
  List<Object> get props => [ownerId, ownerData];
}

class VehicleOwnerVehiclesRequested extends VehicleOwnerEvent {
  final int ownerId;

  const VehicleOwnerVehiclesRequested({required this.ownerId});

  @override
  List<Object> get props => [ownerId];
}

class VehicleOwnerDriversRequested extends VehicleOwnerEvent {
  final int ownerId;

  const VehicleOwnerDriversRequested({required this.ownerId});

  @override
  List<Object> get props => [ownerId];
}

class VehicleOwnerTripsRequested extends VehicleOwnerEvent {
  final int ownerId;

  const VehicleOwnerTripsRequested({required this.ownerId});

  @override
  List<Object> get props => [ownerId];
}

class VehicleOwnerNotificationsRequested extends VehicleOwnerEvent {
  final int userId;

  const VehicleOwnerNotificationsRequested({required this.userId});

  @override
  List<Object> get props => [userId];
}

class VehicleOwnerReportsRequested extends VehicleOwnerEvent {
  final int ownerId;

  const VehicleOwnerReportsRequested({required this.ownerId});

  @override
  List<Object> get props => [ownerId];
}

class VehicleOwnerAddVehicleRequested extends VehicleOwnerEvent {
  final int ownerId;
  final Map<String, dynamic> vehicleData;

  const VehicleOwnerAddVehicleRequested({
    required this.ownerId,
    required this.vehicleData,
  });

  @override
  List<Object> get props => [ownerId, vehicleData];
}

class VehicleOwnerAddDriverRequested extends VehicleOwnerEvent {
  final int ownerId;
  final Map<String, dynamic> driverData;

  const VehicleOwnerAddDriverRequested({
    required this.ownerId,
    required this.driverData,
  });

  @override
  List<Object> get props => [ownerId, driverData];
}

class VehicleOwnerAssignDriverRequested extends VehicleOwnerEvent {
  final int ownerId;
  final int vehicleId;
  final int driverId;

  const VehicleOwnerAssignDriverRequested({
    required this.ownerId,
    required this.vehicleId,
    required this.driverId,
  });

  @override
  List<Object> get props => [ownerId, vehicleId, driverId];
}

class VehicleOwnerRefreshRequested extends VehicleOwnerEvent {
  final int ownerId;

  const VehicleOwnerRefreshRequested({required this.ownerId});

  @override
  List<Object> get props => [ownerId];
}

class VehicleOwnerRealtimeNotificationReceived extends VehicleOwnerEvent {
  final WebSocketNotification notification;

  const VehicleOwnerRealtimeNotificationReceived({required this.notification});

  @override
  List<Object> get props => [notification];
}

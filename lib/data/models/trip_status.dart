import '../../utils/constants.dart';

class TripStatus {
  final int tripStatusId;
  final int tripId;
  final String tripName;
  final String status;
  final String statusDisplay;
  final DateTime statusTime;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? totalTimeMinutes;
  final String totalTimeDisplay;
  final String? remarks;
  final String? createdBy;
  final DateTime? createdDate;

  TripStatus({
    required this.tripStatusId,
    required this.tripId,
    required this.tripName,
    required this.status,
    required this.statusDisplay,
    required this.statusTime,
    this.startTime,
    this.endTime,
    this.totalTimeMinutes,
    required this.totalTimeDisplay,
    this.remarks,
    this.createdBy,
    this.createdDate,
  });

  factory TripStatus.fromJson(Map<String, dynamic> json) {
    return TripStatus(
      tripStatusId: json[AppConstants.keyTripStatusId],
      tripId: json[AppConstants.keyTripId],
      tripName: json[AppConstants.keyTripName],
      status: json[AppConstants.keyStatus],
      statusDisplay: json[AppConstants.keyStatusDisplay] ?? _getStatusDisplay(json[AppConstants.keyStatus]),
      statusTime: DateTime.parse(json[AppConstants.keyStatusTime]),
      startTime: json[AppConstants.keyStartTime] != null ? DateTime.parse(json[AppConstants.keyStartTime]) : null,
      endTime: json[AppConstants.keyEndTime] != null ? DateTime.parse(json[AppConstants.keyEndTime]) : null,
      totalTimeMinutes: json[AppConstants.keyTotalTimeMinutes],
      totalTimeDisplay: json[AppConstants.keyTotalTimeDisplay] ?? _formatTotalTime(json[AppConstants.keyTotalTimeMinutes]),
      remarks: json[AppConstants.keyRemarks],
      createdBy: json[AppConstants.keyCreatedBy],
      createdDate: json[AppConstants.keyCreatedDate] != null ? DateTime.parse(json[AppConstants.keyCreatedDate]) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConstants.keyTripStatusId: tripStatusId,
      AppConstants.keyTripId: tripId,
      AppConstants.keyTripName: tripName,
      AppConstants.keyStatus: status,
      AppConstants.keyStatusDisplay: statusDisplay,
      AppConstants.keyStatusTime: statusTime.toIso8601String(),
      AppConstants.keyStartTime: startTime?.toIso8601String(),
      AppConstants.keyEndTime: endTime?.toIso8601String(),
      AppConstants.keyTotalTimeMinutes: totalTimeMinutes,
      AppConstants.keyTotalTimeDisplay: totalTimeDisplay,
      AppConstants.keyRemarks: remarks,
      AppConstants.keyCreatedBy: createdBy,
      AppConstants.keyCreatedDate: createdDate?.toIso8601String(),
    };
  }

  static String _getStatusDisplay(String status) {
    switch (status) {
      case 'NOT_STARTED':
        return 'Not Started';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      case 'DELAYED':
        return 'Delayed';
      default:
        return status;
    }
  }

  static String _formatTotalTime(int? totalTimeMinutes) {
    if (totalTimeMinutes == null) {
      return 'N/A';
    }
    
    int hours = totalTimeMinutes ~/ 60;
    int minutes = totalTimeMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  TripStatus copyWith({
    int? tripStatusId,
    int? tripId,
    String? tripName,
    String? status,
    String? statusDisplay,
    DateTime? statusTime,
    DateTime? startTime,
    DateTime? endTime,
    int? totalTimeMinutes,
    String? totalTimeDisplay,
    String? remarks,
    String? createdBy,
    DateTime? createdDate,
  }) {
    return TripStatus(
      tripStatusId: tripStatusId ?? this.tripStatusId,
      tripId: tripId ?? this.tripId,
      tripName: tripName ?? this.tripName,
      status: status ?? this.status,
      statusDisplay: statusDisplay ?? this.statusDisplay,
      statusTime: statusTime ?? this.statusTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalTimeMinutes: totalTimeMinutes ?? this.totalTimeMinutes,
      totalTimeDisplay: totalTimeDisplay ?? this.totalTimeDisplay,
      remarks: remarks ?? this.remarks,
      createdBy: createdBy ?? this.createdBy,
      createdDate: createdDate ?? this.createdDate,
    );
  }
}

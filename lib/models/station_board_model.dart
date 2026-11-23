import '../core/constants/app_strings.dart';
import '../core/theme/operator_themes.dart';

enum BoardType { departures, arrivals }

enum StationTrainStatus {
  onTime,
  delayed,
  boarding,
  departed,
  cancelled,
}

extension StationTrainStatusX on StationTrainStatus {
  String get label {
    switch (this) {
      case StationTrainStatus.onTime:
        return AppStrings.stationStatusOnTime;
      case StationTrainStatus.delayed:
        return AppStrings.stationStatusDelayed;
      case StationTrainStatus.boarding:
        return AppStrings.stationStatusBoarding;
      case StationTrainStatus.departed:
        return AppStrings.stationStatusDeparted;
      case StationTrainStatus.cancelled:
        return AppStrings.stationStatusCancelled;
    }
  }
}

class StationBoardItem {
  final String id;
  final String scheduledTime; // "14:35"
  final String? estimatedTime; // "14:45"
  final RailOperator operator;
  final String trainType; // AVE, Avlo, Alvia, Iryo, Ouigo, MD, Cercanías
  final String trainNumber;
  final String destination; // "Madrid-Chamartín"
  final String origin; // for arrivals
  final List<String> stops;
  final String? platform; // "2", "4" or null
  final StationTrainStatus status;
  final int? delayMinutes;

  const StationBoardItem({
    required this.id,
    required this.scheduledTime,
    this.estimatedTime,
    required this.operator,
    required this.trainType,
    required this.trainNumber,
    required this.destination,
    required this.origin,
    required this.stops,
    this.platform,
    required this.status,
    this.delayMinutes,
  });

  factory StationBoardItem.fromJson(Map<String, dynamic> json) {
    return StationBoardItem(
      id: json['id'] as String,
      scheduledTime: json['scheduledTime'] as String,
      estimatedTime: json['estimatedTime'] as String?,
      operator: RailOperator.values.byName(json['operator'] as String),
      trainType: json['trainType'] as String,
      trainNumber: json['trainNumber'] as String,
      destination: json['destination'] as String,
      origin: json['origin'] as String? ?? '',
      stops: (json['stops'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      platform: json['platform'] as String?,
      status: StationTrainStatus.values.byName(json['status'] as String),
      delayMinutes: json['delayMinutes'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'scheduledTime': scheduledTime,
        if (estimatedTime != null) 'estimatedTime': estimatedTime,
        'operator': operator.name,
        'trainType': trainType,
        'trainNumber': trainNumber,
        'destination': destination,
        'origin': origin,
        'stops': stops,
        if (platform != null) 'platform': platform,
        'status': status.name,
        if (delayMinutes != null) 'delayMinutes': delayMinutes,
      };
}

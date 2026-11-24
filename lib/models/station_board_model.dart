import '../core/constants/app_strings.dart';
import '../core/constants/adif_stations.dart';
import '../core/theme/operator_themes.dart';

enum BoardType { departures, arrivals }

enum StationTrainStatus {
  onTime,
  delayed,
  boarding,
  departed,
  cancelled,
  unknown,
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
      case StationTrainStatus.unknown:
        return AppStrings.stationStatusUnknown;
    }
  }
}

class StationBoardItem {
  final String id;
  final String scheduledTime; // "14:35"
  final String? estimatedTime; // "14:45"
  final RailOperator operator;
  final String trainType; // AVE, AVANT, AVLO, INTERCITY, REGIONAL, CERCANÍAS
  final String trainNumber;
  final String destination; // "Madrid-Chamartín"
  final String origin; // for arrivals
  final List<String> stops;
  final String? platform; // "2", "4" or null
  final StationTrainStatus status;
  final int? delayMinutes;

  StationBoardItem({
    required this.id,
    required this.scheduledTime,
    this.estimatedTime,
    required this.operator,
    required this.trainType,
    required this.trainNumber,
    required String destination,
    required String origin,
    required this.stops,
    String? platform,
    required this.status,
    this.delayMinutes,
  }) : origin = AdifStations.resolveName(origin),
       destination = AdifStations.resolveName(destination),
       platform = normalizePlatform(platform);

  static String? normalizePlatform(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null ||
        trimmed.isEmpty ||
        const {
          '-',
          '--',
          '—',
          'null',
          'por asignar',
        }.contains(trimmed.toLowerCase())) {
      return null;
    }
    final numeric = double.tryParse(trimmed);
    if (numeric != null && numeric <= 0) return null;
    return trimmed;
  }

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
      stops:
          (json['stops'] as List<dynamic>?)
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

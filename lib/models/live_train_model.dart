class LiveTrain {
  final String id;
  final String trainNumber;
  final String serviceBrand;
  final double latitude;
  final double longitude;
  final double? speedKmh;
  final int? delayMinutes;
  final String? origin;
  final String? destination;
  final String? currentStation;
  final String? nextStop;
  final String? platform;
  final DateTime? updatedAt;

  const LiveTrain({
    required this.id,
    required this.trainNumber,
    required this.serviceBrand,
    required this.latitude,
    required this.longitude,
    this.speedKmh,
    this.delayMinutes,
    this.origin,
    this.destination,
    this.currentStation,
    this.nextStop,
    this.platform,
    this.updatedAt,
  });

  factory LiveTrain.fromJson(Map<String, dynamic> json) {
    return LiveTrain(
      id: json['id']?.toString() ?? json['trainNumber']?.toString() ?? '',
      trainNumber: json['trainNumber']?.toString() ?? '',
      serviceBrand: json['serviceBrand']?.toString() ?? 'RENFE',
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
      speedKmh: (json['speedKmh'] as num?)?.toDouble(),
      delayMinutes: (json['delayMinutes'] as num?)?.toInt(),
      origin: json['origin'] as String?,
      destination: json['destination'] as String?,
      currentStation: json['currentStation'] as String?,
      nextStop: json['nextStop'] as String?,
      platform: json['platform'] as String?,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

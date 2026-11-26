import 'package:flutter/material.dart';

enum TrainCategory {
  ave,
  avlo,
  avant,
  alviaEuromed,
  intercityMedia,
  rexional,
  cercanias,
}

extension TrainCategoryStyle on TrainCategory {
  Color get color => switch (this) {
        TrainCategory.ave => const Color(0xFF8E1B6B),
        TrainCategory.avlo => const Color(0xFF00A8E8),
        TrainCategory.avant => const Color(0xFFF26419),
        TrainCategory.alviaEuromed => const Color(0xFF1D63DC),
        TrainCategory.intercityMedia => const Color(0xFF4F46E5),
        TrainCategory.rexional => const Color(0xFFD97706),
        TrainCategory.cercanias => const Color(0xFF10B981),
      };

  Color get foreground => switch (this) {
        TrainCategory.avlo ||
        TrainCategory.avant ||
        TrainCategory.rexional ||
        TrainCategory.cercanias =>
          const Color(0xFF111827),
        _ => Colors.white,
      };
}

TrainCategory? classifyTrain({
  String? serviceBrand,
  String? trainType,
  String? product,
  String? serviceName,
  String? routeShortName,
  String? line,
  String? operatorName,
}) {
  final values = [
    serviceBrand,
    trainType,
    product,
    serviceName,
    routeShortName,
    line,
    operatorName,
  ].whereType<String>().join(' ').toUpperCase();
  final normalized = values
      .replaceAll('Á', 'A')
      .replaceAll('É', 'E')
      .replaceAll('Í', 'I')
      .replaceAll('Ó', 'O')
      .replaceAll('Ú', 'U');
  final normalizedLine = (line ?? routeShortName ?? '').toUpperCase();

  if (normalized.contains('CERCANIAS') ||
      normalized.contains('RODALIES') ||
      normalized.contains('PROXIMIDADES') ||
      RegExp(r'^(?:C(?:[1-9]|10)|R(?:[1-9]|1[0-7])|RAM)(?:$|[-\s])')
          .hasMatch(normalizedLine) ||
      RegExp(r'(?:C(?:[1-9]|10)|R(?:[1-9]|1[0-7])|RAM)$')
          .hasMatch(routeShortName?.toUpperCase() ?? '')) {
    return TrainCategory.cercanias;
  }
  if (normalized.contains('AVLO')) return TrainCategory.avlo;
  if (RegExp(r'\bAVE\b').hasMatch(normalized)) return TrainCategory.ave;
  if (normalized.contains('AVANT')) return TrainCategory.avant;
  if (normalized.contains('ALVIA') || normalized.contains('EUROMED')) {
    return TrainCategory.alviaEuromed;
  }
  if (normalized.contains('INTERCITY') ||
      RegExp(r'\bIC\b').hasMatch(normalized) ||
      RegExp(r'\bMD\b').hasMatch(normalized) ||
      normalized.contains('MEDIA DISTANCIA') ||
      normalized.contains('TALGO') ||
      normalized.contains('TRENHOTEL')) {
    return TrainCategory.intercityMedia;
  }
  if (normalized.contains('REGIONAL') ||
      normalized.contains('REXIONAL') ||
      normalized.contains('REG.EXP') ||
      normalized.contains('R. EXPRES') ||
      normalized.contains('FEVE')) {
    return TrainCategory.rexional;
  }
  return null;
}

class LiveTrain {
  final String id;
  final String trainNumber;
  final String serviceBrand;
  final String? trainType;
  final String? product;
  final String? serviceName;
  final String? routeShortName;
  final String? line;
  final String? operatorName;
  final TrainCategory? category;
  final double latitude;
  final double longitude;
  final double? bearingDegrees;
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
    this.trainType,
    this.product,
    this.serviceName,
    this.routeShortName,
    this.line,
    this.operatorName,
    this.category,
    required this.latitude,
    required this.longitude,
    this.bearingDegrees,
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
    final serviceBrand = json['serviceBrand']?.toString() ?? 'RENFE';
    final trainType = json['trainType']?.toString();
    final product = json['product']?.toString();
    final serviceName = json['serviceName']?.toString();
    final routeShortName = json['routeShortName']?.toString();
    final line = json['line']?.toString();
    final operatorName = json['operator']?.toString();
    return LiveTrain(
      id: json['id']?.toString() ?? json['trainNumber']?.toString() ?? '',
      trainNumber: json['trainNumber']?.toString() ?? '',
      serviceBrand: serviceBrand,
      trainType: trainType,
      product: product,
      serviceName: serviceName,
      routeShortName: routeShortName,
      line: line,
      operatorName: operatorName,
      category: classifyTrain(
        serviceBrand: serviceBrand,
        trainType: trainType,
        product: product,
        serviceName: serviceName,
        routeShortName: routeShortName,
        line: line,
        operatorName: operatorName,
      ),
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
      bearingDegrees: (json['bearingDegrees'] as num?)?.toDouble(),
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

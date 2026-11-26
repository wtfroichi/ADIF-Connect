import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/live_train_model.dart';

class LiveFleetService {
  Future<List<LiveTrain>> fetchTrains() async {
    try {
      final response = await Supabase.instance.client.functions
          .invoke('adif-fleet', method: HttpMethod.get)
          .timeout(const Duration(seconds: 12));
      if (response.status == 200 &&
          response.data is Map<String, dynamic> &&
          response.data['error'] == null) {
        final decoded = response.data as Map<String, dynamic>;
        if (decoded['trains'] is List) {
          return (decoded['trains'] as List)
              .whereType<Map<String, dynamic>>()
              .map(LiveTrain.fromJson)
              .toList(growable: false);
        }
      }
    } catch (_) {
      // Fall back to Renfe's openly licensed position feeds below.
    }

    return _fetchRenfeFeeds();
  }

  Future<List<LiveTrain>> _fetchRenfeFeeds() async {
    const feeds = [
      'https://gtfsrt.renfe.com/vehicle_positions_LD.json',
      'https://gtfsrt.renfe.com/vehicle_positions.json',
    ];
    final results = await Future.wait(
      feeds.map((url) async {
        try {
          final response = await http.get(Uri.parse(url), headers: {
            'Accept': 'application/json'
          }).timeout(const Duration(seconds: 8));
          if (response.statusCode != 200) return null;
          final decoded = jsonDecode(response.body);
          if (decoded is! Map<String, dynamic> || decoded['entity'] is! List) {
            return null;
          }
          return decoded['entity'] as List;
        } catch (_) {
          return null;
        }
      }),
    );
    if (results.every((result) => result == null)) {
      throw const FormatException('Non foi posible obter posicións de Renfe.');
    }

    final trains = <LiveTrain>[];
    for (var feedIndex = 0; feedIndex < results.length; feedIndex++) {
      for (final raw in results[feedIndex] ?? const []) {
        if (raw is! Map<String, dynamic>) continue;
        final vehicle = raw['vehicle'];
        if (vehicle is! Map<String, dynamic>) continue;
        final position = vehicle['position'];
        if (position is! Map<String, dynamic>) continue;
        final latitude = _number(position['latitude']);
        final longitude = _number(position['longitude']);
        if (latitude == null || longitude == null) continue;
        if (latitude < -90 ||
            latitude > 90 ||
            longitude < -180 ||
            longitude > 180) {
          continue;
        }

        final vehicleInfo = vehicle['vehicle'];
        final label = vehicleInfo is Map<String, dynamic>
            ? vehicleInfo['label']?.toString() ?? ''
            : '';
        final number = vehicleInfo is Map<String, dynamic>
            ? vehicleInfo['id']?.toString() ??
                RegExp(r'\d{4,6}').firstMatch(label)?.group(0)
            : RegExp(r'\d{4,6}').firstMatch(label)?.group(0);
        if (number == null || number.isEmpty) continue;

        final trip = vehicle['trip'];
        final tripId = trip is Map<String, dynamic>
            ? trip['tripId']?.toString() ?? ''
            : '';
        final line = feedIndex == 1
            ? RegExp(r'^([A-Z]+\d+|RAM)', caseSensitive: false)
                .firstMatch(label)
                ?.group(1)
            : null;
        final isCercanias = feedIndex == 1 ||
            RegExp(r'(?:C(?:[1-9]|10)|R(?:[1-9]|1[0-7])|RAM)$',
                    caseSensitive: false)
                .hasMatch(tripId);
        final timestamp = _number(vehicle['timestamp']);
        final status = vehicle['currentStatus']?.toString();
        final stopId = vehicle['stopId']?.toString();
        final platform =
            RegExp(r'PLATF\.\(([^)]+)\)').firstMatch(label)?.group(1);
        final speed = _number(position['speed']);
        final bearing = _number(position['bearing']);
        final trainType = vehicleInfo is Map<String, dynamic>
            ? vehicleInfo['trainType']?.toString()
            : null;
        final product = vehicleInfo is Map<String, dynamic>
            ? vehicleInfo['product']?.toString()
            : null;
        final serviceName = vehicleInfo is Map<String, dynamic>
            ? vehicleInfo['serviceName']?.toString()
            : null;
        final routeShortName = trip is Map<String, dynamic>
            ? trip['routeShortName']?.toString()
            : null;
        final serviceBrand = isCercanias ? 'RENFE CERCANÍAS' : 'RENFE';

        trains.add(
          LiveTrain(
            id: raw['id']?.toString() ?? '$feedIndex-$tripId-$number',
            trainNumber: number,
            serviceBrand: serviceBrand,
            trainType: trainType,
            product: product,
            serviceName: serviceName,
            routeShortName: routeShortName,
            line: line,
            operatorName: 'RENFE',
            category: classifyTrain(
              serviceBrand: serviceBrand,
              trainType: trainType,
              product: product,
              serviceName: serviceName,
              routeShortName: routeShortName,
              line: line,
              operatorName: 'RENFE',
            ),
            latitude: latitude,
            longitude: longitude,
            bearingDegrees: bearing,
            speedKmh: speed == null ? null : (speed * 3.6).roundToDouble(),
            origin: null,
            destination: null,
            currentStation: status == 'STOPPED_AT' ? stopId : null,
            nextStop: status == 'STOPPED_AT' ? null : stopId,
            platform: platform,
            updatedAt: timestamp == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(
                    (timestamp * 1000).round(),
                    isUtc: true,
                  ),
          ),
        );
      }
    }
    return trains;
  }

  double? _number(Object? value) {
    if (value is num) return value.toDouble();
    return value == null ? null : double.tryParse(value.toString());
  }
}

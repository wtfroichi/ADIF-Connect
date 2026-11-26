import '../core/constants/adif_stations.dart';
import '../models/station_board_model.dart';
import '../models/ticket_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TicketTrackInfo {
  final String? departurePlatform;
  final String? predictedPlatform;
  final double? predictionConfidence;
  final String? arrivalPlatform;

  const TicketTrackInfo({
    this.departurePlatform,
    this.predictedPlatform,
    this.predictionConfidence,
    this.arrivalPlatform,
  });
}

class TrackPredictionService {
  TrackPredictionService._();

  static final TrackPredictionService instance = TrackPredictionService._();
  final Map<String, ({DateTime expiresAt, List<StationBoardItem> items})>
      _boards = {};
  final Map<String, Future<List<StationBoardItem>>> _pending = {};

  Future<TicketTrackInfo> forTicket(TicketModel ticket) async {
    final departure = await _board(ticket.originCode, 'departures');
    final matchingDeparture = _match(departure, ticket);
    final arrival = await _board(ticket.destinationCode, 'arrivals');
    final matchingArrival = _match(arrival, ticket);

    return TicketTrackInfo(
      departurePlatform: StationBoardItem.normalizePlatform(
            matchingDeparture?.platform,
          ) ??
          StationBoardItem.normalizePlatform(ticket.platform),
      predictedPlatform: StationBoardItem.normalizePlatform(
              matchingDeparture?.predictedPlatform) ??
          StationBoardItem.normalizePlatform(ticket.predictedPlatform),
      predictionConfidence: matchingDeparture?.predictionConfidence ??
          ticket.predictionConfidence,
      arrivalPlatform: StationBoardItem.normalizePlatform(
            matchingArrival?.platform,
          ) ??
          StationBoardItem.normalizePlatform(ticket.arrivalPlatform),
    );
  }

  StationBoardItem? _match(List<StationBoardItem> items, TicketModel ticket) {
    for (final item in items) {
      if (item.trainNumber.trim() == ticket.trainNumber.trim()) return item;
    }
    return null;
  }

  Future<List<StationBoardItem>> _board(String station, String direction) {
    final stationCode =
        AdifStations.byCode(station)?.adifCode ?? station.trim();
    final key = '$stationCode:$direction';
    final cached = _boards[key];
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
      return Future.value(cached.items);
    }
    return _pending.putIfAbsent(key, () async {
      try {
        final response = await Supabase.instance.client.functions.invoke(
          'adif-board',
          method: HttpMethod.get,
          queryParameters: {'station': stationCode, 'type': direction},
        ).timeout(const Duration(seconds: 8));
        if (response.status != 200) return const [];
        final decoded = response.data;
        if (decoded is! Map<String, dynamic> || decoded['items'] is! List) {
          return const [];
        }
        final items = (decoded['items'] as List)
            .whereType<Map<String, dynamic>>()
            .map(StationBoardItem.fromJson)
            .toList(growable: false);
        _boards[key] = (
          expiresAt: DateTime.now().add(const Duration(seconds: 30)),
          items: items,
        );
        return items;
      } catch (_) {
        return const [];
      } finally {
        _pending.remove(key);
      }
    });
  }
}

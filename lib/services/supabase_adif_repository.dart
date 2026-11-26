import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/adif_stations.dart';
import '../core/constants/app_strings.dart';
import '../models/station_board_model.dart';
import 'adif_live_repository.dart';
import 'settings_service.dart';
import 'station_widget_cache.dart';

class SupabaseAdifRepository implements AdifLiveRepository {
  final SettingsService settingsService;

  SupabaseAdifRepository({required this.settingsService});

  @override
  List<StationInfo> getAvailableStations() => StationCatalog.stations;

  @override
  Future<List<StationBoardItem>> getDepartures(String stationCode) async {
    return _fetchFromSupabase(stationCode, 'departures');
  }

  @override
  Future<List<StationBoardItem>> getArrivals(String stationCode) async {
    return _fetchFromSupabase(stationCode, 'arrivals');
  }

  Future<List<StationBoardItem>> _fetchFromSupabase(
      String stationCode, String type) async {
    final response = await Supabase.instance.client.functions.invoke(
      'adif-board',
      method: HttpMethod.get,
      queryParameters: {'station': stationCode, 'type': type},
    ).timeout(const Duration(seconds: 8));
    if (response.status != 200) {
      throw const FormatException(AppStrings.stationBoardLoadError);
    }
    final decoded = response.data;
    if (decoded is! Map<String, dynamic> || decoded['items'] is! List) {
      throw const FormatException(AppStrings.stationBoardLoadError);
    }

    final items = decoded['items'] as List<dynamic>;
    final error = decoded['error'];
    if (items.isEmpty &&
        error is String &&
        error != AppStrings.stationNoTrains) {
      throw FormatException(error);
    }

    final parsedItems = items
        .map((json) => StationBoardItem.fromJson(json as Map<String, dynamic>))
        .toList();
    if (type == 'departures') {
      final station = AdifStations.byCode(stationCode);
      if (station != null) {
        await StationWidgetCache.cacheDepartures(station, parsedItems);
      }
    }
    return parsedItems;
  }
}

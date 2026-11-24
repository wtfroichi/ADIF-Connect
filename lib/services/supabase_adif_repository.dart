import 'dart:convert';
import 'dart:io';
import '../core/constants/adif_stations.dart';
import '../core/constants/app_strings.dart';
import '../models/station_board_model.dart';
import 'adif_live_repository.dart';
import 'settings_service.dart';
import 'station_widget_cache.dart';

class SupabaseAdifRepository implements AdifLiveRepository {
  final SettingsService settingsService;
  final HttpClient _httpClient = HttpClient();

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
    final base = SettingsService.supabaseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse(
        '$base/functions/v1/adif-board?station=$stationCode&type=$type');

    final request = await _httpClient.getUrl(uri);
    request.headers
        .set('Authorization', 'Bearer ${SettingsService.supabaseAnonKey}');
    request.headers.set('apikey', SettingsService.supabaseAnonKey);
    request.headers.set('Accept', 'application/json');

    final response = await request.close().timeout(const Duration(seconds: 8));
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('ADIF board returned HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic> || decoded['items'] is! List) {
      throw const FormatException('Invalid ADIF board response');
    }

    final items = decoded['items'] as List<dynamic>;
    final error = decoded['error'];
    if (items.isEmpty &&
        error is String &&
        error != AppStrings.stationNoTrains) {
      throw HttpException(error);
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

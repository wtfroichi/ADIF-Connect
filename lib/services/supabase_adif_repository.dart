import 'dart:convert';
import 'dart:io';
import '../models/station_board_model.dart';
import 'adif_live_repository.dart';
import 'settings_service.dart';

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
    try {
      final base = SettingsService.supabaseUrl.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse(
          '$base/functions/v1/adif-board?station=$stationCode&type=$type');

      final request = await _httpClient.getUrl(uri);
      request.headers
          .set('Authorization', 'Bearer ${SettingsService.supabaseAnonKey}');
      request.headers.set('apikey', SettingsService.supabaseAnonKey);
      request.headers.set('Accept', 'application/json');

      final response =
          await request.close().timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final dynamic decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic> && decoded['items'] is List) {
          final List<dynamic> list = decoded['items'] as List<dynamic>;
          return list
              .map((json) =>
                  StationBoardItem.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {
      // Return empty list on failure so StationBoardScreen shows the retry state
    }

    return const [];
  }
}

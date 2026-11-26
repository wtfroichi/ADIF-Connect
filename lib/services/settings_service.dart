import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/adif_stations.dart';
import 'station_widget_cache.dart';

class SettingsService extends ChangeNotifier {
  static const String _keyDefaultStation = 'settings_default_station';
  static const String _keyNearestStation = 'settings_nearest_station';
  static const String _keyLiveActivities = 'settings_live_activities_enabled';

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tzfmyfyecfzanjokeugy.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_inw5P8_x_530ztDwY7xnGg_gqlDCjrU',
  );

  String _defaultStationCode = '22100';
  bool _useNearestStation = false;
  bool _liveActivitiesEnabled = true;

  String get defaultStationCode => _defaultStationCode;
  bool get useNearestStation => _useNearestStation;
  bool get liveActivitiesEnabled => _liveActivitiesEnabled;
  bool get useLiveSupabase => true;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStation = prefs.getString(_keyDefaultStation) ?? '22100';
      _defaultStationCode =
          AdifStations.byCode(savedStation)?.adifCode ?? '22100';
      _useNearestStation = prefs.getBool(_keyNearestStation) ?? false;
      _liveActivitiesEnabled = prefs.getBool(_keyLiveActivities) ?? true;
      final station = AdifStations.byCode(_defaultStationCode);
      if (station != null) {
        await StationWidgetCache.updateDefaultStation(station);
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> updateSettings({
    String? defaultStationCode,
    bool? useNearestStation,
    bool? liveActivitiesEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (defaultStationCode != null) {
      _defaultStationCode = defaultStationCode;
      await prefs.setString(_keyDefaultStation, _defaultStationCode);
      final station = AdifStations.byCode(_defaultStationCode);
      if (station != null) {
        await StationWidgetCache.updateDefaultStation(station);
      }
    }
    if (useNearestStation != null) {
      _useNearestStation = useNearestStation;
      await prefs.setBool(_keyNearestStation, _useNearestStation);
    }
    if (liveActivitiesEnabled != null) {
      _liveActivitiesEnabled = liveActivitiesEnabled;
      await prefs.setBool(_keyLiveActivities, _liveActivitiesEnabled);
    }

    notifyListeners();
  }
}

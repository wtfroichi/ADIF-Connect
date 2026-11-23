import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _keyDefaultStation = 'settings_default_station';
  static const String _keyLiveActivities = 'settings_live_activities_enabled';

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tzfmyfyecfzanjokeugy.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_inw5P8_x_530ztDwY7xnGg_gqlDCjrU',
  );

  String _defaultStationCode = 'OUR';
  bool _liveActivitiesEnabled = true;

  String get defaultStationCode => _defaultStationCode;
  bool get liveActivitiesEnabled => _liveActivitiesEnabled;
  bool get useLiveSupabase => true;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _defaultStationCode = prefs.getString(_keyDefaultStation) ?? 'OUR';
      _liveActivitiesEnabled = prefs.getBool(_keyLiveActivities) ?? true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> updateSettings({
    String? defaultStationCode,
    bool? liveActivitiesEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (defaultStationCode != null) {
      _defaultStationCode = defaultStationCode;
      await prefs.setString(_keyDefaultStation, _defaultStationCode);
    }
    if (liveActivitiesEnabled != null) {
      _liveActivitiesEnabled = liveActivitiesEnabled;
      await prefs.setBool(_keyLiveActivities, _liveActivitiesEnabled);
    }

    notifyListeners();
  }
}

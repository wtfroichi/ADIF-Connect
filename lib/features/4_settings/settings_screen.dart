import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/constants/adif_stations.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/station_picker_field.dart';
import '../../services/adif_live_repository.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsService settingsService;
  final AdifLiveRepository adifRepository;

  const SettingsScreen({
    super.key,
    required this.settingsService,
    required this.adifRepository,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _liveActivities;
  late String _defaultStation;

  @override
  void initState() {
    super.initState();
    final s = widget.settingsService;
    _liveActivities = s.liveActivitiesEnabled;
    _defaultStation = s.defaultStationCode;
  }

  Future<void> _saveSettings() async {
    await widget.settingsService.updateSettings(
      liveActivitiesEnabled: _liveActivities,
      defaultStationCode: _defaultStation,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.settingsSavedSuccess),
          backgroundColor: AppTheme.adifTeal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final stations = widget.adifRepository.getAvailableStations();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section: Live Activities
          GlassContainer(
            padding: const EdgeInsets.all(18),
            borderRadius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.settingsLiveActivities,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                    ),
                    CupertinoSwitch(
                      value: _liveActivities,
                      activeColor: AppTheme.adifTeal,
                      onChanged: (val) {
                        setState(() => _liveActivities = val);
                        _saveSettings();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.settingsLiveActivitiesDesc,
                  style: TextStyle(fontSize: 13, color: onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section: Default Station
          GlassContainer(
            padding: const EdgeInsets.all(18),
            borderRadius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.settingsDefaultStation,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                StationPickerField(
                  label: AppStrings.settingsDefaultStation,
                  value:
                      AdifStations.byCode(_defaultStation) ??
                      (stations.isNotEmpty ? stations.first : null),
                  onChanged: (station) {
                    setState(() => _defaultStation = station.adifCode);
                    _saveSettings();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          GlassContainer(
            padding: const EdgeInsets.all(18),
            borderRadius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.settingsRealtimeSources,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                _sourceRow(
                  context,
                  Icons.train_rounded,
                  AppStrings.settingsAdifSources,
                  AppStrings.settingsAdifSourcesDescription,
                ),
                const SizedBox(height: 14),
                _sourceRow(
                  context,
                  Icons.cached_rounded,
                  AppStrings.settingsSupabaseCache,
                  AppStrings.settingsSupabaseCacheDescription,
                ),
                const SizedBox(height: 14),
                _sourceRow(
                  context,
                  Icons.wallet_rounded,
                  AppStrings.settingsWalletPrivacy,
                  AppStrings.settingsWalletPrivacyDescription,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // About Card & Renfe / ADIF System Theme
          GlassContainer(
            padding: const EdgeInsets.all(18),
            borderRadius: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.appName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppStrings.settingsVersion} 1.0.0 (Build 1)',
                      style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.adifTeal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.adifTeal.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'RENFE / ADIF iOS 27',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.adifTeal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 140),
        ],
      ),
    );
  }

  Widget _sourceRow(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: AppTheme.adifTeal),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

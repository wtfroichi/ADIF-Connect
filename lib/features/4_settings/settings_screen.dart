import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/adif_stations.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/station_picker_field.dart';
import '../../services/adif_live_repository.dart';
import '../../services/settings_service.dart';
import '../../services/station_location_service.dart';

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
  late bool _useNearestStation;
  late String _defaultStation;
  bool _isLocatingNearest = false;

  @override
  void initState() {
    super.initState();
    final s = widget.settingsService;
    _liveActivities = s.liveActivitiesEnabled;
    _useNearestStation = s.useNearestStation;
    _defaultStation = s.defaultStationCode;
    s.addListener(_syncSettingsFromService);
  }

  @override
  void dispose() {
    widget.settingsService.removeListener(_syncSettingsFromService);
    super.dispose();
  }

  void _syncSettingsFromService() {
    if (!mounted) return;
    final service = widget.settingsService;
    setState(() {
      _liveActivities = service.liveActivitiesEnabled;
      _useNearestStation = service.useNearestStation;
      _defaultStation = service.defaultStationCode;
    });
  }

  Future<void> _saveSettings() async {
    await widget.settingsService.updateSettings(
      liveActivitiesEnabled: _liveActivities,
      defaultStationCode: _defaultStation,
      useNearestStation: _useNearestStation,
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

  Future<void> _selectNearestStation() async {
    if (_isLocatingNearest) return;
    setState(() => _isLocatingNearest = true);
    try {
      final station = await StationLocationService().findNearestStation();
      await widget.settingsService.updateSettings(
        defaultStationCode: station.adifCode,
        useNearestStation: true,
      );
      if (!mounted) return;
      setState(() {
        _defaultStation = station.adifCode;
        _useNearestStation = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.stationDefaultUpdated}: ${station.name}',
          ),
          backgroundColor: AppTheme.adifTeal,
        ),
      );
    } on StationLocationException catch (error) {
      if (!mounted) return;
      final message = switch (error.failure) {
        StationLocationFailure.serviceDisabled =>
          AppStrings.stationLocationServiceDisabled,
        StationLocationFailure.permissionDenied =>
          AppStrings.stationLocationPermissionDenied,
        StationLocationFailure.permissionDeniedForever =>
          AppStrings.stationLocationPermissionDeniedForever,
        StationLocationFailure.stationNotFound =>
          AppStrings.stationNearestUnavailable,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.stationNearestUnavailable)),
      );
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.stationNearestUnavailable)),
      );
    } finally {
      if (mounted) setState(() => _isLocatingNearest = false);
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
                const SizedBox(height: 4),
                Text(
                  AppStrings.settingsNearestStationDescription,
                  style: TextStyle(fontSize: 13, color: onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed:
                        _isLocatingNearest ? null : _selectNearestStation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLocatingNearest)
                          const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        else
                          const Icon(CupertinoIcons.location_fill, size: 17),
                        const SizedBox(width: 8),
                        Text(
                          _isLocatingNearest
                              ? AppStrings.stationNearestLoading
                              : AppStrings.stationNearestAction,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                StationPickerField(
                  label: AppStrings.settingsDefaultStation,
                  value: AdifStations.byCode(_defaultStation) ??
                      (stations.isNotEmpty ? stations.first : null),
                  onChanged: (station) {
                    setState(() {
                      _defaultStation = station.adifCode;
                      _useNearestStation = false;
                    });
                    _saveSettings();
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _useNearestStation
                      ? '${AppStrings.stationIsDefault} · ${AppStrings.stationNearestAction}'
                      : AppStrings.stationCoordinatesCredit,
                  style: TextStyle(fontSize: 12, color: onSurfaceVariant),
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

          // About card
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
                const Icon(
                  CupertinoIcons.train_style_one,
                  color: AppTheme.adifTeal,
                  size: 24,
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

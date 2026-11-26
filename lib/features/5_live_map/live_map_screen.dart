import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/operator_themes.dart';
import '../../core/widgets/glass_container.dart';
import '../../models/live_train_model.dart';
import '../../services/live_fleet_service.dart';

class LiveMapScreen extends StatefulWidget {
  final bool isVisible;

  const LiveMapScreen({super.key, required this.isVisible});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  static const _initialCenter = LatLng(40.2, -3.7);
  final _fleetService = LiveFleetService();
  final _mapController = MapController();
  Timer? _refreshTimer;
  List<LiveTrain> _trains = const [];
  bool _isLoading = true;
  bool _hasError = false;
  double _zoom = 5.2;
  String _filter = AppStrings.mapFilterAll;

  @override
  void initState() {
    super.initState();
    if (widget.isVisible) _startRefresh();
  }

  @override
  void didUpdateWidget(covariant LiveMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible == oldWidget.isVisible) return;
    if (widget.isVisible) {
      _startRefresh();
    } else {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final trains = await _fleetService.fetchTrains();
      if (!mounted) return;
      setState(() {
        _trains = trains;
        _isLoading = false;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _startRefresh() {
    _refresh();
    _refreshTimer?.cancel();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  List<LiveTrain> get _visibleTrains {
    if (_filter == AppStrings.mapFilterAll) return _trains;
    if (_filter == AppStrings.mapFilterHighSpeed) {
      return _trains
          .where((train) => const {'RENFE AVE', 'RENFE AVANT', 'RENFE AVLO'}
              .contains(train.serviceBrand))
          .toList();
    }
    return _trains
        .where((train) => const {'RENFE INTERCITY', 'RENFE REGIONAL'}
            .contains(train.serviceBrand))
        .toList();
  }

  OperatorStyle _styleFor(LiveTrain train, bool isDark) {
    if (train.serviceBrand == 'RENFE CERCANÍAS') {
      return OperatorThemes.forTrain(RailOperator.renfeCercanias, 'CERCANÍAS',
          isDark: isDark);
    }
    if (train.serviceBrand == 'RENFE') {
      return OperatorThemes.of(RailOperator.adif);
    }
    return OperatorThemes.forTrain(RailOperator.renfe, train.serviceBrand,
        isDark: isDark);
  }

  void _showTrain(LiveTrain train, bool isDark) {
    final style = _styleFor(train, isDark);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: GlassContainer(
            padding: const EdgeInsets.all(22),
            borderRadius: 24,
            backgroundColor:
                AppTheme.getSurfaceColor(context).withValues(alpha: 0.94),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${train.serviceBrand} · ${train.trainNumber}',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: style.primary),
                      ),
                    ),
                    IconButton(
                      tooltip: AppStrings.ticketClose,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                if (train.origin != null || train.destination != null)
                  Text(
                    '${train.origin ?? '—'} → ${train.destination ?? '—'}',
                    style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                const SizedBox(height: 12),
                _detailRow(
                  Icons.speed_rounded,
                  train.speedKmh == null
                      ? AppStrings.mapSpeedUnavailable
                      : '${train.speedKmh!.round()} ${AppStrings.mapSpeedUnit}',
                  context,
                ),
                _detailRow(
                  Icons.schedule_rounded,
                  train.delayMinutes == null
                      ? AppStrings.mapDelayUnavailable
                      : train.delayMinutes! > 0
                          ? '+${train.delayMinutes} ${AppStrings.mapDelayMinuteUnit}'
                          : AppStrings.stationStatusOnTime,
                  context,
                ),
                if (train.currentStation != null)
                  _detailRow(
                      Icons.place_outlined, train.currentStation!, context),
                if (train.nextStop != null)
                  _detailRow(Icons.flag_outlined,
                      '${AppStrings.mapNextStop}: ${train.nextStop}', context),
                if (train.platform != null)
                  _detailRow(Icons.train_outlined,
                      '${AppStrings.mapPlatform} ${train.platform}', context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text, BuildContext context) =>
      Padding(
        padding: const EdgeInsets.only(top: 9),
        child: Row(
          children: [
            Icon(icon, size: 17, color: AppTheme.adifTeal),
            const SizedBox(width: 9),
            Expanded(
                child: Text(text,
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final background = AppTheme.getBackgroundColor(context);
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _initialCenter,
            initialZoom: _zoom,
            onPositionChanged: (camera, _) {
              if ((_zoom - camera.zoom).abs() >= 0.4 && mounted) {
                setState(() => _zoom = camera.zoom);
              }
            },
          ),
          children: [
            if (isDark)
              ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  0.38,
                  0,
                  0,
                  0,
                  8,
                  0,
                  0.38,
                  0,
                  0,
                  14,
                  0,
                  0,
                  0.42,
                  0,
                  22,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
                child: TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'es.andenlibre.app',
                ),
              )
            else
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'es.andenlibre.app',
              ),
            MarkerLayer(
              markers: [
                for (final train in _visibleTrains)
                  Marker(
                    point: LatLng(train.latitude, train.longitude),
                    width: _zoom < 10.5 ? 34 : 126,
                    height: 38,
                    child: _trainMarker(train, isDark),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(AppStrings.mapFilterAll),
                const SizedBox(width: 8),
                _filterChip(AppStrings.mapFilterHighSpeed),
                const SizedBox(width: 8),
                _filterChip(AppStrings.mapFilterRegional),
              ],
            ),
          ),
        ),
        if (_isLoading || _hasError || (!_isLoading && _trains.isEmpty))
          Center(
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              borderRadius: 18,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoading) ...[
                    const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      _isLoading
                          ? AppStrings.mapLoading
                          : _hasError
                              ? AppStrings.mapUnavailable
                              : AppStrings.mapNoPositions,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_hasError) ...[
                    const SizedBox(width: 8),
                    IconButton(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded)),
                  ],
                ],
              ),
            ),
          ),
        Positioned(
          left: 8,
          bottom: 86,
          child: DecoratedBox(
            decoration: BoxDecoration(
                color: background.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              child: Wrap(
                spacing: 5,
                children: [
                  _attributionLink(
                    AppStrings.mapOsmAttribution,
                    'https://www.openstreetmap.org/copyright',
                  ),
                  const Text('·'),
                  _attributionLink(
                    AppStrings.mapRenfeAttribution,
                    'https://data.renfe.com/dataset/posicion-vehiculos-av-ld-md',
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 102,
          child: FloatingActionButton.small(
            heroTag: 'live-map-refresh',
            onPressed: _refresh,
            backgroundColor: AppTheme.adifPrimary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.refresh_rounded),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String value) {
    final selected = _filter == value;
    return FilterChip(
      selected: selected,
      label: Text(value),
      onSelected: (_) => setState(() => _filter = value),
      showCheckmark: false,
      selectedColor: AppTheme.adifMint,
      labelStyle: TextStyle(
        color: selected
            ? AppTheme.adifPrimary
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor:
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      side: BorderSide(color: AppTheme.adifTeal.withValues(alpha: 0.28)),
    );
  }

  Widget _attributionLink(String label, String url) => InkWell(
        onTap: () => launchUrl(Uri.parse(url)),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            decoration: TextDecoration.underline,
          ),
        ),
      );

  Widget _trainMarker(LiveTrain train, bool isDark) {
    final style = _styleFor(train, isDark);
    final compact = _zoom < 10.5;
    return GestureDetector(
      onTap: () => _showTrain(train, isDark),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: compact ? 34 : 126,
        height: 34,
        padding: compact
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: style.primary,
          shape: compact ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: compact ? null : BorderRadius.circular(18),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.88), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.train_rounded, size: 18, color: Colors.white),
            if (!compact) ...[
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  '${_shortBrand(train.serviceBrand)} ${train.trainNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _shortBrand(String brand) =>
      brand.replaceFirst('RENFE ', '').replaceFirst('CERCANÍAS', 'CERC.');
}

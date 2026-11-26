import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
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
  final Set<TrainCategory> _selectedCategories = {};
  double _rotation = 0;
  bool _northLocked = true;
  bool _isLocating = false;

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
    if (_selectedCategories.isEmpty) return _trains;
    return _trains
        .where((train) =>
            train.category != null &&
            _selectedCategories.contains(train.category))
        .toList(growable: false);
  }

  Color _colorFor(LiveTrain train) =>
      train.category?.color ?? const Color(0xFF64748B);

  String _labelFor(TrainCategory category) => switch (category) {
        TrainCategory.ave => AppStrings.mapFilterAve,
        TrainCategory.avlo => AppStrings.mapFilterAvlo,
        TrainCategory.avant => AppStrings.mapFilterAvant,
        TrainCategory.alviaEuromed => AppStrings.mapFilterAlviaEuromed,
        TrainCategory.intercityMedia => AppStrings.mapFilterIntercityMedia,
        TrainCategory.rexional => AppStrings.mapFilterRexional,
        TrainCategory.cercanias => AppStrings.mapFilterCercanias,
      };

  int _countFor(TrainCategory category) =>
      _trains.where((train) => train.category == category).length;

  void _toggleCategory(TrainCategory category) {
    setState(() {
      if (!_selectedCategories.add(category)) {
        _selectedCategories.remove(category);
      }
    });
  }

  void _resetFilters() => setState(_selectedCategories.clear);

  void _toggleNorthLock() {
    _mapController.rotate(0);
    setState(() {
      _rotation = 0;
      _northLocked = !_northLocked;
    });
  }

  Future<void> _centerOnLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationServiceDisabledException();
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        throw const PermissionDeniedException('Location permission denied');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      _mapController.move(LatLng(position.latitude, position.longitude), 11);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.mapLocationUnavailable)),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showSpainOverview() => _mapController.move(_initialCenter, 5.2);

  void _showTrain(LiveTrain train) {
    final color = _colorFor(train);
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
                            color: color),
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
                if (train.category != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      _labelFor(train.category!),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (train.category != null) const SizedBox(height: 4),
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
            initialRotation: _rotation,
            interactionOptions: InteractionOptions(
              flags: _northLocked
                  ? InteractiveFlag.all & ~InteractiveFlag.rotate
                  : InteractiveFlag.all,
            ),
            onPositionChanged: (camera, _) {
              final zoomChanged = (_zoom - camera.zoom).abs() >= 0.4;
              final rotationChanged =
                  (_rotation - camera.rotation).abs() >= 0.5;
              if ((zoomChanged || rotationChanged) && mounted) {
                setState(() {
                  _zoom = camera.zoom;
                  _rotation = camera.rotation;
                });
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
                    width: _zoom < 6.5
                        ? 14
                        : _zoom < 8.5
                            ? 26
                            : 148,
                    height: _zoom < 6.5 ? 14 : 38,
                    child: _trainMarker(train),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 8,
          left: 12,
          right: 12,
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            borderRadius: 22,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _allFilterChip(),
                  for (final category in TrainCategory.values) ...[
                    const SizedBox(width: 6),
                    _filterChip(category),
                  ],
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 66,
          right: 12,
          child: Column(
            children: [
              _compassButton(),
              const SizedBox(height: 8),
              _hudButton(
                icon: _isLocating ? null : Icons.my_location_rounded,
                tooltip: AppStrings.mapCenterLocation,
                onPressed: _centerOnLocation,
                isLoading: _isLocating,
              ),
              const SizedBox(height: 8),
              _hudButton(
                icon: Icons.public_rounded,
                tooltip: AppStrings.mapSpainOverview,
                onPressed: _showSpainOverview,
              ),
              const SizedBox(height: 8),
              _hudButton(
                icon: Icons.add_rounded,
                tooltip: AppStrings.mapZoomIn,
                onPressed: () => _mapController.move(
                  _mapController.camera.center,
                  (_zoom + 1).clamp(2, 18),
                ),
              ),
              const SizedBox(height: 8),
              _hudButton(
                icon: Icons.remove_rounded,
                tooltip: AppStrings.mapZoomOut,
                onPressed: () => _mapController.move(
                  _mapController.camera.center,
                  (_zoom - 1).clamp(2, 18),
                ),
              ),
            ],
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
          bottom: 126,
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
          bottom: 142,
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

  Widget _allFilterChip() => _countFilterChip(
        label: AppStrings.mapFilterAll,
        count: _trains.length,
        color: AppTheme.adifTeal,
        selected: _selectedCategories.isEmpty,
        onSelected: _resetFilters,
      );

  Widget _filterChip(TrainCategory category) => _countFilterChip(
        label: _labelFor(category),
        count: _countFor(category),
        color: category.color,
        selected: _selectedCategories.contains(category),
        onSelected: () => _toggleCategory(category),
      );

  Widget _countFilterChip({
    required String label,
    required int count,
    required Color color,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return FilterChip(
      selected: selected,
      avatar: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 6),
          Text('$count'),
        ],
      ),
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: color.withValues(alpha: 0.22),
      labelStyle: TextStyle(
        color: onSurface,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor:
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
      side: BorderSide(
        color: selected
            ? color.withValues(alpha: 0.85)
            : color.withValues(alpha: 0.28),
        width: selected ? 1.2 : 0.8,
      ),
    );
  }

  Widget _hudButton({
    required IconData? icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) =>
      Tooltip(
        message: tooltip,
        child: GlassContainer(
          width: 46,
          height: 46,
          padding: EdgeInsets.zero,
          borderRadius: 23,
          onTap: onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon,
                    size: 20, color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      );

  Widget _compassButton() {
    final tooltip =
        _northLocked ? AppStrings.mapNorthLocked : AppStrings.mapOrientNorth;
    return Tooltip(
      message: tooltip,
      child: GlassContainer(
        width: 46,
        height: 46,
        padding: EdgeInsets.zero,
        borderRadius: 23,
        onTap: _toggleNorthLock,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 4,
              child: Text(
                'N',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Transform.rotate(
              angle: -_rotation * math.pi / 180,
              child: const Icon(
                Icons.navigation_rounded,
                size: 21,
                color: Color(0xFFE5484D),
              ),
            ),
            if (_northLocked)
              Positioned(
                right: 7,
                bottom: 7,
                child: Icon(
                  Icons.lock_rounded,
                  size: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
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

  Widget _trainMarker(LiveTrain train) {
    final color = _colorFor(train);
    final foreground = train.category?.foreground ?? Colors.white;
    final compact = _zoom < 8.5;
    final compactSize = _zoom < 6.5 ? 14.0 : 26.0;
    return GestureDetector(
      onTap: () => _showTrain(train),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: compact ? compactSize : 126,
        height: compact ? compactSize : 34,
        padding: compact
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: color,
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
            if (train.bearingDegrees != null)
              Transform.rotate(
                angle: train.bearingDegrees! * math.pi / 180,
                child: Icon(
                  Icons.navigation_rounded,
                  size: compact && compactSize < 20 ? 9 : 16,
                  color: foreground,
                ),
              )
            else
              Icon(
                Icons.train_rounded,
                size: compact && compactSize < 20 ? 9 : 18,
                color: foreground,
              ),
            if (!compact) ...[
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  '${train.category == null ? 'RENFE' : _shortCategory(train.category!)} ${train.trainNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: foreground),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _shortCategory(TrainCategory category) => switch (category) {
        TrainCategory.ave => 'AVE',
        TrainCategory.avlo => 'AVLO',
        TrainCategory.avant => 'AVANT',
        TrainCategory.alviaEuromed => 'ALVIA',
        TrainCategory.intercityMedia => 'IC/MD',
        TrainCategory.rexional => 'REG.',
        TrainCategory.cercanias => 'CERC.',
      };
}

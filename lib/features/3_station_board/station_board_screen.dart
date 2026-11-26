import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/adif_stations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/station_picker_field.dart';
import '../../models/station_board_model.dart';
import '../../services/adif_live_repository.dart';
import '../../services/settings_service.dart';
import '../../services/station_location_service.dart';
import 'station_board_row.dart';

class StationBoardScreen extends StatefulWidget {
  final AdifLiveRepository adifRepository;
  final SettingsService settingsService;
  final String initialStationCode;

  const StationBoardScreen({
    super.key,
    required this.adifRepository,
    required this.settingsService,
    required this.initialStationCode,
  });

  @override
  State<StationBoardScreen> createState() => _StationBoardScreenState();
}

class _StationBoardScreenState extends State<StationBoardScreen> {
  late StationInfo _selectedStation;
  BoardType _currentBoard = BoardType.departures;
  List<StationBoardItem> _items = [];
  bool _isLoading = true;
  bool _hasLoadError = false;
  bool _isLocatingNearest = false;
  int _requestId = 0;
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _currentTime = _madridNow();
    final stations = widget.adifRepository.getAvailableStations();
    _selectedStation =
        AdifStations.byCode(widget.initialStationCode) ?? stations.first;
    _fetchBoardData();

    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = _madridNow());
      }
    });
  }

  @override
  void didUpdateWidget(covariant StationBoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStationCode == oldWidget.initialStationCode) return;
    final stations = widget.adifRepository.getAvailableStations();
    final station =
        AdifStations.byCode(widget.initialStationCode) ?? stations.first;
    setState(() => _selectedStation = station);
    _fetchBoardData();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _fetchBoardData() async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });
    try {
      final data = _currentBoard == BoardType.departures
          ? await widget.adifRepository.getDepartures(_selectedStation.code)
          : await widget.adifRepository.getArrivals(_selectedStation.code);
      final items = List<StationBoardItem>.from(data)
        ..sort(_compareItemsByTime);

      if (mounted && requestId == _requestId) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && requestId == _requestId) {
        setState(() {
          _items = const [];
          _hasLoadError = true;
          _isLoading = false;
        });
      }
    }
  }

  int _compareItemsByTime(StationBoardItem a, StationBoardItem b) {
    int minutes(String value) {
      final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
      if (match == null) return -1;
      return int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
    }

    final aMinutes = minutes(a.scheduledTime);
    final bMinutes = minutes(b.scheduledTime);
    if (aMinutes >= 0 && bMinutes >= 0 && aMinutes != bMinutes) {
      return aMinutes.compareTo(bMinutes);
    }
    return a.scheduledTime.compareTo(b.scheduledTime) != 0
        ? a.scheduledTime.compareTo(b.scheduledTime)
        : a.trainNumber.compareTo(b.trainNumber);
  }

  DateTime _madridNow() {
    final utc = DateTime.now().toUtc();
    final marchLastDay = DateTime.utc(utc.year, 3, 31);
    final octoberLastDay = DateTime.utc(utc.year, 10, 31);
    final summerStarts = DateTime.utc(
      utc.year,
      3,
      31 - marchLastDay.weekday % 7,
      1,
    );
    final summerEnds = DateTime.utc(
      utc.year,
      10,
      31 - octoberLastDay.weekday % 7,
      1,
    );
    final isSummer = !utc.isBefore(summerStarts) && utc.isBefore(summerEnds);
    return utc.add(Duration(hours: isSummer ? 2 : 1));
  }

  String _formatLiveClock(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectStation(StationInfo station) async {
    setState(() => _selectedStation = station);
    await _fetchBoardData();
  }

  Future<void> _setDefaultStation() async {
    await widget.settingsService.updateSettings(
      defaultStationCode: _selectedStation.adifCode,
      useNearestStation: false,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${AppStrings.stationDefaultUpdated}: ${_selectedStation.name}',
        ),
      ),
    );
  }

  Future<void> _useNearestStation() async {
    if (_isLocatingNearest) return;
    setState(() => _isLocatingNearest = true);
    try {
      final station = await StationLocationService().findNearestStation();
      await widget.settingsService.updateSettings(
        defaultStationCode: station.adifCode,
        useNearestStation: true,
      );
      if (!mounted) return;
      if (_selectedStation.adifCode != station.adifCode) {
        setState(() => _selectedStation = station);
        await _fetchBoardData();
      }
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: StationPickerField(
                      label: AppStrings.stationSelectorLabel,
                      value: AdifStations.byCode(_selectedStation.adifCode),
                      accentColor: AppTheme.adifPrimary,
                      onChanged: _selectStation,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildNearestButton(),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    CupertinoIcons.clock,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${AppStrings.stationLiveClock} ${_formatLiveClock(_currentTime)}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Spacer(),
                  _buildDefaultStationButton(),
                ],
              ),
              const SizedBox(height: 12),
              _buildBoardSwitcher(context),
            ],
          ),
        ),
        Expanded(child: _buildBoardContent(context)),
      ],
    );
  }

  Widget _buildNearestButton() {
    final child = _isLocatingNearest
        ? const CupertinoActivityIndicator()
        : const Icon(CupertinoIcons.location_circle, size: 22);
    return Tooltip(
      message: AppStrings.stationNearestAction,
      child: Platform.isIOS
          ? CupertinoButton(
              padding: const EdgeInsets.all(8),
              onPressed: _isLocatingNearest ? null : _useNearestStation,
              child: child,
            )
          : IconButton(
              tooltip: AppStrings.stationNearestAction,
              onPressed: _isLocatingNearest ? null : _useNearestStation,
              icon: child,
              color: AppTheme.adifPrimary,
            ),
    );
  }

  Widget _buildDefaultStationButton() {
    final isDefault =
        widget.settingsService.defaultStationCode == _selectedStation.adifCode;
    if (Platform.isIOS) {
      return CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        onPressed: isDefault ? null : _setDefaultStation,
        child: Text(
          isDefault
              ? AppStrings.stationIsDefault
              : AppStrings.stationSetAsDefault,
        ),
      );
    }
    return TextButton(
      onPressed: isDefault ? null : _setDefaultStation,
      child: Text(
        isDefault
            ? AppStrings.stationIsDefault
            : AppStrings.stationSetAsDefault,
      ),
    );
  }

  Widget _buildBoardSwitcher(BuildContext context) {
    if (Platform.isIOS) {
      return SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<BoardType>(
          groupValue: _currentBoard,
          backgroundColor: CupertinoColors.systemFill.resolveFrom(context),
          thumbColor:
              CupertinoColors.secondarySystemBackground.resolveFrom(context),
          children: const {
            BoardType.departures: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(AppStrings.stationsDepartures),
            ),
            BoardType.arrivals: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(AppStrings.stationsArrivals),
            ),
          },
          onValueChanged: (value) {
            if (value == null || value == _currentBoard) return;
            setState(() => _currentBoard = value);
            _fetchBoardData();
          },
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<BoardType>(
        segments: const [
          ButtonSegment(
            value: BoardType.departures,
            label: Text(AppStrings.stationsDepartures),
            icon: Icon(Icons.train),
          ),
          ButtonSegment(
            value: BoardType.arrivals,
            label: Text(AppStrings.stationsArrivals),
            icon: Icon(Icons.train_outlined),
          ),
        ],
        selected: {_currentBoard},
        onSelectionChanged: (selection) {
          final value = selection.first;
          if (value == _currentBoard) return;
          setState(() => _currentBoard = value);
          _fetchBoardData();
        },
      ),
    );
  }

  Widget _buildBoardContent(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Platform.isIOS
            ? const CupertinoActivityIndicator()
            : const CircularProgressIndicator(),
      );
    }

    final emptyState = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _hasLoadError
                  ? CupertinoIcons.exclamationmark_circle
                  : CupertinoIcons.tram_fill,
              size: 36,
              color: AppTheme.adifPrimary,
            ),
            const SizedBox(height: 12),
            Text(
              _hasLoadError
                  ? AppStrings.stationBoardLoadError
                  : AppStrings.stationNoTrains,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Platform.isIOS
                ? CupertinoButton(
                    onPressed: _fetchBoardData,
                    child: const Text(AppStrings.stationErrorRetry),
                  )
                : TextButton.icon(
                    onPressed: _fetchBoardData,
                    icon: const Icon(Icons.refresh),
                    label: const Text(AppStrings.stationErrorRetry),
                  ),
          ],
        ),
      ),
    );

    if (Platform.isIOS) {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: _fetchBoardData),
          if (_items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: emptyState,
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 140),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => StationBoardRow(
                    item: _items[index],
                    isDepartures: _currentBoard == BoardType.departures,
                  ),
                  childCount: _items.length,
                ),
              ),
            ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchBoardData,
      child: _items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [SizedBox(height: 360, child: emptyState)],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 140),
              itemCount: _items.length,
              itemBuilder: (context, index) => StationBoardRow(
                item: _items[index],
                isDepartures: _currentBoard == BoardType.departures,
              ),
            ),
    );
  }
}

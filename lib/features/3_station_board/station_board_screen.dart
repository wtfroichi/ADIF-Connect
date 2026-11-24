import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/adif_stations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/station_picker_field.dart';
import '../../models/station_board_model.dart';
import '../../services/adif_live_repository.dart';
import 'station_board_row.dart';

class StationBoardScreen extends StatefulWidget {
  final AdifLiveRepository adifRepository;
  final String initialStationCode;

  const StationBoardScreen({
    super.key,
    required this.adifRepository,
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
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });
    try {
      final data = _currentBoard == BoardType.departures
          ? await widget.adifRepository.getDepartures(_selectedStation.code)
          : await widget.adifRepository.getArrivals(_selectedStation.code);
      final items = _filterAndSortByTime(data, _madridNow());

      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _items = const [];
          _hasLoadError = true;
          _isLoading = false;
        });
      }
    }
  }

  List<StationBoardItem> _filterAndSortByTime(
    List<StationBoardItem> items,
    DateTime now,
  ) {
    final nowMinutes = now.hour * 60 + now.minute;
    final visible = items.where((item) {
      final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(item.scheduledTime);
      if (match == null) return false;
      final scheduledMinutes =
          int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
      final offset = scheduledMinutes - nowMinutes;
      return offset >= -10 && offset <= 24 * 60;
    }).toList()
      ..sort((a, b) {
        final timeOrder = a.scheduledTime.compareTo(b.scheduledTime);
        return timeOrder != 0
            ? timeOrder
            : a.trainNumber.compareTo(b.trainNumber);
      });
    return visible;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark
          ? AppTheme.stationDarkBackground
          : AppTheme.stationLightBackground,
      child: Column(
        children: [
          // ADIF Board Header: Station Selector & Live Clock
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: 18,
              backgroundColor:
                  isDark ? AppTheme.stationDarkCard : AppTheme.stationLightCard,
              borderColor: isDark
                  ? AppTheme.stationDarkBorder
                  : AppTheme.stationLightBorder,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: StationPickerField(
                      label: AppStrings.stationSelectorLabel,
                      value: AdifStations.byCode(_selectedStation.adifCode),
                      borderColor: isDark
                          ? AppTheme.darkInputBorder
                          : AppTheme.lightInputBorder,
                      accentColor: AppTheme.adifPrimary,
                      onChanged: (station) {
                        setState(() => _selectedStation = station);
                        _fetchBoardData();
                      },
                    ),
                  ),

                  // Muted local clock, styled as a secondary status indicator.
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E2631)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _formatLiveClock(_currentTime),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Departures / Arrivals Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.stationDarkCard
                    : AppTheme.stationLightCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildToggleButton(
                    BoardType.departures,
                    AppStrings.stationsDepartures,
                    Icons.train_rounded,
                  ),
                  _buildToggleButton(
                    BoardType.arrivals,
                    AppStrings.stationsArrivals,
                    Icons.directions_railway_filled_rounded,
                  ),
                ],
              ),
            ),
          ),

          // Station Board List or Real Empty/Retry State
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.adifTeal,
                    ),
                  )
                : _items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons
                                    .signal_cellular_connected_no_internet_4_bar_rounded,
                                size: 48,
                                color: AppTheme.adifTeal.withValues(alpha: 0.7),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _hasLoadError
                                    ? AppStrings.stationBoardLoadError
                                    : AppStrings.stationNoTrains,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppTheme.adifPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton.icon(
                                onPressed: _fetchBoardData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.adifPrimary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 11),
                                ),
                                icon:
                                    const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text(
                                  AppStrings.stationErrorRetry,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppTheme.adifPrimary,
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.stationDarkCard
                                : AppTheme.stationLightCard,
                        onRefresh: _fetchBoardData,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            return StationBoardRow(
                              item: _items[index],
                              isDepartures:
                                  _currentBoard == BoardType.departures,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(BoardType type, String label, IconData icon) {
    final isSelected = _currentBoard == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_currentBoard != type) {
            setState(() => _currentBoard = type);
            _fetchBoardData();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.adifTeal : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? AppTheme.adifMint
                        : AppTheme.adifPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : isDark
                          ? AppTheme.adifMint
                          : AppTheme.adifPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

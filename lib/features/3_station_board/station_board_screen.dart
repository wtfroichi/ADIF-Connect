import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_container.dart';
import '../../models/station_board_model.dart';
import '../../services/adif_live_repository.dart';
import 'station_board_row.dart';

class StationBoardScreen extends StatefulWidget {
  final AdifLiveRepository adifRepository;

  const StationBoardScreen({
    super.key,
    required this.adifRepository,
  });

  @override
  State<StationBoardScreen> createState() => _StationBoardScreenState();
}

class _StationBoardScreenState extends State<StationBoardScreen> {
  late StationInfo _selectedStation;
  BoardType _currentBoard = BoardType.departures;
  List<StationBoardItem> _items = [];
  bool _isLoading = true;
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedStation = widget.adifRepository.getAvailableStations().first;
    _fetchBoardData();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _fetchBoardData() async {
    setState(() => _isLoading = true);
    final data = _currentBoard == BoardType.departures
        ? await widget.adifRepository.getDepartures(_selectedStation.code)
        : await widget.adifRepository.getArrivals(_selectedStation.code);

    if (mounted) {
      setState(() {
        _items = data;
        _isLoading = false;
      });
    }
  }

  String _formatLiveClock(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final stations = widget.adifRepository.getAvailableStations();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppTheme.adifNavyBackground : AppTheme.adifMint,
      child: Column(
        children: [
          // ADIF Board Header: Station Selector & Live Clock
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: 18,
              backgroundColor: AppTheme.adifPrimary,
              borderColor: AppTheme.adifLime.withValues(alpha: 0.55),
              glowColor: AppTheme.adifPrimary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Station dropdown
                  DropdownButtonHideUnderline(
                    child: DropdownButton<StationInfo>(
                      value: _selectedStation,
                      dropdownColor: AppTheme.adifPrimary,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: AppTheme.adifLime),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      items: stations.map((s) {
                        return DropdownMenuItem<StationInfo>(
                          value: s,
                          child: Text(s.name),
                        );
                      }).toList(),
                      onChanged: (newStation) {
                        if (newStation != null) {
                          setState(() => _selectedStation = newStation);
                          _fetchBoardData();
                        }
                      },
                    ),
                  ),

                  // ADIF Live Official Clock with Lime Accent
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.adifNavyBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.adifMint.withValues(alpha: 0.45),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.adifLime,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatLiveClock(_currentTime),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            fontFeatures: [FontFeature.tabularFigures()],
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
                    ? AppTheme.adifMint.withValues(alpha: 0.08)
                    : AppTheme.adifTeal.withValues(alpha: 0.12),
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
                      color: AppTheme.adifLime,
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
                                AppStrings.stationNoTrains,
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
                                  backgroundColor: AppTheme.adifTeal,
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
                        color: AppTheme.adifLime,
                        backgroundColor: AppTheme.adifPrimary,
                        onRefresh: _fetchBoardData,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
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

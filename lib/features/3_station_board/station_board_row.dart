import 'package:flutter/material.dart';
import '../../core/constants/adif_stations.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/operator_themes.dart';
import '../../models/station_board_model.dart';

class StationBoardRow extends StatelessWidget {
  final StationBoardItem item;
  final bool isDepartures;

  const StationBoardRow({
    super.key,
    required this.item,
    required this.isDepartures,
  });

  @override
  Widget build(BuildContext context) {
    final targetStation = AdifStations.resolveName(
      isDepartures ? item.destination : item.origin,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface =
        isDark ? AppTheme.stationDarkCard : AppTheme.stationLightCard;
    final borderColor =
        isDark ? AppTheme.stationDarkBorder : AppTheme.stationLightBorder;
    final primaryText =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final platform = StationBoardItem.normalizePlatform(item.platform);

    final isDelayed = item.status == StationTrainStatus.delayed ||
        item.status == StationTrainStatus.boarding;
    final statusBackground = isDelayed
        ? isDark
            ? AppTheme.adifAmberDarkSurface
            : AppTheme.adifAmberLightSurface
        : AppTheme.adifTeal;
    final statusForeground = isDelayed
        ? isDark
            ? AppTheme.adifAmberDarkText
            : AppTheme.adifAmberLightText
        : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Scheduled Time, Train Badge + Silhouette, Platform
          Row(
            children: [
              // High-Contrast LED style time
              Text(
                item.scheduledTime,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: primaryText,
                  letterSpacing: -0.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (item.delayMinutes != null && item.delayMinutes! > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.adifAmberDarkSurface
                        : AppTheme.adifAmberLightSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${item.delayMinutes}m',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppTheme.adifAmberDarkText
                          : AppTheme.adifAmberLightText,
                    ),
                  ),
                ),
              ],
              const Spacer(),

              // Platform remains neutral unless the service confirms a value.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: platform != null
                      ? isDark
                          ? AppTheme.adifPlatformDarkSurface
                          : AppTheme.adifPlatformLightSurface
                      : (isDark
                          ? AppTheme.stationDarkBackground
                          : AppTheme.stationLightBackground),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: platform != null
                        ? isDark
                            ? AppTheme.adifPlatformDarkSurface
                            : AppTheme.adifPlatformLightSurface
                        : borderColor,
                  ),
                ),
                child: Text(
                  platform != null
                      ? '${AppStrings.stationVia} $platform'
                      : AppStrings.ticketPlatformPending,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: platform != null
                        ? isDark
                            ? AppTheme.adifPlatformDarkText
                            : AppTheme.adifPlatformLightText
                        : (isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _productBadge(
                  item.trainType,
                  AppTheme.isDark(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Middle Row: Destination & Train Number
          Row(
            children: [
              Expanded(
                child: Text(
                  targetStation,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Stops list (if any)
          if (item.stops.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${AppStrings.stationStops}: ${item.stops.join(" · ")}',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppTheme.adifMint.withValues(alpha: 0.8)
                    : AppTheme.adifTeal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),

          // Bottom status row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  item.status.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusForeground,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _productBadge(String raw, bool isDark) {
    final style = OperatorThemes.forTrain(
      item.operator,
      raw,
      isDark: isDark,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: style.badgeBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: style.accent, width: 0.8),
      ),
      child: FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.scaleDown,
        child: Text(
          '${style.name} · ${item.trainNumber}',
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
            color: style.badgeText,
          ),
        ),
      ),
    );
  }
}

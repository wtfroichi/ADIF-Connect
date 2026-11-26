import 'package:flutter/material.dart';

import '../../core/constants/adif_stations.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/operator_themes.dart';
import '../../core/widgets/glass_container.dart';
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
    final isDark = AppTheme.isDark(context);
    final style =
        OperatorThemes.forTrain(item.operator, item.trainType, isDark: isDark);
    final livePlatform = StationBoardItem.normalizePlatform(item.platform);
    final predictedPlatform =
        StationBoardItem.normalizePlatform(item.predictedPlatform);
    final platform = livePlatform ?? predictedPlatform;
    final station = AdifStations.resolveName(
      isDepartures ? item.destination : item.origin,
    );
    final delayed = item.delayMinutes != null && item.delayMinutes! > 0;
    final statusColor = delayed
        ? (isDark ? AppTheme.adifAmberDarkText : AppTheme.adifAmberLightText)
        : item.status == StationTrainStatus.unknown
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : (isDark ? AppTheme.adifPlatformDarkText : AppTheme.adifPrimary);
    final statusBackground = delayed
        ? (isDark
            ? AppTheme.adifAmberDarkSurface
            : AppTheme.adifAmberLightSurface)
        : statusColor.withValues(alpha: 0.12);

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      backgroundColor: style.primary.withValues(alpha: isDark ? 0.20 : 0.07),
      borderColor: style.accent.withValues(alpha: isDark ? 0.35 : 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 7,
                  runSpacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _serviceBadge(style, item.trainNumber),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _platformBadge(
                context,
                platform,
                isPredicted: livePlatform == null && predictedPlatform != null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                item.scheduledTime,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.7,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 10),
              if (item.delayMinutes != null && item.delayMinutes! > 0)
                _statusPill(
                  '+${item.delayMinutes}m',
                  isDark
                      ? AppTheme.adifAmberDarkSurface
                      : AppTheme.adifAmberLightSurface,
                  isDark
                      ? AppTheme.adifAmberDarkText
                      : AppTheme.adifAmberLightText,
                )
              else
                _statusPill(item.status.label, statusBackground, statusColor),
            ],
          ),
          if (item.estimatedTime != null &&
              item.estimatedTime != item.scheduledTime) ...[
            const SizedBox(height: 4),
            Text(
              '${AppStrings.stationEstimatedTimeLabel}: ${item.estimatedTime}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            station,
            softWrap: true,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          if (item.stops.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${AppStrings.stationStops}: ${item.stops.join(' · ')}',
              softWrap: true,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _serviceBadge(OperatorStyle style, String trainNumber) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: style.badgeBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: style.accent.withValues(alpha: 0.75)),
        ),
        child: Text(
          '${style.name} · $trainNumber',
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            color: style.badgeText,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.35,
          ),
        ),
      );

  Widget _platformBadge(
    BuildContext context,
    String? platform, {
    required bool isPredicted,
  }) {
    final label = platform == null
        ? AppStrings.ticketPlatformPending
        : '${isDepartures ? AppStrings.stationVia : AppStrings.stationArrivalVia} $platform${isPredicted ? ' (${AppStrings.ticketPredictedShort})' : ''}';
    final color = platform == null
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : isPredicted
            ? AppTheme.adifAmberDarkText
            : (AppTheme.isDark(context)
                ? AppTheme.adifPlatformDarkText
                : AppTheme.adifPlatformLightText);
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Text(
        label,
        maxLines: 2,
        textAlign: TextAlign.center,
        style:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _statusPill(String label, Color background, Color foreground) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: foreground),
        ),
      );
}

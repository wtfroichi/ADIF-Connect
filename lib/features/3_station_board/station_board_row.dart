import 'package:flutter/material.dart';
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
    final opStyle = OperatorThemes.of(item.operator);
    final targetStation = isDepartures ? item.destination : item.origin;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.adifNavySurface : AppTheme.adifMint;
    final primaryText = isDark ? Colors.white : AppTheme.adifPrimary;

    Color statusColor;
    switch (item.status) {
      case StationTrainStatus.onTime:
        statusColor = AppTheme.adifTeal;
        break;
      case StationTrainStatus.delayed:
        statusColor = AppTheme.adifTeal;
        break;
      case StationTrainStatus.boarding:
        statusColor = AppTheme.adifLime;
        break;
      case StationTrainStatus.departed:
        statusColor = AppTheme.adifMint;
        break;
      case StationTrainStatus.cancelled:
        statusColor = AppTheme.adifPrimary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: isDark ? 0.9 : 1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.adifTeal.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 10),
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
                Text(
                  '+${item.delayMinutes}m',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.adifTeal,
                  ),
                ),
              ],
              const SizedBox(width: 12),

              // Uniform rounded train icon & Type Badge
              const Icon(
                Icons.train_rounded,
                color: AppTheme.adifLime,
                size: 20,
              ),
              const SizedBox(width: 8),

              _productBadge(item.trainType),

              const Spacer(),

              // Platform (Vía) Glowing Badge with ADIF Lime/Dark Green accent
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.platform != null
                      ? AppTheme.adifPrimary.withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.platform != null
                        ? AppTheme.adifLime
                        : Colors.white.withValues(alpha: 0.15),
                    width: 1.2,
                  ),
                  boxShadow: item.platform != null
                      ? [
                          BoxShadow(
                            color: AppTheme.adifLime.withValues(alpha: 0.25),
                            blurRadius: 8,
                            spreadRadius: -1,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  item.platform != null
                      ? '${AppStrings.stationVia} ${item.platform}'
                      : AppStrings.ticketPlatformPending,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: item.platform != null
                        ? AppTheme.adifLime
                        : (isDark ? AppTheme.adifMint : AppTheme.adifPrimary),
                  ),
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
                    color: isDark ? Colors.white : AppTheme.adifPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '№ ${item.trainNumber}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.adifMint : AppTheme.adifTeal,
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
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isDark ? statusColor : AppTheme.adifPrimary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                item.status.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
              const Spacer(),
              Text(
                opStyle.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.adifLime : AppTheme.adifPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _productBadge(String raw) {
    final compact = raw.toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    String product = compact;
    if (compact.contains('AVE')) {
      product = 'AVE';
    } else if (compact.contains('AVLO')) {
      product = 'AVLO';
    } else if (compact.contains('ALVIA')) {
      product = 'ALVIA';
    } else if (compact.contains('INTERCITY') ||
        compact.contains('INTC') ||
        compact.contains('ICITY')) {
      product = 'INTERCITY';
    } else if (compact.contains('AVANT') || compact.contains('AVA')) {
      product = 'AVANT';
    } else if (RegExp(r'(^|\\s)MD($|\\s)').hasMatch(compact)) {
      product = 'MD';
    } else if (compact.contains('REGIONAL')) {
      product = compact.contains('EXP') ? 'REG.EXP.' : 'REGIONAL';
    } else if (compact.contains('CERCAN')) {
      product = 'CERCANÍAS';
    } else if (compact.contains('IRYO') || compact.contains('IRY')) {
      product = 'IRYO';
    } else if (compact.contains('OUIGO') || compact.contains('OUI')) {
      product = 'OUIGO';
    }

    const background = AppTheme.adifPrimary;
    const foreground = Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
            color: AppTheme.adifLime.withValues(alpha: 0.75), width: 0.8),
      ),
      child: Text(
        product,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
          color: foreground,
        ),
      ),
    );
  }
}

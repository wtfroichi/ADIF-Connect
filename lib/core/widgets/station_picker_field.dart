import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../constants/adif_stations.dart';
import '../constants/app_strings.dart';
import '../theme/app_theme.dart';

class StationPickerField extends StatelessWidget {
  final String label;
  final StationInfo? value;
  final ValueChanged<StationInfo> onChanged;
  final Color? borderColor;
  final Color? accentColor;

  const StationPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.borderColor,
    this.accentColor,
  });

  Future<void> _selectStation(BuildContext context) async {
    final station = Platform.isIOS
        ? await showCupertinoModalPopup<StationInfo>(
            context: context,
            builder: (context) => const _StationPickerSheet(),
          )
        : await showModalBottomSheet<StationInfo>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const _StationPickerSheet(),
          );
    if (station != null) onChanged(station);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    if (Platform.isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _selectStation(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value?.name ?? AppStrings.stationPickerHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: value == null ? muted : color,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_down,
                size: 16,
                color: muted,
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _selectStation(context),
      borderRadius: BorderRadius.circular(18),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 12, color: muted),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: borderColor ??
                  (AppTheme.isDark(context)
                      ? AppTheme.darkInputBorder
                      : AppTheme.lightInputBorder),
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: accentColor ?? AppTheme.adifTeal,
              width: 1.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value?.name ?? AppStrings.stationPickerHint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: value == null ? muted : color,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.expand_more_rounded,
                color: accentColor ?? AppTheme.adifTeal),
          ],
        ),
      ),
    );
  }
}

class _StationPickerSheet extends StatefulWidget {
  const _StationPickerSheet();

  @override
  State<_StationPickerSheet> createState() => _StationPickerSheetState();
}

class _StationPickerSheetState extends State<_StationPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final stations = AdifStations.search(_query);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final keyboardInset = media.viewInsets.bottom;
    final sheetHeight = math
        .min(
          media.size.height * 0.85,
          media.size.height - keyboardInset,
        )
        .toDouble();

    final isIOS = Platform.isIOS;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SizedBox(
        height: sheetHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isIOS
                ? CupertinoColors.systemGroupedBackground.resolveFrom(context)
                : AppTheme.getBackgroundColor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                children: [
                  if (isIOS)
                    CupertinoSearchTextField(
                      autofocus: true,
                      placeholder: AppStrings.stationsSearchHint,
                      onChanged: (value) => setState(() => _query = value),
                    )
                  else
                    TextField(
                      autofocus: true,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: AppStrings.stationsSearchHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: AppTheme.isDark(context)
                                ? AppTheme.darkInputBorder
                                : AppTheme.lightInputBorder,
                            width: 1.2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: AppTheme.isDark(context)
                                ? AppTheme.darkInputBorder
                                : AppTheme.lightInputBorder,
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: AppTheme.adifTeal,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: stations.isEmpty
                        ? Center(
                            child: Text(
                              AppStrings.stationsNoResults,
                              style: TextStyle(color: onSurface),
                            ),
                          )
                        : ListView.builder(
                            itemCount: stations.length,
                            itemBuilder: (context, index) {
                              final station = stations[index];
                              if (isIOS) {
                                return CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 10,
                                  ),
                                  onPressed: () =>
                                      Navigator.of(context).pop(station),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              station.name,
                                              style: TextStyle(
                                                color: onSurface,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${station.province} · ${station.adifCode}',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        CupertinoIcons.chevron_right,
                                        size: 15,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return ListTile(
                                title: Text(station.name,
                                    style: TextStyle(color: onSurface)),
                                subtitle: Text(
                                    '${station.province} · ${station.adifCode}'),
                                onTap: () => Navigator.of(context).pop(station),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

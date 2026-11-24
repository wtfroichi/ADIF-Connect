import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart' hide BarcodeType;
import '../../core/constants/adif_stations.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/operator_themes.dart';
import '../../core/widgets/glass_container.dart';
import '../../models/ticket_model.dart';
import '../../services/live_activity_service.dart';

class TicketDetailSheet extends StatefulWidget {
  final TicketModel ticket;
  final VoidCallback onDelete;

  const TicketDetailSheet({
    super.key,
    required this.ticket,
    required this.onDelete,
  });

  @override
  State<TicketDetailSheet> createState() => _TicketDetailSheetState();
}

class _TicketDetailSheetState extends State<TicketDetailSheet> {
  bool _isActivityRunning = false;
  bool _isActivityLoading = false;

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _stationCodeForDisplay(String code) {
    final trimmed = code.trim();
    return RegExp(r'^\d+$').hasMatch(trimmed)
        ? AdifStations.resolveName(trimmed)
        : trimmed;
  }

  Future<void> _toggleLiveActivity() async {
    if (_isActivityLoading) return;
    setState(() => _isActivityLoading = true);
    try {
      if (_isActivityRunning) {
        await LiveActivityService.instance.endActivity();
        if (!mounted) return;
        setState(() => _isActivityRunning = false);
      } else {
        final id = await LiveActivityService.instance
            .startOrUpdateActivity(widget.ticket);
        if (!mounted) return;
        setState(() => _isActivityRunning = id != null);
      }
    } on LiveActivityException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppStrings.liveActivitySetupError} (${error.toString()})',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActivityLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = OperatorThemes.forTrain(
      widget.ticket.operator,
      widget.ticket.trainType,
      isDark: AppTheme.isDark(context),
    );
    final ticketNumber = widget.ticket.ticketNumber?.trim();
    final barcodeData = ticketNumber != null && ticketNumber.isNotEmpty
        ? ticketNumber
        : widget.ticket.barcode?.message ?? '';
    final originCode = _stationCodeForDisplay(widget.ticket.originCode);
    final destinationCode =
        _stationCodeForDisplay(widget.ticket.destinationCode);
    final origin = AdifStations.resolveName(widget.ticket.origin);
    final destination = AdifStations.resolveName(widget.ticket.destination);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: AppStrings.ticketClose,
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.adifPrimary,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Main Dynamic Pass Header
            GlassContainer(
              padding: const EdgeInsets.all(20),
              borderRadius: 22,
              backgroundColor: isDark
                  ? style.primary.withValues(alpha: 0.2)
                  : style.primary.withValues(alpha: 0.08),
              borderColor: AppTheme.getGlassBorder(context),
              glowColor: style.primary,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: style.badgeBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          style.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: style.badgeText,
                          ),
                        ),
                      ),
                      if (widget.ticket.bookingReference.trim().isNotEmpty)
                        Text(
                          '${AppStrings.ticketLocalizer}: ${widget.ticket.bookingReference}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Route
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              originCode,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: onSurface,
                              ),
                            ),
                            if (origin != originCode)
                              Text(
                                origin,
                                maxLines: 2,
                                softWrap: true,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: onSurfaceVariant,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              _formatTime(widget.ticket.departureTime),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.train_rounded,
                            color: style.primary, size: 28),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              destinationCode,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: onSurface,
                              ),
                            ),
                            if (destination != destinationCode)
                              Text(
                                destination,
                                maxLines: 2,
                                softWrap: true,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: onSurfaceVariant,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              _formatTime(widget.ticket.arrivalTime),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (widget.ticket.barcode != null &&
                widget.ticket.barcode!.format != BarcodeType.unknown) ...[
              // High-Contrast Bright Aztec/QR Card
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 220,
                      height:
                          widget.ticket.barcode?.format == BarcodeType.pdf417
                              ? 140
                              : 180,
                      child: _buildBarcode(
                        widget.ticket.barcode!,
                        barcodeData,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      ticketNumber != null && ticketNumber.isNotEmpty
                          ? '${AppStrings.ticketNumber}: $ticketNumber'
                          : widget.ticket.barcode?.altText ??
                              widget.ticket.bookingReference,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      AppStrings.ticketBrightnessHint,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Stylized boarding summary badge when ticket has no barcode
              GlassContainer(
                padding: const EdgeInsets.all(22),
                borderRadius: 22,
                borderColor:
                    style.primary.withValues(alpha: isDark ? 0.4 : 0.25),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: style.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: style.primary.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.confirmation_number_outlined,
                        size: 30,
                        color: style.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.ticketNoBarcodeBadge,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.ticketNoBarcodeDesc,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: style.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: style.primary.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${AppStrings.ticketLocalizer}: ${widget.ticket.bookingReference}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Seat & Passenger Info
            GlassContainer(
              padding: const EdgeInsets.all(18),
              borderRadius: 20,
              child: Column(
                children: [
                  _buildInfoRow(AppStrings.ticketPassenger,
                      widget.ticket.passengerName, onSurface, onSurfaceVariant),
                  Divider(
                      color: isDark ? Colors.white12 : Colors.black12,
                      height: 20),
                  _buildInfoRow(
                      AppStrings.ticketDate,
                      _formatDate(widget.ticket.departureTime),
                      onSurface,
                      onSurfaceVariant),
                  Divider(
                      color: isDark ? Colors.white12 : Colors.black12,
                      height: 20),
                  Row(
                    children: [
                      Expanded(
                          child: _buildInfoItem(
                              AppStrings.ticketTrain,
                              widget.ticket.trainNumber,
                              onSurface,
                              onSurfaceVariant)),
                      Expanded(
                          child: _buildInfoItem(
                              AppStrings.ticketCar,
                              widget.ticket.coach,
                              onSurface,
                              onSurfaceVariant)),
                      Expanded(
                          child: _buildInfoItem(AppStrings.ticketSeat,
                              widget.ticket.seat, onSurface, onSurfaceVariant)),
                      Expanded(
                        child: _buildInfoItem(
                          AppStrings.ticketPlatform,
                          widget.ticket.platform ??
                              AppStrings.ticketPlatformPending,
                          onSurface,
                          onSurfaceVariant,
                          highlight: widget.ticket.platform != null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Activity button — real wiring
            GlassContainer(
              padding: const EdgeInsets.symmetric(vertical: 14),
              borderRadius: 16,
              glowColor: _isActivityRunning
                  ? AppTheme.adifTeal
                  : AppTheme.renfePrimary,
              onTap: _isActivityLoading ? null : _toggleLiveActivity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isActivityLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.renfePrimary),
                    )
                  else
                    Icon(
                      _isActivityRunning
                          ? Icons.lock_clock
                          : Icons.bolt_rounded,
                      color: _isActivityRunning
                          ? AppTheme.adifTeal
                          : AppTheme.renfePrimary,
                      size: 22,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _isActivityRunning
                        ? AppStrings.ticketLiveActivityActive
                        : AppStrings.ticketLiveActivityBtn,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Delete action
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDelete();
              },
              child: const Text(
                AppStrings.ticketDeleteConfirm,
                style: TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      String label, String value, Color onSurface, Color onSurfaceVariant) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: onSurfaceVariant, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
      String label, String value, Color onSurface, Color onSurfaceVariant,
      {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
              color: onSurfaceVariant, fontSize: 10, letterSpacing: 0.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: highlight ? AppTheme.adifTeal : onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildBarcode(TicketBarcode barcode, String data) {
    final Barcode barcodeType;
    switch (barcode.format) {
      case BarcodeType.aztec:
        barcodeType = Barcode.aztec();
        break;
      case BarcodeType.pdf417:
        barcodeType = Barcode.pdf417();
        break;
      case BarcodeType.qrCode:
        barcodeType = Barcode.qrCode();
        break;
      case BarcodeType.code128:
        barcodeType = Barcode.code128();
        break;
      case BarcodeType.unknown:
        barcodeType = Barcode.qrCode();
        break;
    }

    return BarcodeWidget(
      barcode: barcodeType,
      data: data,
      color: Colors.black,
      backgroundColor: Colors.white,
      drawText: false,
      padding: const EdgeInsets.all(8),
      errorBuilder: (context, error) => Text(
        AppStrings.ticketNoBarcodeBadge,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.red.shade700),
      ),
    );
  }
}

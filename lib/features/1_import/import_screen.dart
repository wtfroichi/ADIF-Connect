import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/constants/adif_stations.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/operator_themes.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/station_picker_field.dart';
import '../../models/ticket_model.dart';
import '../../services/adif_live_repository.dart';
import '../../services/local_file_system.dart';
import '../../services/pkpass_parser_service.dart';
import '../../services/pdf_ticket_parser_service.dart';
import '../../services/ticket_repository.dart';
import '../2_tickets/ticket_detail_sheet.dart';

enum _AddTicketAction { pkpass, pdf, manual }

class ImportScreen extends StatefulWidget {
  final TicketRepository ticketRepository;
  final AdifLiveRepository adifRepository;
  final VoidCallback onTicketImported;
  final VoidCallback onShowDepartures;
  final String defaultStationCode;

  const ImportScreen({
    super.key,
    required this.ticketRepository,
    required this.adifRepository,
    required this.onTicketImported,
    required this.onShowDepartures,
    required this.defaultStationCode,
  });

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isLoading = false;
  String? _statusMessage;
  bool _isError = false;
  bool _isStationStatusLoading = true;
  bool _hasStationStatusError = false;
  int? _stationDepartureCount;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDefaultStationStatus());
  }

  @override
  void didUpdateWidget(covariant ImportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.defaultStationCode != widget.defaultStationCode) {
      unawaited(_loadDefaultStationStatus());
    }
  }

  Future<void> _loadDefaultStationStatus() async {
    final stationCode = widget.defaultStationCode;
    setState(() {
      _isStationStatusLoading = true;
      _hasStationStatusError = false;
    });
    try {
      final departures = await widget.adifRepository.getDepartures(stationCode);
      if (!mounted || stationCode != widget.defaultStationCode) return;
      setState(() {
        _stationDepartureCount = departures.length;
        _isStationStatusLoading = false;
      });
    } catch (_) {
      if (!mounted || stationCode != widget.defaultStationCode) return;
      setState(() {
        _hasStationStatusError = true;
        _isStationStatusLoading = false;
      });
    }
  }

  String get _stationStatusText {
    if (_isStationStatusLoading) return AppStrings.homeStationLoading;
    if (_hasStationStatusError) return AppStrings.homeStationLoadError;
    final count = _stationDepartureCount ?? 0;
    return count == 0
        ? AppStrings.homeStationNoDepartures
        : AppStrings.homeStationDepartureCount(count);
  }

  void _showTicketDetails(TicketModel ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => TicketDetailSheet(
        ticket: ticket,
        onDelete: () => widget.ticketRepository.deleteTicket(ticket.id),
      ),
    );
  }

  String _countdown(DateTime departure) {
    final remaining = departure.difference(DateTime.now());
    if (remaining.isNegative) {
      return AppStrings.homeTripInProgress;
    }
    if (remaining <= const Duration(minutes: 5)) {
      return AppStrings.homeTripNow;
    }
    if (remaining.inDays > 0) {
      return '${AppStrings.homeDepartureIn} ${remaining.inDays} d ${remaining.inHours % 24} h';
    }
    if (remaining.inHours > 0) {
      return '${AppStrings.homeDepartureIn} ${remaining.inHours} h ${remaining.inMinutes % 60} min';
    }
    return '${AppStrings.homeDepartureIn} ${remaining.inMinutes} min';
  }

  Future<DateTime?> _pickDateTime(
    BuildContext context, {
    required DateTime initialDateTime,
    required DateTime minimumDate,
    required DateTime maximumDate,
  }) async {
    final initialDate = initialDateTime.isBefore(minimumDate)
        ? minimumDate
        : initialDateTime.isAfter(maximumDate)
            ? maximumDate
            : initialDateTime;
    final date = await _showWheelPicker(
      context,
      mode: CupertinoDatePickerMode.date,
      initialDateTime: initialDate,
      minimumDate: minimumDate,
      maximumDate: maximumDate,
    );
    if (date == null || !context.mounted) return null;

    final timeInitial = DateTime(
      date.year,
      date.month,
      date.day,
      initialDate.hour,
      initialDate.minute,
    );
    final time = await _showWheelPicker(
      context,
      mode: CupertinoDatePickerMode.time,
      initialDateTime: timeInitial,
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<DateTime?> _showWheelPicker(
    BuildContext context, {
    required CupertinoDatePickerMode mode,
    required DateTime initialDateTime,
    DateTime? minimumDate,
    DateTime? maximumDate,
  }) {
    var selectedDateTime = initialDateTime;
    final isDatePicker = mode == CupertinoDatePickerMode.date;
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (pickerContext) {
        final onSurface = Theme.of(pickerContext).colorScheme.onSurface;
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.getBackgroundColor(pickerContext),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(pickerContext).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 310,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            isDatePicker
                                ? AppStrings.datePickerChooseDate
                                : AppStrings.datePickerChooseTime,
                            style: TextStyle(
                              color: onSurface,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: AppTheme.adifPrimary,
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () =>
                              Navigator.of(pickerContext).pop(selectedDateTime),
                          child: const Text(AppStrings.actionConfirm),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: mode,
                      initialDateTime: initialDateTime,
                      minimumDate: isDatePicker ? minimumDate : null,
                      maximumDate: isDatePicker ? maximumDate : null,
                      dateOrder: DatePickerDateOrder.dmy,
                      use24hFormat: true,
                      onDateTimeChanged: (value) => selectedDateTime = value,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddTicketActions() async {
    final action = await showModalBottomSheet<_AddTicketAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final onSurface = theme.colorScheme.onSurface;
        final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.getSurfaceColor(sheetContext),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: AppTheme.getGlassBorder(sheetContext),
                width: 1.2,
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: onSurfaceVariant.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      AppStrings.homeAddTicket,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.homeAddTicketHint,
                      style: TextStyle(color: onSurfaceVariant, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    _buildAddTicketActionTile(
                      sheetContext,
                      icon: Icons.wallet_rounded,
                      title: AppStrings.homeImportPkpass,
                      description: AppStrings.homePkpassDescription,
                      action: _AddTicketAction.pkpass,
                    ),
                    const SizedBox(height: 10),
                    _buildAddTicketActionTile(
                      sheetContext,
                      icon: Icons.picture_as_pdf_rounded,
                      title: AppStrings.homeImportPdf,
                      description: AppStrings.homePdfDescription,
                      action: _AddTicketAction.pdf,
                    ),
                    const SizedBox(height: 10),
                    _buildAddTicketActionTile(
                      sheetContext,
                      icon: Icons.edit_note_rounded,
                      title: AppStrings.homeAddManual,
                      description: AppStrings.homeAddManualDescription,
                      action: _AddTicketAction.manual,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;
    switch (action) {
      case _AddTicketAction.pkpass:
        await _pickPkpassFile();
        break;
      case _AddTicketAction.pdf:
        await _pickPdfFile();
        break;
      case _AddTicketAction.manual:
        await _showManualEntryModal();
        break;
    }
  }

  Widget _buildAddTicketActionTile(
    BuildContext sheetContext, {
    required IconData icon,
    required String title,
    required String description,
    required _AddTicketAction action,
  }) {
    final theme = Theme.of(sheetContext);
    return Material(
      color: theme.brightness == Brightness.dark
          ? AppTheme.darkSurface
          : AppTheme.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppTheme.getGlassBorder(sheetContext)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Icon(icon, color: AppTheme.adifPrimary, size: 26),
        title: Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        onTap: () => Navigator.of(sheetContext).pop(action),
      ),
    );
  }

  Future<void> _pickPkpassFile() => _pickTicketFile(extension: 'pkpass');

  Future<void> _pickPdfFile() => _pickTicketFile(extension: 'pdf');

  Future<void> _pickTicketFile({required String extension}) async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _isError = false;
    });

    try {
      final result = extension == 'pkpass'
          ? await FilePicker.platform.pickFiles(
              type: FileType.any,
              withData: true,
            )
          : await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: const ['pdf'],
              withData: true,
            );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (!file.name.toLowerCase().endsWith('.$extension')) {
          final message = extension == 'pkpass'
              ? AppStrings.importSelectPkpass
              : AppStrings.importSelectPdf;
          if (mounted) {
            setState(() {
              _statusMessage = message;
              _isError = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
          return;
        }

        List<int>? bytes = file.bytes;
        if (bytes == null && !kIsWeb && file.path != null) {
          bytes = await readLocalFileBytes(file.path!);
        }

        if (bytes == null) {
          setState(() {
            _statusMessage = AppStrings.importInvalidFormat;
            _isError = true;
          });
          return;
        }

        final fileBytes =
            bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
        final ticket = extension == 'pdf'
            ? await PdfTicketParserService.parse(fileBytes)
            : PkpassParserService.parse(fileBytes);
        await widget.ticketRepository.saveTicket(ticket);

        if (!mounted) return;
        setState(() {
          _statusMessage = AppStrings.importSuccess;
          _isError = false;
        });
        widget.onTicketImported();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _statusMessage = '${AppStrings.importError} (${error.toString()})';
          _isError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_statusMessage!)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showManualEntryModal() async {
    final formKey = GlobalKey<FormState>();
    final trainNumCtrl = TextEditingController();
    final coachCtrl = TextEditingController();
    final seatCtrl = TextEditingController();
    final platformCtrl = TextEditingController();
    final localizerCtrl = TextEditingController();
    final passengerCtrl = TextEditingController();
    RailOperator selectedOp = RailOperator.renfe;
    String selectedTrainType = 'AVE';
    StationInfo? selectedOrigin;
    StationInfo? selectedDestination;
    DateTime? depTime;
    DateTime? arrTime;
    String ticketNumber = '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final onSurface = Theme.of(ctx).colorScheme.onSurface;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: AppTheme.getBackgroundColor(ctx),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppStrings.importManualTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Operator Selector
                      DropdownButtonFormField<RailOperator>(
                        value: selectedOp,
                        decoration:
                            _inputDec(AppStrings.importManualOperator, ctx),
                        dropdownColor: AppTheme.getSurfaceColor(ctx),
                        items: const [
                          DropdownMenuItem(
                              value: RailOperator.renfe, child: Text('RENFE')),
                          DropdownMenuItem(
                              value: RailOperator.iryo, child: Text('IRYO')),
                          DropdownMenuItem(
                              value: RailOperator.ouigo, child: Text('OUIGO')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedOp = val;
                              if (val == RailOperator.iryo) {
                                selectedTrainType = 'IRYO';
                              } else if (val == RailOperator.ouigo) {
                                selectedTrainType = 'OUIGO';
                              } else if (selectedTrainType == 'IRYO' ||
                                  selectedTrainType == 'OUIGO') {
                                selectedTrainType = 'AVE';
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      FormField<StationInfo>(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (_) => selectedOrigin == null
                            ? AppStrings.importManualRequired
                            : null,
                        builder: (field) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            StationPickerField(
                              label: AppStrings.importManualOrigin,
                              value: selectedOrigin,
                              onChanged: (station) {
                                setModalState(() => selectedOrigin = station);
                                field.didChange(station);
                              },
                            ),
                            if (field.hasError)
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 16, top: 4),
                                child: Text(field.errorText!,
                                    style: TextStyle(
                                        color: Theme.of(ctx).colorScheme.error,
                                        fontSize: 12)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      FormField<StationInfo>(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (_) => selectedDestination == null
                            ? AppStrings.importManualRequired
                            : null,
                        builder: (field) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            StationPickerField(
                              label: AppStrings.importManualDestination,
                              value: selectedDestination,
                              onChanged: (station) {
                                setModalState(
                                    () => selectedDestination = station);
                                field.didChange(station);
                              },
                            ),
                            if (field.hasError)
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 16, top: 4),
                                child: Text(field.errorText!,
                                    style: TextStyle(
                                        color: Theme.of(ctx).colorScheme.error,
                                        fontSize: 12)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedTrainType,
                              decoration: _inputDec(
                                  AppStrings.importManualTrainType, ctx),
                              dropdownColor: AppTheme.getSurfaceColor(ctx),
                              items: const [
                                'AVE',
                                'AVANT',
                                'AVLO',
                                'INTERCITY',
                                'REGIONAL',
                                'CERCANÍAS',
                                'IRYO',
                                'OUIGO',
                              ]
                                  .map((type) => DropdownMenuItem(
                                      value: type, child: Text(type)))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setModalState(
                                      () => selectedTrainType = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: trainNumCtrl,
                              decoration:
                                  _inputDec(AppStrings.importManualTrain, ctx),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        keyboardType: TextInputType.number,
                        onChanged: (value) => ticketNumber = value,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? AppStrings.importManualRequired
                                : null,
                        decoration: _inputDec(
                          AppStrings.ticketNumber,
                          ctx,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: coachCtrl,
                              decoration:
                                  _inputDec(AppStrings.importManualCoach, ctx),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: seatCtrl,
                              decoration:
                                  _inputDec(AppStrings.importManualSeat, ctx),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: platformCtrl,
                              decoration: _inputDec(
                                  AppStrings.importManualPlatform, ctx),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: passengerCtrl,
                              decoration: _inputDec(
                                  AppStrings.importManualPassenger, ctx),
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                      ? AppStrings.importManualRequired
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: localizerCtrl,
                              decoration: _inputDec(
                                  AppStrings.importManualLocalizer, ctx),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                backgroundColor:
                                    Theme.of(ctx).brightness == Brightness.dark
                                        ? Colors.white.withValues(alpha: 0.04)
                                        : Colors.black.withValues(alpha: 0.03),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18)),
                                side: BorderSide(
                                    color: AppTheme.adifTeal
                                        .withValues(alpha: 0.55)),
                              ),
                              onPressed: () async {
                                final now = DateTime.now();
                                final selectedDateTime = await _pickDateTime(
                                  ctx,
                                  initialDateTime: depTime ?? now,
                                  minimumDate:
                                      now.subtract(const Duration(days: 365)),
                                  maximumDate:
                                      now.add(const Duration(days: 730)),
                                );
                                if (selectedDateTime != null && ctx.mounted) {
                                  setModalState(
                                      () => depTime = selectedDateTime);
                                }
                              },
                              child: Text(
                                depTime == null
                                    ? AppStrings.ticketDeparture
                                    : '${AppStrings.ticketDeparture}: ${depTime!.day.toString().padLeft(2, '0')}/${depTime!.month.toString().padLeft(2, '0')} ${depTime!.hour.toString().padLeft(2, '0')}:${depTime!.minute.toString().padLeft(2, '0')}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                backgroundColor:
                                    Theme.of(ctx).brightness == Brightness.dark
                                        ? Colors.white.withValues(alpha: 0.04)
                                        : Colors.black.withValues(alpha: 0.03),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18)),
                                side: BorderSide(
                                    color: AppTheme.adifTeal
                                        .withValues(alpha: 0.55)),
                              ),
                              onPressed: () async {
                                final now = DateTime.now();
                                final selectedDateTime = await _pickDateTime(
                                  ctx,
                                  initialDateTime: arrTime ?? depTime ?? now,
                                  minimumDate: depTime ?? now,
                                  maximumDate:
                                      now.add(const Duration(days: 730)),
                                );
                                if (selectedDateTime != null && ctx.mounted) {
                                  setModalState(
                                      () => arrTime = selectedDateTime);
                                }
                              },
                              child: Text(
                                arrTime == null
                                    ? AppStrings.ticketArrival
                                    : '${AppStrings.ticketArrival}: ${arrTime!.day.toString().padLeft(2, '0')}/${arrTime!.month.toString().padLeft(2, '0')} ${arrTime!.hour.toString().padLeft(2, '0')}:${arrTime!.minute.toString().padLeft(2, '0')}',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.adifPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: () async {
                          if (formKey.currentState?.validate() ?? false) {
                            if (depTime == null || arrTime == null) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text(AppStrings.importManualDateRequired),
                                  backgroundColor: AppTheme.statusCancelled,
                                ),
                              );
                              return;
                            }
                            final origin = selectedOrigin!;
                            final dest = selectedDestination!;
                            final ticket = TicketModel(
                              id: 'manual-${DateTime.now().millisecondsSinceEpoch}',
                              operator: selectedOp,
                              origin: origin.name,
                              originCode: origin.adifCode,
                              destination: dest.name,
                              destinationCode: dest.adifCode,
                              departureTime: depTime!,
                              arrivalTime: arrTime!,
                              trainNumber: trainNumCtrl.text.trim(),
                              trainType: selectedTrainType,
                              coach: coachCtrl.text.trim(),
                              seat: seatCtrl.text.trim(),
                              seatClass: 'Estándar',
                              ticketNumber: ticketNumber.trim(),
                              platform: platformCtrl.text.trim().isEmpty
                                  ? null
                                  : platformCtrl.text.trim(),
                              passengerName: passengerCtrl.text.trim(),
                              bookingReference: localizerCtrl.text.trim(),
                              barcode: TicketBarcode(
                                message: ticketNumber.trim(),
                                format: BarcodeType.aztec,
                                rawFormat: 'PKBarcodeFormatAztec',
                              ),
                            );

                            await widget.ticketRepository.saveTicket(ticket);
                            if (ctx.mounted && mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(AppStrings.importSuccess),
                                  backgroundColor: AppTheme.adifPrimary,
                                ),
                              );
                              widget.onTicketImported();
                            }
                          }
                        },
                        child: const Text(
                          AppStrings.importManualSubmit,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDec(String label, BuildContext ctx) {
    final onSurfaceVar = Theme.of(ctx).colorScheme.onSurfaceVariant;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 12, color: onSurfaceVar),
      filled: true,
      fillColor: Theme.of(ctx).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.03),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: Theme.of(ctx).brightness == Brightness.dark
              ? AppTheme.darkInputBorder
              : AppTheme.lightInputBorder,
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppTheme.adifTeal, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return ValueListenableBuilder<List<TicketModel>>(
      valueListenable: widget.ticketRepository.ticketsListenable,
      builder: (context, tickets, _) {
        final now = DateTime.now();
        final upcoming = tickets
            .where((ticket) => ticket.arrivalTime.isAfter(now))
            .toList()
          ..sort((a, b) => a.departureTime.compareTo(b.departureTime));
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).padding.bottom + 140,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.homeGreeting,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppTheme.isDark(context)
                            ? AppTheme.adifMint
                            : AppTheme.adifPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.homeWelcome,
                      style: TextStyle(
                        fontSize: 14,
                        color: onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (upcoming.isNotEmpty) ...[
                _buildNextTripCard(upcoming.first),
                const SizedBox(height: 16),
              ],
              _buildLiveDeparturesCard(context),
              const SizedBox(height: 16),
              GlassContainer(
                padding: const EdgeInsets.all(22),
                borderRadius: 24,
                glowColor: AppTheme.adifPrimary,
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.adifMint.withValues(alpha: 0.45),
                        border: Border.all(
                          color: AppTheme.adifTeal.withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.wallet_travel_rounded,
                        size: 36,
                        color: AppTheme.adifPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppStrings.importSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _showAddTicketActions,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.adifPrimary,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isLoading)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else
                              const Icon(
                                Icons.add_circle_outline_rounded,
                                size: 20,
                              ),
                            const SizedBox(width: 10),
                            const Text(
                              AppStrings.homeAddTicket,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSupportedFormatsCard(context),
              if (_statusMessage != null) ...[
                const SizedBox(height: 16),
                GlassContainer(
                  padding: const EdgeInsets.all(12),
                  borderRadius: 24,
                  borderColor: _isError
                      ? Colors.redAccent.withValues(alpha: 0.5)
                      : AppTheme.adifTeal.withValues(alpha: 0.5),
                  child: Row(
                    children: [
                      Icon(
                        _isError
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        color: _isError ? Colors.redAccent : AppTheme.adifTeal,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: _isError ? Colors.redAccent : onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 140),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNextTripCard(TicketModel ticket) {
    final style = OperatorThemes.forTrain(
      ticket.operator,
      ticket.trainType,
      isDark: AppTheme.isDark(context),
    );
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      glowColor: style.primary,
      backgroundColor: style.primary.withValues(
        alpha: AppTheme.isDark(context) ? 0.2 : 0.08,
      ),
      borderColor: AppTheme.getGlassBorder(context),
      onTap: () => _showTicketDetails(ticket),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.homeUpcomingTrip,
                  style: TextStyle(
                    color: onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                style.name,
                style: TextStyle(
                  color: style.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  AdifStations.resolveName(ticket.origin),
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward_rounded,
                    color: style.accent, size: 20),
              ),
              Expanded(
                child: Text(
                  AdifStations.resolveName(ticket.destination),
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 16, color: style.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _countdown(ticket.departureTime),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  '${AppStrings.homeDeparturePlatform}: ${ticket.platform ?? AppStrings.ticketPlatformPending}',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveDeparturesCard(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _isStationStatusLoading
        ? theme.colorScheme.onSurfaceVariant
        : _hasStationStatusError
            ? theme.colorScheme.error
            : AppTheme.adifTeal;
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      borderRadius: 24,
      backgroundColor: AppTheme.adifPrimary.withValues(
        alpha: AppTheme.isDark(context) ? 0.28 : 0.08,
      ),
      borderColor: AppTheme.getGlassBorder(context),
      onTap: widget.onShowDepartures,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.adifPrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.train_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.homeLiveDepartures,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AdifStations.resolveName(widget.defaultStationCode),
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    if (_isStationStatusLoading)
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: statusColor,
                        ),
                      )
                    else
                      Icon(
                        _hasStationStatusError
                            ? Icons.error_outline_rounded
                            : Icons.circle,
                        size: 10,
                        color: statusColor,
                      ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _stationStatusText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: statusColor, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.adifTeal),
        ],
      ),
    );
  }

  Widget _buildSupportedFormatsCard(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.homeTravelTipsTitle,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildFormatTip(
            context,
            Icons.wallet_rounded,
            AppStrings.homePkpassTip,
          ),
          const SizedBox(height: 10),
          _buildFormatTip(
            context,
            Icons.picture_as_pdf_rounded,
            AppStrings.homePdfTip,
          ),
          const SizedBox(height: 10),
          _buildFormatTip(
            context,
            Icons.ios_share_rounded,
            AppStrings.homeShareTip,
          ),
        ],
      ),
    );
  }

  Widget _buildFormatTip(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.adifTeal),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

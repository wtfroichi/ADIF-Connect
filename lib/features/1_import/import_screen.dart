import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/operator_themes.dart';
import '../../core/widgets/glass_container.dart';
import '../../models/ticket_model.dart';
import '../../services/pkpass_parser_service.dart';
import '../../services/ticket_repository.dart';

class ImportScreen extends StatefulWidget {
  final TicketRepository ticketRepository;
  final VoidCallback onTicketImported;

  const ImportScreen({
    super.key,
    required this.ticketRepository,
    required this.onTicketImported,
  });

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isLoading = false;
  String? _statusMessage;
  bool _isError = false;

  Future<void> _pickPkpassFile() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _isError = false;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        List<int>? bytes = file.bytes;
        if (bytes == null && file.path != null) {
          bytes = await File(file.path!).readAsBytes();
        }

        if (bytes != null) {
          final ticket = PkpassParserService.parse(bytes is Uint8List ? bytes : Uint8List.fromList(bytes));
          await widget.ticketRepository.saveTicket(ticket);

          setState(() {
            _statusMessage = AppStrings.importSuccess;
            _isError = false;
          });

          widget.onTicketImported();
        } else {
          setState(() {
            _statusMessage = AppStrings.importInvalidFormat;
            _isError = true;
          });
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = '${AppStrings.importError} (${e.toString()})';
        _isError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showManualEntryModal() async {
    final formKey = GlobalKey<FormState>();
    final originCtrl = TextEditingController();
    final destCtrl = TextEditingController();
    final trainNumCtrl = TextEditingController();
    final coachCtrl = TextEditingController();
    final seatCtrl = TextEditingController();
    final platformCtrl = TextEditingController();
    final localizerCtrl = TextEditingController();
    final passengerCtrl = TextEditingController();
    RailOperator selectedOp = RailOperator.renfe;
    String selectedTrainType = 'AVE';
    DateTime? depTime;
    DateTime? arrTime;

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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                        decoration: _inputDec(AppStrings.importManualOperator, ctx),
                        dropdownColor: AppTheme.getSurfaceColor(ctx),
                        items: const [
                          DropdownMenuItem(value: RailOperator.renfe, child: Text('Renfe (AVE/Alvia/MD)')),
                          DropdownMenuItem(value: RailOperator.renfeAvlo, child: Text('Renfe Avlo')),
                          DropdownMenuItem(value: RailOperator.iryo, child: Text('Iryo')),
                          DropdownMenuItem(value: RailOperator.ouigo, child: Text('Ouigo')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedOp = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: originCtrl,
                              decoration: _inputDec(AppStrings.importManualOrigin, ctx),
                              validator: (v) => (v == null || v.isEmpty) ? AppStrings.importManualRequired : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: destCtrl,
                              decoration: _inputDec(AppStrings.importManualDestination, ctx),
                              validator: (v) => (v == null || v.isEmpty) ? AppStrings.importManualRequired : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedTrainType,
                              decoration: _inputDec(AppStrings.importManualTrainType, ctx),
                              dropdownColor: AppTheme.getSurfaceColor(ctx),
                              items: const [
                                'AVE',
                                'Avlo',
                                'Alvia',
                                'Intercity',
                                'Avant',
                                'MD',
                                'Regional',
                                'CERCANÍAS',
                                'Iryo',
                                'Ouigo',
                              ].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                              onChanged: (value) {
                                if (value != null) setModalState(() => selectedTrainType = value);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: trainNumCtrl,
                              decoration: _inputDec(AppStrings.importManualTrain, ctx),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: coachCtrl,
                              decoration: _inputDec(AppStrings.importManualCoach, ctx),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: seatCtrl,
                              decoration: _inputDec(AppStrings.importManualSeat, ctx),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: platformCtrl,
                              decoration: _inputDec(AppStrings.importManualPlatform, ctx),
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
                              decoration: _inputDec(AppStrings.importManualPassenger, ctx),
                              validator: (value) => (value == null || value.trim().isEmpty) ? 'Requirido' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: localizerCtrl,
                              decoration: _inputDec(AppStrings.importManualLocalizer, ctx),
                              validator: (value) => (value == null || value.trim().isEmpty) ? 'Requirido' : null,
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                side: BorderSide(color: AppTheme.adifTeal.withValues(alpha: 0.55)),
                              ),
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: ctx,
                                  initialDate: depTime ?? DateTime.now(),
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 730)),
                                );
                                if (date != null) {
                                  if (!ctx.mounted) return;
                                  final time = await showTimePicker(
                                    context: ctx,
                                    initialTime: depTime != null
                                        ? TimeOfDay.fromDateTime(depTime!)
                                        : TimeOfDay.now(),
                                  );
                                  if (time != null) {
                                    setModalState(() {
                                      depTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                    });
                                  }
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                side: BorderSide(color: AppTheme.adifTeal.withValues(alpha: 0.55)),
                              ),
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: ctx,
                                  initialDate: arrTime ?? depTime ?? DateTime.now(),
                                  firstDate: depTime ?? DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 730)),
                                );
                                if (date != null) {
                                  if (!ctx.mounted) return;
                                  final time = await showTimePicker(
                                    context: ctx,
                                    initialTime: arrTime != null
                                        ? TimeOfDay.fromDateTime(arrTime!)
                                        : const TimeOfDay(hour: 12, minute: 0),
                                  );
                                  if (time != null) {
                                    setModalState(() {
                                      arrTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                    });
                                  }
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
                          backgroundColor: AppTheme.adifTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: () async {
                          if (formKey.currentState?.validate() ?? false) {
                            if (depTime == null || arrTime == null) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text(AppStrings.importManualDateRequired),
                                  backgroundColor: AppTheme.statusCancelled,
                                ),
                              );
                              return;
                            }
                            final origin = originCtrl.text.trim();
                            final dest = destCtrl.text.trim();
                            final ticket = TicketModel(
                              id: 'manual-${DateTime.now().millisecondsSinceEpoch}',
                              operator: selectedOp,
                              origin: origin,
                              originCode: origin.length >= 3 ? origin.substring(0, 3).toUpperCase() : 'ORX',
                              destination: dest,
                              destinationCode: dest.length >= 3 ? dest.substring(0, 3).toUpperCase() : 'DST',
                              departureTime: depTime!,
                              arrivalTime: arrTime!,
                              trainNumber: trainNumCtrl.text.trim(),
                              trainType: selectedTrainType,
                              coach: coachCtrl.text.trim(),
                              seat: seatCtrl.text.trim(),
                              seatClass: 'Estándar',
                              platform: platformCtrl.text.trim().isEmpty ? null : platformCtrl.text.trim(),
                              passengerName: passengerCtrl.text.trim(),
                              bookingReference: localizerCtrl.text.trim(),
                              barcode: null,
                            );

                            await widget.ticketRepository.saveTicket(ticket);
                            if (ctx.mounted && mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(AppStrings.importSuccess),
                                  backgroundColor: AppTheme.adifTeal,
                                ),
                              );
                              widget.onTicketImported();
                            }
                          }
                        },
                        child: const Text(
                          AppStrings.importManualSubmit,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.12),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Primary Import Area
          GlassContainer(
            padding: const EdgeInsets.all(28),
            borderRadius: 24,
            glowColor: AppTheme.adifTeal,
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.adifTeal.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppTheme.adifTeal.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.wallet_travel_rounded,
                    size: 36,
                    color: AppTheme.adifTeal,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppStrings.importTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.importSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickPkpassFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.adifTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.file_upload_outlined, size: 20),
                  label: const Text(
                    AppStrings.importActionBtn,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _showManualEntryModal,
                  icon: const Icon(Icons.edit_note_rounded, size: 20, color: AppTheme.adifTeal),
                  label: Text(
                    AppStrings.importManualBtn,
                    style: TextStyle(
                      color: onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_statusMessage != null) ...[
            const SizedBox(height: 16),
            GlassContainer(
              padding: const EdgeInsets.all(12),
              borderRadius: 14,
              borderColor: _isError ? Colors.redAccent.withValues(alpha: 0.5) : AppTheme.adifTeal.withValues(alpha: 0.5),
              child: Row(
                children: [
                  Icon(
                    _isError ? Icons.error_outline : Icons.check_circle_outline,
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
        ],
      ),
    );
  }
}

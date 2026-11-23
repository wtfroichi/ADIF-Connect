import 'dart:io';
import 'package:flutter/services.dart';
import '../services/pkpass_parser_service.dart';
import '../services/ticket_repository.dart';

class SharingService {
  static const MethodChannel _channel = MethodChannel('es.adifconnect.app/sharing');
  final TicketRepository ticketRepository;
  final void Function() onTicketImported;

  SharingService({
    required this.ticketRepository,
    required this.onTicketImported,
  });

  void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPassReceived') {
        final path = call.arguments as String?;
        if (path != null && path.isNotEmpty) {
          await _processPassFile(path);
        }
      }
    });

    _checkInitialPass();
  }

  Future<void> _checkInitialPass() async {
    try {
      final initialPath = await _channel.invokeMethod<String>('getInitialPass');
      if (initialPath != null && initialPath.isNotEmpty) {
        await _processPassFile(initialPath);
      }
    } catch (_) {}
  }

  Future<void> _processPassFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final ticket = PkpassParserService.parse(bytes);
        await ticketRepository.saveTicket(ticket);
        onTicketImported();
      }
    } catch (_) {}
  }
}

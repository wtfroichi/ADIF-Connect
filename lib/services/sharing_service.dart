import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'pdf_ticket_parser_service.dart';
import 'pkpass_parser_service.dart';
import 'ticket_repository.dart';

class SharingService with WidgetsBindingObserver {
  static const MethodChannel _channel =
      MethodChannel('es.adifconnect.app/sharing');

  final TicketRepository ticketRepository;
  final void Function() onTicketImported;
  final ValueChanged<String> onImportError;
  bool _isReadingInbox = false;

  SharingService({
    required this.ticketRepository,
    required this.onTicketImported,
    required this.onImportError,
  });

  void init() {
    WidgetsBinding.instance.addObserver(this);
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPassReceived':
          final path = call.arguments as String?;
          if (path != null && path.isNotEmpty) {
            await _processFile(path);
          }
          return;
        case 'onImportInbox':
          await _processSharedInbox();
          return;
      }
    });
    unawaited(_checkInitialPass());
    unawaited(_processSharedInbox());
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_processSharedInbox());
    }
  }

  Future<void> _checkInitialPass() async {
    try {
      final initialPath = await _channel.invokeMethod<String>('getInitialPass');
      if (initialPath != null && initialPath.isNotEmpty) {
        await _processFile(initialPath);
      }
    } on MissingPluginException {
      onImportError('A importación compartida só está dispoñible en iOS.');
    } on PlatformException catch (error) {
      _reportError(error.message ?? error.code);
    }
  }

  Future<void> _processSharedInbox() async {
    if (_isReadingInbox) return;
    _isReadingInbox = true;
    try {
      final paths =
          await _channel.invokeListMethod<String>('getSharedInbox') ?? [];
      for (final path in paths) {
        await _processFile(path, sharedInbox: true);
      }
    } on MissingPluginException {
      return;
    } on PlatformException catch (error) {
      _reportError(error.message ?? error.code);
    } finally {
      _isReadingInbox = false;
    }
  }

  Future<void> _processFile(String path, {bool sharedInbox = false}) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw FileSystemException('O ficheiro compartido xa non existe.', path);
      }
      final bytes = await file.readAsBytes();
      final ticket = file.path.toLowerCase().endsWith('.pdf')
          ? await PdfTicketParserService.parse(bytes)
          : PkpassParserService.parse(bytes);
      await ticketRepository.saveTicket(ticket);
      if (sharedInbox) {
        await _channel.invokeMethod<void>('removeSharedInboxItem', path);
      } else {
        await file.delete();
      }
      onTicketImported();
    } on PlatformException catch (error) {
      _reportError(error.message ?? error.code);
    } catch (error) {
      _reportError(error.toString());
    }
  }

  void _reportError(String detail) {
    onImportError('Non se puido importar o ficheiro compartido: $detail');
  }
}

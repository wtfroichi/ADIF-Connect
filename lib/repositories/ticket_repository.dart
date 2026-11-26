import 'package:flutter/foundation.dart';

import '../models/ticket_model.dart';
import '../services/auth_sync_service.dart';
import '../services/ticket_repository.dart';

/// Keeps the local ticket store authoritative for offline use and queues
/// account-scoped cloud mutations when an authenticated session is available.
class SyncedTicketRepository implements TicketRepository {
  final LocalTicketRepository localRepository;
  final AuthSyncService authSyncService;

  const SyncedTicketRepository({
    required this.localRepository,
    required this.authSyncService,
  });

  @override
  ValueListenable<List<TicketModel>> get ticketsListenable =>
      localRepository.ticketsListenable;

  @override
  List<TicketModel> get currentTickets => localRepository.currentTickets;

  @override
  Future<void> init() => localRepository.init();

  @override
  Future<void> saveTicket(TicketModel ticket) async {
    await localRepository.saveTicket(ticket);
    try {
      await authSyncService.enqueueTicketUpsert(ticket);
    } catch (_) {
      // Keep the local save successful if the sync queue cannot be persisted.
    }
  }

  @override
  Future<void> deleteTicket(String id) async {
    try {
      await authSyncService.enqueueTicketDelete(id);
    } catch (_) {
      // The device copy remains usable even if the sync queue is unavailable.
    }
    await localRepository.deleteTicket(id);
  }
}

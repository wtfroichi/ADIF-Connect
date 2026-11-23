import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket_model.dart';

abstract class TicketRepository {
  ValueListenable<List<TicketModel>> get ticketsListenable;
  List<TicketModel> get currentTickets;
  Future<void> init();
  Future<void> saveTicket(TicketModel ticket);
  Future<void> deleteTicket(String id);
}

class LocalTicketRepository implements TicketRepository {
  static const String _storageKey = 'adif_connect_saved_tickets_v1';
  final ValueNotifier<List<TicketModel>> _ticketsNotifier = ValueNotifier<List<TicketModel>>([]);

  @override
  ValueListenable<List<TicketModel>> get ticketsListenable => _ticketsNotifier;

  @override
  List<TicketModel> get currentTickets => _ticketsNotifier.value;

  @override
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedString = prefs.getString(_storageKey);
      if (storedString != null && storedString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(storedString) as List<dynamic>;
        _ticketsNotifier.value = decoded
            .map((item) => TicketModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _ticketsNotifier.value = [];
      }
    } catch (_) {
      _ticketsNotifier.value = [];
    }
  }

  @override
  Future<void> saveTicket(TicketModel ticket) async {
    final updated = List<TicketModel>.from(_ticketsNotifier.value);
    // Replace if exists, or prepend as newest
    final index = updated.indexWhere((t) => t.id == ticket.id);
    if (index >= 0) {
      updated[index] = ticket;
    } else {
      updated.insert(0, ticket);
    }
    _ticketsNotifier.value = updated;
    await _persist();
  }

  @override
  Future<void> deleteTicket(String id) async {
    final updated = _ticketsNotifier.value.where((t) => t.id != id).toList();
    _ticketsNotifier.value = updated;
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_ticketsNotifier.value.map((t) => t.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {
      // Preserve in-memory state when persistent storage is unavailable.
    }
  }
}

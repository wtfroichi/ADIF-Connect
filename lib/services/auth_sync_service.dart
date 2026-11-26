import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_strings.dart';
import '../models/ticket_model.dart';
import 'ticket_repository.dart';

class AuthSyncException implements Exception {
  final String message;

  const AuthSyncException(this.message);

  @override
  String toString() => message;
}

class AuthSyncService extends ChangeNotifier {
  static const _outboxKey = 'adif_connect_ticket_sync_outbox_v1';

  final SupabaseClient _client;
  final LocalTicketRepository _localRepository;
  StreamSubscription<AuthState>? _authSubscription;
  Future<void>? _syncTask;
  Future<void> _outboxWrite = Future<void>.value();
  List<Map<String, dynamic>> _outbox = [];
  bool _initialized = false;
  bool _isSyncing = false;
  bool _hasSynced = false;
  String? _syncError;

  AuthSyncService({
    required LocalTicketRepository localRepository,
    SupabaseClient? client,
  })  : _localRepository = localRepository,
        _client = client ?? Supabase.instance.client;

  String? get userEmail => _client.auth.currentUser?.email;
  bool get isSignedIn => _client.auth.currentUser != null;
  bool get isSyncing => _isSyncing;
  bool get hasSynced => _hasSynced;
  String? get syncError => _syncError;

  String? get _emailRedirectTo =>
      kIsWeb ? null : 'andenlibre://login-callback/';

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      final storedOutbox = preferences.getString(_outboxKey);
      if (storedOutbox != null) {
        final decoded = jsonDecode(storedOutbox) as List<dynamic>;
        _outbox = decoded
            .whereType<Map<String, dynamic>>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();
      }
    } catch (_) {
      _outbox = [];
    }
    _authSubscription = _client.auth.onAuthStateChange.listen((state) {
      notifyListeners();
      if (state.session != null &&
          (state.event == AuthChangeEvent.signedIn ||
              state.event == AuthChangeEvent.initialSession)) {
        unawaited(_syncAfterAuthentication());
      }
    });
    _initialized = true;
    if (isSignedIn) unawaited(_syncAfterAuthentication());
    notifyListeners();
  }

  Future<void> signInWithPassword(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } catch (error) {
      throw AuthSyncException(_authErrorMessage(error));
    }
  }

  Future<bool> signUpWithPassword(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: _emailRedirectTo,
      );
      return response.session != null;
    } catch (error) {
      throw AuthSyncException(_authErrorMessage(error));
    }
  }

  Future<void> sendEmailOtp(String email) async {
    try {
      await _client.auth.signInWithOtp(
        email: email.trim(),
        shouldCreateUser: true,
        emailRedirectTo: _emailRedirectTo,
      );
    } catch (error) {
      throw AuthSyncException(_authErrorMessage(error));
    }
  }

  Future<void> verifyEmailOtp(String email, String token) async {
    try {
      await _client.auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: OtpType.email,
      );
    } catch (error) {
      throw AuthSyncException(_authErrorMessage(error));
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      _hasSynced = false;
      _syncError = null;
      notifyListeners();
    } catch (_) {
      throw const AuthSyncException(AppStrings.accountSignOutFailed);
    }
  }

  Future<void> enqueueTicketUpsert(TicketModel ticket) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _queueOperation({
      'operationId': '${DateTime.now().microsecondsSinceEpoch}-${ticket.id}',
      'operation': 'upsert',
      'userId': userId,
      'localTicketId': ticket.id,
      'ticket': ticket.toJson(),
    });
    unawaited(_flushOutbox().catchError((Object _) {}));
  }

  Future<void> enqueueTicketDelete(String ticketId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _queueOperation({
      'operationId': '${DateTime.now().microsecondsSinceEpoch}-$ticketId',
      'operation': 'delete',
      'userId': userId,
      'localTicketId': ticketId,
    });
    unawaited(_flushOutbox().catchError((Object _) {}));
  }

  Future<void> syncNow() {
    final activeTask = _syncTask;
    if (activeTask != null) return activeTask;
    final task = _performSync();
    _syncTask = task;
    return task.whenComplete(() {
      if (identical(_syncTask, task)) _syncTask = null;
    });
  }

  Future<void> _syncAfterAuthentication() async {
    try {
      await syncNow();
    } on AuthSyncException {
      // The account screen exposes the localized sync state for a manual retry.
    }
  }

  Future<void> _performSync() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthSyncException(AppStrings.accountRequired);
    }

    _isSyncing = true;
    _syncError = null;
    notifyListeners();
    try {
      await _flushOutbox(userId: user.id, throwOnError: true);
      final localTickets = _localRepository.currentTickets;
      if (localTickets.isNotEmpty) {
        await _client.from('user_tickets').upsert(
              localTickets
                  .map((ticket) => _remoteRecord(user.id, ticket))
                  .toList(),
              onConflict: 'user_id,local_ticket_id',
            );
      }

      final remoteRows = await _client
          .from('user_tickets')
          .select('local_ticket_id,ticket_json')
          .eq('user_id', user.id);
      for (final row in remoteRows) {
        final ticketJson = row['ticket_json'];
        if (ticketJson is! Map<String, dynamic>) continue;
        try {
          final ticket = TicketModel.fromJson(ticketJson);
          if (row['local_ticket_id'] == ticket.id) {
            await _localRepository.saveTicketFromSync(ticket);
          }
        } catch (_) {
          // Ignore malformed legacy records without interrupting other tickets.
        }
      }
      _hasSynced = true;
    } catch (error) {
      _syncError = _authErrorMessage(error);
      throw AuthSyncException(_syncError!);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _flushOutbox({String? userId, bool throwOnError = false}) async {
    final currentUserId = userId ?? _client.auth.currentUser?.id;
    if (currentUserId == null || _outbox.isEmpty) return;
    final pending = _outbox
        .where((entry) => entry['userId'] == currentUserId)
        .toList(growable: false);
    for (final operation in pending) {
      try {
        if (operation['operation'] == 'delete') {
          await _client
              .from('user_tickets')
              .delete()
              .eq('user_id', currentUserId)
              .eq('local_ticket_id', operation['localTicketId'] as String);
        } else {
          final json = operation['ticket'];
          if (json is! Map<String, dynamic>) continue;
          final ticket = TicketModel.fromJson(json);
          await _client.from('user_tickets').upsert(
                _remoteRecord(currentUserId, ticket),
                onConflict: 'user_id,local_ticket_id',
              );
        }
        await _removeOutboxOperation(operation['operationId'] as String);
        _syncError = null;
        notifyListeners();
      } catch (error) {
        _syncError = _authErrorMessage(error);
        notifyListeners();
        if (throwOnError) {
          throw AuthSyncException(_syncError!);
        }
        break;
      }
    }
  }

  Map<String, dynamic> _remoteRecord(String userId, TicketModel ticket) => {
        'user_id': userId,
        'local_ticket_id': ticket.id,
        'ticket_json': ticket.toJson(),
        'departure_time': ticket.departureTime.toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  Future<void> _queueOperation(Map<String, dynamic> operation) async {
    _outbox.removeWhere((entry) =>
        entry['userId'] == operation['userId'] &&
        entry['localTicketId'] == operation['localTicketId']);
    _outbox.add(operation);
    _outboxWrite = _outboxWrite.catchError((Object _) {}).then((_) async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_outboxKey, jsonEncode(_outbox));
    });
    await _outboxWrite;
  }

  Future<void> _removeOutboxOperation(String operationId) async {
    _outbox.removeWhere((entry) => entry['operationId'] == operationId);
    _outboxWrite = _outboxWrite.catchError((Object _) {}).then((_) async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_outboxKey, jsonEncode(_outbox));
    });
    await _outboxWrite;
  }

  String _authErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('invalid login credentials') ||
        message.contains('invalid email or password')) {
      return AppStrings.accountAuthInvalidCredentials;
    }
    if (message.contains('email not confirmed')) {
      return AppStrings.accountEmailNotConfirmed;
    }
    if (message.contains('already registered') ||
        message.contains('user already exists')) {
      return AppStrings.accountEmailAlreadyRegistered;
    }
    if (message.contains('password should be at least') ||
        message.contains('weak_password')) {
      return AppStrings.accountPasswordTooShort;
    }
    if (message.contains('invalid') && message.contains('token')) {
      return AppStrings.accountInvalidCode;
    }
    if (message.contains('rate limit') || message.contains('too many')) {
      return AppStrings.accountRateLimited;
    }
    if (error is AuthException) return AppStrings.accountAuthRequestFailed;
    if (error is PostgrestException) return AppStrings.accountSyncFailed;
    return AppStrings.accountConnectionFailed;
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }
}

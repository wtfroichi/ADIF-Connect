import 'package:live_activities/live_activities.dart';
import 'package:flutter/services.dart';
import '../core/constants/adif_stations.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/operator_themes.dart';
import '../models/ticket_model.dart';

class LiveActivityException implements Exception {
  final String message;

  const LiveActivityException(this.message);
}

class LiveActivityService {
  static final LiveActivityService instance = LiveActivityService._();
  LiveActivityService._();

  static const String _appGroupId = 'group.es.adifconnect.app';
  final LiveActivities _liveActivities = LiveActivities();
  bool _isInitialized = false;
  Future<void>? _initialization;
  String? _activeActivityId;

  String? get activeActivityId => _activeActivityId;
  bool get hasActiveActivity => _activeActivityId != null;

  String _nativeErrorDetail(Object error) {
    if (error is PlatformException) {
      final details = error.details == null ? '' : ' · ${error.details}';
      return '${error.code}: ${error.message ?? error.toString()}$details';
    }
    return error.toString();
  }

  String _stationCodeForActivity(String code) {
    final trimmed = code.trim();
    final station = RegExp(r'^\d+$').hasMatch(trimmed)
        ? AdifStations.resolveName(trimmed)
        : trimmed;
    return _nonEmpty(station);
  }

  String _nonEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? AppStrings.liveActivityUnavailableValue : trimmed;
  }

  String _cleanIdentifier(String value) {
    final identifier = value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    return identifier.isEmpty
        ? AppStrings.liveActivityUnavailableValue
        : identifier;
  }

  String _normalizeActivityId(String value) {
    final hex = value.replaceAll(RegExp(r'[^A-Fa-f0-9]'), '').toLowerCase();
    if (hex.length != 32) {
      throw const FormatException('Live Activity identifier is not a UUID.');
    }
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  Future<void> init() async {
    if (_isInitialized) return;
    final pendingInitialization = _initialization;
    if (pendingInitialization != null) {
      await pendingInitialization;
      return;
    }

    final initialization = _initialize();
    _initialization = initialization;
    try {
      await initialization;
    } finally {
      _initialization = null;
    }
  }

  Future<void> _initialize() async {
    try {
      await _liveActivities.init(appGroupId: _appGroupId);
      _isInitialized = true;
    } catch (error) {
      throw LiveActivityException(
        '${AppStrings.liveActivitySetupError} (${_nativeErrorDetail(error)})',
      );
    }
  }

  Future<String?> startOrUpdateActivity(TicketModel ticket) async {
    await init();

    final bool enabled;
    try {
      enabled = await _liveActivities.areActivitiesEnabled();
    } catch (error) {
      throw LiveActivityException(
        '${AppStrings.liveActivitySetupError} (${_nativeErrorDetail(error)})',
      );
    }
    if (!enabled) {
      throw const LiveActivityException(
          AppStrings.liveActivityPermissionDisabled);
    }

    final departure = ticket.departureTime;
    final arrival = ticket.arrivalTime;
    final activityData = <String, dynamic>{
      'trainNumber': _cleanIdentifier(ticket.trainNumber),
      'operatorName': _nonEmpty(
        OperatorThemes.forTrain(ticket.operator, ticket.trainType).name,
      ),
      'originCode': _stationCodeForActivity(ticket.originCode),
      'destinationCode': _stationCodeForActivity(ticket.destinationCode),
      'departureTime':
          '${departure.hour.toString().padLeft(2, '0')}:${departure.minute.toString().padLeft(2, '0')}',
      'arrivalTime':
          '${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}',
      'platform': _nonEmpty(ticket.platform ?? ''),
      'coach': _nonEmpty(ticket.coach),
      'seat': _nonEmpty(ticket.seat),
      'progress': 0.0,
      'statusText': _nonEmpty(AppStrings.stationStatusOnTime),
    };

    try {
      final id = _activeActivityId;
      if (id != null) {
        await _liveActivities.updateActivity(id, activityData);
        return id;
      }

      final activityId = await _liveActivities.createActivity(activityData);
      if (activityId == null) {
        throw const LiveActivityException(AppStrings.liveActivitySetupError);
      }
      final normalizedActivityId = _normalizeActivityId(activityId);
      _activeActivityId = normalizedActivityId;
      return normalizedActivityId;
    } on LiveActivityException {
      rethrow;
    } catch (error) {
      throw LiveActivityException(
        '${AppStrings.liveActivitySetupError} (${_nativeErrorDetail(error)})',
      );
    }
  }

  Future<void> endActivity([String? activityId]) async {
    final id = activityId ?? _activeActivityId;
    if (id == null) return;
    try {
      final normalizedId = _normalizeActivityId(id);
      await _liveActivities.endActivity(normalizedId);
      if (_activeActivityId == normalizedId) {
        _activeActivityId = null;
      }
    } catch (error) {
      throw LiveActivityException(
        '${AppStrings.liveActivityEndError} (${_nativeErrorDetail(error)})',
      );
    }
  }
}

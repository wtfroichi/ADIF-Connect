import 'package:live_activities/live_activities.dart';
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
  String? _activeActivityId;

  String? get activeActivityId => _activeActivityId;
  bool get hasActiveActivity => _activeActivityId != null;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _liveActivities.init(appGroupId: _appGroupId);
      _isInitialized = true;
    } catch (_) {
      throw const LiveActivityException(AppStrings.liveActivitySetupError);
    }
  }

  Future<String?> startOrUpdateActivity(TicketModel ticket) async {
    await init();

    final bool enabled;
    try {
      enabled = await _liveActivities.areActivitiesEnabled();
    } catch (_) {
      throw const LiveActivityException(AppStrings.liveActivitySetupError);
    }
    if (!enabled) {
      throw const LiveActivityException(
          AppStrings.liveActivityPermissionDisabled);
    }

    final departure = ticket.departureTime;
    final arrival = ticket.arrivalTime;
    final activityData = <String, dynamic>{
      'trainNumber': ticket.trainNumber,
      'operatorName':
          OperatorThemes.forTrain(ticket.operator, ticket.trainType).name,
      'originCode': ticket.originCode,
      'destinationCode': ticket.destinationCode,
      'departureTime':
          '${departure.hour.toString().padLeft(2, '0')}:${departure.minute.toString().padLeft(2, '0')}',
      'arrivalTime':
          '${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}',
      'platform': ticket.platform ?? AppStrings.ticketPlatformPending,
      'coach': ticket.coach,
      'seat': ticket.seat,
      'progress': 0.0,
      'statusText': AppStrings.stationStatusOnTime,
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
      _activeActivityId = activityId;
      return activityId;
    } on LiveActivityException {
      rethrow;
    } catch (_) {
      throw const LiveActivityException(AppStrings.liveActivitySetupError);
    }
  }

  Future<void> endActivity([String? activityId]) async {
    final id = activityId ?? _activeActivityId;
    if (id == null) return;
    try {
      await _liveActivities.endActivity(id);
      if (_activeActivityId == id) {
        _activeActivityId = null;
      }
    } catch (_) {
      throw const LiveActivityException(AppStrings.liveActivityEndError);
    }
  }
}

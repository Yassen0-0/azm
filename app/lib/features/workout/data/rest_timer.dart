import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../settings/data/app_settings.dart';
import 'rest_notifications.dart';
import 'workout_models.dart';
import 'workout_repository.dart' show noRetry, workoutClockProvider;

/// Step of the −15 / +15 buttons.
const int kRestAdjustSeconds = 15;

/// Rest timer = END TIMESTAMP (+ a scheduled notification). The UI derives
/// the remaining time from `endsAt − now`; nothing ever counts down a stored
/// value, so backgrounding, app kill and paused frames don't drift.
@immutable
class RestTimerState {
  const RestTimerState({required this.endsAt, required this.totalSeconds, required this.notificationId});

  final DateTime endsAt;

  /// Current full length (start length ± adjustments), for the progress bar.
  final int totalSeconds;
  final int notificationId;

  Duration remaining(DateTime now) => restRemaining(endsAt, now);

  /// 1 → just started, 0 → done.
  double fraction(DateTime now) =>
      totalSeconds <= 0 ? 0 : (remaining(now).inMilliseconds / (totalSeconds * 1000)).clamp(0.0, 1.0);
}

/// Remaining rest, never negative.
Duration restRemaining(DateTime endsAt, DateTime now) {
  final d = endsAt.difference(now);
  return d.isNegative ? Duration.zero : d;
}

/// Seconds shown for a remaining duration: rounded UP, so "0:01" shows until
/// the very end and the display never hits 0:00 before the alarm.
int restDisplaySeconds(Duration remaining) => (remaining.inMilliseconds / 1000).ceil();

/// ±[deltaSeconds] applied to a running timer. Returns null when the new end
/// is not in the future (the timer is over).
({DateTime endsAt, int totalSeconds})? adjustRest(
  RestTimerState s,
  int deltaSeconds,
  DateTime now,
) {
  final endsAt = s.endsAt.add(Duration(seconds: deltaSeconds));
  if (!endsAt.isAfter(now)) return null;
  return (endsAt: endsAt, totalSeconds: max(1, s.totalSeconds + deltaSeconds));
}

/// The running rest timer (null = none). Persisted in settings
/// (`active_rest_ends_at`, `active_rest_notification_id`) and restored on launch.
class RestTimerController extends Notifier<RestTimerState?> {
  Timer? _endTimer;
  final _random = Random();

  AppDatabase get _db => ref.read(appDatabaseProvider);
  RestAlarm get _alarm => ref.read(restAlarmProvider);
  DateTime _now() => ref.read(workoutClockProvider)().toUtc();

  @override
  RestTimerState? build() {
    ref.onDispose(() => _endTimer?.cancel());
    unawaited(_restore());
    return null;
  }

  Future<void> _restore() async {
    try {
      final endsRaw = await _db.readSetting(WorkoutSettingsKeys.restEndsAt);
      final idRaw = await _db.readSetting(WorkoutSettingsKeys.restNotificationId);
      final totalRaw = await _db.readSetting(WorkoutSettingsKeys.restTotalSeconds);
      final ends = endsRaw == null ? null : jsonDecode(endsRaw);
      if (ends is! String || state != null) return;
      final endsAt = DateTime.parse(ends).toUtc();
      if (!endsAt.isAfter(_now())) {
        await _persist(null); // ended while the app was dead: the OS already notified
        return;
      }
      final id = idRaw == null ? null : jsonDecode(idRaw);
      final total = totalRaw == null ? null : jsonDecode(totalRaw);
      _set(RestTimerState(
        endsAt: endsAt,
        totalSeconds: total is int ? total : restDisplaySeconds(endsAt.difference(_now())),
        notificationId: id is int ? id : 0,
      ));
    } catch (e) {
      debugPrint('rest timer restore failed: $e');
    }
  }

  /// Starts (or restarts) the rest for [seconds].
  Future<void> start(int seconds) async {
    final old = state;
    final next = RestTimerState(
      endsAt: _now().add(Duration(seconds: seconds)),
      totalSeconds: seconds,
      notificationId: 1 + _random.nextInt(0x7ffffff0),
    );
    _set(next);
    await _persist(next);
    if (old != null) await _safe(() => _alarm.cancel(old.notificationId));
    await _askPermissionOnce();
    await _schedule(next);
  }

  /// −15 / +15. Going to (or past) zero ends the rest.
  Future<void> adjust(int deltaSeconds) async {
    final s = state;
    if (s == null) return;
    final r = adjustRest(s, deltaSeconds, _now());
    if (r == null) return skip();
    final next = RestTimerState(endsAt: r.endsAt, totalSeconds: r.totalSeconds, notificationId: s.notificationId);
    _set(next);
    await _persist(next);
    await _schedule(next); // same id: replaces the pending one
  }

  Future<void> skip() async {
    final s = state;
    if (s == null) return;
    _set(null);
    await _persist(null);
    await _safe(() => _alarm.cancel(s.notificationId));
  }

  /// Timer reached zero while the app runs: haptic; on Android without exact
  /// alarms show the notification now (the scheduled one may be late).
  Future<void> _onEnd() async {
    final s = state;
    if (s == null) return;
    _set(null);
    await _persist(null);
    final lateBy = _now().difference(s.endsAt);
    final foreground = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (foreground) unawaited(HapticFeedback.heavyImpact());
    if (lateBy < const Duration(seconds: 5) && await _safe(_alarm.mayBeLate) == true) {
      await _safe(() => _alarm.cancel(s.notificationId));
      await _safe(() => _alarm.showNow(id: s.notificationId, text: _text()));
    }
  }

  void _set(RestTimerState? s) {
    _endTimer?.cancel();
    _endTimer = null;
    state = s;
    if (s != null) {
      _endTimer = Timer(restRemaining(s.endsAt, _now()), () => unawaited(_onEnd()));
    }
  }

  Future<void> _persist(RestTimerState? s) async {
    try {
      await _db.writeSetting(WorkoutSettingsKeys.restEndsAt, jsonEncode(s?.endsAt.toUtc().toIso8601String()));
      await _db.writeSetting(WorkoutSettingsKeys.restNotificationId, jsonEncode(s?.notificationId));
      await _db.writeSetting(WorkoutSettingsKeys.restTotalSeconds, jsonEncode(s?.totalSeconds));
    } catch (e) {
      debugPrint('rest timer persist failed: $e');
    }
  }

  Future<void> _schedule(RestTimerState s) =>
      _safe(() => _alarm.schedule(id: s.notificationId, at: s.endsAt, text: _text()));

  Future<void> _askPermissionOnce() async {
    try {
      if (await _db.readSetting(WorkoutSettingsKeys.notificationsAsked) != null) return;
      await _db.writeSetting(WorkoutSettingsKeys.notificationsAsked, jsonEncode(true));
      await _alarm.requestPermission();
    } catch (e) {
      debugPrint('notification permission failed: $e');
    }
  }

  /// Notification text in the app language (forced setting, else device).
  RestAlarmText _text() {
    final locale = ref.read(appSettingsProvider).forcedLocale ??
        AzmLocales.resolve(PlatformDispatcher.instance.locales);
    final l = lookupAppLocalizations(locale);
    return (
      title: l.workoutRestNotificationTitle,
      body: l.workoutRestNotificationBody,
      channelName: l.workoutRestChannelName,
      channelDescription: l.workoutRestChannelDescription,
    );
  }

  /// Notification failures must never break logging.
  static Future<T?> _safe<T>(Future<T> Function() f) async {
    try {
      return await f();
    } catch (e) {
      debugPrint('rest alarm: $e');
      return null;
    }
  }
}

final restTimerProvider = NotifierProvider<RestTimerController, RestTimerState?>(
  RestTimerController.new,
  retry: noRetry,
);

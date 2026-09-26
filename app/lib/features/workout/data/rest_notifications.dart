import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// TZDateTime is required by zonedSchedule but not re-exported by the plugin;
// `timezone` is its transitive dependency. Request filed in docs/PLAN.md to
// make it a direct dependency.
// ignore: depend_on_referenced_packages
import 'package:timezone/timezone.dart' as tz;

/// Localized notification text (resolved by the caller: no BuildContext here).
typedef RestAlarmText = ({String title, String body, String channelName, String channelDescription});

/// The OS side of the rest timer: one scheduled local notification.
abstract interface class RestAlarm {
  /// Asks for notification permission (iOS / Android 13+). Safe to repeat.
  Future<void> requestPermission();

  /// Schedules the "rest is over" notification at [at] (replaces [id]).
  Future<void> schedule({required int id, required DateTime at, required RestAlarmText text});

  Future<void> cancel(int id);

  /// Shows it right now (Android fallback when exact alarms are not allowed).
  Future<void> showNow({required int id, required RestAlarmText text});

  /// True when the scheduled notification may arrive late (Android without
  /// the exact-alarm permission), so the app shows it itself while running.
  Future<bool> mayBeLate();
}

/// flutter_local_notifications implementation (both platforms).
class LocalRestAlarm implements RestAlarm {
  LocalRestAlarm([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'rest_timer';

  /// Monochrome status-bar icon (android/app/src/main/res/drawable).
  static const String androidIcon = 'ic_stat_azm';

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _init;

  bool get _android => defaultTargetPlatform == TargetPlatform.android;

  AndroidFlutterLocalNotificationsPlugin? get _androidImpl =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  Future<void> _ensureInit() => _init ??= _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(androidIcon),
          // Permission is requested explicitly (first rest timer), not at launch.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );

  NotificationDetails _details(RestAlarmText text) => NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          text.channelName,
          channelDescription: text.channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          onlyAlertOnce: true,
        ),
        // Shown with sound in the foreground too: it IS the end-of-rest sound.
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.active,
        ),
      );

  @override
  Future<void> requestPermission() async {
    await _ensureInit();
    if (_android) {
      await _androidImpl?.requestNotificationsPermission();
    } else {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, sound: true);
    }
  }

  @override
  Future<void> schedule({required int id, required DateTime at, required RestAlarmText text}) async {
    await _ensureInit();
    final exact = !_android || (await _androidImpl?.canScheduleExactNotifications() ?? false);
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
      notificationDetails: _details(text),
      androidScheduleMode:
          exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
      title: text.title,
      body: text.body,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await _ensureInit();
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> showNow({required int id, required RestAlarmText text}) async {
    await _ensureInit();
    await _plugin.show(id: id, title: text.title, body: text.body, notificationDetails: _details(text));
  }

  @override
  Future<bool> mayBeLate() async {
    if (!_android) return false;
    await _ensureInit();
    return !(await _androidImpl?.canScheduleExactNotifications() ?? false);
  }
}

/// Overridden in tests with a fake.
final restAlarmProvider = Provider<RestAlarm>((ref) => LocalRestAlarm());

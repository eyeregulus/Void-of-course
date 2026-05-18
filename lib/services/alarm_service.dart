import 'dart:ui';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int preVoidAlarmId = 100; // pre-void
const int vocStartAlarmId = 101; // void
const int vocMidAlarmId = 102;   // void
const int vocEndAlarmId = 103;   // void

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  Future<void> init() async {
    await AndroidAlarmManager.initialize();
  }

  /// 1) pre-void
  Future<void> schedulePreVoidAlarm(DateTime preVoidStart) async {
    final now = DateTime.now();
    if (preVoidStart.isBefore(now)) return;

    await AndroidAlarmManager.cancel(preVoidAlarmId);
    await AndroidAlarmManager.oneShotAt(
      preVoidStart,
      preVoidAlarmId,
      _preVoidAlarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
  }

  /// 2) void
  Future<void> scheduleVocStartAlarm(DateTime vocStart) async {
    final now = DateTime.now();
    if (vocStart.isBefore(now)) return;

    await AndroidAlarmManager.cancel(vocStartAlarmId);
    await AndroidAlarmManager.oneShotAt(
      vocStart,
      vocStartAlarmId,
      _vocStartAlarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
  }

  /// 3) void
  Future<void> scheduleVocMidAlarm(DateTime vocMid) async {
    final now = DateTime.now();
    if (vocMid.isBefore(now)) return;

    await AndroidAlarmManager.cancel(vocMidAlarmId);
    await AndroidAlarmManager.oneShotAt(
      vocMid,
      vocMidAlarmId,
      _vocMidAlarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
  }

  /// 4) void
  Future<void> scheduleVocEndAlarm(DateTime vocEnd) async {
    final now = DateTime.now();
    if (vocEnd.isBefore(now)) return;

    await AndroidAlarmManager.cancel(vocEndAlarmId);
    await AndroidAlarmManager.oneShotAt(
      vocEnd,
      vocEndAlarmId,
      _vocEndAlarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
  }

  Future<void> cancelAlarm() async {
    await Future.wait([
      AndroidAlarmManager.cancel(preVoidAlarmId),
      AndroidAlarmManager.cancel(vocStartAlarmId),
      AndroidAlarmManager.cancel(vocMidAlarmId),
      AndroidAlarmManager.cancel(vocEndAlarmId),
    ]);
  }
}

// -------------------------------------------------------------------
// AlarmManager (top-level)
// -------------------------------------------------------------------

/// (void_alert_channel, void_end_channel)
Future<FlutterLocalNotificationsPlugin> _initNotificationsPlugin() async {
  final plugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initSettings =
      AndroidInitializationSettings('@drawable/ic_notification');
  await plugin.initialize(
    const InitializationSettings(android: initSettings),
  );
  await plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          'void_alert_channel',
          'Void Alerts',
          description: 'Alert when Void of Course starts',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
  await plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          'void_end_channel',
          'Void End Notifications',
          description: 'Notification when Void of Course ends',
          importance: Importance.high,
        ),
      );
  return plugin;
}

/// 1) pre-void: + (countdown)
@pragma('vm:entry-point')
Future<void> _preVoidAlarmCallback() async {
  DartPluginRegistrant.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();

  final bool isEnabled = prefs.getBool('voidAlarmEnabled') ?? false;
  if (!isEnabled) return;

  // 1. (Pre-Void )
  final plugin = await _initNotificationsPlugin();
  final isKorean = (prefs.getString('cached_language_code') ?? 'en').startsWith('ko');
  final preHours = prefs.getInt('cached_pre_void_hours') ?? 6;

  await plugin.show(
    666,
    isKorean ? '⏰ 보이드가 ${preHours}시간 후 시작됩니다!' : '⏰ Void starts in $preHours hours!',
    isKorean ? '미리 준비하세요.' : 'Prepare in advance.',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'void_alert_channel',
        'Void Alerts',
        channelDescription: 'Alert when Void of Course starts',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
        autoCancel: true,
        icon: '@drawable/ic_notification',
      ),
    ),
  );

  // 2. (countdown)
  try {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }
  } catch (_) {}
}

/// 2) void: + (countdown)
@pragma('vm:entry-point')
Future<void> _vocStartAlarmCallback() async {
  DartPluginRegistrant.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();

  final bool isEnabled = prefs.getBool('voidAlarmEnabled') ?? false;
  if (!isEnabled) return;

  // 1.
  final plugin = await _initNotificationsPlugin();
  final isKorean = (prefs.getString('cached_language_code') ?? 'en').startsWith('ko');

  await plugin.show(
    777,
    isKorean ? '🚫 보이드가 시작되었습니다!' : '🚫 Void of Course Started!',
    isKorean ? '중요한 결정을 피하세요.' : 'Avoid important decisions.',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'void_alert_channel',
        'Void Alerts',
        channelDescription: 'Alert when Void of Course starts',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
        autoCancel: true,
        icon: '@drawable/ic_notification',
      ),
    ),
  );

  // 2. (countdown)
  try {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    } else {
      service.invoke("refreshData");
    }
  } catch (_) {}
}

/// 3) void: + 
@pragma('vm:entry-point')
Future<void> _vocMidAlarmCallback() async {
  DartPluginRegistrant.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();

  final bool isEnabled = prefs.getBool('voidAlarmEnabled') ?? false;
  if (!isEnabled) return;

  // 1.
  try {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    } else {
      service.invoke("refreshData");
    }
  } catch (_) {}

  // 2. (chain)
  final vocEndString = prefs.getString('cached_voc_end');
  if (vocEndString == null) return;

  final vocEnd = DateTime.parse(vocEndString);
  final now = DateTime.now().toUtc();
  const maxInterval = Duration(hours: 12);
  final nextMidVoc = now.add(maxInterval);

  if (nextMidVoc.isBefore(vocEnd)) {
    await AndroidAlarmManager.oneShotAt(
      nextMidVoc,
      vocMidAlarmId,
      _vocMidAlarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
  }
}

/// 4) void: +
@pragma('vm:entry-point')
Future<void> _vocEndAlarmCallback() async {
  DartPluginRegistrant.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();

  final bool isEnabled = prefs.getBool('voidAlarmEnabled') ?? false;
  if (!isEnabled) return;

  try {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    } else {
      service.invoke("refreshData");
    }
  } catch (_) {}
}

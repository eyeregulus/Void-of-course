import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:android_intent_plus/android_intent.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'void_channel_id',
      'Void Notifications',
      description: 'Notifications for Void of Course periods',
      importance: Importance.max,
    );

    const AndroidNotificationChannel silentChannel = AndroidNotificationChannel(
      'void_silent_channel_id',
      'Void Silent Notifications',
      description: 'Silent persistent notifications for Void of Course',
      importance: Importance.low, // Low importance = No sound, no vibration
      playSound: false,
      enableVibration: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    tz.initializeTimeZones();

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(silentChannel);

    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> requestBatteryOptimizationPermission() async {
    if (Platform.isAndroid) {
      const intent = AndroidIntent(
        action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
        data: 'package:dev.lioluna.voidofcourse',
      );
      await intent.launch();
    }
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final bool? androidResult =
          await _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission();
      return androidResult ?? false;
    }
    return false;
  }

  Future<bool> checkExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final bool? canSchedule =
          await _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.canScheduleExactNotifications();
      return canSchedule ?? false;
    }
    return true;
  }

  Future<void> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required bool canScheduleExact,
    bool usesChronometer = false,
    bool chronometerCountDown = false,
    int? when,
    bool isOngoing = false,
    bool onlyAlertOnce = false,
    bool isSilent = false, // New parameter
    int? timeoutAfter, // New parameter
  }) async {
    if (Platform.isAndroid && canScheduleExact) {
      final bool hasExactAlarmPermission = await checkExactAlarmPermission();
      if (!hasExactAlarmPermission) {
        await requestExactAlarmPermission();
        if (!await checkExactAlarmPermission()) {
          developer.log('Exact alarm permission denied', name: 'NotificationService');
          return;
        }
      }
    }

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
    developer.log(
      'Scheduling notification for: $tzScheduledTime (Local time: $scheduledTime)',
      name: 'NotificationService',
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          isSilent ? 'void_silent_channel_id' : 'void_channel_id',
          isSilent ? 'Void Silent Notifications' : 'Void Notifications',
          channelDescription: 'Notifications for Void of Course periods',
          importance: isSilent ? Importance.low : Importance.max,
          priority: isSilent ? Priority.low : Priority.high,
          usesChronometer: usesChronometer,
          chronometerCountDown: chronometerCountDown,
          when: when,
          ongoing: isOngoing,
          autoCancel: !isOngoing,
          onlyAlertOnce: onlyAlertOnce,
          playSound: !isSilent,
          enableVibration: !isSilent,
          timeoutAfter: timeoutAfter,
          icon: '@drawable/ic_notification',
        ),
      ),
      androidScheduleMode:
          canScheduleExact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexact,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    bool usesChronometer = false,
    bool chronometerCountDown = false,
    int? when,
    bool isOngoing = false,
    bool onlyAlertOnce = false,
    bool isSilent = false, // New parameter
    int? timeoutAfter, // New parameter
  }) async {
    final NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        isSilent ? 'void_silent_channel_id' : 'void_channel_id',
        isSilent ? 'Void Silent Notifications' : 'Void Notifications',
        channelDescription: 'Notifications for Void of Course periods',
        importance: isSilent ? Importance.low : Importance.max,
        priority: isSilent ? Priority.low : Priority.high,
        usesChronometer: usesChronometer,
        chronometerCountDown: chronometerCountDown,
        when: when,
        ongoing: isOngoing,
        autoCancel: !isOngoing,
        onlyAlertOnce: onlyAlertOnce,
        playSound: !isSilent,
        enableVibration: !isSilent,
        timeoutAfter: timeoutAfter,
        icon: '@drawable/ic_notification',
      ),
    );
    await _notificationsPlugin.show(id, title, body, notificationDetails);
  }
}

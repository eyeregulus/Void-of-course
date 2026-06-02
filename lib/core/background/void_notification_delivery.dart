import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 포그라운드 서비스 없이 AlarmManager 콜백에서 직접 보내는 핵심 알림.
/// (FG 서비스는 카운트다운 '보조'용 — OS가 죽여도 이 경로는 유지됩니다)
class VoidNotificationDelivery {
  static const int countdownNotificationId = 888;
  static const int preVoidNotificationId = 666;
  static const int vocStartNotificationId = 777;
  static const int vocEndNotificationId = 999;

  static Future<FlutterLocalNotificationsPlugin> _plugin() async {
    final plugin = FlutterLocalNotificationsPlugin();
    const initSettings = AndroidInitializationSettings('@drawable/ic_notification');
    await plugin.initialize(const InitializationSettings(android: initSettings));

    final android = plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'void_service_channel',
        'Void Countdown',
        description: 'Shows countdown timer for Void of Course',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'void_alert_channel',
        'Void Alerts',
        description: 'Alert when Void of Course starts',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'void_end_channel',
        'Void End Notifications',
        description: 'Notification when Void of Course ends',
        importance: Importance.high,
      ),
    );
    return plugin;
  }

  static bool _isKorean(SharedPreferences prefs) {
    return (prefs.getString('cached_language_code') ?? 'en').startsWith('ko');
  }

  static Future<void> showPreVoidStarted(SharedPreferences prefs) async {
    final plugin = await _plugin();
    final isKorean = _isKorean(prefs);
    final preHours = prefs.getInt('cached_pre_void_hours') ?? 6;

    await plugin.show(
      preVoidNotificationId,
      isKorean
          ? '⏰ 보이드가 ${preHours}시간 후 시작됩니다!'
          : '⏰ Void starts in $preHours hours!',
      isKorean ? '미리 준비하세요.' : 'Prepare in advance.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'void_alert_channel',
          'Void Alerts',
          importance: Importance.high,
          priority: Priority.high,
          autoCancel: true,
          icon: '@drawable/ic_notification',
        ),
      ),
    );
    await showCountdown(prefs);
  }

  static Future<void> showVocStarted(SharedPreferences prefs) async {
    final plugin = await _plugin();
    final isKorean = _isKorean(prefs);

    await plugin.cancel(preVoidNotificationId);
    await plugin.show(
      vocStartNotificationId,
      isKorean ? '🚫 보이드가 시작되었습니다!' : '🚫 Void of Course Started!',
      isKorean ? '중요한 결정을 피하세요.' : 'Avoid important decisions.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'void_alert_channel',
          'Void Alerts',
          importance: Importance.high,
          priority: Priority.high,
          autoCancel: true,
          timeoutAfter: 10000,
          icon: '@drawable/ic_notification',
        ),
      ),
    );
    await showCountdown(prefs, vocActive: true);
  }

  static Future<void> showVocEnded(SharedPreferences prefs) async {
    final plugin = await _plugin();
    final isKorean = _isKorean(prefs);

    await plugin.cancel(countdownNotificationId);
    await plugin.cancel(preVoidNotificationId);
    await plugin.cancel(vocStartNotificationId);

    await plugin.show(
      vocEndNotificationId,
      isKorean ? '✅ 보이드 종료!' : '✅ Void of Course Ended!',
      isKorean ? '보이드가 종료되었습니다.' : 'The Void period has ended.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'void_end_channel',
          'Void End Notifications',
          importance: Importance.high,
          priority: Priority.high,
          autoCancel: true,
          icon: '@drawable/ic_notification',
        ),
      ),
    );
  }

  /// FG 서비스 대신 카운트다운 알림만 갱신 (15초 폴링 보조)
  static Future<void> showCountdown(
    SharedPreferences prefs, {
    bool? vocActive,
  }) async {
    final startStr = prefs.getString('cached_voc_start');
    final endStr = prefs.getString('cached_voc_end');
    if (startStr == null || endStr == null) return;

    final utcNow = DateTime.now().toUtc();
    final vocStart = DateTime.parse(startStr);
    final vocEnd = DateTime.parse(endStr);
    final isKorean = _isKorean(prefs);

    final bool active =
        vocActive ?? (utcNow.isAfter(vocStart) && utcNow.isBefore(vocEnd));
    final bool preVoid =
        !active && utcNow.isBefore(vocStart);

    if (!active && !preVoid) return;

    final plugin = await _plugin();
    String title;
    String content;
    final target = active ? vocEnd : vocStart;
    final targetLocal = target.toLocal();
    final timeStr = DateFormat('MM/dd HH:mm').format(targetLocal);

    if (active) {
      title = isKorean ? '지금은 보이드입니다' : 'Void of Course Active';
      content =
          isKorean ? '보이드 종료: $timeStr' : 'Ends at: $timeStr';
    } else {
      title = isKorean ? '⏰ 보이드 시작 예정' : '⏰ Void Starting Soon';
      content = isKorean ? '시작: $timeStr' : 'Starts at: $timeStr';
    }

    await plugin.show(
      countdownNotificationId,
      title,
      content,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'void_service_channel',
          'Void Countdown',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: false,
          autoCancel: true,
          playSound: false,
          enableVibration: false,
          onlyAlertOnce: true,
          icon: '@drawable/ic_notification',
        ),
      ),
    );
  }
}

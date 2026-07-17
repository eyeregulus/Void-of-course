import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweph/sweph.dart';
import 'package:void_of_course/core/astro/sweph_initializer.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:void_of_course/core/background/alarm_service.dart';
import 'package:void_of_course/core/background/notification_service.dart';
import 'package:void_of_course/core/astro/astro_calculator.dart';
import 'package:void_of_course/features/home/services/widget_service.dart';

/// 보이드 주기 캐시 + 알림 알람(100–103) + 위젯 알람(110–111) 예약
class VoidCycleScheduler {
  static final AstroCalculator _calculator = AstroCalculator();

  static Future<bool> isVoidAlarmEnabled(SharedPreferences prefs) async {
    await prefs.reload();
    return prefs.getBool('voidAlarmEnabled') ?? false;
  }

  static Future<bool> isHomeWidgetEnabled(SharedPreferences prefs) async {
    await prefs.reload();
    return WidgetService.isEnabled(prefs);
  }

  /// 선택 타임존 기준 다음 보이드 구간 검색
  static Future<({DateTime start, DateTime end})?> findUpcomingVoc(
    SharedPreferences prefs,
  ) async {
    await SwephInitializer.init();
    tz_data.initializeTimeZones();

    final selectedTimezoneId =
        prefs.getString('selected_timezone') ??
        prefs.getString('cached_selected_timezone') ??
        'Asia/Seoul';
    final location = tz.getLocation(selectedTimezoneId);
    final utcNow = DateTime.now().toUtc();
    final tzNow = tz.TZDateTime.from(utcNow, location);

    DateTime searchDate = tz.TZDateTime(
      location,
      tzNow.year,
      tzNow.month,
      tzNow.day,
    ).toUtc();

    for (int i = 0; i < 10; i++) {
      final vocTimes = _calculator.findVoidOfCoursePeriod(searchDate);
      final start = vocTimes['start'] as DateTime?;
      final end = vocTimes['end'] as DateTime?;

      if (start == null || end == null) {
        searchDate = searchDate.add(const Duration(days: 1));
        continue;
      }
      if (end.isBefore(utcNow)) {
        searchDate = end.add(const Duration(minutes: 1));
        continue;
      }
      return (start: start, end: end);
    }
    return null;
  }

  static Future<void> cacheVocPeriod(
    SharedPreferences prefs, {
    required DateTime start,
    required DateTime end,
  }) async {
    await prefs.setString('cached_voc_start', start.toIso8601String());
    await prefs.setString('cached_voc_end', end.toIso8601String());
  }

  /// void 알림 알람만 예약 (FG 서비스와 무관)
  /// 다음 N개의 보이드 구간 검색
  static Future<List<({DateTime start, DateTime end})>> findUpcomingVocList(
    SharedPreferences prefs,
    int count,
  ) async {
    await SwephInitializer.init();
    tz_data.initializeTimeZones();

    final selectedTimezoneId =
        prefs.getString('selected_timezone') ??
        prefs.getString('cached_selected_timezone') ??
        'Asia/Seoul';
    final location = tz.getLocation(selectedTimezoneId);
    final utcNow = DateTime.now().toUtc();
    final tzNow = tz.TZDateTime.from(utcNow, location);

    DateTime searchDate = tz.TZDateTime(
      location,
      tzNow.year,
      tzNow.month,
      tzNow.day,
    ).toUtc();

    List<({DateTime start, DateTime end})> list = [];

    // 최대 루프 제한을 주어 무한 루프 방지
    for (int i = 0; i < count * 2; i++) {
      final vocTimes = _calculator.findVoidOfCoursePeriod(searchDate);
      final start = vocTimes['start'] as DateTime?;
      final end = vocTimes['end'] as DateTime?;

      if (start == null || end == null) {
        searchDate = searchDate.add(const Duration(days: 1));
        continue;
      }
      if (end.isBefore(utcNow)) {
        searchDate = end.add(const Duration(minutes: 1));
        continue;
      }

      list.add((start: start, end: end));
      if (list.length >= count) {
        break;
      }
      searchDate = end.add(const Duration(minutes: 1));
    }
    return list;
  }

  /// iOS용 보이드 로컬 알림 예약 (최대 10개 보이드 주기 예약 = 30개 알림)
  static Future<void> scheduleVoidNotificationAlarmsIOS(
    SharedPreferences prefs,
  ) async {
    final notificationService = NotificationService();

    // 1. 기존에 등록했던 모든 iOS 보이드 알림 ID 삭제
    for (int i = 0; i < 10; i++) {
      await notificationService.cancelNotification(2000 + i);
      await notificationService.cancelNotification(3000 + i);
      await notificationService.cancelNotification(4000 + i);
    }

    // 알림 비활성화 상태이면 취소만 하고 종료
    if (!await isVoidAlarmEnabled(prefs)) return;

    // 2. 앞으로 올 보이드 주기 10개 조회
    final list = await findUpcomingVocList(prefs, 10);
    if (list.isEmpty) return;

    final preVoidHours = prefs.getInt('cached_pre_void_hours') ?? 6;
    final languageCode = prefs.getString('cached_language_code') ?? 'en';
    final isKorean = languageCode.startsWith('ko');
    final utcNow = DateTime.now().toUtc();

    // 3. 각 주기마다 Pre-Void, 시작, 종료 알림을 zonedSchedule로 예약
    for (int i = 0; i < list.length; i++) {
      final vocStart = list[i].start;
      final vocEnd = list[i].end;

      final preVoidStart = vocStart.subtract(Duration(hours: preVoidHours));

      // 3-1. Pre-Void 시작 알림 예약 (ID: 2000 + i)
      if (preVoidStart.isAfter(utcNow)) {
        await notificationService.scheduleNotification(
          id: 2000 + i,
          title: isKorean
              ? '⏰ 보이드가 $preVoidHours시간 후 시작됩니다!'
              : '⏰ Void starts in $preVoidHours hours!',
          body: isKorean ? '미리 준비하세요.' : 'Prepare in advance.',
          scheduledTime: preVoidStart,
          canScheduleExact: false,
        );
      }

      // 3-2. Void 시작 알림 예약 (ID: 3000 + i)
      if (vocStart.isAfter(utcNow)) {
        await notificationService.scheduleNotification(
          id: 3000 + i,
          title: isKorean ? '🚫 보이드가 시작되었습니다!' : '🚫 Void of Course Started!',
          body: isKorean ? '중요한 결정을 피하세요.' : 'Avoid important decisions.',
          scheduledTime: vocStart,
          canScheduleExact: false,
        );
      }

      // 3-3. Void 종료 알림 예약 (ID: 4000 + i)
      if (vocEnd.isAfter(utcNow)) {
        await notificationService.scheduleNotification(
          id: 4000 + i,
          title: isKorean ? '✅ 보이드 종료!' : '✅ Void of Course Ended!',
          body: isKorean ? '보이드가 종료되었습니다.' : 'The Void period has ended.',
          scheduledTime: vocEnd,
          canScheduleExact: false,
        );
      }
    }

    if (kDebugMode) {
      developer.log(
        'iOS Local Notifications Scheduled: ${list.length} VOC periods',
        name: 'VoidCycleScheduler',
      );
    }
  }

  /// void 알림 알람만 예약 (FG 서비스와 무관)
  static Future<void> scheduleVoidNotificationAlarms(
    SharedPreferences prefs, {
    required DateTime vocStart,
    required DateTime vocEnd,
  }) async {
    if (Platform.isIOS) {
      await scheduleVoidNotificationAlarmsIOS(prefs);
      return;
    }

    final alarmService = AlarmService();
    final preVoidHours = prefs.getInt('cached_pre_void_hours') ?? 6;
    final utcNow = DateTime.now().toUtc();
    final preVoidStart = vocStart.subtract(Duration(hours: preVoidHours));

    await alarmService.cancelAlarm();

    if (preVoidStart.isAfter(utcNow)) {
      await alarmService.schedulePreVoidAlarm(preVoidStart);
    }
    if (vocStart.isAfter(utcNow)) {
      await alarmService.scheduleVocStartAlarm(vocStart);
    }

    const maxInterval = Duration(hours: 12);
    final nextMidVoc = vocStart.add(maxInterval);
    if (nextMidVoc.isBefore(vocEnd) && nextMidVoc.isAfter(utcNow)) {
      await alarmService.scheduleVocMidAlarm(nextMidVoc);
    }
    await alarmService.scheduleVocEndAlarm(vocEnd);

    if (kDebugMode) {
      developer.log(
        'Notification alarms scheduled: pre=$preVoidStart start=$vocStart end=$vocEnd',
        name: 'VoidCycleScheduler',
      );
    }
  }

  static Future<void> cancelVoidNotificationAlarms() async {
    await AlarmService().cancelAlarm();
    if (Platform.isIOS) {
      final notificationService = NotificationService();
      for (int i = 0; i < 10; i++) {
        await notificationService.cancelNotification(2000 + i);
        await notificationService.cancelNotification(3000 + i);
        await notificationService.cancelNotification(4000 + i);
      }
    }
  }

  /// FG 카운트다운 서비스 — 실패해도 AlarmManager 알림은 동작
  static Future<void> tryStartCountdownService(SharedPreferences prefs) async {
    if (!await isVoidAlarmEnabled(prefs)) return;

    final startStr = prefs.getString('cached_voc_start');
    final endStr = prefs.getString('cached_voc_end');
    if (startStr == null || endStr == null) return;

    final utcNow = DateTime.now().toUtc();
    final vocStart = DateTime.parse(startStr);
    final preHours = prefs.getInt('cached_pre_void_hours') ?? 6;
    final preVoidStart = vocStart.subtract(Duration(hours: preHours));

    if (utcNow.isBefore(preVoidStart)) return;

    try {
      final service = FlutterBackgroundService();
      if (await service.isRunning()) {
        service.invoke('refreshData');
      } else {
        await service.startService();
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          'FG countdown service unavailable (alarms still active): $e',
          name: 'VoidCycleScheduler',
        );
      }
    }
  }

  static Future<void> stopCountdownService() async {
    try {
      final service = FlutterBackgroundService();
      if (await service.isRunning()) {
        service.invoke('stopService');
      }
    } catch (_) {}
  }

  /// 보이드 종료 후 다음 주기 예약 (알림·위젯 각각 설정에 따라)
  static Future<void> advanceAfterVocEnd(
    SharedPreferences prefs,
    DateTime endedVocEnd,
  ) async {
    await SwephInitializer.init();
    tz_data.initializeTimeZones();

    var searchDate = endedVocEnd.add(const Duration(minutes: 1));
    final utcNow = DateTime.now().toUtc();
    if (searchDate.isBefore(utcNow)) searchDate = utcNow;

    DateTime? foundStart;
    DateTime? foundEnd;

    for (int i = 0; i < 10; i++) {
      final vocTimes = _calculator.findVoidOfCoursePeriod(searchDate);
      final start = vocTimes['start'] as DateTime?;
      final end = vocTimes['end'] as DateTime?;

      if (start == null || end == null) {
        searchDate = searchDate.add(const Duration(days: 1));
        continue;
      }
      if (end.isBefore(utcNow)) {
        searchDate = end.add(const Duration(minutes: 1));
        continue;
      }
      foundStart = start;
      foundEnd = end;
      break;
    }

    if (foundStart == null || foundEnd == null) return;

    await cacheVocPeriod(prefs, start: foundStart, end: foundEnd);

    if (await isVoidAlarmEnabled(prefs)) {
      await scheduleVoidNotificationAlarms(
        prefs,
        vocStart: foundStart,
        vocEnd: foundEnd,
      );
      await tryStartCountdownService(prefs);
    }

    if (await isHomeWidgetEnabled(prefs)) {
      await WidgetService.refreshFromPrefs();
      await WidgetService.scheduleRefreshAlarms(
        vocStart: foundStart,
        vocEnd: foundEnd,
      );
    }
  }
}

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweph/sweph.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:void_of_course/core/background/alarm_service.dart';
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
    await Sweph.init();
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
  static Future<void> scheduleVoidNotificationAlarms(
    SharedPreferences prefs, {
    required DateTime vocStart,
    required DateTime vocEnd,
  }) async {
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
    await Sweph.init();
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

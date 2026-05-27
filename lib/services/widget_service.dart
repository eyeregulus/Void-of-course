import 'dart:developer' as developer;
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweph/sweph.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'astro_calculator.dart';
import 'purchase_service.dart';

const int _widgetVocStartAlarmId = 110;

const int _widgetVocEndAlarmId = 111;

/// 보이드 진행 중 30분마다 위젯 갱신 (상태 텍스트 최신화)
const int _widgetVocMidAlarmBaseId = 120; // 120..149 슬롯 사용

class WidgetService {
  static const String appGroupId = 'dev.lioluna.voidofcourse';

  static const String androidWidgetName = 'VocWidgetProvider';

  static final AstroCalculator _calculator = AstroCalculator();

  static const String _installedPrefKey = 'hasHomeWidgetInstalled';

  /// 홈 위젯 설치 여부 (앱·알람 콜백·네이티브 onEnabled 공통)

  static Future<bool> refreshInstalledFlag(
    SharedPreferences? prefs, {
    bool allowClear = true,
  }) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    try {
      final widgets = await HomeWidget.getInstalledWidgets();
      if (widgets.isNotEmpty) {
        await p.setBool(_installedPrefKey, true);
        return true;
      }
      if (allowClear) {
        await p.setBool(_installedPrefKey, false);
        return false;
      }
      return p.getBool(_installedPrefKey) ?? false;
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          'getInstalledWidgets failed, using pref: $e',
          name: 'WidgetService',
        );
      }
      return p.getBool(_installedPrefKey) ?? false;
    }
  }

  /// 알람·백그라운드: pref 우선 (getInstalledWidgets가 빈 목록을 줄 수 있음)
  static Future<bool> isEnabled([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    if (p.getBool(_installedPrefKey) ?? false) return true;
    return refreshInstalledFlag(p);
  }

  static Future<void> setInstallStatus(bool installed) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_installedPrefKey, installed);
  }

  static Future<void> cancelRefreshAlarms() async {
    await AndroidAlarmManager.cancel(_widgetVocStartAlarmId);

    await AndroidAlarmManager.cancel(_widgetVocEndAlarmId);

    // mid 알람 슬롯도 모두 취소
    for (int i = 0; i < 30; i++) {
      await AndroidAlarmManager.cancel(_widgetVocMidAlarmBaseId + i);
    }
  }

  /// 선택 타임존 기준 현재 보이드 또는 다음 보이드 구간 (앱 없이 알람에서도 재계산)

  static Future<({DateTime start, DateTime end})?> resolveCurrentVocPeriod(
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

    DateTime searchDate =
        tz.TZDateTime(location, tzNow.year, tzNow.month, tzNow.day).toUtc();

    for (int i = 0; i < 10; i++) {
      final vocTimes = _calculator.findVoidOfCoursePeriod(searchDate);

      final start = vocTimes['start'] as DateTime?;

      final end = vocTimes['end'] as DateTime?;

      if (start == null || end == null) {
        searchDate = searchDate.add(const Duration(days: 1));

        continue;
      }

      if (utcNow.isAfter(start) && utcNow.isBefore(end)) {
        return (start: start, end: end);
      }

      if (end.isAfter(utcNow)) {
        return (start: start, end: end);
      }

      searchDate = end.add(const Duration(minutes: 1));
    }

    return null;
  }

  /// 보이드 시작/종료 시각 알람으로 위젯 갱신 (배터리: 하루 2회 수준, 폴링 없음)

  static Future<void> refreshFromPrefs({bool advanceAfterEnd = false}) async {
    try {
      DartPluginRegistrant.ensureInitialized();

      await AndroidAlarmManager.initialize();

      final prefs = await SharedPreferences.getInstance();

      if (!await refreshInstalledFlag(prefs, allowClear: false)) return;

      await prefs.reload();

      final period = await resolveCurrentVocPeriod(prefs);

      if (period == null) {
        if (kDebugMode) {
          developer.log('No VOC period for widget', name: 'WidgetService');
        }

        return;
      }

      await cacheVocPeriod(prefs, vocStart: period.start, vocEnd: period.end);

      final utcNow = DateTime.now().toUtc();

      DateTime? nextVocStart;

      DateTime? nextVocEnd;

      if (utcNow.isAfter(period.start) && utcNow.isBefore(period.end)) {
        final next = await findNextVocPeriod(period.end);

        nextVocStart = next?.start;

        nextVocEnd = next?.end;
      }

      final moonZodiac = _calculator.getMoonZodiacEmoji(utcNow);

      await updateWidgetData(
        vocStart: period.start,

        vocEnd: period.end,

        nextVocStart: nextVocStart,

        nextVocEnd: nextVocEnd,

        moonZodiac: moonZodiac,
      );

      await scheduleRefreshAlarms(vocStart: period.start, vocEnd: period.end);
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log(
          'refreshFromPrefs failed: $e\n$stack',

          name: 'WidgetService',
        );
      }
    }
  }

  static Future<({DateTime start, DateTime end})?> findNextVocPeriod(
    DateTime afterUtc,
  ) async {
    await Sweph.init();

    final utcNow = DateTime.now().toUtc();

    var searchDate = afterUtc.add(const Duration(minutes: 1));

    if (searchDate.isBefore(utcNow)) {
      searchDate = utcNow;
    }

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

    required DateTime? vocStart,

    required DateTime? vocEnd,
  }) async {
    if (vocStart == null || vocEnd == null) return;

    await prefs.setString('cached_voc_start', vocStart.toIso8601String());

    await prefs.setString('cached_voc_end', vocEnd.toIso8601String());
  }

  static Future<void> updateWidgetData({
    required DateTime? vocStart,
    required DateTime? vocEnd,
    required DateTime? nextVocStart,
    required DateTime? nextVocEnd,
    required String moonZodiac,
  }) async {
    try {
      // ── 프리미엄(플러스 이상) 결제 유무 체크 ─────────────────────────
      if (!PurchaseService.instance.isPlus) {
        await HomeWidget.saveWidgetData<String>('widget_icon', '🔒');
        await HomeWidget.saveWidgetData<String>(
          'widget_title_text',
          '프리미엄 전용 위젯',
        );
        await HomeWidget.saveWidgetData<String>(
          'widget_times_text',
          '앱 내 [설정]에서 플러스 또는 프로 패스를\n구매하시면 위젯이 활성화됩니다.',
        );
        await HomeWidget.updateWidget(androidName: androidWidgetName);
        return;
      }

      final now = DateTime.now().toUtc();

      var displayStart = vocStart;

      var displayEnd = vocEnd;

      // 현재 보이드가 이미 끝났다면 다음 보이드로 전환
      if (displayEnd != null && now.isAfter(displayEnd)) {
        if (nextVocStart != null && nextVocEnd != null) {
          displayStart = nextVocStart;

          displayEnd = nextVocEnd;
        } else {
          final next = await findNextVocPeriod(displayEnd);

          if (next != null) {
            displayStart = next.start;

            displayEnd = next.end;
          }
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final selectedTimezoneId =
          prefs.getString('selected_timezone') ?? 'Asia/Seoul';
      final location = tz.getLocation(selectedTimezoneId);
      final localeStr = prefs.getString('cached_language_code') ?? 'en';
      final dateFormat = DateFormat('MM/dd HH:mm', localeStr);

      // 아이콘 결정
      // 🚫 보이드 진행 중 / 🔔 오늘 보이드 예정 / ✅ 그 외
      final isVocNow =
          displayStart != null &&
          displayEnd != null &&
          now.isAfter(displayStart) &&
          now.isBefore(displayEnd);

      final tzNow = tz.TZDateTime.from(now, location);
      final isVocToday =
          displayStart != null &&
          displayEnd != null &&
          !isVocNow &&
          displayStart.isAfter(now) &&
          tz.TZDateTime.from(displayStart, location).day == tzNow.day &&
          tz.TZDateTime.from(displayStart, location).month == tzNow.month;

      final widgetIcon = isVocNow ? '🚫' : (isVocToday ? '🔔' : '✅');

      final widgetStartTimeText =
          displayStart != null
              ? dateFormat.format(tz.TZDateTime.from(displayStart, location))
              : 'N/A';
      final widgetEndTimeText =
          displayEnd != null
              ? dateFormat.format(tz.TZDateTime.from(displayEnd, location))
              : 'N/A';

      // ── HomeWidget 저장 ────────────────────────────────────────────
      await HomeWidget.saveWidgetData<String>('widget_icon', widgetIcon);

      await HomeWidget.saveWidgetData<String>(
        'widget_title_text',
        '🌙 Void of course  $moonZodiac',
      );

      await HomeWidget.saveWidgetData<String>(
        'widget_times_text',
        'Start : $widgetStartTimeText\nEnd   : $widgetEndTimeText',
      );

      await HomeWidget.updateWidget(androidName: androidWidgetName);

      if (kDebugMode) {
        developer.log(
          'Widget updated: $widgetIcon | $widgetStartTimeText → $widgetEndTimeText',
          name: 'WidgetService',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error updating widget: $e', name: 'WidgetService');
      }
    }
  }

  /// 보이드 시작/종료 정각 + 진행 중 30분 간격 알람으로 위젯 갱신
  /// - vocStart 정각: 상태 "진행 중"으로 즉시 전환
  /// - vocEnd   정각: 상태 "종료"로 즉시 전환
  /// - 보이드 진행 중 30분마다: 남은 시간 텍스트 갱신
  /// - 보이드 시작 전 1시간: 미리 "오늘 시작" 표시
  static Future<void> scheduleRefreshAlarms({
    required DateTime vocStart,

    required DateTime vocEnd,
  }) async {
    if (!await refreshInstalledFlag(null, allowClear: false)) return;

    final utcNow = DateTime.now().toUtc();

    // 기존 알람 취소
    await AndroidAlarmManager.cancel(_widgetVocStartAlarmId);
    await AndroidAlarmManager.cancel(_widgetVocEndAlarmId);
    // mid 알람 슬롯 취소 (최대 30개)
    for (int i = 0; i < 30; i++) {
      await AndroidAlarmManager.cancel(_widgetVocMidAlarmBaseId + i);
    }

    // ── 1. vocStart 정각 알람 ──────────────────────────────────────
    if (vocStart.isAfter(utcNow)) {
      await AndroidAlarmManager.oneShotAt(
        vocStart,

        _widgetVocStartAlarmId,

        _widgetVocStartAlarmCallback,

        exact: true,

        wakeup: true,

        allowWhileIdle: true,

        rescheduleOnReboot: true,
      );

      if (kDebugMode) {
        developer.log(
          'Widget alarm scheduled at voc start: $vocStart',

          name: 'WidgetService',
        );
      }

      // ── 2. 보이드 시작 1시간 전 미리 알람 ("오늘 시작 X시간 후" 표시) ──
      final previewTime = vocStart.subtract(const Duration(hours: 1));
      if (previewTime.isAfter(utcNow)) {
        // previewTime은 mid 슬롯 0번 사용
        await AndroidAlarmManager.oneShotAt(
          previewTime,
          _widgetVocMidAlarmBaseId,
          _widgetVocMidAlarmCallback,
          exact: true,
          wakeup: false, // 화면 켤 필요 없음
          allowWhileIdle: true,
          rescheduleOnReboot: true,
        );
      }
    }

    // ── 3. vocEnd 정각 알람 ───────────────────────────────────────
    if (vocEnd.isAfter(utcNow)) {
      await AndroidAlarmManager.oneShotAt(
        vocEnd,

        _widgetVocEndAlarmId,

        _widgetVocEndAlarmCallback,

        exact: true,

        wakeup: true,

        allowWhileIdle: true,

        rescheduleOnReboot: true,
      );

      if (kDebugMode) {
        developer.log(
          'Widget alarm scheduled at voc end: $vocEnd',

          name: 'WidgetService',
        );
      }
    }

    // ── 4. 보이드 진행 중 30분 간격 mid 알람 (슬롯 1..N) ─────────
    // 현재 보이드 중이거나 앞으로 시작될 때 모두 등록
    final midStart = utcNow.isAfter(vocStart) ? utcNow : vocStart;
    var midTime = midStart.add(const Duration(minutes: 30));
    // 30분 단위로 정렬 (예: 14:30, 15:00, 15:30)
    final roundedMinutes = ((midTime.minute / 30).ceil() * 30);
    midTime = DateTime.utc(
      midTime.year,
      midTime.month,
      midTime.day,
      midTime.hour + (roundedMinutes >= 60 ? 1 : 0),
      roundedMinutes >= 60 ? 0 : roundedMinutes,
    );

    int slotIdx = 1; // 슬롯 0은 preview용
    while (midTime.isBefore(vocEnd) && slotIdx < 30) {
      await AndroidAlarmManager.oneShotAt(
        midTime,
        _widgetVocMidAlarmBaseId + slotIdx,
        _widgetVocMidAlarmCallback,
        exact: true,
        wakeup: false, // 진행 중 갱신은 화면 켜지 않아도 됨
        allowWhileIdle: true,
        rescheduleOnReboot: true,
      );
      if (kDebugMode) {
        developer.log(
          'Widget mid alarm [$slotIdx] at $midTime',
          name: 'WidgetService',
        );
      }
      midTime = midTime.add(const Duration(minutes: 30));
      slotIdx++;
    }
  }
}

@pragma('vm:entry-point')
Future<void> _widgetVocStartAlarmCallback() async {
  await WidgetService.refreshFromPrefs();
}

@pragma('vm:entry-point')
Future<void> _widgetVocEndAlarmCallback() async {
  await WidgetService.refreshFromPrefs();
}

/// 보이드 진행 중 30분 간격 위젯 갱신 콜백
@pragma('vm:entry-point')
Future<void> _widgetVocMidAlarmCallback() async {
  await WidgetService.refreshFromPrefs();
}

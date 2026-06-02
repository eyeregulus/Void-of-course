import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:sweph/sweph.dart';

import 'package:void_of_course/core/astro/astro_calculator.dart';

/// 캘린더 VOC 월별 데이터 — 앱 전역 캐시 + 백그라운드 프리로드
class CalendarVocCache {
  CalendarVocCache._();

  static final CalendarVocCache instance = CalendarVocCache._();

  static String monthKey(int year, int month) => '$year-$month';

  final Map<String, Map<DateTime, List<Map<String, dynamic>>>> _cache = {};
  final Set<String> _inFlight = {};

  bool hasMonth(int year, int month) =>
      _cache.containsKey(monthKey(year, month));

  /// TableCalendar 한 페이지(이전·현재·다음 달) 기준 좌표
  static List<(int, int)> windowCoords(DateTime month) {
    final prev = DateTime.utc(month.year, month.month - 1, 1);
    final center = DateTime.utc(month.year, month.month, 1);
    final next = DateTime.utc(month.year, month.month + 1, 1);
    return [
      (prev.year, prev.month),
      (center.year, center.month),
      (next.year, next.month),
    ];
  }

  /// 중심 월 기준 ±[radius]개월 (프리로드용)
  static List<(int, int)> coordsInRadius(DateTime center, int radius) {
    final base = DateTime.utc(center.year, center.month, 1);
    final out = <(int, int)>[];
    for (var i = -radius; i <= radius; i++) {
      final d = DateTime.utc(base.year, base.month + i, 1);
      out.add((d.year, d.month));
    }
    return out;
  }

  List<(int, int)> missingMonths(Iterable<(int, int)> coords) {
    return coords
        .where((m) => !hasMonth(m.$1, m.$2))
        .toList();
  }

  bool isWindowCached(DateTime month) =>
      missingMonths(windowCoords(month)).isEmpty;

  Map<DateTime, List<Map<String, dynamic>>> mergeWindow(DateTime month) {
    final merged = <DateTime, List<Map<String, dynamic>>>{};
    for (final m in windowCoords(month)) {
      merged.addAll(_cache[monthKey(m.$1, m.$2)] ?? {});
    }
    return merged;
  }

  Future<Map<String, Map<DateTime, List<Map<String, dynamic>>>>>
      loadMonths(List<(int, int)> months) async {
    if (months.isEmpty) return {};
    await Sweph.init();
    final calculator = AstroCalculator();
    final out = <String, Map<DateTime, List<Map<String, dynamic>>>>{};
    for (final m in months) {
      out[monthKey(m.$1, m.$2)] =
          calculator.getVocEventsForMonth(m.$1, m.$2);
    }
    return out;
  }

  /// UI를 막지 않고 캐시만 채움 (앱 시작·탭 진입·월 스와이프 후)
  void preloadAroundSilent(DateTime center, {int radius = 2}) {
    final missing = missingMonths(coordsInRadius(center, radius));
    if (missing.isEmpty) return;

    final keys =
        missing.map((m) => monthKey(m.$1, m.$2)).toList();
    if (keys.any(_inFlight.contains)) {
      final stillMissing = missing.where((m) {
        final k = monthKey(m.$1, m.$2);
        return !_cache.containsKey(k) && !_inFlight.contains(k);
      }).toList();
      if (stillMissing.isEmpty) return;
      _runSilentLoad(stillMissing);
      return;
    }
    _runSilentLoad(missing);
  }

  void _runSilentLoad(List<(int, int)> months) {
    for (final m in months) {
      _inFlight.add(monthKey(m.$1, m.$2));
    }

    loadMonths(months)
        .then((loaded) {
          _cache.addAll(loaded);
        })
        .catchError((Object e, StackTrace stack) {
          if (kDebugMode) {
            developer.log(
              'Calendar VOC preload failed: $e\n$stack',
              name: 'CalendarVocCache',
            );
          }
        })
        .whenComplete(() {
          for (final m in months) {
            _inFlight.remove(monthKey(m.$1, m.$2));
          }
        });
  }

  /// 화면에서 await로 창(3개월) 로드
  Future<void> ensureWindowLoaded(DateTime month) async {
    final missing = missingMonths(windowCoords(month));
    if (missing.isEmpty) return;
    final keys = missing.map((m) => monthKey(m.$1, m.$2)).toList();
    for (final k in keys) {
      _inFlight.add(k);
    }
    try {
      final loaded = await loadMonths(missing);
      _cache.addAll(loaded);
    } finally {
      for (final k in keys) {
        _inFlight.remove(k);
      }
    }
  }
}

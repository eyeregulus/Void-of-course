import 'dart:developer' as developer;
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sweph/sweph.dart';
import 'package:void_of_course/core/astro/sweph_initializer.dart';

import 'package:void_of_course/core/astro/astro_calculator.dart';

/// 캘린더 VOC 월별 데이터 — 앱 전역 캐시 + 백그라운드 프리로드
class CalendarVocCache {
  CalendarVocCache._();

  static final CalendarVocCache instance = CalendarVocCache._();

  static String monthKey(int year, int month) => '$year-$month';

  final Map<String, Map<DateTime, List<Map<String, dynamic>>>> _cache = {};
  final Set<String> _inFlight = {};
  final Map<String, Future<Map<DateTime, List<Map<String, dynamic>>>>>
  _inFlightFutures = {};

  bool hasMonth(int year, int month) =>
      _cache.containsKey(monthKey(year, month));

  SendPort? _workerSendPort;
  int _requestIdCounter = 0;

  Future<void> initWorker() async {
    if (_workerSendPort != null) return;
    final token = RootIsolateToken.instance;
    if (token == null) return;

    final epheFilesPath = SwephInitializer.epheFilesPath;

    final receivePort = ReceivePort();
    await Isolate.spawn(_astroWorkerEntryPoint, {
      'sendPort': receivePort.sendPort,
      'token': token,
      'epheFilesPath': epheFilesPath,
    });

    _workerSendPort = await receivePort.first as SendPort;
  }

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
    return coords.where((m) => !hasMonth(m.$1, m.$2)).toList();
  }

  bool isWindowCached(DateTime month) =>
      missingMonths(windowCoords(month)).isEmpty;

  Map<DateTime, List<Map<String, dynamic>>> mergeWindow(DateTime month) {
    final coords = windowCoords(month);
    final merged = <DateTime, List<Map<String, dynamic>>>{};
    for (final c in coords) {
      final mKey = monthKey(c.$1, c.$2);
      final mData = _cache[mKey];
      if (mData != null) {
        merged.addAll(mData);
      }
    }
    return merged;
  }

  Future<Map<DateTime, List<Map<String, dynamic>>>> loadSingleMonth(
    int year,
    int month,
  ) async {
    final key = monthKey(year, month);
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }
    if (_inFlightFutures.containsKey(key)) {
      return _inFlightFutures[key]!;
    }

    final future = () async {
      await Future.delayed(Duration.zero);
      if (_workerSendPort == null) {
        await initWorker();
      }

      if (_workerSendPort != null) {
        final replyPort = ReceivePort();
        final requestId = ++_requestIdCounter;

        _workerSendPort!.send({
          'id': requestId,
          'year': year,
          'month': month,
          'replyPort': replyPort.sendPort,
        });

        final response = await replyPort.first as Map<String, dynamic>;
        replyPort.close();

        if (response['success'] as bool) {
          final rawData = response['data'] as Map;
          final formattedData = <DateTime, List<Map<String, dynamic>>>{};
          rawData.forEach((k, v) {
            if (k is DateTime && v is List) {
              formattedData[k] =
                  v.map((item) {
                    if (item is Map) {
                      return Map<String, dynamic>.from(item);
                    }
                    return <String, dynamic>{};
                  }).toList();
            }
          });
          return formattedData;
        } else {
          throw Exception(response['error']);
        }
      } else {
        final calculator = AstroCalculator();
        return calculator.getVocEventsForMonth(year, month);
      }
    }();

    _inFlightFutures[key] = future;
    try {
      final res = await future;
      _cache[key] = res;
      return res;
    } finally {
      _inFlightFutures.remove(key);
    }
  }

  Future<Map<String, Map<DateTime, List<Map<String, dynamic>>>>> loadMonths(
    List<(int, int)> months,
  ) async {
    if (months.isEmpty) return {};
    final out = <String, Map<DateTime, List<Map<String, dynamic>>>>{};
    final futures =
        <(int, int), Future<Map<DateTime, List<Map<String, dynamic>>>>>{};

    for (final m in months) {
      futures[m] = loadSingleMonth(m.$1, m.$2);
    }

    for (final entry in futures.entries) {
      final m = entry.key;
      try {
        out[monthKey(m.$1, m.$2)] = await entry.value;
      } catch (e, stack) {
        developer.log(
          'Error loading month ${m.$1}-${m.$2} via background isolate: $e. Falling back to main thread calculation.',
          name: 'CalendarVocCache',
          error: e,
          stackTrace: stack,
        );
        try {
          final calculator = AstroCalculator();
          out[monthKey(m.$1, m.$2)] = calculator.getVocEventsForMonth(m.$1, m.$2);
        } catch (fallbackError, fallbackStack) {
          developer.log(
            'Fallback calculation failed for month ${m.$1}-${m.$2}: $fallbackError\n$fallbackStack',
            name: 'CalendarVocCache',
            error: fallbackError,
            stackTrace: fallbackStack,
          );
          out[monthKey(m.$1, m.$2)] = {};
        }
      }
    }
    return out;
  }

  /// UI를 막지 않고 캐시만 채움 (앱 시작·탭 진입·월 스와이프 후)
  void preloadAroundSilent(DateTime center, {int radius = 2}) {
    final missing = missingMonths(coordsInRadius(center, radius));
    if (missing.isEmpty) return;

    final keys = missing.map((m) => monthKey(m.$1, m.$2)).toList();
    if (keys.any(_inFlight.contains)) {
      final stillMissing =
          missing.where((m) {
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

void _astroWorkerEntryPoint(Map<String, dynamic> initData) async {
  final SendPort mainSendPort = initData['sendPort'];
  final RootIsolateToken token = initData['token'];
  final String? epheFilesPath = initData['epheFilesPath'];

  BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  await SwephInitializer.init(customEpheFilesPath: epheFilesPath);
  final calculator = AstroCalculator();

  final commandPort = ReceivePort();
  mainSendPort.send(commandPort.sendPort);

  await for (final message in commandPort) {
    if (message is Map<String, dynamic>) {
      final int requestId = message['id'];
      final int year = message['year'];
      final int month = message['month'];
      final SendPort replyPort = message['replyPort'];

      try {
        final res = calculator.getVocEventsForMonth(year, month);
        replyPort.send({'id': requestId, 'success': true, 'data': res});
      } catch (e) {
        replyPort.send({
          'id': requestId,
          'success': false,
          'error': e.toString(),
        });
      }
    }
  }
}

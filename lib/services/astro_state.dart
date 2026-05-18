import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:timezone/timezone.dart' as tz;
import 'astro_calculator.dart';
import 'notification_service.dart';
import 'alarm_service.dart';
import 'package:sweph/sweph.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'widget_service.dart';

final AstroCalculator _calculator = AstroCalculator();

enum AlarmPermissionStatus { granted, notificationDenied, exactAlarmDenied }

class AstroState with ChangeNotifier {
  Timer? _timer;
  final NotificationService _notificationService = NotificationService();
  final AlarmService _alarmService = AlarmService();
  SharedPreferences? _prefs; // 캐시된 SharedPreferences 인스턴스
  bool _isScheduling = false; // _schedulePreVoidAlarm 동시 실행 방지
  bool _voidAlarmEnabled = false;
  int _preVoidAlarmHours = 6;

  DateTime _selectedDate = DateTime.now();
  bool _isFollowingTime = true;
  String _moonPhase = '';
  String _moonZodiac = '';
  String _moonInSign = '';

  // VOC for the selected date
  DateTime? _vocStart;
  DateTime? _vocEnd;

  // VOC Aspect Info
  String? _vocPlanet;
  String? _vocAspect;

  DateTime? _nextSignTime;
  DateTime? _currentSignStartTime;
  String? _lastError;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isDarkMode = false;
  String _nextMoonPhaseName = 'calculating';
  DateTime? _nextMoonPhaseTime;
  DateTime? _moonPhaseStartTime;
  DateTime? _moonPhaseEndTime;
  late String _currentLocale;

  DateTime get selectedDate => _selectedDate;
  String get moonPhase => _moonPhase;
  String get moonZodiac => _moonZodiac;
  String get moonInSign => _moonInSign;
  DateTime? get vocStart => _vocStart;
  DateTime? get vocEnd => _vocEnd;
  String? get vocPlanet => _vocPlanet;
  String? get vocAspect => _vocAspect;
  DateTime? get nextSignTime => _nextSignTime;
  DateTime? get currentSignStartTime => _currentSignStartTime;
  String? get lastError => _lastError;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  bool get voidAlarmEnabled => _voidAlarmEnabled;
  int get preVoidAlarmHours => _preVoidAlarmHours;
  String get nextMoonPhaseName => _nextMoonPhaseName;
  DateTime? get nextMoonPhaseTime => _nextMoonPhaseTime;
  DateTime? get moonPhaseStartTime => _moonPhaseStartTime;
  DateTime? get moonPhaseEndTime => _moonPhaseEndTime;
  bool get isFollowingTime => _isFollowingTime;

  bool showTimezoneChangeWarning = false;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  Future<void> followTime() async {
    await FirebaseAnalytics.instance.logEvent(name: 'click_reset_today');
    if (_isFollowingTime) return;
    _isFollowingTime = true;
    _selectedDate = DateTime.now();
    await refreshData();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isLoading = true;

    try {
      //스위프 초기화
      //천문학 라이브러리 초기화
      await Sweph.init();
      //shared preferences 초기화 (캐싱)
      _prefs = await SharedPreferences.getInstance();
      
      //현재 로케일 설정
      final savedLang = _prefs!.getString('language_code');
      _currentLocale = savedLang ?? Intl.getCurrentLocale() ?? 'en';
      await _prefs!.setString('cached_language_code', _currentLocale);

      //알림 서비스 초기화
      await _notificationService.init();
      //알람 매니저 초기화 (앱 종료 후에도 백그라운드 서비스 시작 가능)
      await _alarmService.init();
      //void alarm enabled 상태 저장
      _voidAlarmEnabled = _prefs!.getBool('voidAlarmEnabled') ?? false;
      _preVoidAlarmHours = _prefs!.getInt('preVoidAlarmHours') ?? 6;

      // [Analytics] 앱 시작 시 유저 속성(User Property) 설정
      // 이를 통해 "현재 알람을 켜둔 유저 비율", "한국어/영어 사용자 비율"을 파악할 수 있습니다.
      await FirebaseAnalytics.instance.setUserProperty(
        name: 'void_alarm_enabled',
        value: _voidAlarmEnabled.toString(),
      );
      await FirebaseAnalytics.instance.setUserProperty(
        name: 'language',
        value: _currentLocale,
      );

      await _updateData();

      // 알람이 활성화되어 있으면 예약 알림 설정 (앱 재시작 시에도 동작)
      // 항상 스케줄링하여 서비스가 죽었더라도 재시작되도록 함
      // try-catch로 감싸서 서비스 시작 실패가 앱 초기화 실패로 번지지 않도록 함
      // (삼성 One UI / Android 15: 앱 첫 실행 시 ForegroundServiceStartNotAllowedException)
      if (_voidAlarmEnabled) {
        try {
          await _schedulePreVoidAlarm();
        } catch (e) {
          if (kDebugMode) {
            developer.log('_schedulePreVoidAlarm failed on init (ignored): $e', name: 'AstroState');
          }
          // 서비스 시작 실패는 무시 - 앱은 정상 실행되고 알림만 비활성화됨
        }
      }

      _isInitialized = true;
      _lastError = null;
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log('Initialization error: $e\n$stack', name: 'AstroState');
      }
      _lastError = 'initializationError';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //
  Future<void> updateLocale(String languageCode) async {
    _currentLocale = languageCode;
    await _prefs?.setString('cached_language_code', languageCode);

    if (_voidAlarmEnabled) {
      await _schedulePreVoidAlarm();
    }

    // 언어가 변경되면 알림 메시지도 갱신되어야 하므로 데이터 갱신 (배경 서비스용)
    if (_vocStart != null) {
      // Trigger update to save new locale to prefs if not already done by _schedulePreVoidAlarm
      // But _schedulePreVoidAlarm doesn't save to prefs. _updateStateFromResult does.
      // So let's just save explicitly here or rely on _updateData if called.
      // Actually, _updateData calls _updateStateFromResult.
      // Let's call _updateData to be safe and consistent.
      // But _updateData might be expensive.
      // Let's just ensure prefs are saved.
      // We already saved 'cached_language_code' above.
    }
  }

  /// 타임존 변경 시 호출 (VOC 알람을 선택된 타임존 기준으로 재계산)
  Future<void> updateVocAlarmForTimezone() async {
    if (_voidAlarmEnabled) {
      showTimezoneChangeWarning = true;
      // 알람을 끄고, toggleVoidAlarm 내부에서 notifyListeners()가 호출됨
      await toggleVoidAlarm(false);
    } else {
      // 알람이 꺼져 있으면, 경고 없이 알람만 재계산
      await _schedulePreVoidAlarm();
    }
  }

  Future<AlarmPermissionStatus> toggleVoidAlarm(bool enable) async {
    if (enable) {
      final bool hasNotificationPermission =
          await _notificationService.requestPermissions();
      if (!hasNotificationPermission) {
        _voidAlarmEnabled = false;
        notifyListeners();
        return AlarmPermissionStatus.notificationDenied;
      }

      // 배터리 최적화 제외 요청 (알람이 죽지 않도록)
      await _notificationService.requestBatteryOptimizationPermission();

      bool hasExactAlarmPermission =
          await _notificationService.checkExactAlarmPermission();
      if (!hasExactAlarmPermission) {
        await _notificationService.requestExactAlarmPermission();
        hasExactAlarmPermission =
            await _notificationService.checkExactAlarmPermission();
      }

      if (hasExactAlarmPermission) {
        _voidAlarmEnabled = true;
        await _prefs?.setBool('voidAlarmEnabled', true);
        // _schedulePreVoidAlarm에서 pre-void 시작 여부에 따라 서비스 시작 결정
        await _schedulePreVoidAlarm(isToggleOn: true);

        notifyListeners();
        return AlarmPermissionStatus.granted;
      } else {
        _voidAlarmEnabled = false;
        await _prefs?.setBool('voidAlarmEnabled', false);
        notifyListeners();
        return AlarmPermissionStatus.exactAlarmDenied;
      }
    } else {
      _voidAlarmEnabled = false;
      await _prefs?.setBool('voidAlarmEnabled', false);
      await _notificationService.cancelAllNotifications();
      await _alarmService.cancelAlarm();

      // Stop Background Service
      final service = FlutterBackgroundService();
      service.invoke("stopService");

      notifyListeners();
      return AlarmPermissionStatus.granted;
    }
  }

  /// 앱이 포그라운드로 복귀할 때 호출하여 서비스가 실행 중인지 확인하고 필요시 재시작
  Future<void> ensureServiceRunning() async {
    if (!_isInitialized || !_voidAlarmEnabled) return;
    await _schedulePreVoidAlarm();
  }

  Future<void> setPreVoidAlarmHours(int hours) async {
    _preVoidAlarmHours = hours;
    await _prefs?.setInt('preVoidAlarmHours', hours);
    await _schedulePreVoidAlarm(isToggleOn: false);
    notifyListeners();
  }

  Future<void> _schedulePreVoidAlarm({bool isToggleOn = false}) async {
    // 동시 실행 방지 (platform channel 병목으로 UI 프리징 방지)
    if (_isScheduling) return;
    _isScheduling = true;

    try {
    // 기존 예약된 알림들 병렬로 취소 (1000~1100번)
    await Future.wait([
      for (int i = 0; i < 100; i++)
        _notificationService.cancelNotification(1000 + i),
      _alarmService.cancelAlarm(), // AlarmManager 알람도 함께 취소
    ]);

    if (!_voidAlarmEnabled) {
      notifyListeners();
      return;
    }

    // 선택된 타임존 ID 읽기 (기본값: Asia/Seoul)
    final selectedTimezoneId = _prefs?.getString('selected_timezone') ?? 'Asia/Seoul';
    
    // 현재 시간을 UTC로 변환후 선택된 타임존으로 변환
    try {
      final location = tz.getLocation(selectedTimezoneId);
      final utcNow = DateTime.now().toUtc();
      final tzDateTime = tz.TZDateTime.from(utcNow, location);
      
      // 선택된 타임존의 현지 자정을 UTC로 변환하여 검색 시작
      // (기기 타임존이 아닌 선택된 타임존 기준으로 날짜 경계를 결정)
      DateTime searchDate = tz.TZDateTime(
        location,
        tzDateTime.year,
        tzDateTime.month,
        tzDateTime.day,
      ).toUtc();

      // 백그라운드 서비스용 타임존 및 pre-void 시간 동기화
      await _prefs?.setString('cached_selected_timezone', selectedTimezoneId);
      await _prefs?.setInt('cached_pre_void_hours', _preVoidAlarmHours);

      DateTime? foundVocStart;
      DateTime? foundVocEnd;

      for (int i = 0; i < 10; i++) {
        final vocTimes = _calculator.findVoidOfCoursePeriod(searchDate);
        final vocStart = vocTimes['start'];
        final vocEnd = vocTimes['end'];

        if (vocStart == null || vocEnd == null) {
          searchDate = searchDate.add(const Duration(days: 1));
          continue;
        }

        // 현재 타임존 시간 기준으로 이미 지난 VOC는 스킵
        if (vocEnd.isBefore(utcNow)) {
          searchDate = vocEnd.add(const Duration(minutes: 1));
          continue;
        }

        // 첫 번째 유효한 VOC를 백그라운드 서비스용으로 캐시
        await _prefs?.setString('cached_voc_start', vocStart.toIso8601String());
        await _prefs?.setString('cached_voc_end', vocEnd.toIso8601String());

        foundVocStart = vocStart;
        foundVocEnd = vocEnd;

        if (kDebugMode) {
          developer.log('Cached VOC (Timezone: $selectedTimezoneId): start=$vocStart, end=$vocEnd', name: 'AstroState');
        }

        break; // 첫 번째 유효한 VOC만 캐시하면 됨
      }

      // 백그라운드 서비스는 pre-void 시작 이후에만 필요
      // pre-void 시작 전이면 서비스를 시작하지 않음 (빈 알림 방지)
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();

      if (foundVocStart != null && foundVocEnd != null) {
        final preVoidStart = foundVocStart.subtract(Duration(hours: _preVoidAlarmHours));
        final shouldServiceRun = utcNow.isAfter(preVoidStart) || utcNow.isAtSameMomentAs(preVoidStart);

        if (shouldServiceRun && _voidAlarmEnabled) {
          if (!isRunning) {
            // 서비스가 실행 중이 아니면 시작
            await service.startService();
            if (kDebugMode) {
              developer.log('Background service started for VOC monitoring', name: 'AstroState');
            }
          } else {
            // 서비스가 실행 중이라고 보고하더라도,
            // SharedPreferences를 즉시 반영하도록 refreshData 이벤트 전송
            service.invoke("refreshData");
            if (kDebugMode) {
              developer.log('Background service refreshData invoked', name: 'AstroState');
            }
          }
        } else if (!shouldServiceRun && isRunning) {
          // pre-void 전인데 서비스가 실행 중이면 종료
          service.invoke("stopService");
          if (kDebugMode) {
            developer.log('Background service stopped (pre-void not yet started)', name: 'AstroState');
          }
        }

        // AlarmManager 예약 (4개 - 알림 4종 각각 보장):
        // 1) pre-void 시작 → 서비스 시작 (pre-void 카운트다운)
        // 2) void 시작    → "시작합니다!" 직접 전송 + 서비스 재시작 (void 카운트다운)
        // 3) void 중간    → 서비스 재시작 (mid-void 죽었을 때 카운트다운 복구)
        // 4) void 종료    → "종료됩니다." 직접 전송
        if (preVoidStart.isAfter(utcNow)) {
          await _alarmService.schedulePreVoidAlarm(preVoidStart);
          if (kDebugMode) {
            developer.log('Scheduled AlarmManager [1] pre-void at: $preVoidStart', name: 'AstroState');
          }
        }
        if (foundVocStart.isAfter(utcNow)) {
          await _alarmService.scheduleVocStartAlarm(foundVocStart);
          if (kDebugMode) {
            developer.log('Scheduled AlarmManager [2] voc-start at: $foundVocStart', name: 'AstroState');
          }
        }
        // 장기 보이드(24시간 이상)에도 서비스가 생존하도록 12시간 간격으로 알람 체인 예약
        const maxInterval = Duration(hours: 12);
        final nextMidVoc = foundVocStart.add(maxInterval);

        // 다음 중간 알람이 보이드 종료 시점보다 이르고, 현재보다 나중일 경우에만 예약
        if (nextMidVoc.isBefore(foundVocEnd) && nextMidVoc.isAfter(utcNow)) {
          await _alarmService.scheduleVocMidAlarm(nextMidVoc);
          if (kDebugMode) {
            developer.log(
                'Scheduled chained voc-mid alarm at: $nextMidVoc',
                name: 'AstroState');
          }
        }
        // void 종료 알림은 항상 예약 (서비스가 죽어도 AlarmManager가 직접 전송)
        await _alarmService.scheduleVocEndAlarm(foundVocEnd);
        if (kDebugMode) {
          developer.log('Scheduled AlarmManager [4] voc-end at: $foundVocEnd', name: 'AstroState');
        }
      } else if (isRunning) {
        // VOC 데이터가 없으면 서비스 종료
        service.invoke("stopService");
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error in _schedulePreVoidAlarm: $e', name: 'AstroState');
      }
    }

    notifyListeners();
    } finally {
      _isScheduling = false;
    }
  }

  void _scheduleNextUpdate() {
    _timer?.cancel();

    // We only schedule updates if the app is following the current time.
    if (!_isFollowingTime) {
      return;
    }

    // Determine the soonest event time that is in the future.
    final now = DateTime.now();
    DateTime? nextEvent;

    final signTime = _nextSignTime;
    final phaseTime = _nextMoonPhaseTime;
    final vocStart = _vocStart;
    final vocEnd = _vocEnd;

    if (signTime != null && signTime.isAfter(now)) {
      nextEvent = signTime;
    }
    if (phaseTime != null && phaseTime.isAfter(now)) {
      if (nextEvent == null || phaseTime.isBefore(nextEvent)) {
        nextEvent = phaseTime;
      }
    }
    if (vocStart != null && vocStart.isAfter(now)) {
      if (nextEvent == null || vocStart.isBefore(nextEvent)) {
        nextEvent = vocStart;
      }
    }
    if (vocEnd != null && vocEnd.isAfter(now)) {
      if (nextEvent == null || vocEnd.isBefore(nextEvent)) {
        nextEvent = vocEnd;
      }
    }

    if (nextEvent != null) {
      // We have a future event. Schedule a timer to fire just after it.
      final duration = nextEvent.difference(now) + const Duration(seconds: 1);

      if (kDebugMode) {
        developer.log('Scheduling next UI update in $duration for event at $nextEvent', name: 'AstroState');
      }

      _timer = Timer(duration, () {
        if (kDebugMode) {
          developer.log('Timer fired for UI update. Refreshing data...', name: 'AstroState');
        }

        // If we are still following time, refresh the data.
        if (_isFollowingTime) {
          _selectedDate = DateTime.now();
          refreshData(); // This will re-calculate event times and re-schedule the next update via _updateStateFromResult

          // Also reschedule alarms if they are enabled.
          if (_voidAlarmEnabled) {
            _schedulePreVoidAlarm();
          }
        }
      });
    } else {
      if (kDebugMode) {
        developer.log('No future events found to schedule an update for.', name: 'AstroState');
      }
    }
  }

  Future<void> updateDate(DateTime newDate) async {
    await FirebaseAnalytics.instance.logEvent(name: 'click_calendar');
    final now = DateTime.now();
    final bool isSameDay =
        newDate.year == now.year &&
        newDate.month == now.month &&
        newDate.day == now.day;

    if (isSameDay) {
      _selectedDate = now;
      _isFollowingTime = true;
    } else {
      _selectedDate = DateTime(newDate.year, newDate.month, newDate.day);
      _isFollowingTime = false;
    }
    await refreshData();
  }

  Future<void> refreshData() async {
    final now = DateTime.now();

    // On refresh, if we are in follow mode, snap back to the current time.
    if (_isFollowingTime) {
      _isFollowingTime = true;
      _selectedDate = now;
    }

    await _updateData();
  }

  /// 유저가 직접 새로고침 버튼을 눌렀을 때 호출 (Analytics 이벤트 전송)
  Future<void> refreshDataByUser() async {
    await FirebaseAnalytics.instance.logEvent(name: 'click_refresh');
    await refreshData();
  }


// ----------------------------------------------------------------------------------------------------


  //실제 계산 시작
  Future<void> _updateData() async {
    _isLoading = true;
    notifyListeners();

    // 선택된 타임존 기준으로 계산 시점을 결정
    final selectedTimezoneId = _prefs?.getString('selected_timezone') ?? 'Asia/Seoul';
    DateTime dateForCalc;
    try {
      final location = tz.getLocation(selectedTimezoneId);
      if (_isFollowingTime) {
        // 실시간 모드: 현재 UTC 시간을 그대로 사용
        // (기기 로컬 시간을 선택된 타임존으로 잘못 해석하는 문제 방지)
        dateForCalc = DateTime.now().toUtc();
      } else {
        // 날짜 선택 모드: 선택된 날짜를 선택된 타임존의 자정으로 변환
        dateForCalc = tz.TZDateTime(
          location,
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        ).toUtc();
      }
    } catch (e) {
      dateForCalc = _selectedDate.toUtc();
    }

    //카큘레이터에서 가져와서 계산 시작
    try {
      final moonPhaseInfo = _calculator.getMoonPhaseInfo(dateForCalc);
      final moonPhase = moonPhaseInfo['phaseName'] ?? '';
      final moonZodiac = _calculator.getMoonZodiacEmoji(dateForCalc);
      var vocTimes = _calculator.findVoidOfCoursePeriod(dateForCalc);

      // If we are following time and the found VOC has already passed, find the next one
      DateTime? nextVocStart;
      DateTime? nextVocEnd;
      if (_isFollowingTime && vocTimes['end'] != null) {
        final now = DateTime.now();
        final vocStart = vocTimes['start'] as DateTime?;
        final vocEnd = vocTimes['end'] as DateTime;
        
        if (vocStart != null && now.isAfter(vocStart) && now.isBefore(vocEnd)) {
          // We are currently IN the VOC. We need the NEXT VOC start for the widget.
          final nextVocTimes = _calculator.findVoidOfCoursePeriod(
            vocEnd.add(const Duration(minutes: 1)),
          );
          nextVocStart = nextVocTimes['start'];
          nextVocEnd = nextVocTimes['end'];
        } else if (vocEnd.isBefore(now)) {
          // Search from the next day to ensure we find the next VOC event
          // (findVoidOfCoursePeriod resets search to start of the day)
          vocTimes = _calculator.findVoidOfCoursePeriod(
            vocEnd.add(const Duration(days: 1)),
          );
        }
      }

      final moonSignTimes = _calculator.getMoonSignTimes(dateForCalc);

      final moonSignName = _calculator.getMoonSignName(dateForCalc);
      
      final moonPhaseTimes = _calculator.getMoonPhaseTimes(dateForCalc);

      // getMoonPhaseTimes가 nextPhaseName도 함께 반환 (findNextPhase 중복 호출 제거)
      final nextMoonPhaseName = moonPhaseTimes['nextPhaseName'] as String? ?? 'N/A';

      if (kDebugMode) {
        print('[DEBUG] moonPhaseInfo: $moonPhaseInfo');
        print('[DEBUG] moonZodiac: $moonZodiac');
        print('[DEBUG] moonInSign (Name): $moonSignName');
        print('[DEBUG] vocTimes: $vocTimes');
        print('[DEBUG] moonSignTimes: $moonSignTimes');
        print('[DEBUG] moonPhaseTimes: $moonPhaseTimes');
      }

      final Map<String, dynamic> result = {
        'moonPhase': moonPhase,
        'moonZodiac': moonZodiac,
        'moonInSign': moonSignName,
        'vocStart': vocTimes['start'],
        'vocEnd': vocTimes['end'],
        'vocPlanet': vocTimes['planet'],
        'vocAspect': vocTimes['aspect'],
        'nextSignTime': moonSignTimes['end'],
        'currentSignStartTime': moonSignTimes['start'],
        'nextMoonPhaseName': nextMoonPhaseName,
        'nextMoonPhaseTime': moonPhaseTimes['end'],
        'moonPhaseStartTime': moonPhaseTimes['start'],
        'moonPhaseEndTime': moonPhaseTimes['end'],
        'nextVocStart': nextVocStart,
        'nextVocEnd': nextVocEnd,
      };

      await _updateStateFromResult(result);
      _lastError = null;
    } catch (e, stack) {
      if (kDebugMode) {
        print('[AstroState] Error during calculation: $e\n$stack');
      }
      _lastError = 'calculationError';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 계산된 결과를 -> 메모리에 저장하고
  Future<void> _updateStateFromResult(Map<String, dynamic> result) async {
    _moonPhase = result['moonPhase'] as String? ?? '';
    // 수정: null일 경우 빈 문자열로 처리하여 오류 방지
    _moonZodiac = result['moonZodiac'] as String? ?? '';
    _moonInSign = result['moonInSign'] as String? ?? '';
    _vocStart = result['vocStart'] as DateTime?;
    _vocEnd = result['vocEnd'] as DateTime?;
    _vocPlanet = result['vocPlanet'] as String?;
    _vocAspect = result['vocAspect'] as String?;
    _nextSignTime = result['nextSignTime'] as DateTime?;
    _currentSignStartTime = result['currentSignStartTime'] as DateTime?;
    _nextMoonPhaseName = result['nextMoonPhaseName'] as String? ?? '';
    _nextMoonPhaseTime = result['nextMoonPhaseTime'] as DateTime?;
    _moonPhaseStartTime = result['moonPhaseStartTime'] as DateTime?;
    _moonPhaseEndTime = result['moonPhaseEndTime'] as DateTime?;

    // Cache VOC times and settings for background service
    await _prefs?.setInt('cached_pre_void_hours', _preVoidAlarmHours);

    // 수정: _currentLocale이 초기화되지 않았을 경우를 대비해 예외 처리
    try {
      await _prefs?.setString('cached_language_code', _currentLocale);
    } catch (_) {
      // 초기화 전이라면 무시하거나 기본값 사용
    }

    // Update the Android Widget
    if (_isFollowingTime) {
      await WidgetService.updateWidgetData(
        vocStart: _vocStart,
        vocEnd: _vocEnd,
        nextVocStart: result['nextVocStart'] as DateTime?,
        nextVocEnd: result['nextVocEnd'] as DateTime?,
        moonZodiac: _moonZodiac,
      );
    }

    // ... (나머지 코드는 동일)
    _scheduleNextUpdate();
  }
}

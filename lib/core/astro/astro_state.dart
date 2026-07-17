import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:void_of_course/core/utils/app_analytics.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:void_of_course/core/astro/astro_calculator.dart';
import 'package:void_of_course/core/background/notification_service.dart';
import 'package:void_of_course/core/background/alarm_service.dart';
import 'package:sweph/sweph.dart';
import 'package:void_of_course/core/astro/sweph_initializer.dart';
import 'package:void_of_course/features/calendar/services/calendar_voc_cache.dart';
import 'package:void_of_course/core/astro/void_cycle_scheduler.dart';
import 'package:void_of_course/features/home/services/widget_service.dart';

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

  // Mercury and Venus retrograde details
  bool _mercuryRetrograde = false;
  DateTime? _mercuryRetroStart;
  DateTime? _mercuryRetroEnd;

  bool _venusRetrograde = false;
  DateTime? _venusRetroStart;
  DateTime? _venusRetroEnd;

  bool _showRetrogradeCard = true;

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

  bool get mercuryRetrograde => _mercuryRetrograde;
  DateTime? get mercuryRetroStart => _mercuryRetroStart;
  DateTime? get mercuryRetroEnd => _mercuryRetroEnd;

  bool get venusRetrograde => _venusRetrograde;
  DateTime? get venusRetroStart => _venusRetroStart;
  DateTime? get venusRetroEnd => _venusRetroEnd;

  bool get showRetrogradeCard => _showRetrogradeCard;

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
    await AppAnalytics.logTapResetToToday();
    if (_isFollowingTime) return;
    _isFollowingTime = true;
    _selectedDate = DateTime.now();
    await refreshData();
  }

  static const _initializeTimeout = Duration(seconds: 20);

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isLoading = true;

    try {
      await _runInitializeBody().timeout(
        _initializeTimeout,
        onTimeout: () {
          throw TimeoutException(
            'AstroState initialize timed out after ${_initializeTimeout.inSeconds}s',
          );
        },
      );
      _isInitialized = true;
      _lastError = null;
    } catch (e, stack) {
      print('AstroState Initialization error: $e\n$stack');
      if (kDebugMode) {
        developer.log('Initialization error: $e\n$stack', name: 'AstroState');
      }
      _lastError = 'initializationError';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _runInitializeBody() async {
    await SwephInitializer.init();
    await CalendarVocCache.instance.initWorker();
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
    _showRetrogradeCard = _prefs!.getBool('showRetrogradeCard') ?? true;

    // [Analytics] 앱 시작 시 유저 속성(User Property) 설정
    // 이를 통해 "현재 알람을 켜둔 유저 비율", "한국어/영어 사용자 비율"을 파악할 수 있습니다.
    await AppAnalytics.setVoidAlarmEnabled(_voidAlarmEnabled);
    await AppAnalytics.setLanguage(_currentLocale);
    await AppAnalytics.setRetrogradeCardEnabled(_showRetrogradeCard);

    // _updateData() -> _updateStateFromResult() -> _syncVocSchedules() 순서로 호수되며,
    // _syncVocSchedules() 내부에 자체 에러 핸들링이 있어 별도 try-catch 불필요입니다.
    await _updateData();

    await _updateAnalyticsUserSegment();

    // 메인 스레드 계산(_updateData)이 완전히 끝난 후, 안전하게 백그라운드 프리로드 진행 (동시성 충돌 방지)
    CalendarVocCache.instance.preloadAroundSilent(DateTime.now(), radius: 1);
  }

  //
  Future<void> updateLocale(String languageCode) async {
    _currentLocale = languageCode;
    await _prefs?.setString('cached_language_code', languageCode);

    if (_voidAlarmEnabled || await WidgetService.isEnabled(_prefs)) {
      await _syncVocSchedules();
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
        await _syncVocSchedules();
        await _updateAnalyticsUserSegment();

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
      await VoidCycleScheduler.cancelVoidNotificationAlarms();
      await VoidCycleScheduler.stopCountdownService();

      await _syncVocSchedules();
      await _updateAnalyticsUserSegment();

      notifyListeners();
      return AlarmPermissionStatus.granted;
    }
  }

  /// 홈 위젯 설치 여부 반영 (위젯이 있으면 자동 갱신·알람 재예약)
  Future<void> syncHomeWidgetFromInstallStatus(bool hasInstalledWidget) async {
    if (_prefs == null) return;
    await WidgetService.setInstallStatus(hasInstalledWidget);
    await _syncVocSchedules();
    await _updateAnalyticsUserSegment();
  }

  Future<void> _updateAnalyticsUserSegment() async {
    final hasWidget = await WidgetService.isEnabled(_prefs);
    final segment = switch ((_voidAlarmEnabled, hasWidget)) {
      (true, true) => 'alarm_and_widget',
      (true, false) => 'alarm_only',
      (false, true) => 'widget_only',
      (false, false) => 'neither',
    };
    await AppAnalytics.setHasHomeWidget(hasWidget);
    await AppAnalytics.setVoidAlarmEnabled(_voidAlarmEnabled);
  }

  /// 앱이 포그라운드로 복귀할 때 호출하여 서비스가 실행 중인지 확인하고 필요시 재시작
  Future<void> ensureServiceRunning() async {
    if (!_isInitialized) return;
    await _syncVocSchedules();
  }

  Future<void> setPreVoidAlarmHours(int hours) async {
    _preVoidAlarmHours = hours;
    await _prefs?.setInt('preVoidAlarmHours', hours);
    await _syncVocSchedules();
    notifyListeners();
  }

  Future<void> setShowRetrogradeCard(bool value) async {
    _showRetrogradeCard = value;
    await _prefs?.setBool('showRetrogradeCard', value);
    notifyListeners();
  }

  /// 알림(AlarmManager) · 위젯 · FG 카운트다운을 각 설정에 맞게 동기화
  Future<void> _syncVocSchedules() async {
    if (_isScheduling) return;
    if (!_isInitialized || !_isFollowingTime) return;

    _isScheduling = true;
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.reload();
      await prefs.setInt('cached_pre_void_hours', _preVoidAlarmHours);
      await prefs.setString('cached_language_code', _currentLocale);

      final selectedTimezoneId =
          prefs.getString('selected_timezone') ?? 'Asia/Seoul';
      await prefs.setString('cached_selected_timezone', selectedTimezoneId);

      final upcoming = await VoidCycleScheduler.findUpcomingVoc(prefs);
      if (upcoming == null) {
        if (await WidgetService.isEnabled(prefs)) {
          await WidgetService.cancelRefreshAlarms();
        }
        if (_voidAlarmEnabled) {
          await VoidCycleScheduler.cancelVoidNotificationAlarms();
          await VoidCycleScheduler.stopCountdownService();
        }
        return;
      }

      await VoidCycleScheduler.cacheVocPeriod(
        prefs,
        start: upcoming.start,
        end: upcoming.end,
      );

      _vocStart = upcoming.start;
      _vocEnd = upcoming.end;

      if (await WidgetService.isEnabled(prefs)) {
        DateTime? nextStart;
        DateTime? nextEnd;
        final now = DateTime.now().toUtc();
        if (now.isAfter(upcoming.start) && now.isBefore(upcoming.end)) {
          final next = await WidgetService.findNextVocPeriod(upcoming.end);
          nextStart = next?.start;
          nextEnd = next?.end;
        }
        await WidgetService.updateWidgetData(
          vocStart: upcoming.start,
          vocEnd: upcoming.end,
          nextVocStart: nextStart,
          nextVocEnd: nextEnd,
          moonZodiac: _moonZodiac,
        );
        await WidgetService.scheduleRefreshAlarms(
          vocStart: upcoming.start,
          vocEnd: upcoming.end,
        );
      } else {
        await WidgetService.cancelRefreshAlarms();
      }

      if (_voidAlarmEnabled) {
        await Future.wait([
          for (int i = 0; i < 100; i++)
            _notificationService.cancelNotification(1000 + i),
        ]);
        await VoidCycleScheduler.scheduleVoidNotificationAlarms(
          prefs,
          vocStart: upcoming.start,
          vocEnd: upcoming.end,
        );
        await VoidCycleScheduler.tryStartCountdownService(prefs);
      } else {
        await VoidCycleScheduler.cancelVoidNotificationAlarms();
        await VoidCycleScheduler.stopCountdownService();
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error in _syncVocSchedules: $e', name: 'AstroState');
      }
    } finally {
      _isScheduling = false;
    }
  }

  Future<void> _schedulePreVoidAlarm() async {
    await _syncVocSchedules();
    notifyListeners();
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
        developer.log(
          'Scheduling next UI update in $duration for event at $nextEvent',
          name: 'AstroState',
        );
      }

      _timer = Timer(duration, () async {
        if (kDebugMode) {
          developer.log(
            'Timer fired for UI update. Refreshing data...',
            name: 'AstroState',
          );
        }

        // If we are still following time, refresh the data.
        if (_isFollowingTime) {
          _selectedDate = DateTime.now();
          refreshData(); // This will re-calculate event times and re-schedule the next update via _updateStateFromResult

          // Also reschedule alarms if they are enabled.
          if (_voidAlarmEnabled || await WidgetService.isEnabled(_prefs)) {
            await _syncVocSchedules();
          }
        }
      });
    } else {
      if (kDebugMode) {
        developer.log(
          'No future events found to schedule an update for.',
          name: 'AstroState',
        );
      }
    }
  }

  Future<void> updateDate(DateTime newDate) async {
    await AppAnalytics.logTapCalendarDay(
      year: newDate.year,
      month: newDate.month,
      day: newDate.day,
      hasVoc: false,
    );
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
    await AppAnalytics.logTapRefresh();
    await refreshData();
  }

  // ----------------------------------------------------------------------------------------------------

  //실제 계산 시작
  Future<void> _updateData() async {
    _isLoading = true;
    notifyListeners();

    // 선택된 타임존 기준으로 계산 시점을 결정
    final selectedTimezoneId =
        _prefs?.getString('selected_timezone') ?? 'Asia/Seoul';
    DateTime dateForCalc;
    try {
      final location = tz.getLocation(selectedTimezoneId);
      if (_isFollowingTime) {
        // 실시간 모드: 현재 UTC 시간을 그대로 사용
        // (기기 로컬 시간을 선택된 타임존으로 잘못 해석하는 문제 방지)
        dateForCalc = DateTime.now().toUtc();
      } else {
        // 날짜 선택 모드: 선택된 날짜를 선택된 타임존의 자정으로 변환
        dateForCalc =
            tz.TZDateTime(
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
      final nextMoonPhaseName =
          moonPhaseTimes['nextPhaseName'] as String? ?? 'N/A';

      // 수성 및 금성 역행 계산
      final mercuryRetroInfo = _calculator.findRetrogradePeriod(
        HeavenlyBody.SE_MERCURY,
        dateForCalc,
      );
      final venusRetroInfo = _calculator.findRetrogradePeriod(
        HeavenlyBody.SE_VENUS,
        dateForCalc,
      );

      if (kDebugMode) {
        print('[DEBUG] moonPhaseInfo: $moonPhaseInfo');
        print('[DEBUG] moonZodiac: $moonZodiac');
        print('[DEBUG] moonInSign (Name): $moonSignName');
        print('[DEBUG] vocTimes: $vocTimes');
        print('[DEBUG] moonSignTimes: $moonSignTimes');
        print('[DEBUG] moonPhaseTimes: $moonPhaseTimes');
        print('[DEBUG] mercuryRetroInfo: $mercuryRetroInfo');
        print('[DEBUG] venusRetroInfo: $venusRetroInfo');
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
        'mercuryRetrograde': mercuryRetroInfo['isRetrograde'] ?? false,
        'mercuryRetroStart': mercuryRetroInfo['start'],
        'mercuryRetroEnd': mercuryRetroInfo['end'],
        'venusRetrograde': venusRetroInfo['isRetrograde'] ?? false,
        'venusRetroStart': venusRetroInfo['start'],
        'venusRetroEnd': venusRetroInfo['end'],
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

    _mercuryRetrograde = result['mercuryRetrograde'] as bool? ?? false;
    _mercuryRetroStart = result['mercuryRetroStart'] as DateTime?;
    _mercuryRetroEnd = result['mercuryRetroEnd'] as DateTime?;
    _venusRetrograde = result['venusRetrograde'] as bool? ?? false;
    _venusRetroStart = result['venusRetroStart'] as DateTime?;
    _venusRetroEnd = result['venusRetroEnd'] as DateTime?;

    // Cache VOC times and settings for background service
    await _prefs?.setInt('cached_pre_void_hours', _preVoidAlarmHours);

    // 수정: _currentLocale이 초기화되지 않았을 경우를 대비해 예외 처리
    try {
      await _prefs?.setString('cached_language_code', _currentLocale);
    } catch (_) {
      // 초기화 전이라면 무시하거나 기본값 사용
    }

    if (_isFollowingTime) {
      await _syncVocSchedules();
    }

    _scheduleNextUpdate();
  }
}

// lib/services/google_calendar_service.dart
// 구글 캘린더 연동 서비스
// - 구글 계정 로그인/로그아웃
// - "Void of Course" 전용 캘린더 생성 (빨간색 고정)
// - VOC 이벤트 일괄 동기화 (오늘 기준 2주 전 ~ 선택 기간)
// - 캘린더 표시/숨기기 토글

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:void_of_course/features/premium/services/purchase_service.dart';
import 'package:void_of_course/core/astro/astro_calculator.dart';
import 'package:void_of_course/core/utils/timezone_provider.dart';
import 'package:sweph/sweph.dart';

/// 동기화 기간 옵션 (오늘 기준 미래 방향)
enum CalendarSyncRange {
  oneMonth(1, '1개월', '1 Month'),
  threeMonths(3, '3개월', '3 Months'),
  sixMonths(6, '6개월', '6 Months');

  final int months;
  final String labelKo;
  final String labelEn;
  const CalendarSyncRange(this.months, this.labelKo, this.labelEn);

  String label(String locale) => locale == 'ko' ? labelKo : labelEn;
}

/// 구글 로그인 및 캘린더 API 연동을 담당하는 서비스
class GoogleCalendarService extends ChangeNotifier {
  GoogleCalendarService._();
  static final GoogleCalendarService instance = GoogleCalendarService._();

  // ─── SharedPreferences 키 ───────────────────────────────────────────────
  static const _kSignedInEmail = 'gcal_signed_in_email';
  static const _kSyncRangeMonths = 'gcal_sync_range_months';
  static const _kVocCalendarId = 'gcal_voc_calendar_id'; // 전용 캘린더 ID
  static const _kSyncedEventIdsPrefix = 'gcal_synced_event_ids_';

  // ─── 전용 캘린더 설정 ─────────────────────────────────────────────────────
  static const _kCalendarName = 'Void of Course 🌙';
  static const _kCalendarColor = '#ff0000'; // 생성 캘린더 색상 고정
  static const _kCalendarFgColor = '#FFFFFF';

  // ─── google_sign_in v6 ───────────────────────────────────────────────────
  static const String _serverClientId =
      '5706956834-4l1hgsvd7lft5omnf785brpo9njc2j5k.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _serverClientId,
    scopes: [gcal.CalendarApi.calendarScope],
  );

  // ─── 상태 ─────────────────────────────────────────────────────────────────
  GoogleSignInAccount? _currentUser;
  gcal.CalendarApi? _calendarApi;
  CalendarSyncRange _syncRange = CalendarSyncRange.threeMonths;
  bool _isSyncing = false;
  String? _vocCalendarId; // 생성된 전용 캘린더 ID
  String? _lastError;

  // ─── Getters ─────────────────────────────────────────────────────────────
  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;
  CalendarSyncRange get syncRange => _syncRange;
  bool get isSyncing => _isSyncing;
  String? get vocCalendarId => _vocCalendarId;
  String? get lastError => _lastError;

  // RevenueCat 인앱 결제 서비스의 프리미엄 여부를 가져옵니다.
  bool get isPremiumUser => PurchaseService.instance.isPremiumUser;

  // ─── 초기화 ───────────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // 저장된 동기화 범위 복원
    final savedMonths = prefs.getInt(_kSyncRangeMonths) ?? 3;
    _syncRange = CalendarSyncRange.values.firstWhere(
      (r) => r.months == savedMonths,
      orElse: () => CalendarSyncRange.threeMonths,
    );

    // 저장된 캘린더 ID 복원
    _vocCalendarId = prefs.getString(_kVocCalendarId);

    // 이전 로그인 조용히 복원
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        _currentUser = account;
        await _initCalendarApi(account);
        debugPrint('[GoogleCalendar] 조용한 로그인 복원: ${account.email}');
      }
    } catch (e) {
      debugPrint('[GoogleCalendar] 조용한 로그인 복원 실패 (무시): $e');
    }
    notifyListeners();
  }

  // ─── 로그인/로그아웃 ──────────────────────────────────────────────────────

  Future<bool> signIn() async {
    try {
      _lastError = null;
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      final hasScope = await _googleSignIn.requestScopes([
        gcal.CalendarApi.calendarScope,
      ]);
      if (!hasScope) {
        _lastError = 'calendar_permission_denied';
        await _googleSignIn.signOut();
        notifyListeners();
        return false;
      }

      _currentUser = account;
      await _initCalendarApi(account);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSignedInEmail, account.email);

      debugPrint('[GoogleCalendar] 로그인 성공: ${account.email}');
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('[GoogleCalendar] 로그인 실패: $e');
      notifyListeners();
      return false;
    }
  }

  /// 로그아웃 (deleteCalendar: true면 전용 캘린더 자체를 삭제)
  Future<void> signOut({bool deleteCalendar = true}) async {
    if (deleteCalendar && _calendarApi != null && _vocCalendarId != null) {
      await _deleteVocCalendar();
    }
    await _googleSignIn.signOut();
    _currentUser = null;
    _calendarApi = null;
    _vocCalendarId = null;
    _lastError = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSignedInEmail);
    await prefs.remove(_kVocCalendarId);
    await _clearEventIds();

    debugPrint('[GoogleCalendar] 로그아웃 완료');
    notifyListeners();
  }

  // ─── 동기화 범위 설정 ─────────────────────────────────────────────────────

  Future<void> setSyncRange(CalendarSyncRange range) async {
    _syncRange = range;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSyncRangeMonths, range.months);
    notifyListeners();

    // 기간 설정이 변경되면 자동으로 동기화 수행
    if (isPremiumUser && isSignedIn) {
      // 강제 동기화를 위해 마지막 동기화 시간 무시
      await syncVocEvents();
      await prefs.setString(
        'gcal_last_auto_sync',
        DateTime.now().toIso8601String(),
      );
    }
  }

  // ─── VOC 이벤트 동기화 ───────────────────────────────────────────────────

  /// 프리미엄 유저를 위한 자동 동기화 (구글 캘린더 API 호출 제한 방지를 위해 최소 1시간 간격 유지)
  Future<void> autoSyncIfPremium({String locale = 'ko'}) async {
    if (!isPremiumUser || !isSignedIn || _isSyncing) return;

    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString('gcal_last_auto_sync');
    final now = DateTime.now();

    if (lastSyncStr != null) {
      final lastSync = DateTime.parse(lastSyncStr);
      // 마지막 동기화로부터 1시간이 지나지 않았다면 스킵
      if (now.difference(lastSync).inHours < 1) {
        debugPrint('[GoogleCalendar] 1시간 이내 자동 동기화 방지 스킵');
        return;
      }
    }

    await syncVocEvents(locale: locale);
    await prefs.setString('gcal_last_auto_sync', now.toIso8601String());
  }

  /// VOC 이벤트를 전용 캘린더에 일괄 동기화
  /// 범위: 오늘 기준 2주 전 ~ 선택 기간(1/3/6개월) 이후
  /// 반환: 동기화된 이벤트 수 (실패 시 -1)
  Future<int> syncVocEvents({String locale = 'ko'}) async {
    if (!isPremiumUser) {
      _lastError = 'premium_required';
      return -1;
    }
    if (!isSignedIn || _calendarApi == null) {
      _lastError = 'not_signed_in';
      return -1;
    }
    if (_isSyncing) return -1;

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      // 1. 전용 캘린더 확보 (없으면 새로 생성)
      final calendarId = await _ensureVocCalendar();
      if (calendarId == null) {
        throw Exception('전용 캘린더를 생성할 수 없습니다.');
      }

      // 2. 기존 동기화 이벤트 삭제
      await _deleteAllSyncedEvents(calendarId);

      // 3. VOC 이벤트 계산
      //    범위: 2주 전 ~ (오늘 + syncRange.months개월)
      await Sweph.init();
      final calculator = AstroCalculator();
      final now = DateTime.now().toUtc();
      final rangeStart = now.subtract(const Duration(days: 14)); // 2주 전
      final rangeEnd =
          DateTime(now.year, now.month + _syncRange.months, now.day).toUtc();

      // 필요한 월 목록 계산
      final Set<String> monthKeys = {};
      var cursor = DateTime(rangeStart.year, rangeStart.month, 1);
      while (cursor.isBefore(rangeEnd) || cursor.month == rangeEnd.month) {
        monthKeys.add('${cursor.year}-${cursor.month}');
        cursor = DateTime(cursor.year, cursor.month + 1, 1);
        if (cursor.isAfter(rangeEnd)) break;
      }

      final Set<String> seenKeys = {};
      final List<Map<String, DateTime>> vocPeriods = [];

      for (final key in monthKeys) {
        final parts = key.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final monthEvents = calculator.getVocEventsForMonth(year, month);

        for (final eventList in monthEvents.values) {
          for (final event in eventList) {
            final start = event['start'] as DateTime?;
            final end = event['end'] as DateTime?;
            if (start == null || end == null) continue;

            // 범위 내 이벤트만 (end가 rangeStart 이후 && start가 rangeEnd 이전)
            if (end.isBefore(rangeStart) || start.isAfter(rangeEnd)) continue;

            final dedupeKey = '${start.millisecondsSinceEpoch}';
            if (seenKeys.add(dedupeKey)) {
              vocPeriods.add({'start': start, 'end': end});
            }
          }
        }
      }

      vocPeriods.sort((a, b) => a['start']!.compareTo(b['start']!));

      // 타임존 프로바이더 로드 (홈에서 설정한 타임존 기준 적용)
      final tzProvider = TimezoneProvider();
      await tzProvider.loadTimezone();

      // 4. 구글 캘린더에 이벤트 추가 (속도 개선을 위해 10개씩 병렬 처리)
      final List<String> createdEventIds = [];
      final title = 'Void of Course 🌙';
      final description =
          locale == 'ko'
              ? '달이 보이드 오브 코스 상태입니다.\n이 시간에는 중요한 결정이나 시작을 피하는 것이 좋습니다.'
              : 'The Moon is Void of Course.\nAvoid important decisions or new beginnings during this time.';

      const batchSize = 40;
      for (var i = 0; i < vocPeriods.length; i += batchSize) {
        final chunk = vocPeriods.skip(i).take(batchSize);
        final results = await Future.wait(
          chunk.map((period) {
            return _addEventToCalendar(
              calendarId: calendarId,
              startUtc: period['start']!,
              endUtc: period['end']!,
              title: title,
              description: description,
              tzProvider: tzProvider,
            );
          }),
        );
        for (final id in results) {
          if (id != null) createdEventIds.add(id);
        }
      }

      // 6. 이벤트 ID 저장
      await _saveEventIds(calendarId, createdEventIds);

      debugPrint('[GoogleCalendar] ${createdEventIds.length}개 이벤트 동기화 완료');
      _isSyncing = false;
      notifyListeners();
      return createdEventIds.length;
    } catch (e) {
      _lastError = e.toString();
      _isSyncing = false;
      debugPrint('[GoogleCalendar] 동기화 실패: $e');
      notifyListeners();
      return -1;
    }
  }

  // ─── 전용 캘린더 관리 ────────────────────────────────────────────────────

  /// "Void of Course 🌙" 캘린더를 확보합니다.
  /// 이미 생성된 ID가 있으면 재사용, 없으면 새로 생성합니다.
  Future<String?> _ensureVocCalendar() async {
    final api = _calendarApi;
    if (api == null) return null;

    // 캐시된 ID가 있으면 실제로 존재하는지 확인
    if (_vocCalendarId != null) {
      try {
        await api.calendarList.get(_vocCalendarId!);
        return _vocCalendarId; // 존재함 → 재사용
      } catch (_) {
        // 캘린더가 삭제됐거나 없음 → 새로 생성
        _vocCalendarId = null;
      }
    }

    // 기존 캘린더 목록에서 같은 이름 찾기
    try {
      final list = await api.calendarList.list();
      for (final entry in list.items ?? []) {
        if (entry.summary == _kCalendarName) {
          _vocCalendarId = entry.id;
          await _persistCalendarId(_vocCalendarId!);
          return _vocCalendarId;
        }
      }
    } catch (e) {
      debugPrint('[GoogleCalendar] 캘린더 목록 조회 실패: $e');
    }

    // 새 캘린더 생성
    try {
      final newCal = gcal.Calendar(summary: _kCalendarName);
      final created = await api.calendars.insert(newCal);
      final newId = created.id!;

      // 빨간색으로 설정
      try {
        // 구글 서버에 캘린더가 완전히 생성될 때까지 약간 대기 (404 에러 방지)
        await Future.delayed(const Duration(milliseconds: 500));
        
        await api.calendarList.patch(
          gcal.CalendarListEntry(
            backgroundColor: '#ff0000',
            foregroundColor: '#ffffff',
          ),
          newId,
          colorRgbFormat: true,
        );
      } catch (e) {
        debugPrint('[GoogleCalendar] 색상 강제 지정 실패 (무시됨): $e');
      }

      _vocCalendarId = newId;
      await _persistCalendarId(newId);
      debugPrint('[GoogleCalendar] 새 캘린더 생성: $newId');
      return newId;
    } catch (e) {
      debugPrint('[GoogleCalendar] 캘린더 생성 실패: $e');
      return null;
    }
  }

  Future<void> _persistCalendarId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVocCalendarId, id);
  }

  /// 전용 캘린더 자체를 삭제 (연동 해제 시)
  Future<void> _deleteVocCalendar() async {
    final api = _calendarApi;
    final id = _vocCalendarId;
    if (api == null || id == null) return;
    try {
      await api.calendars.delete(id);
      debugPrint('[GoogleCalendar] 전용 캘린더 삭제: $id');
    } catch (e) {
      debugPrint('[GoogleCalendar] 캘린더 삭제 실패: $e');
    }
  }

  // ─── 이벤트 CRUD ─────────────────────────────────────────────────────────

  Future<String?> _addEventToCalendar({
    required String calendarId,
    required DateTime startUtc,
    required DateTime endUtc,
    required String title,
    required String description,
    required TimezoneProvider tzProvider,
  }) async {
    final api = _calendarApi;
    if (api == null) return null;

    // 홈에서 설정한 타임존 기준으로 로컬 시간 변환
    final startLocal = tzProvider.convert(startUtc);
    final endLocal = tzProvider.convert(endUtc);
    final isMultiDay =
        startLocal.year != endLocal.year ||
        startLocal.month != endLocal.month ||
        startLocal.day != endLocal.day;

    try {
      gcal.EventDateTime startEvent;
      gcal.EventDateTime endEvent;
      String eventTitle = title;

      if (isMultiDay) {
        // 이틀 이상 넘어가는 이벤트는 All-Day(종일) 이벤트로 설정하여 긴 바로 표시
        startEvent = gcal.EventDateTime(
          date: DateTime.utc(startLocal.year, startLocal.month, startLocal.day),
        );
        // 종일 이벤트의 end date는 exclusive(포함하지 않음)이므로 1일 추가
        final endDate = endLocal.add(const Duration(days: 1));
        endEvent = gcal.EventDateTime(
          date: DateTime.utc(endDate.year, endDate.month, endDate.day),
        );

        // 종일 이벤트로 변경 시 캘린더에서 시간을 알 수 없으므로 제목에 날짜와 시간 추가
        final startStr =
            '${startLocal.month}/${startLocal.day} ${startLocal.hour.toString().padLeft(2, '0')}:${startLocal.minute.toString().padLeft(2, '0')}';
        final endStr =
            '${endLocal.month}/${endLocal.day} ${endLocal.hour.toString().padLeft(2, '0')}:${endLocal.minute.toString().padLeft(2, '0')}';
        eventTitle = '$title ($startStr ~ $endStr)';
      } else {
        // 단일 날짜 이벤트는 시간 지정 이벤트로 설정
        startEvent = gcal.EventDateTime(dateTime: startUtc, timeZone: 'UTC');
        endEvent = gcal.EventDateTime(dateTime: endUtc, timeZone: 'UTC');
      }

      final event = gcal.Event(
        summary: eventTitle,
        description: description,
        start: startEvent,
        end: endEvent,
        transparency: 'transparent', // 시간 차단 안 함
        // colorId 지정 생략: 캘린더의 #ff0000 색상을 자동으로 상속받음
        reminders: gcal.EventReminders(useDefault: false, overrides: []),
      );
      final created = await api.events.insert(event, calendarId);
      return created.id;
    } catch (e) {
      debugPrint('[GoogleCalendar] 이벤트 추가 실패: $e');
      return null;
    }
  }

  Future<void> _deleteAllSyncedEvents(String calendarId) async {
    final api = _calendarApi;
    if (api == null) return;
    final ids = await _loadEventIds();
    if (ids.isEmpty) return;

    int deleted = 0;
    const batchSize = 40;
    for (int i = 0; i < ids.length; i += batchSize) {
      final chunk = ids.skip(i).take(batchSize);
      await Future.wait(
        chunk.map((id) async {
          try {
            await api.events.delete(calendarId, id);
            deleted++;
          } catch (e) {
            debugPrint('[GoogleCalendar] 이벤트 삭제 실패 ($id): $e');
          }
        }),
      );
    }
    await _clearEventIds();
    debugPrint('[GoogleCalendar] $deleted개 이벤트 삭제');
  }

  // ─── SharedPreferences 헬퍼 ──────────────────────────────────────────────

  Future<void> _saveEventIds(String calendarId, List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    // calendarId도 함께 저장해 삭제 시 참조
    await prefs.setString('${_kSyncedEventIdsPrefix}cal', calendarId);
    const chunkSize = 500;
    int chunk = 0;
    for (int i = 0; i < ids.length; i += chunkSize) {
      await prefs.setStringList(
        '$_kSyncedEventIdsPrefix$chunk',
        ids.skip(i).take(chunkSize).toList(),
      );
      chunk++;
    }
    await prefs.setInt('${_kSyncedEventIdsPrefix}chunks', chunk);
  }

  Future<List<String>> _loadEventIds() async {
    final prefs = await SharedPreferences.getInstance();
    final chunkCount = prefs.getInt('${_kSyncedEventIdsPrefix}chunks') ?? 0;
    final allIds = <String>[];
    for (int i = 0; i < chunkCount; i++) {
      allIds.addAll(prefs.getStringList('$_kSyncedEventIdsPrefix$i') ?? []);
    }
    return allIds;
  }

  Future<void> _clearEventIds() async {
    final prefs = await SharedPreferences.getInstance();
    final chunkCount = prefs.getInt('${_kSyncedEventIdsPrefix}chunks') ?? 0;
    for (int i = 0; i < chunkCount; i++) {
      await prefs.remove('$_kSyncedEventIdsPrefix$i');
    }
    await prefs.remove('${_kSyncedEventIdsPrefix}chunks');
    await prefs.remove('${_kSyncedEventIdsPrefix}cal');
  }

  // ─── Calendar API 초기화 ──────────────────────────────────────────────────

  Future<void> _initCalendarApi(GoogleSignInAccount account) async {
    final headers = await account.authHeaders;
    _calendarApi = gcal.CalendarApi(_GoogleAuthClient(headers));
  }
}

/// googleapis 패키지를 위한 인증 HTTP 클라이언트 래퍼
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() => _client.close();
}

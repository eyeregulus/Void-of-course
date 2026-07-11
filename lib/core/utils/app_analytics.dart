import 'package:firebase_analytics/firebase_analytics.dart';

/// Firebase Analytics 이벤트·User Property 이름을 한곳에서 관리합니다.
///
/// 이벤트 이름 규칙 (모바일 업계 표준):
///   - 동사 접두사: tap_ / view_ / toggle_ / select_ / change_ / swipe_
///   - 예: tap_timezone_button, toggle_alarm, select_timezone, change_language
class AppAnalytics {
  AppAnalytics._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // ---------------------------------------------------------------------------
  // User Properties — 유저 속성 (세그먼트/코호트 분석용)
  // ---------------------------------------------------------------------------

  static Future<void> setDarkModeEnabled(bool enabled) {
    return _analytics.setUserProperty(
      name: 'dark_mode_enabled',
      value: enabled.toString(),
    );
  }

  static Future<void> setLanguage(String languageCode) {
    return _analytics.setUserProperty(
      name: 'language',
      value: languageCode,
    );
  }

  static Future<void> setVoidAlarmEnabled(bool enabled) {
    return _analytics.setUserProperty(
      name: 'void_alarm_enabled',
      value: enabled.toString(),
    );
  }

  static Future<void> setRetrogradeCardEnabled(bool enabled) {
    return _analytics.setUserProperty(
      name: 'retrograde_card_enabled',
      value: enabled.toString(),
    );
  }

  static Future<void> setHasHomeWidget(bool hasWidget) {
    return _analytics.setUserProperty(
      name: 'has_home_widget',
      value: hasWidget.toString(),
    );
  }

  // ---------------------------------------------------------------------------
  // Screen Views — 화면 전환 추적
  // ---------------------------------------------------------------------------

  static Future<void> logScreenView(String screenName) {
    return _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenName,
    );
  }

  // ---------------------------------------------------------------------------
  // 탭 네비게이션 — 하단 탭바
  // index: 0=홈, 1=캘린더, 2=프리미엄, 3=설정, 4=정보
  // ---------------------------------------------------------------------------

  static Future<void> logTabTap(int index) {
    const names = [
      'tap_home_tab',
      'tap_calendar_tab',
      'tap_premium_tab',
      'tap_settings_tab',
      'tap_info_tab',
    ];
    if (index < 0 || index >= names.length) return Future.value();
    return _analytics.logEvent(name: names[index]);
  }

  // ---------------------------------------------------------------------------
  // 홈 화면 액션
  // ---------------------------------------------------------------------------

  /// 오늘로 되돌아가기 버튼 탭
  static Future<void> logTapResetToToday() {
    return _analytics.logEvent(name: 'tap_reset_to_today');
  }

  /// 새로고침 버튼 탭 (유저 직접)
  static Future<void> logTapRefresh() {
    return _analytics.logEvent(name: 'tap_refresh');
  }

  /// 타임존 변경 버튼 탭
  static Future<void> logTapTimezoneButton() {
    return _analytics.logEvent(name: 'tap_timezone_button');
  }

  // ---------------------------------------------------------------------------
  // 설정 화면 액션
  // ---------------------------------------------------------------------------

  /// 다크모드 토글
  static Future<void> logToggleDarkMode(bool enabled) {
    return _analytics.logEvent(
      name: 'toggle_dark_mode',
      parameters: {'enabled': enabled.toString()},
    );
  }

  /// 알람 토글
  static Future<void> logToggleAlarm(bool enabled) {
    return _analytics.logEvent(
      name: 'toggle_alarm',
      parameters: {'enabled': enabled.toString()},
    );
  }

  /// 역행 카드 토글
  static Future<void> logToggleRetrogradeCard(bool enabled) {
    return _analytics.logEvent(
      name: 'toggle_retrograde_card',
      parameters: {'enabled': enabled.toString()},
    );
  }

  /// 언어 변경
  static Future<void> logChangeLanguage(String languageCode) {
    return _analytics.logEvent(
      name: 'change_language',
      parameters: {'lang': languageCode},
    );
  }

  /// DST(서머타임) 토글
  static Future<void> logToggleDst(bool enabled) {
    return _analytics.logEvent(
      name: 'toggle_dst',
      parameters: {'enabled': enabled.toString()},
    );
  }

  // ---------------------------------------------------------------------------
  // 타임존 선택
  // ---------------------------------------------------------------------------

  /// 타임존 항목 선택
  static Future<void> logSelectTimezone(String timezoneId) {
    return _analytics.logEvent(
      name: 'select_timezone',
      parameters: {'timezone_id': timezoneId},
    );
  }

  // ---------------------------------------------------------------------------
  // 캘린더 화면 액션
  // ---------------------------------------------------------------------------

  /// 캘린더 월 이동 (스와이프)
  static Future<void> logSwipeCalendarMonth(int year, int month) {
    return _analytics.logEvent(
      name: 'swipe_calendar_month',
      parameters: {'year': year, 'month': month},
    );
  }

  /// 캘린더 날짜 탭
  static Future<void> logTapCalendarDay({
    required int year,
    required int month,
    required int day,
    required bool hasVoc,
  }) {
    return _analytics.logEvent(
      name: 'tap_calendar_day',
      parameters: {
        'year': year,
        'month': month,
        'day': day,
        'has_voc': hasVoc ? 'true' : 'false',
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 개발자 노트
  // ---------------------------------------------------------------------------

  /// 개발자 노트 항목 펼치기
  static Future<void> logExpandDeveloperNote(String noteDate) {
    return _analytics.logEvent(
      name: 'expand_developer_note',
      parameters: {'note_date': noteDate},
    );
  }

  // ---------------------------------------------------------------------------
  // 외부 링크
  // ---------------------------------------------------------------------------

  static Future<void> logExternalLinkTap(String serviceName) {
    return _analytics.logEvent(
      name: 'tap_external_link',
      parameters: {'service_name': serviceName},
    );
  }

  static Future<void> logExternalLinkConfirm(String serviceName) {
    return _analytics.logEvent(
      name: 'confirm_external_link',
      parameters: {'service_name': serviceName},
    );
  }

  static Future<void> logExternalLinkCancel(String serviceName) {
    return _analytics.logEvent(
      name: 'cancel_external_link',
      parameters: {'service_name': serviceName},
    );
  }

  // ---------------------------------------------------------------------------
  // 프리미엄 관련
  // ---------------------------------------------------------------------------

  static Future<void> logPremiumTabClick() {
    return _analytics.logEvent(name: 'tap_premium_tab');
  }

  static Future<void> logPremiumInfoButtonClick() {
    return _analytics.logEvent(name: 'tap_premium_info');
  }

  static Future<void> logPremiumTierSelect(String tier) {
    return _analytics.logEvent(
      name: 'select_tier',
      parameters: {'tier': tier},
    );
  }

  static Future<void> logPremiumPurchase(String tier) {
    return _analytics.logEvent(
      name: 'attempt_purchase',
      parameters: {'tier': tier},
    );
  }

  static Future<void> logPremiumRestore() {
    return _analytics.logEvent(name: 'attempt_restore');
  }

  static Future<void> logPremiumWidgetClick() {
    return _analytics.logEvent(name: 'tap_widget_feature');
  }

  static Future<void> logPremiumCalendarSyncClick() {
    return _analytics.logEvent(name: 'tap_calendar_sync_feature');
  }

  static Future<void> logPremiumCalendarSyncDuration(int months) {
    return _analytics.logEvent(
      name: 'select_calendar_sync_duration',
      parameters: {'months': months},
    );
  }

  // ---------------------------------------------------------------------------
  // 하위 호환 별칭 — 기존 호출 코드와의 호환성 유지
  // ---------------------------------------------------------------------------

  /// [별칭] logTapCalendarDay 와 동일 (calendar_screen.dart 호환)
  static Future<void> logCalendarDaySelected({
    required int year,
    required int month,
    required int day,
    required bool hasVoc,
  }) => logTapCalendarDay(year: year, month: month, day: day, hasVoc: hasVoc);

  /// [별칭] logSwipeCalendarMonth 와 동일 (calendar_screen.dart 호환)
  static Future<void> logCalendarMonthChanged(int year, int month) =>
      logSwipeCalendarMonth(year, month);

  /// [별칭] logExpandDeveloperNote 와 동일 (developer_notes_screen.dart 호환)
  static Future<void> logDeveloperNoteExpanded(String noteDate) =>
      logExpandDeveloperNote(noteDate);
}


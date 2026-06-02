import 'package:firebase_analytics/firebase_analytics.dart';

/// Firebase Analytics 이벤트·User Property 이름을 한곳에서 관리합니다.
class AppAnalytics {
  AppAnalytics._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

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

  static Future<void> setVoidAlarmEnabled(bool enabled) async {
    await _analytics.logEvent(
      name: 'toggle_void_alarm',
      parameters: {'enabled': enabled.toString()},
    );
    await _analytics.setUserProperty(
      name: 'void_alarm_enabled',
      value: enabled.toString(),
    );
  }

  static Future<void> logScreenView(String screenName) {
    return _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenName,
    );
  }

  static Future<void> logCalendarMonthChanged(int year, int month) {
    return _analytics.logEvent(
      name: 'calendar_month_changed',
      parameters: {
        'year': year,
        'month': month,
      },
    );
  }

  static Future<void> logCalendarDaySelected({
    required int year,
    required int month,
    required int day,
    required bool hasVoc,
  }) {
    return _analytics.logEvent(
      name: 'calendar_day_selected',
      parameters: {
        'year': year,
        'month': month,
        'day': day,
        'has_voc': hasVoc ? 'true' : 'false',
      },
    );
  }

  static Future<void> logDeveloperNoteExpanded(String noteDate) {
    return _analytics.logEvent(
      name: 'expand_developer_note',
      parameters: {'note_date': noteDate},
    );
  }

  static Future<void> logExternalLinkTap(String serviceName) {
    return _analytics.logEvent(
      name: 'click_external_link',
      parameters: {'service_name': serviceName},
    );
  }

  static Future<void> logExternalLinkConfirm(String serviceName) {
    return _analytics.logEvent(
      name: 'click_external_link_confirm',
      parameters: {'service_name': serviceName},
    );
  }

  static Future<void> logExternalLinkCancel(String serviceName) {
    return _analytics.logEvent(
      name: 'click_external_link_cancel',
      parameters: {'service_name': serviceName},
    );
  }

  // 프리미엄 관련 로깅
  static Future<void> logPremiumTabClick() {
    return _analytics.logEvent(name: 'click_premium_tab');
  }

  static Future<void> logPremiumInfoButtonClick() {
    return _analytics.logEvent(name: 'click_premium_info');
  }

  static Future<void> logPremiumTierSelect(String tier) {
    return _analytics.logEvent(
      name: 'select_premium_tier',
      parameters: {'tier': tier},
    );
  }

  static Future<void> logPremiumPurchase(String tier) {
    return _analytics.logEvent(
      name: 'purchase_premium_attempt',
      parameters: {'tier': tier},
    );
  }

  static Future<void> logPremiumRestore() {
    return _analytics.logEvent(name: 'restore_premium_attempt');
  }

  static Future<void> logPremiumWidgetClick() {
    return _analytics.logEvent(name: 'click_premium_widget');
  }

  static Future<void> logPremiumCalendarSyncClick() {
    return _analytics.logEvent(name: 'click_premium_calendar_sync');
  }

  static Future<void> logPremiumCalendarSyncDuration(int months) {
    return _analytics.logEvent(
      name: 'select_calendar_sync_duration',
      parameters: {'months': months},
    );
  }
}

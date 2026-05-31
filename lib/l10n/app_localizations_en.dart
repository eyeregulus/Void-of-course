// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get home => 'Home';

  @override
  String get settings => 'Settings';

  @override
  String get info => 'Info';

  @override
  String get language => 'Language';

  @override
  String get korean => 'Korean';

  @override
  String get english => 'English';

  @override
  String get community => 'Open Kakaotalk';

  @override
  String get blog => 'Blog';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get voidAlarmTitle => 'Void Alarm';

  @override
  String get voidAlarmSubtitle => 'Alerts from 6 hours before void.';

  @override
  String get voidAlarmEnabledMessage =>
      'Void alarm has been activated.\nThe alarm will sound 6 hours before.';

  @override
  String get voidAlarmDisabledMessage => 'Void alarm has been deactivated.';

  @override
  String get voidAlarmTimeTitle => 'Alarm Time';

  @override
  String voidAlarmTimeUnit(int count) {
    return '$count hours before';
  }

  @override
  String voidAlarmTimeSetMessage(int count) {
    return 'Void alarm time set to $count hours before.';
  }

  @override
  String get mailAppError =>
      'Cannot open mail app. Please check your default mail app settings.';

  @override
  String get contactEmail => 'Arion.Ayin@gmail.com';

  @override
  String get infoScreenTitle => 'Info';

  @override
  String get headerSubtitle => 'Void of Course Calculator';

  @override
  String get whoAreWeTitle => 'Who are we?';

  @override
  String get whoAreWeSubtitle =>
      '• Arion Ayin\'s Mission : Fathoming the world with the eyes of a lion';

  @override
  String get whoIsItUsefulForTitle => 'Who is it useful for?';

  @override
  String get whoIsItUsefulForSubtitle =>
      '• Those who need simple date selection\n• Those who need Void of Course calculations\n• Those who need an indicator for action';

  @override
  String get whyDidWeMakeThisAppTitle => 'Why did we make this?';

  @override
  String get whyDidWeMakeThisAppSubtitle =>
      '• With the hope that anyone can easily access this information.';

  @override
  String get copyrightText =>
      '© Arion Ayin. All rights reserved.\nWith respect to Alexander Kolesnikov\'s iLuna';

  @override
  String get newMoon => 'New Moon';

  @override
  String get crescentMoon => 'Crescent Moon';

  @override
  String get firstQuarter => 'First Quarter';

  @override
  String get gibbousMoon => 'Gibbous Moon';

  @override
  String get fullMoon => 'Full Moon';

  @override
  String get disseminatingMoon => 'Disseminating Moon';

  @override
  String get lastQuarter => 'Last Quarter';

  @override
  String get balsamicMoon => 'Balsamic Moon';

  @override
  String get sunMoonPositionError => 'Sun or Moon position not available.';

  @override
  String get initializationError => 'Initialization Error';

  @override
  String get calculationError => 'Error during calculation';

  @override
  String vocStartsInMinutes(int minutesRemaining) {
    final intl.NumberFormat minutesRemainingNumberFormat = intl
        .NumberFormat.compact(locale: localeName);
    final String minutesRemainingString = minutesRemainingNumberFormat.format(
      minutesRemaining,
    );

    return '$minutesRemainingString minutes until Void of Course begins.';
  }

  @override
  String vocStartsInHours(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    return 'Void of Course begins in $countString hours.';
  }

  @override
  String get vocStartsSoon => 'Void of Course begins soon.';

  @override
  String get vocNotificationTitle => 'Void of Course Notification';

  @override
  String get vocOngoingTitle => 'Void of Course in Progress';

  @override
  String get vocOngoingBody => 'Currently in Void of Course period.';

  @override
  String get vocEndedTitle => 'Void of Course Ended';

  @override
  String get vocEndedBody => 'The Void of Course period has ended.';

  @override
  String get nextMoonPhaseTimePassed => 'Next Moon Phase time has passed.';

  @override
  String get moonSignEndTimePassed => 'Moon Sign end time has passed.';

  @override
  String get vocEndTimePassed => 'VOC end time has passed.';

  @override
  String timeToRefreshData(Object refreshReason) {
    return 'Time to refresh data: $refreshReason. Refreshing...';
  }

  @override
  String get voidAlarmExactAlarmDeniedMessage =>
      'Please allow the *Alarms & Reminders* permission in the app settings.';

  @override
  String get noUpcomingVocFound =>
      'No upcoming Void of Course period found or it has passed. No alarm scheduled.';

  @override
  String get errorSchedulingAlarm => 'Error scheduling alarm';

  @override
  String get errorShowingImmediateAlarm => 'Error showing immediate alarm';

  @override
  String get calculating => 'Calculating...';

  @override
  String get vocStartedTitle => 'Void of Course Started';

  @override
  String get vocStartedBody => 'The Void of Course period has now begun.';

  @override
  String vocRemainingTimeHourMinute(int hours, int minutes) {
    return 'Time remaining: ${hours}h ${minutes}m';
  }

  @override
  String vocRemainingTimeMinute(int minutes) {
    return 'Time remaining: $minutes minutes';
  }

  @override
  String preVocNotificationBodyHourMinute(int hours, int minutes) {
    return '${hours}h ${minutes}m until Void of Course begins.';
  }

  @override
  String preVocNotificationBodyMinute(int minutes) {
    return '$minutes minutes until Void of Course begins.';
  }

  @override
  String get notAvailable => 'N/A';

  @override
  String get vocStatusIsVoc => 'There is a void Now';

  @override
  String get vocStatusHasVocToday => 'Todays schedule has a void';

  @override
  String get vocStatusIsNotVoc => 'It is not a void';

  @override
  String get voidOfCourse => 'Void of Course';

  @override
  String vocStartTime(String time) {
    return 'Starts: $time';
  }

  @override
  String vocEndTime(String time) {
    return 'Ends: $time';
  }

  @override
  String moonInSign(String sign) {
    return 'Moon in $sign';
  }

  @override
  String nextSign(String time) {
    return 'Next Sign: $time';
  }

  @override
  String get moonPhaseTitle => 'Moon Phase';

  @override
  String nextPhase(String time) {
    return 'Next Phase: $time';
  }

  @override
  String get noPostsFound => 'No posts found.';

  @override
  String get btnReadMore => 'Read More';

  @override
  String get btnReview => 'Leave a Review';

  @override
  String get btnContact => 'Contact Developer';

  @override
  String get btnSupport => 'Buy me a coffee';

  @override
  String get msgAppNotFound => 'Cannot find an app to open this.';

  @override
  String get msgEmailCopied =>
      'Email app not found. Address copied to clipboard.';

  @override
  String get ok => 'OK';

  @override
  String get resetVoidAlarmForTimezoneChange =>
      'The timezone has changed. Please set the Void of Course alarm again.';

  @override
  String get calendar => 'Calendar';

  @override
  String get voidCalendar => 'Void Calendar';

  @override
  String get noVocFound => 'No Void of Course period for this day.';

  @override
  String get invalidVocData => 'Invalid VOC data';

  @override
  String get premium => 'Premium';

  @override
  String goToServiceTitle(String serviceName) {
    return 'Go to $serviceName';
  }

  @override
  String goToServiceContent(String serviceName) {
    return 'Do you want to go to $serviceName?';
  }

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get googleCalendar => 'Google Calendar';

  @override
  String get linked => 'Linked';

  @override
  String get linkGoogleCalendar => 'Link with Google Account';

  @override
  String get googleCalendarVocSync => 'Google Calendar VOC Sync';

  @override
  String get notLinked => 'Not linked';

  @override
  String get syncDuration => 'Sync Range';

  @override
  String get syncing => 'Syncing...';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get unlink => 'Unlink';

  @override
  String get plusPassFeature => 'Plus Pass Exclusive Feature';

  @override
  String get premiumCalendarSyncDesc =>
      'Calendar sync will be enabled when you purchase Premium.';

  @override
  String get explorePremium => 'Explore Premium';

  @override
  String get calendarPermissionRequired =>
      'Calendar access permission is required.';

  @override
  String get loginFailedRetry => 'Failed to log in. Please try again.';

  @override
  String get googleCalendarUnlinked => 'Google Calendar has been unlinked.';

  @override
  String vocEventsAdded(int count) {
    return '$count Void of Course events added to Google Calendar.';
  }

  @override
  String get syncFailedRetry => 'Sync failed. Please try again.';

  @override
  String get unlinkGoogleCalendarTitle => 'Unlink Google Calendar';

  @override
  String get unlinkGoogleCalendarContent =>
      'Unlinking will remove the \"Void of Course 🌙\" calendar from Google Calendar.\nDo you want to continue?';

  @override
  String get cancel => 'Cancel';
}

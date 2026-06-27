import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get info;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @korean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get korean;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Open Kakaotalk'**
  String get community;

  /// No description provided for @youtube.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get youtube;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @voidAlarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Void Alarm'**
  String get voidAlarmTitle;

  /// No description provided for @voidAlarmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts from 48 hours before void.'**
  String get voidAlarmSubtitle;

  /// No description provided for @voidAlarmEnabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Void alarm has been activated.\nThe alarm will sound 48 hours before.'**
  String get voidAlarmEnabledMessage;

  /// No description provided for @voidAlarmDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Void alarm has been deactivated.'**
  String get voidAlarmDisabledMessage;

  /// No description provided for @voidAlarmTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Alarm Time'**
  String get voidAlarmTimeTitle;

  /// Unit for void alarm time setting
  ///
  /// In en, this message translates to:
  /// **'{count} hours before'**
  String voidAlarmTimeUnit(int count);

  /// Message shown when void alarm time is set
  ///
  /// In en, this message translates to:
  /// **'Void alarm time set to {count} hours before.'**
  String voidAlarmTimeSetMessage(int count);

  /// No description provided for @mailAppError.
  ///
  /// In en, this message translates to:
  /// **'Cannot open mail app. Please check your default mail app settings.'**
  String get mailAppError;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Arion.Ayin@gmail.com'**
  String get contactEmail;

  /// No description provided for @infoScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer Note'**
  String get infoScreenTitle;

  /// No description provided for @headerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Void of course Calculator'**
  String get headerSubtitle;

  /// No description provided for @whoAreWeTitle.
  ///
  /// In en, this message translates to:
  /// **'Who are we?'**
  String get whoAreWeTitle;

  /// No description provided for @whoAreWeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'• Arion Ayin\'s Mission : Fathoming the world with the eyes of a lion'**
  String get whoAreWeSubtitle;

  /// No description provided for @whoIsItUsefulForTitle.
  ///
  /// In en, this message translates to:
  /// **'Who is it useful for?'**
  String get whoIsItUsefulForTitle;

  /// No description provided for @whoIsItUsefulForSubtitle.
  ///
  /// In en, this message translates to:
  /// **'• Those who need simple date selection\n• Those who need Void of course calculations\n• Those who need an indicator for action'**
  String get whoIsItUsefulForSubtitle;

  /// No description provided for @whyDidWeMakeThisAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Why did we make this?'**
  String get whyDidWeMakeThisAppTitle;

  /// No description provided for @whyDidWeMakeThisAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'• With the hope that anyone can easily access this information.'**
  String get whyDidWeMakeThisAppSubtitle;

  /// No description provided for @copyrightText.
  ///
  /// In en, this message translates to:
  /// **'© Eye of regulus. All rights reserved.\nWith respect to Alexander Kolesnikov\'s iLuna'**
  String get copyrightText;

  /// No description provided for @newMoon.
  ///
  /// In en, this message translates to:
  /// **'New Moon'**
  String get newMoon;

  /// No description provided for @crescentMoon.
  ///
  /// In en, this message translates to:
  /// **'Crescent Moon'**
  String get crescentMoon;

  /// No description provided for @firstQuarter.
  ///
  /// In en, this message translates to:
  /// **'First Quarter'**
  String get firstQuarter;

  /// No description provided for @gibbousMoon.
  ///
  /// In en, this message translates to:
  /// **'Gibbous Moon'**
  String get gibbousMoon;

  /// No description provided for @fullMoon.
  ///
  /// In en, this message translates to:
  /// **'Full Moon'**
  String get fullMoon;

  /// No description provided for @disseminatingMoon.
  ///
  /// In en, this message translates to:
  /// **'Disseminating Moon'**
  String get disseminatingMoon;

  /// No description provided for @lastQuarter.
  ///
  /// In en, this message translates to:
  /// **'Last Quarter'**
  String get lastQuarter;

  /// No description provided for @balsamicMoon.
  ///
  /// In en, this message translates to:
  /// **'Balsamic Moon'**
  String get balsamicMoon;

  /// No description provided for @sunMoonPositionError.
  ///
  /// In en, this message translates to:
  /// **'Sun or Moon position not available.'**
  String get sunMoonPositionError;

  /// No description provided for @initializationError.
  ///
  /// In en, this message translates to:
  /// **'Initialization Error'**
  String get initializationError;

  /// No description provided for @calculationError.
  ///
  /// In en, this message translates to:
  /// **'Error during calculation'**
  String get calculationError;

  /// No description provided for @vocStartsInMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutesRemaining} minutes until Void of course begins.'**
  String vocStartsInMinutes(int minutesRemaining);

  /// No description provided for @vocStartsInHours.
  ///
  /// In en, this message translates to:
  /// **'Void of course begins in {count} hours.'**
  String vocStartsInHours(int count);

  /// No description provided for @vocStartsSoon.
  ///
  /// In en, this message translates to:
  /// **'Void of course begins soon.'**
  String get vocStartsSoon;

  /// No description provided for @vocNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Void of course Notification'**
  String get vocNotificationTitle;

  /// No description provided for @vocOngoingTitle.
  ///
  /// In en, this message translates to:
  /// **'Void of course in Progress'**
  String get vocOngoingTitle;

  /// No description provided for @vocOngoingBody.
  ///
  /// In en, this message translates to:
  /// **'Currently in Void of course period.'**
  String get vocOngoingBody;

  /// No description provided for @vocEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'Void of course Ended'**
  String get vocEndedTitle;

  /// No description provided for @vocEndedBody.
  ///
  /// In en, this message translates to:
  /// **'The Void of course period has ended.'**
  String get vocEndedBody;

  /// No description provided for @nextMoonPhaseTimePassed.
  ///
  /// In en, this message translates to:
  /// **'Next Moon Phase time has passed.'**
  String get nextMoonPhaseTimePassed;

  /// No description provided for @moonSignEndTimePassed.
  ///
  /// In en, this message translates to:
  /// **'Moon Sign end time has passed.'**
  String get moonSignEndTimePassed;

  /// No description provided for @vocEndTimePassed.
  ///
  /// In en, this message translates to:
  /// **'VOC end time has passed.'**
  String get vocEndTimePassed;

  /// No description provided for @timeToRefreshData.
  ///
  /// In en, this message translates to:
  /// **'Time to refresh data: {refreshReason}. Refreshing...'**
  String timeToRefreshData(Object refreshReason);

  /// No description provided for @voidAlarmExactAlarmDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Please allow the *Alarms & Reminders* permission in the app settings.'**
  String get voidAlarmExactAlarmDeniedMessage;

  /// No description provided for @noUpcomingVocFound.
  ///
  /// In en, this message translates to:
  /// **'No upcoming Void of course period found or it has passed. No alarm scheduled.'**
  String get noUpcomingVocFound;

  /// No description provided for @errorSchedulingAlarm.
  ///
  /// In en, this message translates to:
  /// **'Error scheduling alarm'**
  String get errorSchedulingAlarm;

  /// No description provided for @errorShowingImmediateAlarm.
  ///
  /// In en, this message translates to:
  /// **'Error showing immediate alarm'**
  String get errorShowingImmediateAlarm;

  /// No description provided for @calculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get calculating;

  /// No description provided for @vocStartedTitle.
  ///
  /// In en, this message translates to:
  /// **'Void of course Started'**
  String get vocStartedTitle;

  /// No description provided for @vocStartedBody.
  ///
  /// In en, this message translates to:
  /// **'The Void of course period has now begun.'**
  String get vocStartedBody;

  /// No description provided for @vocRemainingTimeHourMinute.
  ///
  /// In en, this message translates to:
  /// **'Time remaining: {hours}h {minutes}m'**
  String vocRemainingTimeHourMinute(int hours, int minutes);

  /// No description provided for @vocRemainingTimeMinute.
  ///
  /// In en, this message translates to:
  /// **'Time remaining: {minutes} minutes'**
  String vocRemainingTimeMinute(int minutes);

  /// No description provided for @preVocNotificationBodyHourMinute.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m until Void of course begins.'**
  String preVocNotificationBodyHourMinute(int hours, int minutes);

  /// No description provided for @preVocNotificationBodyMinute.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes until Void of course begins.'**
  String preVocNotificationBodyMinute(int minutes);

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @vocStatusIsVoc.
  ///
  /// In en, this message translates to:
  /// **'There is a void Now'**
  String get vocStatusIsVoc;

  /// No description provided for @vocStatusHasVocToday.
  ///
  /// In en, this message translates to:
  /// **'Todays schedule has a void'**
  String get vocStatusHasVocToday;

  /// No description provided for @vocStatusIsNotVoc.
  ///
  /// In en, this message translates to:
  /// **'It is not a void'**
  String get vocStatusIsNotVoc;

  /// No description provided for @voidOfCourse.
  ///
  /// In en, this message translates to:
  /// **'Void of course'**
  String get voidOfCourse;

  /// No description provided for @vocStartTime.
  ///
  /// In en, this message translates to:
  /// **'Starts: {time}'**
  String vocStartTime(String time);

  /// No description provided for @vocEndTime.
  ///
  /// In en, this message translates to:
  /// **'Ends: {time}'**
  String vocEndTime(String time);

  /// No description provided for @moonInSign.
  ///
  /// In en, this message translates to:
  /// **'Moon in {sign}'**
  String moonInSign(String sign);

  /// No description provided for @nextSign.
  ///
  /// In en, this message translates to:
  /// **'Next Sign: {time}'**
  String nextSign(String time);

  /// No description provided for @moonPhaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Moon Phase'**
  String get moonPhaseTitle;

  /// No description provided for @nextPhase.
  ///
  /// In en, this message translates to:
  /// **'Next Phase: {time}'**
  String nextPhase(String time);

  /// No description provided for @noPostsFound.
  ///
  /// In en, this message translates to:
  /// **'No posts found.'**
  String get noPostsFound;

  /// No description provided for @btnReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read More'**
  String get btnReadMore;

  /// No description provided for @btnReview.
  ///
  /// In en, this message translates to:
  /// **'Leave a Review'**
  String get btnReview;

  /// No description provided for @btnReviewPlayStore.
  ///
  /// In en, this message translates to:
  /// **'Leave a Review on Google Play'**
  String get btnReviewPlayStore;

  /// No description provided for @btnReviewAppStore.
  ///
  /// In en, this message translates to:
  /// **'Leave a Review on App Store'**
  String get btnReviewAppStore;

  /// No description provided for @btnReviewEventForm.
  ///
  /// In en, this message translates to:
  /// **'Review Event Google Form'**
  String get btnReviewEventForm;

  /// No description provided for @btnContact.
  ///
  /// In en, this message translates to:
  /// **'Contact Developer'**
  String get btnContact;

  /// No description provided for @btnSupport.
  ///
  /// In en, this message translates to:
  /// **'Buy me a coffee'**
  String get btnSupport;

  /// No description provided for @msgAppNotFound.
  ///
  /// In en, this message translates to:
  /// **'Cannot find an app to open this.'**
  String get msgAppNotFound;

  /// No description provided for @msgEmailCopied.
  ///
  /// In en, this message translates to:
  /// **'Email app not found. Address copied to clipboard.'**
  String get msgEmailCopied;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @resetVoidAlarmForTimezoneChange.
  ///
  /// In en, this message translates to:
  /// **'The timezone has changed. Please set the Void of course alarm again.'**
  String get resetVoidAlarmForTimezoneChange;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @voidCalendar.
  ///
  /// In en, this message translates to:
  /// **'Void Calendar'**
  String get voidCalendar;

  /// No description provided for @noVocFound.
  ///
  /// In en, this message translates to:
  /// **'No Void of course period for this day.'**
  String get noVocFound;

  /// No description provided for @invalidVocData.
  ///
  /// In en, this message translates to:
  /// **'Invalid VOC data'**
  String get invalidVocData;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @goToServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Go to {serviceName}'**
  String goToServiceTitle(String serviceName);

  /// No description provided for @goToServiceContent.
  ///
  /// In en, this message translates to:
  /// **'Do you want to go to {serviceName}?'**
  String goToServiceContent(String serviceName);

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @googleCalendar.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar'**
  String get googleCalendar;

  /// No description provided for @linked.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get linked;

  /// No description provided for @linkGoogleCalendar.
  ///
  /// In en, this message translates to:
  /// **'Link with Google Account'**
  String get linkGoogleCalendar;

  /// No description provided for @googleCalendarVocSync.
  ///
  /// In en, this message translates to:
  /// **'Void Google Calendar Sync'**
  String get googleCalendarVocSync;

  /// No description provided for @notLinked.
  ///
  /// In en, this message translates to:
  /// **'Not linked'**
  String get notLinked;

  /// No description provided for @syncDuration.
  ///
  /// In en, this message translates to:
  /// **'Sync Range'**
  String get syncDuration;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @unlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get unlink;

  /// No description provided for @plusPassFeature.
  ///
  /// In en, this message translates to:
  /// **'Plus Pass Exclusive Feature'**
  String get plusPassFeature;

  /// No description provided for @premiumCalendarSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Calendar sync will be enabled when you purchase Premium.'**
  String get premiumCalendarSyncDesc;

  /// No description provided for @explorePremium.
  ///
  /// In en, this message translates to:
  /// **'Explore Premium'**
  String get explorePremium;

  /// No description provided for @calendarPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Calendar access permission is required.'**
  String get calendarPermissionRequired;

  /// No description provided for @loginFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Failed to log in. Please try again.'**
  String get loginFailedRetry;

  /// No description provided for @googleCalendarUnlinked.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar has been unlinked.'**
  String get googleCalendarUnlinked;

  /// No description provided for @vocEventsAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} Void of course events added to Google Calendar.'**
  String vocEventsAdded(int count);

  /// No description provided for @syncFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Please try again.'**
  String get syncFailedRetry;

  /// No description provided for @unlinkGoogleCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlink Google Calendar'**
  String get unlinkGoogleCalendarTitle;

  /// No description provided for @unlinkGoogleCalendarContent.
  ///
  /// In en, this message translates to:
  /// **'Unlinking will remove the \"Void of course 🌙\" calendar from Google Calendar.\nDo you want to continue?'**
  String get unlinkGoogleCalendarContent;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @addHomeWidget.
  ///
  /// In en, this message translates to:
  /// **'Add Widget'**
  String get addHomeWidget;

  /// No description provided for @addHomeWidgetDesc.
  ///
  /// In en, this message translates to:
  /// **'Add the Void widget to your home screen.'**
  String get addHomeWidgetDesc;

  /// No description provided for @widgetAutoPinNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Auto-pinning widgets is not supported on this device. Please add it manually by long-pressing your home screen.'**
  String get widgetAutoPinNotSupported;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Required'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'A critical update is required to continue using the app. Please update to the latest version.'**
  String get updateRequiredBody;

  /// No description provided for @updateRecommendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateRecommendedTitle;

  /// No description provided for @updateRecommendedBody.
  ///
  /// In en, this message translates to:
  /// **'A new version with features and improvements is available. Would you like to update?'**
  String get updateRecommendedBody;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateNow;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

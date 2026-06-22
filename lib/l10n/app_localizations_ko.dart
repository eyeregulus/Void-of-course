// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get home => '홈';

  @override
  String get settings => '설정';

  @override
  String get info => '노트';

  @override
  String get language => '언어';

  @override
  String get korean => '한국어';

  @override
  String get english => '영어';

  @override
  String get community => '오픈카톡';

  @override
  String get youtube => '유튜브';

  @override
  String get darkMode => '다크 모드';

  @override
  String get voidAlarmTitle => '보이드 알람';

  @override
  String get voidAlarmSubtitle => '보이드 48시간 전부터 알림합니다.';

  @override
  String get voidAlarmEnabledMessage =>
      '보이드 알람이 활성화되었습니다.\n48시간 이전부터 알람이 울립니다.';

  @override
  String get voidAlarmDisabledMessage => '보이드 알람이 비활성화되었습니다.';

  @override
  String get voidAlarmTimeTitle => '알림 시간';

  @override
  String voidAlarmTimeUnit(int count) {
    return '$count시간 전';
  }

  @override
  String voidAlarmTimeSetMessage(int count) {
    return '보이드 알림 시간이 $count시간 전으로 설정되었습니다.';
  }

  @override
  String get mailAppError => '메일 앱을 열 수 없습니다. 기본 메일 앱 설정을 확인해주세요.';

  @override
  String get contactEmail => 'eyeregulus@gmail.com';

  @override
  String get infoScreenTitle => '개발자 노트';

  @override
  String get headerSubtitle => '보이드 오브 코스 계산기';

  @override
  String get whoAreWeTitle => '우리는 누구인가요?';

  @override
  String get whoAreWeSubtitle => '• 아리온아인의 사명 : |||사자의 눈으로 세상을 헤아립니다.';

  @override
  String get whoIsItUsefulForTitle => '누구에게 유용한가요?';

  @override
  String get whoIsItUsefulForSubtitle =>
      '• 간단한 택일이 필요하신 분들|||• 보이드 오브 코스 계산이 필요한 분들|||• 행동의 지표성이 필요한 분들';

  @override
  String get whyDidWeMakeThisAppTitle => '왜 이 앱을 만들었나요?';

  @override
  String get whyDidWeMakeThisAppSubtitle =>
      '• 달의 에너지가 닿지 않는 시간을 피하고,\n유저들이 지혜로운 결정을 할 수 있도록\n돕기 위해';

  @override
  String get copyrightText =>
      '© Eye of regulus. All rights reserved.\nWith respect to Alexander Kolesnikov\'s iLuna';

  @override
  String get newMoon => '신월';

  @override
  String get crescentMoon => '초승달';

  @override
  String get firstQuarter => '상현달';

  @override
  String get gibbousMoon => '기울어진 달';

  @override
  String get fullMoon => '보름달';

  @override
  String get disseminatingMoon => '기울어가는 달';

  @override
  String get lastQuarter => '하현달';

  @override
  String get balsamicMoon => '그믐달';

  @override
  String get sunMoonPositionError => '태양 또는 달의 위치를 사용할 수 없습니다.';

  @override
  String get initializationError => '초기화 오류';

  @override
  String get calculationError => '계산 중 오류 발생';

  @override
  String vocStartsInMinutes(int minutesRemaining) {
    final intl.NumberFormat minutesRemainingNumberFormat = intl
        .NumberFormat.compact(locale: localeName);
    final String minutesRemainingString = minutesRemainingNumberFormat.format(
      minutesRemaining,
    );

    return '$minutesRemainingString분 후에 보이드가 시작됩니다.';
  }

  @override
  String vocStartsInHours(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    return '$countString시간 후에 보이드가 시작됩니다.';
  }

  @override
  String get vocStartsSoon => '보이드가 곧 시작됩니다.';

  @override
  String get vocNotificationTitle => 'Void of course 알림';

  @override
  String get vocOngoingTitle => '보이드 중';

  @override
  String get vocOngoingBody => '지금은 보이드 시간입니다.';

  @override
  String get vocEndedTitle => '보이드 종료';

  @override
  String get vocEndedBody => '보이드가 종료되었습니다.';

  @override
  String get nextMoonPhaseTimePassed => '다음 달 위상 시간이 지났습니다.';

  @override
  String get moonSignEndTimePassed => '다음 달 싸인으로의 진입 시간이 지났습니다.';

  @override
  String get vocEndTimePassed => '보이드 기간이 종료되었습니다.';

  @override
  String timeToRefreshData(Object refreshReason) {
    return '데이터를 새로고침할 시간입니다: $refreshReason. 새로고침 중...';
  }

  @override
  String get voidAlarmExactAlarmDeniedMessage =>
      '앱 설정에서 \'알람 및 리마인더\' 권한을 허용해주세요.';

  @override
  String get noUpcomingVocFound =>
      '선택된 날짜에 예정된 보이드 기간이 없거나 이미 지났습니다. 알람이 예약되지 않았습니다.';

  @override
  String get errorSchedulingAlarm => '알람 예약 중 오류 발생';

  @override
  String get errorShowingImmediateAlarm => '즉시 알람 표시 중 오류 발생';

  @override
  String get calculating => '계산 중...';

  @override
  String get vocStartedTitle => '보이드 시작';

  @override
  String get vocStartedBody => '지금은 보이드 시간입니다.';

  @override
  String vocRemainingTimeHourMinute(int hours, int minutes) {
    return '남은 시간: $hours시간 $minutes분';
  }

  @override
  String vocRemainingTimeMinute(int minutes) {
    return '남은 시간: $minutes분';
  }

  @override
  String preVocNotificationBodyHourMinute(int hours, int minutes) {
    return '보이드 시작까지 $hours시간 $minutes분 남았습니다.';
  }

  @override
  String preVocNotificationBodyMinute(int minutes) {
    return '보이드 시작까지 $minutes분 남았습니다.';
  }

  @override
  String get notAvailable => '해당 없음';

  @override
  String get vocStatusIsVoc => '보이드 입니다';

  @override
  String get vocStatusHasVocToday => '금일 보이드가 있습니다.';

  @override
  String get vocStatusIsNotVoc => '보이드가 아닙니다';

  @override
  String get voidOfCourse => '보이드 오브 코스';

  @override
  String vocStartTime(String time) {
    return '시작 : $time';
  }

  @override
  String vocEndTime(String time) {
    return '종료 : $time';
  }

  @override
  String moonInSign(String sign) {
    return '달, $sign에 위치';
  }

  @override
  String nextSign(String time) {
    return '다음 싸인 : $time';
  }

  @override
  String get moonPhaseTitle => '달의 위상';

  @override
  String nextPhase(String time) {
    return '다음 상태 : $time';
  }

  @override
  String get noPostsFound => '등록된 게시글이 없습니다.';

  @override
  String get btnReadMore => '자세히 보기';

  @override
  String get btnReview => '리뷰 남기러 가기';

  @override
  String get btnReviewPlayStore => '구글 플레이 스토어 리뷰 남기기';

  @override
  String get btnReviewAppStore => '앱스토어 리뷰 남기기';

  @override
  String get btnReviewEventForm => '리뷰 이벤트 구글폼';

  @override
  String get btnContact => '개발자에게 한마디';

  @override
  String get btnSupport => '개발자에게 후원하기';

  @override
  String get msgAppNotFound => '실행 가능한 앱을 찾을 수 없습니다.';

  @override
  String get msgEmailCopied => '메일 앱을 찾을 수 없어 이메일 주소가 복사되었습니다.';

  @override
  String get ok => '확인';

  @override
  String get resetVoidAlarmForTimezoneChange =>
      '타임존이 변경되었습니다. 보이드 알람을 다시 설정하여 주세요.';

  @override
  String get calendar => '캘린더';

  @override
  String get voidCalendar => '보이드 캘린더';

  @override
  String get noVocFound => '이 날에는 보이드 기간이 없습니다.';

  @override
  String get invalidVocData => '잘못된 VOC 데이터';

  @override
  String get premium => '프리미엄';

  @override
  String goToServiceTitle(String serviceName) {
    return '$serviceName로 이동';
  }

  @override
  String goToServiceContent(String serviceName) {
    return '$serviceName(으)로 이동하시겠습니까?';
  }

  @override
  String get yes => '예';

  @override
  String get no => '아니오';

  @override
  String get googleCalendar => '구글 캘린더';

  @override
  String get linked => '연동됨';

  @override
  String get linkGoogleCalendar => '구글 계정으로 연동하기';

  @override
  String get googleCalendarVocSync => '보이드 구글 캘린더 연동';

  @override
  String get notLinked => '미연동';

  @override
  String get syncDuration => '동기화 기간';

  @override
  String get syncing => '동기화 중...';

  @override
  String get syncNow => '지금 동기화';

  @override
  String get unlink => '해제';

  @override
  String get plusPassFeature => '플러스 패스 전용 기능';

  @override
  String get premiumCalendarSyncDesc => '프리미엄을 구매시 캘린더 동기화가 활성화됩니다.';

  @override
  String get explorePremium => '프리미엄 혜택 알아보기';

  @override
  String get calendarPermissionRequired => '캘린더 접근 권한이 필요합니다.';

  @override
  String get loginFailedRetry => '로그인에 실패했습니다. 다시 시도해 주세요.';

  @override
  String get googleCalendarUnlinked => '구글 캘린더 연동이 해제되었습니다.';

  @override
  String vocEventsAdded(int count) {
    return '$count개의 Void of course 이벤트가 구글 캘린더에 추가되었습니다.';
  }

  @override
  String get syncFailedRetry => '동기화에 실패했습니다. 다시 시도해 주세요.';

  @override
  String get unlinkGoogleCalendarTitle => '구글 캘린더 연동 해제';

  @override
  String get unlinkGoogleCalendarContent =>
      '연동을 해제하면 구글 캘린더에서 \"Void of course 🌙\" 캘린더가 삭제됩니다.\n계속하시겠습니까?';

  @override
  String get cancel => '취소';

  @override
  String get addHomeWidget => '보이드 위젯';

  @override
  String get addHomeWidgetDesc => '바탕화면에\n보이드 위젯을 추가';

  @override
  String get widgetAutoPinNotSupported =>
      '이 기기에서는 위젯 자동 추가를 지원하지 않습니다. 홈 화면을 길게 눌러 직접 추가해주세요.';

  @override
  String get updateRequiredTitle => '업데이트 안내';

  @override
  String get updateRequiredBody =>
      '앱을 안정적으로 이용하기 위해 필수 업데이트가 필요합니다. 최신 버전으로 업데이트 해 주세요.';

  @override
  String get updateRecommendedTitle => '업데이트 권장';

  @override
  String get updateRecommendedBody =>
      '새로운 기능과 성능 개선이 포함된 새로운 버전이 출시되었습니다. 업데이트 하시겠습니까?';

  @override
  String get updateNow => '업데이트';

  @override
  String get updateLater => '나중에';
}

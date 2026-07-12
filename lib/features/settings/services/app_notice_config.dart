// 공지 팝업 노출 정책을 정의하는 열거형입니다.
enum NoticeShowPolicy {
  /// [실제 서비스 배포용] 공지 ID(noticeId)가 바뀌었을 때 사용자당 딱 1회만 노출합니다.
  /// 사용자가 한 번 닫기 버튼을 누르면 noticeId를 변경하기 전까지 절대 다시 뜨지 않습니다.
  oncePerId,

  /// [개발 및 빌드 테스트용] 앱을 실행하거나 빌드할 때마다 매번 공지를 노출합니다.
  /// 공지 팝업의 디자인, 오타, 다국어 전환 등을 반복해서 테스트하고 싶을 때 이 값을 사용하세요.
  everyLaunch,
}

/// 앱 실행 시 노출되는 공지 팝업 설정입니다.
/// 새로운 공지사항이 있을 때 아래 필드들을 수정하여 바로 적용할 수 있습니다.
class AppNoticeConfig {
  /// 공지 팝업 활성화 여부 (true: 노출, false: 미노출)
  static const bool enabled = false;

  /// 한국어/영어 공지내용을 사용자 기기 언어와 무관하게 한 번에 모두 노출할지 여부
  /// true일 경우 기기 언어 설정에 관계없이 한/영 공지가 동시에 노출됩니다.
  static const bool showBoth = true;

  /// 공지 식별 ID (이 값을 변경하면 'oncePerId' 정책일 때 사용자들에게 다시 공지가 팝업됩니다)
  /// 예: 새 공지를 띄우고 싶을 때 'notice_v[번호]' 형태로 값을 변경하십시오.
  /// 히스토리:
  /// - 'ios_launch_event_v3' (iOS 출시 기념 이벤트 공지 - 만료)
  static const String noticeId = 'ios_launch_event_v3';

  /// 노출 정책 (한 번만 보여줄지, 켤 때마다 보여줄지 설정)
  /// - NoticeShowPolicy.oncePerId: 실제 서비스용
  /// - NoticeShowPolicy.everyLaunch: 개발/테스트용
  static const NoticeShowPolicy showPolicy = NoticeShowPolicy.oncePerId;

  /// 공지 노출 만료일 (이 시각이 지나면 공지가 자동으로 뜨지 않습니다)
  /// 형식: 'YYYY-MM-DD HH:MM:SS' (빈 값 '' 설정 시 기간 제한 없이 무기한 노출)
  static const String expiryDate = '2026-07-07 23:59:59';

  /// ─── [공지 한국어 내용] ───
  static const String titleKo = 'iOS 출시 기념 이벤트 🎊';
  static const String bodyKo =
      '안녕하세요 리오입니다.\n'
      'iOS 앱스토어 출시 기념 리뷰 이벤트가 진행되고 있습니다.\n'
      '이벤트 기간 : 26.06.23 ~ 07.07\n'
      '자세한 내용은 개발자 노트를 확인해주세요.';

  /// ─── [공지 영어 내용] ───
  static const String titleEn = 'iOS Launch Event 🎊';
  static const String bodyEn =
      'Hello, this is Lio.\n'
      'The iOS App Store launch celebration review event is underway!\n'
      'Event Period: Jun 23 ~ Jul 7, 2026\n'
      'Please check the developer notes for details.';
}

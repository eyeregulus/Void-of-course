// 이 파일은 앱의 '개발자 노트' 화면을 만드는 코드를 담고 있어요.
// 최신 업데이트 내역이나 공지사항을 보여주는 게시판 형태의 화면이에요.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // 링크를 열기 위해 필요해요.
import 'package:flutter/services.dart'; // 클립보드 사용을 위해 추가
import 'package:void_of_course/l10n/app_localizations.dart';
import 'package:void_of_course/core/widgets/app_snackbar.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:void_of_course/core/utils/app_analytics.dart';
import 'package:void_of_course/features/premium/widgets/premium_badge.dart';

// 링크 버튼 정보를 담는 클래스예요.
class NoteAction {
  final String label; // 버튼에 들어갈 글자
  final String url; // 연결할 링크 주소
  NoteAction({required this.label, required this.url});
}

// 개발자 노트(게시글)의 데이터 구조를 정의해요.
class DeveloperNote {
  final String date; // 작성 날짜 (YYYY-MM-DD)
  final String titleKo; // 글 제목 (한국어)
  final String titleEn; // 글 제목 (영어)
  final String contentKo; // 글 내용 (한국어)
  final String contentEn; // 글 내용 (영어)
  final List<NoteAction> actions; // (선택) 여러 개의 링크 버튼들

  DeveloperNote({
    required this.date,
    required this.titleKo,
    required this.titleEn,
    required this.contentKo,
    required this.contentEn,
    this.actions = const [], // 기본값은 빈 리스트
  });
}

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    // 현재 언어 코드를 확인해요 (ko 또는 en)
    final isKorean = Localizations.localeOf(context).languageCode == 'ko';

    // 여기에 게시글 데이터를 추가해요. (최신 글이 위로 오도록 리스트의 앞쪽에 넣어주세요)
    final List<DeveloperNote> notes = [
      // ▼▼▼ [최신 글] ▼▼▼
      DeveloperNote(
        date: '2026-06-23',
        titleKo: '<IOS 출시 이벤트🎊🎉 >',
        titleEn: '<IOS Launching Event🎊🎉 >',
        contentKo: '''
안녕하세요, 리오입니다 🦁

Void of Course iOS 버전이 출시되었습니다! 🎉
출시를 기념하여 작은 감사 이벤트를 진행합니다.

📌 이벤트 내용
앱을 사용해보신 분들의 솔직한 피드백을 기다립니다.
소중한 의견을 남겨주신 분들께 감사 선물을 드립니다.

🎁 참여 혜택
•참여자 전원 - 프리미엄 Plus 1개월 이용권
•베스트 리뷰어 2명(한국/글로벌 각 1명씩) - 프리미엄 Plus 영구권

📋 참여 방법
1. 구글 플레이/애플 앱스토어에 리뷰를 남겨주세요.
2. 해당 리뷰를 캡쳐합니다.
3. 아래 구글 폼에 리뷰 캡쳐와 이메일을 제출합니다.
(이메일 제출시, 리뷰를 남긴 계정과 동일한 이메일을 남겨주셔야 합니다.)

📅 기간: 2026.06.23 ~ 2026.07.07
🏆 당첨자 발표: 2026.07.10 (개별 이메일 연락)
🌍 한국 및 글로벌 유저 모두 참여 가능
''',
        contentEn: '''
Hi, this is Lio 🦁

Void of Course is now officially available on iOS! 🎉
To celebrate the launch, I'm running a small thank-you event.

📌 About This Event
I'd love to hear your honest feedback on the app.
As a token of appreciation, I'm offering gifts to everyone who shares their thoughts.

🎁 Rewards
• All participants - 1 month of Premium Plus for free
• Best reviewer(1 Korean, 1 Global) - Premium Plus lifetime access

📋 How to Join
1. Leave a review on the Play Store or App Store
2. Take a screenshot of the review
3. Submit the review screenshot and your email address via the Google Form below
(Please use the same email address as the account used for the review)

📅 Period: Jun 23 ~ Jul 7, 2026
🏆 Winner announced: Jul 10, 2026 (Email)
🌍 Open to both Korean and global users

Thank you so much for your support
Lio
''',
        actions: [
          NoteAction(
            label: appLocalizations.btnReviewPlayStore,
            url:
                'https://play.google.com/store/apps/details?id=dev.lioluna.voidofcourse',
          ),
          NoteAction(
            label: appLocalizations.btnReviewAppStore,
            url: 'https://apps.apple.com/kr/app/void-of-course/id6777887938',
          ),
          NoteAction(
            label:
                appLocalizations
                    .btnReviewEventForm, // '리뷰 이벤트 구글폼' / 'Review Event Google Form'
            url: 'https://forms.gle/Deq7FYd2EdQgv1S88',
          ),
          NoteAction(
            label:
                appLocalizations
                    .btnContact, // '개발자에게 한마디' / 'Contact Developer'
            url: 'mailto:eyeregulus@gmail.com',
          ),
        ],
      ),

      DeveloperNote(
        date: '2026-06-05',
        titleKo: '<26-06-05 업데이트>',
        titleEn: '<26-06-05 Update>',
        contentKo: '''
안녕하세요 리오입니다.
이번 1.2.0+68 업데이트 사항입니다.

1. 보이드 알람 시간체크 방식 변경
2. 캘린더 기능 UTC 시간 수정 및 개선
3. 날짜 설정 (연/월/일) 선택 방식 추가
4. 프리미엄 기능(광고제거, 보이드 위젯, 구글 캘린더 연동) 추가

앱을 편하게 사용하시고 계시거나 or 불편한 점이 있다면, 오픈카톡에 오셔서 점성학에 관한 이야기와, 앱에 대한 피드백을 나눠주세요. 

따뜻한 리뷰는 개발자에게 큰 힘이 됩니다.

감사합니다
리오 드림
''',
        contentEn: '''
Hi, this is developer Lio.
This is a 1.2.0+68 update.

1. Void notification time check method changed
2. Calendar feature UTC time correction and improvement
3. Date setting (Year/Month/Day) selection method added
4. Premium features (Remove ads, Void Widget, Google Calendar Sync) added

If you have any feedback or questions, please contact us.
''',
        actions: [
          NoteAction(
            label: appLocalizations.btnReview, // '리뷰 남기러 가기' / 'Leave a Review'
            url:
                'https://play.google.com/store/apps/details?id=dev.lioluna.voidofcourse',
          ),
          NoteAction(
            label:
                appLocalizations
                    .btnContact, // '개발자에게 한마디' / 'Contact Developer'
            url: 'mailto:eyeregulus@gmail.com',
          ),
        ],
      ),

      DeveloperNote(
        date: '2026-03-10',
        titleKo: '<26-03-10 업데이트>',
        titleEn: '<26-03-10 Update>',
        contentKo: '''
안녕하세요 리오입니다.
이번 1.2.0+51 업데이트 사항입니다.

1. Void 알림 오류 수정
2. Void 캘린더 기능 추가
3. 오픈카톡 커뮤니티 링크 추가

앱을 편하게 사용하시고 계시거나 or 불편한 점이 있다면, 오픈카톡에 오셔서 점성학에 관한 이야기와, 앱에 대한 피드백을 나눠주세요. 

따뜻한 리뷰는 개발자에게 큰 힘이 됩니다.

감사합니다
리오 드림
''',
        contentEn: '''
Hi, this is developer Lio.
This is a 1.2.0+51 update.

1. Correct void notification error
2. Added Void Calendar feature
3. Add Kakao Talk Community Open Link

If you have any feedback or questions, please contact us.
''',
        actions: [
          NoteAction(
            label: appLocalizations.btnReview, // '리뷰 남기러 가기' / 'Leave a Review'
            url:
                'https://play.google.com/store/apps/details?id=dev.lioluna.voidofcourse',
          ),
          NoteAction(
            label:
                appLocalizations
                    .btnContact, // '개발자에게 한마디' / 'Contact Developer'
            url: 'mailto:eyeregulus@gmail.com',
          ),
        ],
      ),

      DeveloperNote(
        date: '2026-02-10',
        titleKo: '<26-02-10 업데이트>',
        titleEn: '<26-02-10 Update>',
        contentKo: '''
안녕하세요 리오입니다.
이번 1.2.0+42 업데이트 사항입니다.

1. 25개국 표준시 지원 추가
2. 서머 타임 추가(토글 버튼으로 적용/해제 가능)
3. 디스코드 커뮤니티 링크 추가

앱을 편하게 사용하시고 계시다면 or 불편한 점이 있다면, 언제든지 리뷰를 남겨주세요. 
따뜻한 리뷰는 개발자에게 큰 힘이 됩니다.

감사합니다
리오 드림
''',
        contentEn: '''
Hi, this is developer Lio.
This is a 1.2.0+42 update.

1. 25 National Standard Time Support Added
2. Add daylight saving time(DST) (applies/disables with toggle button)
3. Added Discord community link

If you have any feedback or questions, please contact us.
''',
        actions: [
          NoteAction(
            label: appLocalizations.btnReview, // '리뷰 남기러 가기' / 'Leave a Review'
            url:
                'https://play.google.com/store/apps/details?id=dev.lioluna.voidofcourse',
          ),
          NoteAction(
            label:
                appLocalizations
                    .btnContact, // '개발자에게 한마디' / 'Contact Developer'
            url: 'mailto:eyeregulus@gmail.com',
          ),
        ],
      ),

      DeveloperNote(
        date: '2026-02-01',
        titleKo: '<26-02-01 업데이트>',
        titleEn: '<26-02-01 Update>',
        contentKo: '''
안녕하세요 리오입니다.
이번 1.2.0 업데이트 사항입니다.

1. 문 페이즈, 문 인 싸인의 시작 및 종료 시간 추가
2. 앱 이미지 원상태로 복구
3. 안드로이드 어플리케이션 최적화

앱을 편하게 사용하시고 계시다면 or 불편한 점이 있다면, 언제든지 리뷰를 남겨주세요. 
따뜻한 리뷰는 개발자에게 큰 힘이 됩니다.

감사합니다
리오 드림
''',
        contentEn: '''
Hi, this is developer Lio.
Here are the updates for this release:

1. Added start and end times for Moon Phase and Moon in Sign
2. Restored app images to their original state
3. Optimized Android application performance

If you have any feedback or questions, please contact us.
''',
        actions: [
          NoteAction(
            label: appLocalizations.btnReview, // '리뷰 남기러 가기' / 'Leave a Review'
            url:
                'https://play.google.com/store/apps/details?id=dev.lioluna.voidofcourse',
          ),
          NoteAction(
            label:
                appLocalizations
                    .btnContact, // '개발자에게 한마디' / 'Contact Developer'
            url: 'mailto:eyeregulus@gmail.com',
          ),
        ],
      ),

      DeveloperNote(
        date: '2025-12-19',
        titleKo: '<Eye of Regulus의 비전>',
        titleEn: '<Vision of Eye of Regulus>',
        contentKo: '''
안녕하세요 리오입니다.
여기 한국은 날씨가 많이 춥습니다.
모든 유저분들의 건강을 기원합니다.

저의 운영비전은 다음과 같습니다.
**사자의 눈으로 세상을 헤아린다**

유저분께서 남겨주신 피드백들을 통해, 앱이라는 도구로써 집단지식을 창출할 수 있어 뿌듯하게 생각합니다.
계속해서 가치를 쌓아나가는 플랫폼을 구축할 예정입니다. 

또한 IOS(Apple) 유저 약 20분께서 앱스토어 출시 또한 요청해주셨습니다.

1. 현재 안드로이드 유저 기반이 1,000명에 도달하고, 서비스의 가치가 검증되는 시점에 앱스토어 출시를 진행할 예정입니다.

2. 만약 그전에 출시를 희망하신다면, 유저분들의 자발적인 후원을 통해 iOS 개발 환경 구축 운영비가 확보되는 대로 절차를 밟겠습니다. 이는 서비스의 독립성과 무료 원칙을 지키기 위함입니다. (아래의 링크 확인)

보이드 오브 코스는 택일을 할때 유용합니다.
자신과 가장 잘 맞는 날을 선택하시고,
행동의 결정에 있어 지표성을 드립니다.
(알람 서비스를 꼭 사용하셔서, 보이드 타임을 준비하세요)

남은 2026년도 행복한 한해가 되시길 바랍니다.

앱을 편하게 사용하시고 계시다면, or 불편한 점이 있다면, 언제든지 리뷰를 남겨주세요. 
따뜻한 리뷰는 개발자에게 큰 힘이 됩니다.

감사합니다
리오 드림
''',
        contentEn: '''
Hi, this is developer Lio.
It is very cold here in Korea.
I wish good health to all our users.

My operational vision is as follows:
**Fathoming the world with the eyes of a lion**

I am proud to create collective intelligence using this app as a tool, thanks to the feedback you have left.
I plan to continue building a platform that accumulates value.

Also, about 20 iOS (Apple) users have requested an App Store release.

1. I plan to proceed with the App Store release when the Android user base reaches 1,000 and the service value is verified.

2. If you wish for an earlier release, I will proceed as soon as the operating costs for the iOS development environment are secured through voluntary sponsorship from users. This is to maintain the service's independence and free principles. (Check the link below)

Void of course is useful for choosing a date.
Choose the day that suits you best, and get guidance for your decisions.
(Be sure to use the alarm service to prepare for the Void Time)

I hope you have a happy 2026 ahead.

If you are using the app comfortably, or if you have any inconveniences,
please leave a review anytime.
Warm reviews are a great strength to the developer.
''',
        actions: [
          NoteAction(
            label: appLocalizations.btnReview, // '리뷰 남기러 가기' / 'Leave a Review'
            url:
                'https://play.google.com/store/apps/details?id=dev.lioluna.voidofcourse',
          ),
          NoteAction(
            label:
                appLocalizations
                    .btnContact, // '개발자에게 한마디' / 'Contact Developer'
            url: 'mailto:eyeregulus@gmail.com',
          ),
        ],
      ),
      // ▲▲▲ 여기까지 ▲▲▲
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.description,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              appLocalizations.infoScreenTitle,
            ), // '개발자 노트' / 'Developer Notes'
            const SizedBox(width: 8),
            const PremiumBadge(),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child:
                    notes.isEmpty
                        ? Center(
                          child: Text(
                            appLocalizations.noPostsFound, // '등록된 게시글이 없습니다.'
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.6),
                            ),
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: notes.length,
                          itemBuilder: (context, index) {
                            final note = notes[index];
                            // 현재 언어에 맞는 제목과 내용을 선택해요
                            final title =
                                isKorean ? note.titleKo : note.titleEn;
                            final content =
                                isKorean ? note.contentKo : note.contentEn;

                            return Card(
                              key: ValueKey(note.date),
                              margin: const EdgeInsets.only(bottom: 16.0),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: Theme.of(context).cardColor,
                              child: Theme(
                                data: Theme.of(
                                  context,
                                ).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  onExpansionChanged: (expanded) {
                                    if (expanded) {
                                      AppAnalytics.logDeveloperNoteExpanded(
                                        note.date,
                                      );
                                    }
                                  },
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  childrenPadding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    16,
                                  ),
                                  initiallyExpanded: false,
                                  collapsedBackgroundColor:
                                      Theme.of(context).cardColor,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).cardColor.withValues(alpha: 0.8),
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        note.date,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        title, // 언어에 맞는 제목 표시
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.only(top: 8.0),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                            color: Theme.of(context)
                                                .dividerColor
                                                .withValues(alpha: 0.1),
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            content, // 언어에 맞는 내용 표시
                                            style: TextStyle(
                                              fontSize: 14,
                                              height: 1.5,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color
                                                  ?.withValues(alpha: 0.8),
                                            ),
                                          ),
                                          // ▼▼▼ [링크 버튼 목록 표시] ▼▼▼
                                          if (note.actions.isNotEmpty) ...[
                                            const SizedBox(height: 20),
                                            ...note.actions.map(
                                              (action) => Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 8.0,
                                                ),
                                                child: OutlinedButton.icon(
                                                  onPressed: () async {
                                                    try {
                                                      String targetUrl =
                                                          action.url;
                                                      if (Theme.of(
                                                                context,
                                                              ).platform ==
                                                              TargetPlatform
                                                                  .iOS &&
                                                          targetUrl ==
                                                              'https://play.google.com/store/apps/details?id=dev.lioluna.voidofcourse') {
                                                        targetUrl =
                                                            'https://apps.apple.com/kr/app/void-of-course/id6777887938';
                                                      }
                                                      await FirebaseAnalytics
                                                          .instance
                                                          .logEvent(
                                                            name:
                                                                'click_note_action',
                                                            parameters: {
                                                              'label':
                                                                  action.label,
                                                              'url': targetUrl,
                                                            },
                                                          );
                                                      final uri = Uri.parse(
                                                        targetUrl,
                                                      );
                                                      bool launched = false;
                                                      if (await canLaunchUrl(
                                                        uri,
                                                      )) {
                                                        launched = await launchUrl(
                                                          uri,
                                                          mode:
                                                              LaunchMode
                                                                  .externalApplication,
                                                        );
                                                      } else {
                                                        launched =
                                                            await launchUrl(
                                                              uri,
                                                            );
                                                      }

                                                      if (!launched) {
                                                        throw 'Could not launch';
                                                      }
                                                    } catch (e) {
                                                      if (context.mounted) {
                                                        if (action.url
                                                            .startsWith(
                                                              'mailto:',
                                                            )) {
                                                          final email = action
                                                              .url
                                                              .replaceFirst(
                                                                'mailto:',
                                                                '',
                                                              );
                                                          await Clipboard.setData(
                                                            ClipboardData(
                                                              text: email,
                                                            ),
                                                          );
                                                          if (!context.mounted)
                                                            return;
                                                          await AppSnackBar.show(
                                                            context,
                                                            message:
                                                                appLocalizations
                                                                    .msgEmailCopied,
                                                          );
                                                        } else {
                                                          await AppSnackBar.show(
                                                            context,
                                                            message:
                                                                appLocalizations
                                                                    .msgAppNotFound,
                                                          );
                                                        }
                                                      }
                                                    }
                                                  },
                                                  icon: const Icon(
                                                    Icons.link,
                                                    color: Colors.black,
                                                  ),
                                                  label: Text(
                                                    action.label,
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFFD4AF37),
                                                    foregroundColor:
                                                        Colors.black,
                                                    side: BorderSide.none,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 12,
                                                        ),
                                                    alignment:
                                                        Alignment
                                                            .center, // 버튼 글자 가운데 정렬
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                          // ▲▲▲ 여기까지 ▲▲▲
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Text(
                  appLocalizations.copyrightText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:void_of_course/core/astro/astro_state.dart';
import 'package:void_of_course/core/utils/timezone_provider.dart';
import 'package:void_of_course/features/calendar/widgets/calendar_dialog.dart';
import 'package:void_of_course/features/calendar/widgets/date_selector.dart';
import 'package:void_of_course/features/home/widgets/moon_phase_card.dart';
import 'package:void_of_course/features/home/widgets/moon_sign_card.dart';
import 'package:void_of_course/features/calendar/widgets/reset_date_button.dart';
import 'package:void_of_course/features/home/widgets/voc_info_card.dart';
import 'package:void_of_course/features/home/widgets/retrograde_card.dart';
import 'package:void_of_course/features/settings/widgets/timezone_selector_dialog.dart';
import 'package:void_of_course/core/widgets/app_snackbar.dart';
import 'package:void_of_course/features/ads/services/ad_service.dart';
import 'package:void_of_course/features/premium/services/purchase_service.dart';
import 'package:void_of_course/features/premium/widgets/premium_badge.dart';
import 'package:void_of_course/l10n/app_localizations.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AstroState>(context, listen: false);
    if (!provider.isInitialized) {
      Future.microtask(() => provider.initialize());
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  void _changeDate(int days) {
    if (mounted) {
      final provider = Provider.of<AstroState>(context, listen: false);
      final newDate = provider.selectedDate.add(Duration(days: days));
      provider.updateDate(newDate);
    }
  }

  static const Duration _pullRefreshMinSpinner = Duration(milliseconds: 800);

  Future<void> _refreshToToday({required bool awaitFeedback}) async {
    if (!mounted) return;
    final provider = Provider.of<AstroState>(context, listen: false);
    if (provider.isFollowingTime) {
      await provider.refreshDataByUser();
    } else {
      await provider.followTime();
    }

    if (!mounted) return;
    final locale = Localizations.localeOf(context).languageCode;
    final message =
        locale == 'ko' ? '오늘 날짜로 재설정되었습니다.' : 'Date has been reset to today.';

    if (!awaitFeedback) {
      AppSnackBar.show(
        context,
        message: message,
        duration: const Duration(seconds: 1),
      );
      AdService().showAdIfNeeded(() {});
      return;
    }

    await AppSnackBar.show(
      context,
      message: message,
      duration: const Duration(seconds: 1),
    );
    await AdService().showAdIfNeeded(() {});
  }

  Future<void> _resetDateToToday() => _refreshToToday(awaitFeedback: true);

  Future<void> _onPullRefresh() async {
    final started = DateTime.now();
    await _refreshToToday(awaitFeedback: false);
    final elapsed = DateTime.now().difference(started);
    final remaining = _pullRefreshMinSpinner - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(context), body: _buildBody(context));
  }

  AppBar _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      title: Padding(
        padding: const EdgeInsets.only(top: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer<PurchaseService>(
              builder: (context, purchaseService, child) {
                return Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color:
                          purchaseService.isPro
                              ? (isDark
                                  ? const Color(0xFFFFD700)
                                  : const Color(0xFFFFA500))
                              : (isDark
                                  ? const Color(0xFFD4AF37)
                                  : const Color(0xFF2C3E50)),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Void of Course',
                        style: Theme.of(context).appBarTheme.titleTextStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (purchaseService.isPro ||
                        purchaseService.isPlus ||
                        purchaseService.isLite) ...[
                      const SizedBox(width: 8),
                      const PremiumBadge(),
                    ],
                  ],
                );
              },
            ),
            // 타임존 정보 표시
            Consumer<TimezoneProvider>(
              builder: (context, tzProvider, child) {
                final tzInfo = tzProvider.currentTimezoneInfo;
                if (tzInfo != null) {
                  final localeCode =
                      Localizations.localeOf(context).languageCode;
                  final countryName =
                      localeCode == 'ko'
                          ? tzInfo.countryNameKo
                          : tzInfo.countryNameEn;
                  final cityName =
                      localeCode == 'ko'
                          ? tzInfo.cityNameKo
                          : tzInfo.cityNameEn;
                  final displayOffset = tzProvider.getDisplayOffset();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${tzInfo.flag} $countryName, $cityName, $displayOffset',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
      centerTitle: false,
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      elevation: 0,
      actions: [
        // 서머타임 토글 버튼 (DST 시행 국가인 경우에만 표시)
        Consumer<TimezoneProvider>(
          builder: (context, tzProvider, child) {
            final tzInfo = tzProvider.currentTimezoneInfo;
            if (tzInfo != null && tzInfo.isDstCountry) {
              return IconButton(
                icon: Icon(
                  tzProvider.isDstApplied ? Icons.light_mode : Icons.dark_mode,
                  color:
                      isDark
                          ? const Color(0xFFD4AF37)
                          : const Color(0xFF2C3E50),
                ),
                onPressed: () async {
                  // DST 토글: 천문 계산은 UTC 기반이므로 재계산 불필요
                  // 카드 위젯들이 TimezoneProvider를 리스닝하므로 convert()로 자동 갱신
                  await FirebaseAnalytics.instance.logEvent(
                    name: 'toggle_dst',
                    parameters: {
                      'enabled': (!tzProvider.isDstApplied).toString(),
                    },
                  );
                  final astroState = Provider.of<AstroState>(
                    context,
                    listen: false,
                  );
                  await tzProvider.toggleDst();
                  if (mounted) {
                    await astroState.updateVocAlarmForTimezone();
                  }
                },
                tooltip: tzProvider.isDstApplied ? 'DST On' : 'DST Off',
              );
            }
            return const SizedBox.shrink();
          },
        ),
        IconButton(
          icon: Icon(
            Icons.public,
            color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF2C3E50),
          ),
          onPressed: () {
            FirebaseAnalytics.instance.logEvent(
              name: 'click_timezone_selector',
            );
            showTimezoneSelectorDialog(context);
          },
          tooltip: 'Timezone',
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Consumer를 사용하여 AstroState 변경 시에만 body 리빌드
    return Consumer<AstroState>(
      builder: (context, astroState, child) {
        // 타임존 변경 시 알람 재설정 경고 표시
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (astroState.showTimezoneChangeWarning) {
            final appLocalizations = AppLocalizations.of(context)!;
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: Text(appLocalizations.voidAlarmTitle),
                    content: Text(
                      appLocalizations.resetVoidAlarmForTimezoneChange,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          // 경고 플래그를 리셋하고 대화 상자를 닫습니다.
                          astroState.showTimezoneChangeWarning = false;
                          Navigator.of(context).pop();
                        },
                        child: Text(appLocalizations.ok),
                      ),
                    ],
                  ),
            );
          }
        });

        // 날짜 컨트롤러는 AstroState에서 전달되는 selectedDate로 업데이트합니다.
        _dateController.text = DateFormat(
          'yyyy/MM/dd',
        ).format(astroState.selectedDate.toLocal());

        if (!astroState.isInitialized) {
          return Center(
            child: CircularProgressIndicator(
              color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF2C3E50),
            ),
          );
        }
        if (astroState.lastError != null) {
          return Center(child: Text('Error: ${astroState.lastError}'));
        }

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors:
                  isDark
                      ? [
                        const Color(0xFF0F0F1A),
                        const Color(0xFF1A1A2E),
                        const Color(0xFF16213E),
                      ]
                      : [
                        const Color(0xFFF8F6F0),
                        const Color(0xFFFFFDF8),
                        const Color(0xFFF0EDE5),
                      ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return RefreshIndicator(
                  onRefresh: _onPullRefresh,
                  color:
                      isDark
                          ? const Color(0xFFD4AF37)
                          : const Color(0xFF2C3E50),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight + 1,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              MediaQuery.of(context).size.width < 380
                                  ? 12.0
                                  : 16.0,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            MoonPhaseCard(provider: astroState),
                            const SizedBox(height: 4),
                            MoonSignCard(provider: astroState),
                            const SizedBox(height: 4),
                            VocInfoCard(provider: astroState),
                            const SizedBox(height: 4),
                            if (astroState.showRetrogradeCard) ...[
                              RetrogradeCard(provider: astroState),
                              const SizedBox(height: 4),
                            ],
                            DateSelector(
                              dateController: _dateController,
                              onPreviousDay: () => _changeDate(-1),
                              onNextDay: () => _changeDate(1),
                              onResetToToday: () => _resetDateToToday(),
                              showCalendar: () => showCalendarDialog(context),
                              selectedDate: astroState.selectedDate,
                              isRetrogradeCardVisible:
                                  astroState.showRetrogradeCard,
                            ),
                            if (!astroState.showRetrogradeCard) ...[
                              const SizedBox(height: 7),
                              ResetDateButton(
                                onPressed: () => _resetDateToToday(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:void_of_course/services/locale_provider.dart';
import 'package:void_of_course/services/google_calendar_service.dart';
import 'package:void_of_course/services/purchase_service.dart';
import '../widgets/setting_card.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/premium_dialog.dart';
import 'package:void_of_course/themes.dart';
import 'package:void_of_course/l10n/app_localizations.dart';
import 'package:home_widget/home_widget.dart';
import '../widgets/premium_badge.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final isKorean = Localizations.localeOf(context).languageCode == 'ko';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.workspace_premium,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(appLocalizations.premium),
            const SizedBox(width: 8),
            const PremiumBadge(),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 프리미엄 서비스 카드
                SettingCard(
                  icon: Icons.workspace_premium,
                  title: appLocalizations.premium,
                  iconColor: const Color.fromARGB(255, 0, 0, 0),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 30,
                    color: Colors.grey,
                  ),
                  onTap: () => showPremiumDialog(context),
                ),

                // 홈 화면 위젯 카드
                const HomeWidgetCard(),

                // 구글 캘린더 연동 카드
                const GoogleCalendarCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 구글 캘린더 연동 카드
// ────────────────────────────────────────────────────────────────────────────
class GoogleCalendarCard extends StatefulWidget {
  const GoogleCalendarCard({super.key});

  @override
  State<GoogleCalendarCard> createState() => _GoogleCalendarCardState();
}

class _GoogleCalendarCardState extends State<GoogleCalendarCard> {
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    final calService = GoogleCalendarService.instance;
    final success = await calService.signIn();
    if (!mounted) return;

    if (success) {
      // 로그인(연동) 성공 시 별도 버튼 클릭 없이 즉시 동기화 실행
      await _handleSync();
    } else {
      setState(() => _isLoading = false);
      final appLocalizations = AppLocalizations.of(context)!;
      final err = calService.lastError;
      final msg = err == 'calendar_permission_denied'
          ? appLocalizations.calendarPermissionRequired
          : appLocalizations.loginFailedRetry;
      await AppSnackBar.show(context, message: msg);
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await _showSignOutDialog();
    if (!confirmed) return;
    await GoogleCalendarService.instance.signOut(deleteCalendar: true);
    if (!mounted) return;
    final appLocalizations = AppLocalizations.of(context)!;
    await AppSnackBar.show(context, message: appLocalizations.googleCalendarUnlinked);
  }

  Future<void> _handleSync() async {
    final calService = GoogleCalendarService.instance;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final locale = localeProvider.locale?.languageCode ?? 'ko';

    setState(() => _isLoading = true);
    final count = await calService.syncVocEvents(locale: locale);
    if (!mounted) return;
    setState(() => _isLoading = false);

    final appLocalizations = AppLocalizations.of(context)!;
    if (count >= 0) {
      await AppSnackBar.show(context, message: appLocalizations.vocEventsAdded(count));
    } else {
      await AppSnackBar.show(context, message: appLocalizations.syncFailedRetry);
    }
  }

  Future<bool> _showSignOutDialog() async {
    final appLocalizations = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(appLocalizations.unlinkGoogleCalendarTitle),
            content: Text(appLocalizations.unlinkGoogleCalendarContent),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(appLocalizations.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(appLocalizations.unlink),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Consumer2<GoogleCalendarService, PurchaseService>(
      builder: (context, calService, purchaseService, _) {
        final isSignedIn = calService.isSignedIn;
        final isSyncing = calService.isSyncing || _isLoading;
        final email = calService.currentUser?.email;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final isPremium = purchaseService.isPlus;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.cardColor, theme.cardColor.withValues(alpha: 0.8)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [Themes.cardShadow(isDark)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 헤더 행 ──
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: const Color(
                        0xFF4285F4,
                      ).withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF4285F4),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appLocalizations.googleCalendar,
                            style: TextStyle(
                              color: theme.textTheme.titleLarge?.color,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isSignedIn ? email ?? appLocalizations.linked : appLocalizations.googleCalendarVocSync,
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // 연결 상태 뱃지
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            !isPremium
                                ? Colors.grey.withValues(alpha: 0.12)
                                : (isSignedIn
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : Colors.grey.withValues(alpha: 0.12)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        !isPremium ? '🔒 ${appLocalizations.premium}' : (isSignedIn ? appLocalizations.linked : appLocalizations.notLinked),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              !isPremium
                                  ? Colors.amber
                                  : (isSignedIn ? Colors.green : Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── 로그인 상태일 때: 동기화 범위 + 버튼들 ──
                if (isSignedIn) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // 동기화 범위 선택
                  Row(
                    children: [
                      Icon(
                        Icons.date_range,
                        size: 18,
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        appLocalizations.syncDuration,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      const Spacer(),
                      DropdownButton<CalendarSyncRange>(
                        value: calService.syncRange,
                        underline: const SizedBox.shrink(),
                        isDense: true,
                        items:
                            CalendarSyncRange.values.map((r) {
                              return DropdownMenuItem(
                                value: r,
                                child: Text(
                                  r.label(Localizations.localeOf(context).languageCode),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                        onChanged:
                            isSyncing
                                ? null
                                : (range) {
                                  if (range != null) {
                                    calService.setSyncRange(range);
                                  }
                                },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 동기화 + 연동해제 버튼
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: isSyncing ? null : _handleSync,
                          icon:
                              isSyncing
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Icon(Icons.sync, size: 18),
                          label: Text(isSyncing ? appLocalizations.syncing : appLocalizations.syncNow),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4285F4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: isSyncing ? null : _handleSignOut,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: Text(appLocalizations.unlink),
                      ),
                    ],
                  ),
                ],

                // ── 로그아웃 상태일 때: 로그인 버튼 ──
                if (!isSignedIn && isPremium) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isSyncing ? null : _handleSignIn,
                      icon:
                          isSyncing
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(Icons.login, size: 18),
                      label: Text(appLocalizations.linkGoogleCalendar),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4285F4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],

                // ── 프리미엄 미결제 상태일 때: 잠금 해제 안내 ──
                if (!isPremium) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          color: Colors.amber,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          appLocalizations.plusPassFeature,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appLocalizations.premiumCalendarSyncDesc,
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => const PremiumDialog(),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                          ),
                          child: Text(appLocalizations.explorePremium),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 홈 화면 위젯 추가 카드
// ────────────────────────────────────────────────────────────────────────────
class HomeWidgetCard extends StatelessWidget {
  const HomeWidgetCard({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Consumer<PurchaseService>(
      builder: (context, purchaseService, _) {
        final isPremium = purchaseService.isPlus;

        return SettingCard(
          icon: Icons.widgets,
          title: appLocalizations.addHomeWidget,
          subtitle: appLocalizations.addHomeWidgetDesc,
          iconColor: Colors.blueAccent,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isPremium
                  ? Colors.blueAccent.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              !isPremium ? '🔒 ${appLocalizations.premium}' : '+',
              style: TextStyle(
                fontSize: !isPremium ? 12 : 20,
                fontWeight: FontWeight.bold,
                color: !isPremium ? Colors.amber : Colors.blueAccent,
              ),
            ),
          ),
          onTap: () async {
            if (!isPremium) {
              showDialog(
                context: context,
                builder: (ctx) => const PremiumDialog(),
              );
              return;
            }

            final supported = await HomeWidget.isRequestPinWidgetSupported();
            if (supported == true) {
              await HomeWidget.requestPinWidget(
                androidName: 'VocWidgetProvider',
                qualifiedAndroidName: 'com.example.lioluna.VocWidgetProvider',
              );
            } else {
              if (context.mounted) {
                AppSnackBar.show(context, message: appLocalizations.widgetAutoPinNotSupported);
              }
            }
          },
        );
      },
    );
  }
}

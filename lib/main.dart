import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:void_of_course/features/calendar/screens/calendar_screen.dart';
import 'package:void_of_course/features/home/screens/home_screen.dart';
import 'package:void_of_course/features/premium/screens/premium_screen.dart';
import 'package:void_of_course/features/settings/screens/developer_notes_screen.dart';
import 'package:void_of_course/features/settings/screens/setting_screen.dart';
import 'package:void_of_course/core/astro/astro_state.dart';
import 'package:void_of_course/core/utils/timezone_provider.dart';
import 'package:void_of_course/themes.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:void_of_course/features/home/screens/splash_screen.dart';
import 'package:void_of_course/core/utils/locale_provider.dart';
import 'package:void_of_course/l10n/app_localizations.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:void_of_course/core/widgets/exit_confirmation_dialog.dart';
import 'package:void_of_course/features/ads/services/ad_service.dart';
import 'package:void_of_course/features/ads/services/ad_ids.dart';
import 'package:flutter/services.dart';
import 'package:void_of_course/core/background/background_service.dart';
import 'package:void_of_course/features/ads/services/native_ad_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:home_widget/home_widget.dart';
import 'package:void_of_course/features/calendar/services/calendar_voc_cache.dart';
import 'package:void_of_course/features/home/services/widget_service.dart';
import 'package:void_of_course/core/utils/app_analytics.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:void_of_course/features/calendar/services/google_calendar_service.dart';
import 'package:void_of_course/features/premium/services/purchase_service.dart';
import 'package:void_of_course/core/services/version_check_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:void_of_course/features/settings/services/app_notice_config.dart';

Future<void> _initWithTimeout(
  String label,
  Future<void> Function() action, {
  Duration timeout = const Duration(seconds: 6),
}) async {
  try {
    await action().timeout(timeout);
  } catch (e) {
    developer.log('$label skipped or timed out: $e', name: 'Main');
  }
}

void main() async {
  // 플러터 위젯들이 준비될 때까지 기다려요.
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-Edge 모드 활성화 (Android 15+ 권장)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Firebase는 다른 서비스(Analytics 등)에서 즉시 사용할 수 있도록 먼저 초기화 (보통 매우 빠름)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    developer.log('Firebase init failed: $e', name: 'Main');
  }

  // 나머지 무거운 초기화 작업들은 앱 실행(runApp)을 블로킹하지 않도록 백그라운드로 던집니다.
  // 이 덕분에 사용자는 하얀 화면 대신 곧바로 앱의 스플래시 화면을 볼 수 있습니다.
  _initHeavyServicesInBackground();

  runApp(
    MultiProvider(
      providers: [
        //astro_state.dart의 AstroState를 초기화(initialize)하고 Provider로 등록
        ChangeNotifierProvider(create: (context) => AstroState()..initialize()),
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
        ChangeNotifierProvider(create: (context) => TimezoneProvider()),
        // 구글 캘린더 서비스
        ChangeNotifierProvider.value(value: GoogleCalendarService.instance),
        // 인앱 결제 서비스
        ChangeNotifierProvider.value(value: PurchaseService.instance),
      ],
      child: const MyApp(),
    ),
  );
}

// 무거운 서비스들을 병렬로 비동기 초기화하는 함수
void _initHeavyServicesInBackground() async {
  if (Platform.isAndroid) {
    _initWithTimeout(
      'AndroidAlarmManager',
      AndroidAlarmManager.initialize,
      timeout: const Duration(seconds: 3),
    );
  }

  _initWithTimeout('BackgroundService', () async {
    try {
      await initializeBackgroundService();
    } catch (e) {
      developer.log('Background service init failed: $e', name: 'Main');
    }
  }, timeout: const Duration(seconds: 5));

  if (Platform.isAndroid || Platform.isIOS) {
    _initWithTimeout('AdMob', () async {
      try {
        await MobileAds.instance.initialize();
        await AdService().initialize();
      } catch (e) {
        developer.log('AdMob init failed: $e', name: 'Main');
      }
    }, timeout: const Duration(seconds: 5)).then((_) {
      NativeAdService().loadAd();
    });
  }

  _initWithTimeout(
    'GoogleCalendarService',
    () => GoogleCalendarService.instance.init(),
    timeout: const Duration(seconds: 5),
  );

  _initWithTimeout(
    'PurchaseService',
    () => PurchaseService.instance.init(),
    timeout: const Duration(seconds: 5),
  );
}

// 우리 앱의 가장 기본적인 위젯이에요.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // 앱 화면 보여주기
  @override
  Widget build(BuildContext context) {
    // 테마를 관리하고 앱의 기본 설정을 하는 위젯이에요.
    return ThemeProvider(
      initTheme:
          Theme.of(context).brightness == Brightness.dark
              ? Themes.darkTheme
              : Themes.lightTheme,
      builder: (context, myTheme) {
        final localeProvider = Provider.of<LocaleProvider>(context);
        return MaterialApp(
          title: 'Void of course',
          debugShowCheckedModeBanner: false,
          theme: myTheme,
          home: const SplashScreen(),
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,

          builder: (context, child) {
            if (child == null) return const SizedBox.shrink();
            final mediaQueryData =
                MediaQuery.maybeOf(context) ??
                MediaQueryData.fromView(View.of(context));
            return MediaQuery(
              // 사용자가 시스템 글자 크기를 키워도 앱 내에서는 1.0배로 고정
              data: mediaQueryData.copyWith(
                textScaler: const TextScaler.linear(1.0),
              ),
              child: child,
            );
          },
          // ▲▲▲ 여기까지 ▲▲▲
        );
      },
    );
  }
}

// 앱의 메인 화면 (하단 내비게이션 바가 있는 화면)
class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncLaunchAnalytics();
      final initialLocale =
          Provider.of<LocaleProvider>(context, listen: false).locale;
      if (initialLocale != null) {
        Provider.of<AstroState>(
          context,
          listen: false,
        ).updateLocale(initialLocale.languageCode);
      }
      _checkAndShowEventNotice();
    });
    _checkForUpdate();
    _checkWidgetStatus();
  }

  void _syncLaunchAnalytics() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    AppAnalytics.setDarkModeEnabled(isDark);

    final locale = Provider.of<LocaleProvider>(context, listen: false).locale;
    if (locale != null) {
      AppAnalytics.setLanguage(locale.languageCode);
    }
  }

  Future<void> _checkWidgetStatus() async {
    try {
      final installedWidgets = await HomeWidget.getInstalledWidgets();
      final hasWidget = installedWidgets.isNotEmpty;
      await FirebaseAnalytics.instance.setUserProperty(
        name: 'has_home_widget',
        value: hasWidget.toString(),
      );
      if (!mounted) return;
      await Provider.of<AstroState>(
        context,
        listen: false,
      ).syncHomeWidgetFromInstallStatus(hasWidget);
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error checking widget status: $e', name: 'Main');
      }
    }
  }

  Future<void> _checkAndShowEventNotice() async {
    try {
      if (!AppNoticeConfig.enabled) return;

      // 만료 시각 체크
      if (AppNoticeConfig.expiryDate.isNotEmpty) {
        final expiry = DateTime.tryParse(AppNoticeConfig.expiryDate);
        if (expiry != null && DateTime.now().isAfter(expiry)) {
          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();

      if (AppNoticeConfig.showPolicy == NoticeShowPolicy.oncePerId) {
        final lastShownId = prefs.getString('last_shown_notice_id');
        if (lastShownId == AppNoticeConfig.noticeId) {
          return;
        }
      }

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      await _showNoticeDialog(prefs);
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error showing event notice: $e', name: 'Main');
      }
    }
  }

  Future<void> _showNoticeDialog(SharedPreferences prefs) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AppNoticeDialog(
          prefs: prefs,
          onViewDetails: () {
            _onTabTapped(4);
          },
        );
      },
    );

    if (AppNoticeConfig.showPolicy == NoticeShowPolicy.oncePerId) {
      await prefs.setString('last_shown_notice_id', AppNoticeConfig.noticeId);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _syncLaunchAnalytics();
      _checkWidgetStatus();
      Provider.of<AstroState>(context, listen: false).ensureServiceRunning();
      WidgetService.refreshFromPrefs();
      WidgetService.refreshFromPrefs();

      // 앱 포그라운드로 복귀 시 전면/스플래시 광고 표시 (30분 제한, 프리미엄 여부 등 자동 검증)
      // iOS의 경우 백그라운드에서 복귀할 때 뷰 계층구조가 완전히 활성화될 시간을 벌어주기 위해 600ms 지연을 둡니다.
      if (Platform.isIOS) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          AdService().loadAndShowSplashAd(
            adUnitId: AdIds.interstitial,
            onAdDismissed: () {
              if (kDebugMode) {
                developer.log('App resumed: Ad dismissed.', name: 'Main');
              }
            },
            onAdFailed: () {
              if (kDebugMode) {
                developer.log('App resumed: Ad failed or skipped.', name: 'Main');
              }
            },
          );
        });
      } else {
        AdService().loadAndShowSplashAd(
          adUnitId: AdIds.interstitial,
          onAdDismissed: () {
            if (kDebugMode) {
              developer.log('App resumed: Ad dismissed.', name: 'Main');
            }
          },
          onAdFailed: () {
            if (kDebugMode) {
              developer.log('App resumed: Ad failed or skipped.', name: 'Main');
            }
          },
        );
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      AdService().onAppPaused();
    }
  }

  Future<void> _checkForUpdate() async {
    if (Platform.isIOS) {
      if (mounted) {
        await VersionCheckService.checkForUpdates(context);
      }
      return;
    }

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error checking for update: $e', name: 'Main');
      }
    }
  }

  void _onTabTapped(int index) {
    if (_selectedIndex != index) {
      String? eventName;
      switch (index) {
        case 0:
          eventName = 'click_home_tab';
          break;
        case 1:
          eventName = 'click_calendar_tab';
          CalendarVocCache.instance.preloadAroundSilent(
            DateTime.now(),
            radius: 2,
          );
          break;
        case 2:
          eventName = 'click_premium_tab';
          break;
        case 3:
          eventName = 'click_settings_tab';
          break;
        case 4:
          eventName = 'click_info_tab';
          break;
      }

      if (eventName != null) {
        FirebaseAnalytics.instance.logEvent(name: eventName);
      }

      switch (index) {
        case 1:
          AppAnalytics.logScreenView('calendar');
          break;
        case 2:
          AppAnalytics.logScreenView('premium');
          break;
        case 4:
          AppAnalytics.logScreenView('developer_notes');
          break;
      }

      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 현재 테마가 다크 모드인지 확인해요.
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Selector를 사용해서 초기화 상태만 확인 (불필요한 rebuild 방지)
    return Selector<AstroState, ({bool isInitialized, String? lastError})>(
      selector:
          (_, state) => (
            isInitialized: state.isInitialized,
            lastError: state.lastError,
          ),
      builder: (context, state, child) {
        if (!state.isInitialized) {
          if (state.lastError != null) {
            return Scaffold(
              backgroundColor: const Color(0xFF2C3E50),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '오류가 발생하여 앱을 실행할 수 없습니다.\n\n${state.lastError}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              ),
            );
          }
          return const Scaffold(
            backgroundColor: Color(0xFF2C3E50),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        if (state.lastError != null) {
          return Scaffold(
            backgroundColor: const Color(0xFF2C3E50),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '오류가 발생하여 앱을 실행할 수 없습니다.\n\n${state.lastError}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ),
          );
        }

        // 초기화 완료 후에는 child를 반환 (AstroState 변경에 반응하지 않음)
        return child!;
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) {
            return;
          }
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => const ExitConfirmationDialog(),
          );
          if (shouldPop ?? false) {
            SystemNavigator.pop();
          }
        },
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarIconBrightness:
                isDarkMode ? Brightness.light : Brightness.dark,
            statusBarBrightness:
                isDarkMode ? Brightness.dark : Brightness.light,
            systemNavigationBarIconBrightness:
                isDarkMode ? Brightness.light : Brightness.dark,
          ),
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: _buildScreens(),
                    ),
                  ),
                  Consumer<PurchaseService>(
                    builder: (context, purchaseService, child) {
                      if (purchaseService.isLite) {
                        return const SizedBox.shrink();
                      }
                      return const BannerAdWidget();
                    },
                  ),
                ],
              ),
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color:
                        isDarkMode
                            ? Colors.black.withValues(alpha: 0.4)
                            : Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onTabTapped,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor:
                    isDarkMode
                        ? const Color(0xFFD4AF37)
                        : const Color(0xFF2C3E50),
                unselectedItemColor:
                    isDarkMode
                        ? const Color(0xFFB8B5AD)
                        : const Color(0xFF6B7280),
                type: BottomNavigationBarType.fixed,
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home),
                    label: AppLocalizations.of(context)!.home,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.calendar_month),
                    label: AppLocalizations.of(context)!.calendar,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.workspace_premium),
                    label: AppLocalizations.of(context)!.premium,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.settings),
                    label: AppLocalizations.of(context)!.settings,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.description),
                    label: AppLocalizations.of(context)!.info,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildScreens() {
    return [
      const HomeScreen(),
      const CalendarScreen(),
      const PremiumScreen(),
      const SettingScreen(),
      const InfoScreen(),
    ];
  }
}

// 배너 광고 위젯
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  final String _adUnitId = AdIds.banner;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          if (kDebugMode) {
            developer.log('BannerAd failed to load: $err', name: 'Main');
          }
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class AppNoticeDialog extends StatefulWidget {
  final SharedPreferences prefs;
  final VoidCallback onViewDetails;

  const AppNoticeDialog({
    super.key,
    required this.prefs,
    required this.onViewDetails,
  });

  @override
  State<AppNoticeDialog> createState() => _AppNoticeDialogState();
}

class _AppNoticeDialogState extends State<AppNoticeDialog> {
  late bool _isKoActive;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final localeProvider =
          Provider.of<LocaleProvider>(context, listen: false);
      final locale = localeProvider.locale?.languageCode ??
          Localizations.localeOf(context).languageCode;
      _isKoActive = locale == 'ko';
      _isInitialized = true;
    }
  }

  Widget _buildTabButton(String label, bool isKo, bool isDark) {
    final isActive = _isKoActive == isKo;
    final primaryColor = const Color(0xFFD4AF37); // Gold
    return GestureDetector(
      onTap: () {
        if (_isKoActive != isKo) {
          setState(() {
            _isKoActive = isKo;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? Colors.black
                : (isDark ? Colors.white54 : Colors.black54),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor =
        isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final Color textColor =
        isDark ? const Color(0xFFF0EDE5) : const Color(0xFF1A1A2E);
    final Color primaryColor = const Color(0xFFD4AF37); // Gold

    final title =
        _isKoActive ? AppNoticeConfig.titleKo : AppNoticeConfig.titleEn;
    final body = _isKoActive ? AppNoticeConfig.bodyKo : AppNoticeConfig.bodyEn;
    final closeText = _isKoActive ? '닫기' : 'Close';
    final viewDetailsText = _isKoActive ? '자세히 보기' : 'View Details';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      elevation: 8,
      backgroundColor: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단 헤더: 아이콘 + 토글 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.campaign, color: primaryColor, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Notice',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                if (AppNoticeConfig.showBoth)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTabButton('KO', true, isDark),
                        _buildTabButton('EN', false, isDark),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // 공지 제목 (애니메이션 전환)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: SizedBox(
                width: double.infinity,
                key: ValueKey<String>(title),
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Divider(
              color: isDark ? Colors.white10 : Colors.black12,
              height: 1,
            ),
            const SizedBox(height: 12),
            // 공지 본문 내용 (스크롤 및 애니메이션 전환)
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    body,
                    key: ValueKey<String>(body),
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 하단 버튼 바
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onViewDetails();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    viewDetailsText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? const Color(0xFFB8B5AD)
                        : const Color(0xFF6B7280),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    closeText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

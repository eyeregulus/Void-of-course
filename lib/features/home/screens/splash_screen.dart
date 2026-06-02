import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:void_of_course/features/ads/services/ad_service.dart';
import 'package:void_of_course/features/ads/services/ad_ids.dart';
import 'package:void_of_course/main.dart';
import 'package:void_of_course/core/astro/astro_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _adTriggered = false;
  bool _hasNavigated = false;
  DateTime? _splashStartTime;

  /// 초기화가 느릴 때 광고 단계로 넘기기 전 대기 (스윗스팟: 대부분 1~3초 내 init 완료)
  static const _softProceedTimeout = Duration(seconds: 3);

  /// 어떤 경우에도 메인으로 넘기는 최대 스플래시 체류 시간
  static const _hardNavigateTimeout = Duration(seconds: 6);

  /// 스플래시 전면광고가 메인 진입을 막는 최대 시간
  static const _adFlowMaxDuration = Duration(seconds: 3);

  /// 광고 로드 대기 (미로드 시 빠르게 스킵)
  static const _adLoadTimeout = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryProceed());

    Future.delayed(_softProceedTimeout, () {
      if (mounted) _tryProceed(force: true);
    });

    Future.delayed(_hardNavigateTimeout, () {
      if (mounted) _forceNavigateToMain();
    });
  }

  bool _canProceed(AstroState astroState) {
    return astroState.isInitialized || astroState.lastError != null;
  }

  void _tryProceed({bool force = false}) {
    if (_adTriggered || _hasNavigated || !mounted) return;
    final astroState = Provider.of<AstroState>(context, listen: false);
    if (force || _canProceed(astroState)) {
      _triggerAdShow();
    }
  }

  void _forceNavigateToMain() {
    _navigateToMainScreen();
  }

  void _navigateToMainScreen() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainAppScreen()),
    );
  }

  Future<void> _showAdAndNavigate() async {
    if (_hasNavigated) return;
    _splashStartTime ??= DateTime.now();

    final adService = AdService();
    final adUnitId = AdIds.interstitial;
    final minDuration =
        kDebugMode ? const Duration(milliseconds: 800) : Duration.zero;

    void goToMain() {
      if (_hasNavigated) return;
      final start = _splashStartTime ?? DateTime.now();
      final elapsed = DateTime.now().difference(start);
      final remaining = minDuration - elapsed;
      if (remaining > Duration.zero) {
        Future.delayed(remaining, _navigateToMainScreen);
      } else {
        _navigateToMainScreen();
      }
    }

    final adFlowGuard = Timer(_adFlowMaxDuration, goToMain);

    try {
      await adService
          .loadAndShowSplashAd(
            adUnitId: adUnitId,
            onAdDismissed: goToMain,
            onAdFailed: goToMain,
            timeout: _adLoadTimeout,
          )
          .timeout(_adFlowMaxDuration, onTimeout: goToMain);
    } catch (_) {
      goToMain();
    } finally {
      adFlowGuard.cancel();
    }
  }

  void _triggerAdShow() {
    if (_adTriggered || _hasNavigated) return;
    _adTriggered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAdAndNavigate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: Consumer<AstroState>(
          builder: (context, astroState, child) {
            if (_canProceed(astroState)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _tryProceed();
              });
            }

            return Container(
              width: double.infinity,
              height: double.infinity,
              color: Theme.of(context).colorScheme.primary,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Loading...',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

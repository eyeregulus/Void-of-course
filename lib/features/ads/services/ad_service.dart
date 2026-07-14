import 'dart:io';
import 'dart:developer' as developer;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:void_of_course/features/ads/services/ad_ids.dart';
import 'package:void_of_course/features/premium/services/purchase_service.dart';

/// 전면 광고 및 광고 정책을 관리하는 서비스 클래스입니다.
class AdService {
  static final AdService _instance = AdService._internal();

  factory AdService() {
    return _instance;
  }

  AdService._internal();

  bool _isInitialized = false;
  SharedPreferences? _prefs; // 캐시된 SharedPreferences

  InterstitialAd? _interstitialAd;
  AppOpenAd? _appOpenAd;
  bool _isAppOpenAdLoading = false;
  int _calculateClickCount = 0;
  final int _adFrequency = 30; // 광고 표시 빈도 (10번 클릭마다)

  static const _clickCountKey = 'calculateClickCount';
  static const _lastSplashAdShowTimeKey = 'lastSplashAdShowTime';
  static const _hasCompletedFirstLaunchKey = 'has_completed_first_launch';

  /// 최초 설치 후 첫 실행 세션 동안 전면광고를 건너뜁니다.
  bool _skipInterstitialForFirstLaunchSession = false;

  /// 서비스 초기화 시 광고와 클릭 횟수를 로드합니다.
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    _prefs = await SharedPreferences.getInstance();
    _skipInterstitialForFirstLaunchSession =
        !(_prefs?.getBool(_hasCompletedFirstLaunchKey) ?? false);
    await _loadCalculateClickCount();
    if (kDebugMode) {
      developer.log(
        'AdService initialized. Click count: $_calculateClickCount',
        name: 'AdService',
      );
    }
    if (Platform.isAndroid || Platform.isIOS) {
      _loadInterstitialAd();
      _loadAppOpenAd();
    }
    _isInitialized = true;
  }

  /// 앱이 백그라운드로 가면 첫 실행 세션 스킵을 해제합니다.
  void onAppPaused() {
    _skipInterstitialForFirstLaunchSession = false;
  }

  Future<void> _persistFirstLaunchCompleted() async {
    await _prefs?.setBool(_hasCompletedFirstLaunchKey, true);
  }

  Future<bool> _skipInterstitialForFirstLaunch() async {
    if (!_skipInterstitialForFirstLaunchSession) {
      return false;
    }
    if (!(_prefs?.getBool(_hasCompletedFirstLaunchKey) ?? false)) {
      await _persistFirstLaunchCompleted();
    }
    if (kDebugMode) {
      developer.log(
        'Interstitial skipped (first launch after install)',
        name: 'AdService',
      );
    }
    return true;
  }

  /// 전면 광고를 로드합니다.
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (kDebugMode) {
            developer.log('Interstitial ad loaded.', name: 'AdService');
          }
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            developer.log(
              'Interstitial ad failed to load: $error',
              name: 'AdService',
            );
          }
          _interstitialAd?.dispose();
          _interstitialAd = null;
        },
      ),
    );
  }

  /// 앱 오프닝 광고를 로드합니다.
  void _loadAppOpenAd() {
    if (_isAppOpenAdLoading || _appOpenAd != null) return;
    _isAppOpenAdLoading = true;
    AppOpenAd.load(
      adUnitId: AdIds.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          if (kDebugMode) {
            developer.log('AppOpen ad loaded.', name: 'AdService');
          }
          _appOpenAd = ad;
          _isAppOpenAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            developer.log('AppOpen ad failed to load: $error', name: 'AdService');
          }
          _appOpenAd = null;
          _isAppOpenAdLoading = false;
        },
      ),
    );
  }

  /// 광고를 표시할지 결정하고, 필요 시 광고를 보여줍니다.
  /// 광고가 표시되면 true, 아니면 false를 반환합니다.
  Future<bool> showAdIfNeeded(Function onAdDismissed) async {
    // 프리미엄(라이트 이상) 결제 유저인 경우 광고를 표시하지 않습니다.
    if (PurchaseService.instance.isLite) {
      onAdDismissed();
      return false;
    }

    if (await _skipInterstitialForFirstLaunch()) {
      onAdDismissed();
      return false;
    }

    _calculateClickCount++;
    await _saveCalculateClickCount();
    if (kDebugMode) {
      developer.log(
        'showAdIfNeeded called. Click count: $_calculateClickCount',
        name: 'AdService',
      );
    }

    if ((Platform.isAndroid || Platform.isIOS) &&
        _calculateClickCount % _adFrequency == 0 &&
        _interstitialAd != null) {
      if (kDebugMode) {
        developer.log('Showing interstitial ad.', name: 'AdService');
      }
      // 광고 표시 시간을 업데이트하여 스플래시 광고와의 중복 노출을 방지합니다 (업계 표준)
      await _prefs?.setInt(_lastSplashAdShowTimeKey, DateTime.now().millisecondsSinceEpoch);
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          onAdDismissed();
          ad.dispose();
          _loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          onAdDismissed();
          ad.dispose();
          _loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
      return true; // 광고가 표시됨
    }
    if (kDebugMode) {
      developer.log('Interstitial ad not shown.', name: 'AdService');
    }
    return false; // 광고가 표시되지 않음
  }

  /// 스플래시 화면에 미리 로드된 앱 오프닝 광고를 표시합니다.
  Future<void> showSplashAd({
    required Function onAdDismissed,
    required Function onAdFailed,
  }) async {
    // 프리미엄(라이트 이상) 결제 유저인 경우 광고를 표시하지 않습니다.
    if (PurchaseService.instance.isLite) {
      onAdFailed();
      return;
    }

    if (await _skipInterstitialForFirstLaunch()) {
      if (!kDebugMode) {
        onAdFailed();
        return;
      }
    }

    final lastAdShowTimeMillis = _prefs?.getInt(_lastSplashAdShowTimeKey) ?? 0;
    final currentTimeMillis = DateTime.now().millisecondsSinceEpoch;

    // 30분 (밀리초 단위)
    const thirtyMinutesInMillis = 30 * 60 * 1000;

    // 클릭 카운트가 일정 수 이상이면 광고 표시 후 카운트를 리셋합니다 (시간 제한은 항상 적용)
    final shouldResetClickCount = _calculateClickCount >= _adFrequency;

    // 30분 이내에 광고를 본 경우, 광고를 표시하지 않습니다.
    if (currentTimeMillis - lastAdShowTimeMillis < thirtyMinutesInMillis) {
      if (kDebugMode) {
        developer.log(
          '스플래시 광고: 마지막 광고 표시 후 30분이 지나지 않았습니다. (디버그 모드이므로 무시하고 진행)',
          name: 'AdService',
        );
      } else {
        onAdFailed();
        return;
      }
    }

    // 미리 로드된 광고가 있는지 확인합니다.
    if ((Platform.isAndroid || Platform.isIOS) && _appOpenAd != null) {
      if (kDebugMode) {
        developer.log('미리 로드된 스플래시 앱 오프닝 광고를 표시합니다.', name: 'AdService');
      }
      // 광고 표시 시간을 지금으로 기록합니다.
      await _prefs?.setInt(_lastSplashAdShowTimeKey, currentTimeMillis);

      // 광고 표시 후 클릭 카운트를 리셋합니다.
      if (shouldResetClickCount) {
        _calculateClickCount = 0;
        await _saveCalculateClickCount();
      }

      _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          onAdDismissed(); // 광고가 닫히면 콜백 실행
          ad.dispose();
          _appOpenAd = null;
          _loadAppOpenAd(); // 다음 광고를 미리 로드합니다.
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          if (kDebugMode) {
            developer.log('스플래시 앱 오프닝 광고 표시에 실패했습니다: $error', name: 'AdService');
          }
          onAdFailed(); // 광고 표시에 실패하면 콜백 실행
          ad.dispose();
          _appOpenAd = null;
          _loadAppOpenAd(); // 다음 광고를 미리 로드합니다.
        },
      );
      await _showAppOpenWithTimeout(_appOpenAd!, () => onAdFailed());
    } else {
      // 광고가 아직 로드되지 않은 경우, 바로 onAdFailed를 호출합니다.
      if (kDebugMode) {
        developer.log('스플래시 광고: 미리 로드된 앱 오프닝 광고가 없습니다.', name: 'AdService');
      }
      onAdFailed();
    }
  }

  Future<void> _showAppOpenWithTimeout(
    AppOpenAd ad,
    void Function() onGiveUp, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      await ad.show().timeout(timeout, onTimeout: onGiveUp);
    } catch (_) {
      onGiveUp();
    }
  }

  /// 주어진 광고 단위 ID로 스플래시 앱 오프닝 광고를 표시합니다.
  /// 미리 로드된 광고가 있으면 즉시 표시하고, 없으면 새로 로드합니다.
  /// `timeout` 내에 로드되지 않으면 `onAdFailed`가 호출됩니다.
  Future<void> loadAndShowSplashAd({
    required String adUnitId,
    required Function onAdDismissed,
    required Function onAdFailed,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    // 프리미엄(라이트 이상) 결제 유저인 경우 광고를 표시하지 않습니다.
    if (PurchaseService.instance.isLite) {
      onAdFailed();
      return;
    }

    if (!(Platform.isAndroid || Platform.isIOS)) {
      onAdFailed();
      return;
    }

    if (await _skipInterstitialForFirstLaunch()) {
      if (!kDebugMode) {
        onAdFailed();
        return;
      }
    }

    final lastAdShowTimeMillis = _prefs?.getInt(_lastSplashAdShowTimeKey) ?? 0;
    final currentTimeMillis = DateTime.now().millisecondsSinceEpoch;
    const thirtyMinutesInMillis = 30 * 60 * 1000;

    final shouldResetClickCount = _calculateClickCount >= _adFrequency;

    if (currentTimeMillis - lastAdShowTimeMillis < thirtyMinutesInMillis) {
      if (kDebugMode) {
        print('스플래시 광고 로드: 30분 규칙 때문에 표시하지 않습니다. (디버그 모드이므로 무시하고 진행)');
      } else {
        onAdFailed();
        return;
      }
    }

    // 미리 로드된 광고가 있으면 즉시 표시
    if (_appOpenAd != null) {
      if (kDebugMode) {
        print('미리 로드된 스플래시 앱 오프닝 광고를 즉시 표시합니다.');
      }
      try {
        await _prefs?.setInt(_lastSplashAdShowTimeKey, currentTimeMillis);
      } on Exception catch (e) {
        if (kDebugMode) {
          print('Failed to save splash ad show time: $e');
        }
      }

      if (shouldResetClickCount) {
        _calculateClickCount = 0;
        await _saveCalculateClickCount();
      }

      _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          try {
            ad.dispose();
          } on Exception catch (_) {}
          _appOpenAd = null;
          _loadAppOpenAd();
          onAdDismissed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          try {
            ad.dispose();
          } on Exception catch (_) {}
          _appOpenAd = null;
          _loadAppOpenAd();
          onAdFailed();
        },
      );

      await _showAppOpenWithTimeout(_appOpenAd!, () => onAdFailed());
      return;
    }

    // 미리 로드된 광고가 없으면 새로 로드 시도
    if (kDebugMode) {
      developer.log('미리 로드된 앱 오프닝 광고가 없어 새로 로드합니다.', name: 'AdService');
    }
    final completer = Completer<void>();
    Timer? timer;
    AppOpenAd? loadedAd;

    void cleanupAndFail([String? reason]) {
      timer?.cancel();
      if (loadedAd != null) {
        try {
          loadedAd!.dispose();
        } on Exception catch (_) {}
        loadedAd = null;
      }
      if (!completer.isCompleted) {
        completer.complete();
      }
      onAdFailed();
      if (kDebugMode && reason != null) {
        developer.log('loadAndShowSplashAd (AppOpen) failed: $reason', name: 'AdService');
      }
    }

    timer = Timer(timeout, () {
      cleanupAndFail('timeout');
    });

    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) async {
          timer?.cancel();
          loadedAd = ad;
          try {
            await _prefs?.setInt(_lastSplashAdShowTimeKey, currentTimeMillis);
          } on Exception catch (_) {}

          if (shouldResetClickCount) {
            _calculateClickCount = 0;
            await _saveCalculateClickCount();
          }

          loadedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              try {
                ad.dispose();
              } on Exception catch (_) {}
              _loadAppOpenAd();
              onAdDismissed();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              try {
                ad.dispose();
              } on Exception catch (_) {}
              _loadAppOpenAd();
              onAdFailed();
            },
          );

          await loadedAd!.show();
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToLoad: (error) {
          cleanupAndFail(error.message);
        },
      ),
    );

    return completer.future;
  }

  Future<void> _loadCalculateClickCount() async {
    _calculateClickCount = _prefs?.getInt(_clickCountKey) ?? 0;
  }

  Future<void> _saveCalculateClickCount() async {
    await _prefs?.setInt(_clickCountKey, _calculateClickCount);
  }
}

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:void_of_course/features/ads/services/ad_ids.dart';
import 'package:void_of_course/features/premium/services/purchase_service.dart';

class NativeAdService extends ChangeNotifier {
  static final NativeAdService _instance = NativeAdService._internal();
  factory NativeAdService() => _instance;
  NativeAdService._internal() {
    PurchaseService.instance.addListener(_onPurchaseChanged);
  }

  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  NativeAd? get nativeAd => _nativeAd;
  bool get isAdLoaded => _isAdLoaded;

  void loadAd() {
    if (PurchaseService.instance.isLite) {
      // 프리미엄 결제 유저인 경우 네이티브 광고를 로드하지 않습니다.
      return;
    }

    _nativeAd = NativeAd(
      adUnitId: AdIds.nativeAd,
      request: const AdRequest(),
      factoryId: 'listTile',
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (PurchaseService.instance.isLite) {
            // 결제 상태가 확인되었는데 광고가 뒤늦게 로드된 경우 즉시 파기
            ad.dispose();
            _isAdLoaded = false;
            notifyListeners();
            return;
          }
          _nativeAd = ad as NativeAd;
          _isAdLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isAdLoaded = false;
          notifyListeners();
        },
      ),
    );
    _nativeAd?.load();
  }

  void dispose() {
    _nativeAd?.dispose();
    _isAdLoaded = false;
    PurchaseService.instance.removeListener(_onPurchaseChanged);
    super.dispose();
  }

  void _onPurchaseChanged() {
    if (PurchaseService.instance.isLite) {
      if (_nativeAd != null) {
        _nativeAd?.dispose();
        _nativeAd = null;
      }
      _isAdLoaded = false;
      notifyListeners();
    }
  }
}

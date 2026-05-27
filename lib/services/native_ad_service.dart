import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:void_of_course/services/ad_ids.dart';
import 'package:void_of_course/services/purchase_service.dart';

class NativeAdService extends ChangeNotifier {
  static final NativeAdService _instance = NativeAdService._internal();
  factory NativeAdService() => _instance;
  NativeAdService._internal();

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

  @override
  void dispose() {
    _nativeAd?.dispose();
    _isAdLoaded = false;
    super.dispose();
  }
}

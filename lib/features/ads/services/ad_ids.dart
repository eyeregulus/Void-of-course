import 'package:flutter/foundation.dart';

/// Centralized ad unit id manager.
/// Use `AdIds.interstitial`, `AdIds.banner`, `AdIds.nativeAd` to get
/// the appropriate id for debug (test) or release (production).
class AdIds {
  // Interstitial (splash / full-screen)
  static String get interstitial => kDebugMode
      ? 'ca-app-pub-3940256099942544/1033173712' // Google test interstitial
      : 'ca-app-pub-7332476431820224/2876868409'; // production interstitial

  // Banner
  static String get banner => kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111' // Google test banner
      : 'ca-app-pub-7332476431820224/6217062207'; // production banner

  // Native
  static String get nativeAd => kDebugMode
      ? 'ca-app-pub-3940256099942544/2247696110' // Google test native
      : 'ca-app-pub-7332476431820224/3843192065'; // production native
}

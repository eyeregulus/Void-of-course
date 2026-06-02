
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:void_of_course/features/ads/services/native_ad_service.dart';

class ReusableNativeAdWidget extends StatefulWidget {
  const ReusableNativeAdWidget({super.key});

  @override
  State<ReusableNativeAdWidget> createState() => _ReusableNativeAdWidgetState();
}

class _ReusableNativeAdWidgetState extends State<ReusableNativeAdWidget> {
  final NativeAdService _nativeAdService = NativeAdService();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _nativeAdService,
      builder: (context, child) {
        if (_nativeAdService.isAdLoaded && _nativeAdService.nativeAd != null) {
          return ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 320, // Ad-Loader says minimum width is 320.
              minHeight: 100, // Minimum height for this template.
              maxWidth: 400,
              maxHeight: 150,
            ),
            child: AdWidget(ad: _nativeAdService.nativeAd!),
          );
        } else {
          return const SizedBox.shrink(); // Return an empty box if the ad is not loaded.
        }
      },
    );
  }
}

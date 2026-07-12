// 이 파일은 프리미엄 서비스 해금 팝업을 만드는 코드예요.
// 세 가지 결제 티어를 보여주고, 선택된 티어에 맞는 버튼을 표시해요.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:void_of_course/features/premium/services/purchase_service.dart';
import 'package:void_of_course/core/widgets/app_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:void_of_course/core/utils/app_analytics.dart';
import 'package:void_of_course/features/premium/widgets/premium_info_carousel.dart';

// 결제 티어를 나타내는 열거형이에요.
enum PremiumTier {
  lite, // 광고 제거
  plus, // 위젯 + 캘린더
  pro, // 전체 해금 (추천)
}

// 각 티어의 정보를 담는 모델이에요.
class _TierInfo {
  final PremiumTier tier;
  final String label;
  final String price;
  final bool recommended;

  const _TierInfo({
    required this.tier,
    required this.label,
    required this.price,
    this.recommended = false,
  });
}

// 프리미엄 팝업 다이얼로그 위젯이에요.
class PremiumDialog extends StatefulWidget {
  const PremiumDialog({super.key});

  @override
  State<PremiumDialog> createState() => _PremiumDialogState();
}

class _PremiumDialogState extends State<PremiumDialog>
    with TickerProviderStateMixin {
  // 기본 선택 티어는 마스터 올인원(추천)이에요.
  PremiumTier _selectedTier = PremiumTier.pro;

  late final AnimationController _shimmerController;

  bool _hasSeenPremiumInfo = true;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool _isPurchasing = false;

  // 기본 가격 및 티어 정보 매핑
  // 실제 RevenueCat 패키지 식별자(Identifier)와 일치해야 합니다.
  static const Map<PremiumTier, String> _tierPackageIds = {
    PremiumTier.lite: 'lite_lifetime',
    PremiumTier.plus: 'plus_lifetime',
    PremiumTier.pro: 'pro_lifetime',
  };

  List<_TierInfo> _getDefaultTiers(bool isKo) {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    return [
      _TierInfo(
        tier: PremiumTier.lite,
        label: isKo ? 'LITE - 광고제거' : 'LITE - Remove ads',
        price: '\$4.99',
      ),
      _TierInfo(
        tier: PremiumTier.plus,
        label: isKo ? 'PLUS - 위젯 + 캘린더' : 'PLUS - Widget + Calendar',
        price: isAndroid ? '\$16.99' : '\$19.99',
      ),
      _TierInfo(
        tier: PremiumTier.pro,
        label:
            isKo
                ? 'PRO - 광고제거\n+ 위젯 + 캘린더'
                : 'PRO - Remove ads + Widget + Calendar',
        price: isAndroid ? '\$19.99' : '\$24.99',
        recommended: true,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkFirstTimeInfo();
  }

  Future<void> _checkFirstTimeInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_premium_info_1_2') ?? false;
    if (mounted) {
      setState(() {
        _hasSeenPremiumInfo = hasSeen;
      });
    }
  }

  Future<void> _markInfoSeen() async {
    if (!_hasSeenPremiumInfo) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_premium_info_1_2', true);
      setState(() {
        _hasSeenPremiumInfo = true;
      });
    }
  }



  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // RevenueCat 오퍼링에서 해당 티어의 패키지를 찾습니다.
  Package? _getPackageForTier(PremiumTier tier, Offerings? offerings) {
    if (offerings == null) return null;

    // RevenueCat 대시보드에서 설정된 'main_offering' 또는 식별자 'ofrng5f35ae8b2b'
    // 혹은 기본 current 중 유효한 것을 사용합니다.
    final offering =
        offerings.all['ofrng5f35ae8b2b'] ??
        offerings.all['main_offering'] ??
        offerings.current;

    if (offering == null) return null;

    final packageId = _tierPackageIds[tier];
    try {
      return offering.availablePackages.firstWhere(
        (p) => p.identifier == packageId,
      );
    } catch (_) {
      return null;
    }
  }



  // 현재 선택된 티어의 정보를 가져와요. (RevenueCat에서 불러온 실제 가격 반영)
  _TierInfo _getDynamicTierInfo(
    PremiumTier tier,
    Offerings? offerings,
    bool isKo,
  ) {
    final defaultInfo = _getDefaultTiers(
      isKo,
    ).firstWhere((t) => t.tier == tier);
    final package = _getPackageForTier(tier, offerings);
    if (package != null) {
      return _TierInfo(
        tier: defaultInfo.tier,
        label: defaultInfo.label,
        // RevenueCat의 스토어 지역 가격(priceString) 대신, 대표님이 요청하신 언어별 고정 가격을 강제로 보여줍니다.
        price: defaultInfo.price,
        recommended: defaultInfo.recommended,
      );
    }
    return defaultInfo;
  }

  _TierInfo _getSelectedTierInfo(Offerings? offerings, bool isKo) =>
      _getDynamicTierInfo(_selectedTier, offerings, isKo);

  Future<void> _handlePurchase(Package package, bool isKo) async {
    AppAnalytics.logPremiumPurchase(_selectedTier.name);
    setState(() => _isPurchasing = true);

    final success = await PurchaseService.instance.purchasePackage(package);

    if (!mounted) return;
    setState(() => _isPurchasing = false);

    if (success) {
      Navigator.of(context).pop();
      AppSnackBar.show(
        context,
        message:
            isKo
                ? '프리미엄 결제가 완료되었습니다. 감사합니다!'
                : 'Premium purchase completed. Thank you!',
      );
    } else {
      AppSnackBar.show(
        context,
        message:
            isKo
                ? '결제를 취소했거나 오류가 발생했습니다.'
                : 'Purchase cancelled or an error occurred.',
      );
    }
  }

  Future<void> _handleRestore(bool isKo) async {
    AppAnalytics.logPremiumRestore();
    setState(() => _isPurchasing = true);

    final success = await PurchaseService.instance.restorePurchases();

    if (!mounted) return;
    setState(() => _isPurchasing = false);

    if (success) {
      Navigator.of(context).pop();
      AppSnackBar.show(
        context,
        message:
            isKo ? '구매 내역 복원 처리가 완료되었습니다.' : 'Purchases restored successfully.',
      );
    } else {
      AppSnackBar.show(
        context,
        message: isKo ? '복원에 실패했습니다.' : 'Failed to restore purchases.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';

    // 다이얼로그 배경색
    final dialogBg = isDark ? const Color(0xFF1E1B2E) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1333);
    final subtitleColor =
        isDark ? const Color(0xFFBBBBBB) : const Color(0xFF666666);

    return Consumer<PurchaseService>(
      builder: (context, purchaseService, child) {
        final offerings = purchaseService.offerings;
        final selectedInfo = _getSelectedTierInfo(offerings, isKo);
        final selectedPackage = _getPackageForTier(_selectedTier, offerings);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 40,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: dialogBg,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── 상단 헤더 (그라데이션 배너) ────────────────────────────
                    _buildHeader(isDark, isKo),

                    // ── 티어 선택 목록 ────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        children:
                            _getDefaultTiers(isKo).map((baseInfo) {
                              final dynamicInfo = _getDynamicTierInfo(
                                baseInfo.tier,
                                offerings,
                                isKo,
                              );
                              return _buildTierRow(
                                dynamicInfo,
                                titleColor,
                                subtitleColor,
                                isDark,
                                purchaseService,
                                isKo,
                              );
                            }).toList(),
                      ),
                    ),

                    // ── 구매 버튼 ─────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: _buildPurchaseButton(
                        selectedInfo,
                        selectedPackage,
                        isKo,
                        offerings,
                        purchaseService,
                      ),
                    ),

                    // ── 구매 복원 버튼 ───────────────────────────────────────
                    TextButton(
                      onPressed:
                          _isPurchasing ? null : () => _handleRestore(isKo),
                      child: Text(
                        isKo
                            ? '이미 구매하셨나요? 구매 내역 복원'
                            : 'Already purchased? Restore purchases',
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),

                if (_isPurchasing)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 상단 헤더 위젯이에요.
  Widget _buildHeader(bool isDark, bool isKo) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isDark
                      ? [
                        const Color.fromARGB(255, 0, 0, 0),
                        const Color(0xFF1A1040),
                      ]
                      : [
                        const Color.fromARGB(255, 0, 0, 0),
                        const Color.fromARGB(255, 0, 0, 0),
                      ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Text(
                isKo ? '프리미엄 서비스' : 'Premium Service',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 24,
          right: 20,
          child: GestureDetector(
            onTap: () {
              AppAnalytics.logPremiumInfoButtonClick();
              _markInfoSeen();
              showPremiumInfoCarousel(context, isKo);
            },
            child:
                _hasSeenPremiumInfo
                    ? const Icon(
                      Icons.info_outline,
                      color: Colors.white70,
                      size: 24,
                    )
                    : ScaleTransition(
                      scale: _pulseAnimation,
                      child: const Icon(
                        Icons.info,
                        color: Colors.amber,
                        size: 28,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  // 각 티어 행을 만드는 위젯이에요.
  Widget _buildTierRow(
    _TierInfo info,
    Color titleColor,
    Color subtitleColor,
    bool isDark,
    PurchaseService purchaseService,
    bool isKo,
  ) {
    final isSelected = _selectedTier == info.tier;
    final isRecommended = info.recommended;

    bool isOwned = false;
    if (info.tier == PremiumTier.pro) {
      isOwned = purchaseService.isPro;
    } else if (info.tier == PremiumTier.plus) {
      isOwned = purchaseService.isPlus;
    } else if (info.tier == PremiumTier.lite) {
      isOwned = purchaseService.isLite;
    }

    // 골드 테두리 & 하이라이트 — 추천 티어이면서 선택된 경우
    final bool showGoldHighlight = isRecommended && isSelected;

    return GestureDetector(
      onTap: () {
        AppAnalytics.logPremiumTierSelect(info.tier.name);
        setState(() => _selectedTier = info.tier);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // 선택 상태에 따라 배경색을 다르게 해요.
          color:
              isSelected
                  ? (isDark
                      ? const Color.fromARGB(
                        255,
                        0,
                        0,
                        0,
                      ).withValues(alpha: 0.9)
                      : const Color(0xFFF5EEFF))
                  : (isDark
                      ? const Color(0xFF13102B).withValues(alpha: 0.6)
                      : const Color(0xFFF8F8F8)),
          // 주황 겉 테두리 또는 일반 테두리
          border:
              showGoldHighlight
                  ? Border.all(color: const Color(0xFFFFA500), width: 2.2)
                  : isSelected
                  ? Border.all(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    width: 1.8,
                  )
                  : Border.all(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.grey.withValues(alpha: 0.2),
                    width: 1.2,
                  ),
          // 노랑 그림자
          boxShadow:
              showGoldHighlight
                  ? [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                  : [],
        ),
        child: Row(
          children: [
            // 라디오 버튼 역할을 하는 동그라미
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected
                          ? (isRecommended
                              ? const Color.fromARGB(255, 0, 0, 0)
                              : const Color.fromARGB(255, 0, 0, 0))
                          : Colors.grey.withValues(alpha: 0.5),
                  width: 2,
                ),
                color:
                    isSelected
                        ? (isRecommended
                            ? const Color.fromARGB(255, 0, 0, 0)
                            : const Color.fromARGB(255, 0, 0, 0))
                        : Colors.transparent,
              ),
              child:
                  isSelected
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : null,
            ),
            const SizedBox(width: 12),
            // 티어 이름 + 추천 뱃지
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          info.label,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 가격 (보유중이면 가격 대신 뱃지와 체크 표시)
            isOwned
                ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: Text(
                        isKo ? '보유중' : 'Owned',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                  ],
                )
                : Text(
                  info.price,
                  style: TextStyle(
                    color:
                        isSelected
                            ? (isRecommended
                                ? const Color.fromARGB(255, 0, 0, 0)
                                : const Color.fromARGB(255, 0, 0, 0))
                            : subtitleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          ],
        ),
      ),
    );
  }

  // 구매 버튼이에요. 선택된 티어의 가격을 보여줘요.
  Widget _buildPurchaseButton(
    _TierInfo info,
    Package? package,
    bool isKo,
    Offerings? offerings,
    PurchaseService purchaseService,
  ) {
    final isGold = info.recommended;

    bool isOwned = false;
    if (info.tier == PremiumTier.pro) {
      isOwned = purchaseService.isPro;
    } else if (info.tier == PremiumTier.plus) {
      isOwned = purchaseService.isPlus;
    } else if (info.tier == PremiumTier.lite) {
      isOwned = purchaseService.isLite;
    }

    if (isOwned) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              isKo ? '이미 보유 중인 서비스입니다' : 'Already Owned',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors:
                isGold
                    ? [
                      const Color.fromARGB(255, 0, 0, 0),
                      const Color.fromARGB(255, 0, 0, 0),
                    ]
                    : [
                      const Color.fromARGB(255, 0, 0, 0),
                      const Color.fromARGB(255, 0, 0, 0),
                    ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isGold
                      ? const Color.fromARGB(255, 0, 0, 0)
                      : const Color.fromARGB(255, 0, 0, 0))
                  .withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap:
                (_isPurchasing || package == null)
                    ? () {
                      // 상품 정보를 가져오지 못했을 때의 처리
                      if (package == null) {
                        AppSnackBar.show(
                          context,
                          message: purchaseService.lastError ?? (
                              isKo
                                  ? '상품 정보를 불러오지 못했습니다. 스토어 연결 상태를 확인해주세요.'
                                  : 'Failed to load product info. Please check your store connection.'),
                        );
                      }
                    }
                    : () => _handlePurchase(package, isKo),
            child: Center(
              child: Text(
                package == null
                    ? (purchaseService.lastError != null
                        ? (isKo ? '에러 발생 (클릭하여 확인)' : 'Error (Tap to view)')
                        : (isKo ? '상품 정보 불러오는 중...' : 'Loading product info...'))
                    : (isKo
                        ? '${info.price}에 평생 소장하기'
                        : 'Get lifetime access for ${info.price}'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 팝업을 띄우는 편의 함수예요.
Future<void> showPremiumDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => const PremiumDialog(),
  );
}

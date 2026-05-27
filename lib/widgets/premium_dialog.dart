// 이 파일은 프리미엄 서비스 해금 팝업을 만드는 코드예요.
// 세 가지 결제 티어를 보여주고, 선택된 티어에 맞는 버튼을 표시해요.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/purchase_service.dart';
import '../widgets/app_snackbar.dart';

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
    with SingleTickerProviderStateMixin {
  // 기본 선택 티어는 마스터 올인원(추천)이에요.
  PremiumTier _selectedTier = PremiumTier.pro;

  late final AnimationController _shimmerController;
  bool _isPurchasing = false;

  // 기본 가격 및 티어 정보 매핑
  // 실제 RevenueCat 패키지 식별자(Identifier)와 일치해야 합니다.
  static const Map<PremiumTier, String> _tierPackageIds = {
    PremiumTier.lite: 'lite',
    PremiumTier.plus: 'plus',
    PremiumTier.pro: 'pro',
  };

  List<_TierInfo> _getDefaultTiers(bool isKo) {
    return [
      _TierInfo(
        tier: PremiumTier.lite,
        label: isKo ? '라이트 - 광고제거' : 'Lite - Ad Removal',
        price: '\$4.99',
      ),
      _TierInfo(
        tier: PremiumTier.plus,
        label:
            isKo
                ? '플러스 - 바탕화면 위젯 \n+ 보이드 구글 캘린더'
                : 'Plus - Home Widget \n+ Void Google Calendar',
        price: '\$16.99',
      ),
      _TierInfo(
        tier: PremiumTier.pro,
        label:
            isKo
                ? '프로 - 전체기능 \n(광고제거 + 위젯 + 캘린더)'
                : 'Pro - All Features \n(Ad Removal + Widget + Calendar)',
        price: '\$19.99',
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
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  // RevenueCat 오퍼링에서 해당 티어의 패키지를 찾습니다.
  Package? _getPackageForTier(PremiumTier tier, Offerings? offerings) {
    if (offerings == null || offerings.current == null) return null;
    final packageId = _tierPackageIds[tier];
    try {
      return offerings.current!.availablePackages.firstWhere(
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
        price: package.storeProduct.priceString, // 앱스토어/플레이스토어 실제 표기 가격
        recommended: defaultInfo.recommended,
      );
    }
    return defaultInfo;
  }

  _TierInfo _getSelectedTierInfo(Offerings? offerings, bool isKo) =>
      _getDynamicTierInfo(_selectedTier, offerings, isKo);

  Future<void> _handlePurchase(Package package, bool isKo) async {
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
    return Container(
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
          const SizedBox(height: 6),
          Text(
            isKo
                ? '한 번 결제로 평생 광고 없이 영구 소장!'
                : 'Lifetime access with a single purchase!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // 각 티어 행을 만드는 위젯이에요.
  Widget _buildTierRow(
    _TierInfo info,
    Color titleColor,
    Color subtitleColor,
    bool isDark,
  ) {
    final isSelected = _selectedTier == info.tier;
    final isRecommended = info.recommended;

    // 골드 테두리 & 하이라이트 — 추천 티어이면서 선택된 경우
    final bool showGoldHighlight = isRecommended && isSelected;

    return GestureDetector(
      onTap: () => setState(() => _selectedTier = info.tier),
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          // shimmer gradient offset
          final shimmerOffset = _shimmerController.value;

          return Container(
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
              // 골드 shimmer 테두리 또는 일반 테두리
              border:
                  showGoldHighlight
                      ? Border.all(
                        color:
                            Color.lerp(
                              const Color(0xFFFFD700),
                              const Color(0xFFFFA500),
                              (shimmerOffset * 2).clamp(0.0, 1.0),
                            )!,
                        width: 2.2,
                      )
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
              // 추천+선택 시 골드 글로우 그림자
              boxShadow:
                  showGoldHighlight
                      ? [
                        BoxShadow(
                          color: const Color(
                            0xFFFFD700,
                          ).withValues(alpha: 0.25),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                      : [],
            ),
            child: child,
          );
        },
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
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '★ 추천',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 가격
            Text(
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
  Widget _buildPurchaseButton(_TierInfo info, Package? package, bool isKo) {
    final isGold = info.recommended;

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
                          message:
                              isKo
                                  ? '상품 정보를 불러오지 못했습니다. 스토어 연결 상태를 확인해주세요.'
                                  : 'Failed to load product info. Please check your store connection.',
                        );
                      }
                    }
                    : () => _handlePurchase(package, isKo),
            child: Center(
              child: Text(
                package == null
                    ? (isKo ? '상품 정보 불러오는 중...' : 'Loading product info...')
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

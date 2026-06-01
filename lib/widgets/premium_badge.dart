import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/purchase_service.dart';

class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PurchaseService>(
      builder: (context, purchaseService, child) {
        if (!purchaseService.isPro &&
            !purchaseService.isPlus &&
            !purchaseService.isLite) {
          return const SizedBox.shrink();
        }

        final isPro = purchaseService.isPro;
        final isPlus = purchaseService.isPlus;

        final gradient = isPro
            ? const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              )
            : isPlus
                ? const LinearGradient(
                    colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                  )
                : const LinearGradient(
                    colors: [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
                  );

        final shadows = isPro
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : <BoxShadow>[];

        final text = isPro ? 'PRO' : isPlus ? 'PLUS' : 'LITE';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(6),
            boxShadow: shadows,
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        );
      },
    );
  }
}

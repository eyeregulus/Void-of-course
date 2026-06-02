import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseService extends ChangeNotifier {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  // TODO: RevenueCat 대시보드에서 발급받은 API 키로 변경해주세요.
  // static const String _appleApiKey = 'goog_YOUR_APPLE_API_KEY';
  static const String _googleApiKey = 'goog_aDuTsOqaJNZcWsTxPsJsnChRfYb';

  // Entitlements (RevenueCat 대시보드의 Entitlements ID와 정확히 일치해야 합니다)
  static const String entitlementLite = 'lite';
  static const String entitlementPlus = 'plus';
  static const String entitlementPro = 'pro';

  // 상태 관리
  bool _isLite = false;
  bool _isPlus = false;
  bool _isPro = false;
  String _debugActiveEntitlements = '';
  Offerings? _offerings;

  bool get isLite => _isLite;
  bool get isPlus => _isPlus;
  bool get isPro => _isPro;
  String get debugActiveEntitlements => _debugActiveEntitlements;

  bool get isPremiumUser => _isPlus;

  Offerings? get offerings => _offerings;

  String? _lastError;
  String? get lastError => _lastError;

  Future<void> init() async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration;
    if (defaultTargetPlatform == TargetPlatform.android) {
      configuration = PurchasesConfiguration(_googleApiKey);
    } else {
      // TODO: Apple API Key 추가 후 코드 복원
      return;
    }

    await Purchases.configure(configuration);

    // 구매 정보 업데이트 리스너 등록
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      _updateStatus(customerInfo);
    });

    // 초기 상태 불러오기 및 재설치 유저 자동 복원
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRestored = prefs.getBool('has_auto_restored_purchases') ?? false;

      // 안드로이드의 경우 첫 실행 시 자동으로 구매 내역을 스토어에서 복원 (재설치 시 프리미엄 유지)
      if (!hasRestored && defaultTargetPlatform == TargetPlatform.android) {
        if (kDebugMode)
          developer.log('Auto restoring purchases on first launch...');
        try {
          await Purchases.restorePurchases();
        } catch (restoreError) {
          developer.log(
            'Auto restore failed (e.g. pending payment), but continuing...',
            error: restoreError,
          );
        }
        await prefs.setBool('has_auto_restored_purchases', true);
      }

      final customerInfo = await Purchases.getCustomerInfo();
      _updateStatus(customerInfo);
      await fetchOfferings();
    } catch (e) {
      developer.log('Failed to fetch initial customer info', error: e);
    }
  }

  void _updateStatus(CustomerInfo customerInfo) {
    // 1. Entitlement 기준으로 확인 (정석)
    bool hasLiteEntitlement =
        customerInfo.entitlements.all[entitlementLite]?.isActive ?? false;
    bool hasPlusEntitlement =
        customerInfo.entitlements.all[entitlementPlus]?.isActive ?? false;
    bool hasProEntitlement =
        customerInfo.entitlements.all[entitlementPro]?.isActive ?? false;

    // 2. Product ID 직접 구매 내역 기준으로 확인 (Entitlement 연결 누락 대비 백업)
    final purchased = customerInfo.allPurchasedProductIdentifiers;
    bool hasLiteProduct = purchased.contains('lite');
    bool hasPlusProduct = purchased.contains('plus');
    bool hasProProduct = purchased.contains('pro');

    bool hasLite = hasLiteEntitlement || hasLiteProduct;
    bool hasPlus = hasPlusEntitlement || hasPlusProduct;
    bool hasPro = hasProEntitlement || hasProProduct;

    // 프로 패스는 모든 기능을 포함합니다.
    _isPro = hasPro;
    _isLite = hasLite || hasPro;
    _isPlus = hasPlus || hasPro;

    // 디버그용: 활성화된 모든 Entitlement ID 추출
    final activeIds =
        customerInfo.entitlements.all.values
            .where((e) => e.isActive)
            .map((e) => e.identifier)
            .toList();

    // 만약 Entitlement가 비어있다면, Product ID라도 샀는지 확인 (Entitlement 연결 누락 디버깅용)
    if (activeIds.isEmpty &&
        customerInfo.allPurchasedProductIdentifiers.isNotEmpty) {
      _debugActiveEntitlements =
          'PROD: ${customerInfo.allPurchasedProductIdentifiers.join(', ')}';
    } else {
      _debugActiveEntitlements = activeIds.join(', ');
    }

    notifyListeners();
  }

  Future<void> fetchOfferings() async {
    try {
      _lastError = null;
      _offerings = await Purchases.getOfferings();
      if (_offerings != null && _offerings!.current != null) {
        if (kDebugMode) {
          developer.log(
            'Current Offering ID: ${_offerings!.current!.identifier}',
            name: 'PurchaseService',
          );
          developer.log(
            'Available Packages: ${_offerings!.current!.availablePackages.map((p) => p.identifier).toList()}',
            name: 'PurchaseService',
          );
        }
      } else {
        if (kDebugMode) {
          developer.log(
            'Offerings or current offering is null',
            name: 'PurchaseService',
          );
        }
        _lastError = '등록된 상품(Offerings)이 없거나 불러올 수 없습니다.';
      }
      notifyListeners();
    } on PlatformException catch (e) {
      _lastError = 'Platform Error: ${e.message} (${e.code})';
      if (kDebugMode) {
        developer.log('Failed to fetch offerings: $e', name: 'PurchaseService');
      }
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      if (kDebugMode) {
        developer.log('Failed to fetch offerings: $e', name: 'PurchaseService');
      }
      notifyListeners();
    }
  }

  Future<bool> purchasePackage(Package package) async {
    try {
      // Purchases.purchasePackage는 이제 PurchaseResult 객체를 반환합니다.
      final result = await Purchases.purchasePackage(package);
      _updateStatus(result.customerInfo);
      return true;
    } catch (e) {
      developer.log('Failed to purchase package', error: e);
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _updateStatus(customerInfo);
      return true;
    } catch (e) {
      developer.log('Failed to restore purchases', error: e);
      return false;
    }
  }
}

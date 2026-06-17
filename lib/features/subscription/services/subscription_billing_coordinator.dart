import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:health/domain/entities/subscription_entities.dart';
import 'package:health/domain/usecases/subscription/subscription_usecases.dart';
import 'package:health/features/subscription/services/play_billing_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

typedef SubscriptionPurchaseHandler = Future<void> Function(
  SubscriptionOperationResult result,
);

typedef SubscriptionPurchaseErrorHandler = void Function(String message);

/// Lắng nghe purchase stream từ Google Play và verify lên backend.
abstract final class SubscriptionBillingCoordinator {
  static PlayBillingService? _billing;
  static VerifySubscriptionPurchaseUseCase? _verify;
  static SubscriptionPurchaseHandler? _onSuccess;
  static SubscriptionPurchaseErrorHandler? _onError;
  static StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  static bool _started = false;
  static bool _reconcileRunning = false;
  static final Set<String> _processedPurchaseIds = {};
  static String? _pendingBasePlanId;

  /// Base plan ID selected before opening the Play purchase sheet.
  static void setPendingBasePlanId(String? basePlanId) {
    _pendingBasePlanId = basePlanId;
  }

  static void configure({
    required PlayBillingService billing,
    required VerifySubscriptionPurchaseUseCase verifyPurchase,
  }) {
    _billing = billing;
    _verify = verifyPurchase;
  }

  static void setHandlers({
    SubscriptionPurchaseHandler? onSuccess,
    SubscriptionPurchaseErrorHandler? onError,
  }) {
    _onSuccess = onSuccess;
    _onError = onError;
  }

  static Future<void> ensureStarted() async {
    if (_started) return;
    final billing = _billing;
    if (billing == null) return;

    _purchaseSub = billing.purchaseStream.listen(
      _handlePurchases,
      onError: (Object e) {
        _onError?.call('Lỗi thanh toán Google Play.');
        if (kDebugMode) debugPrint('SubscriptionBillingCoordinator: $e');
      },
    );
    _started = true;
  }

  /// Queries Google Play for active purchases and verifies with backend.
  /// Returns verify result without triggering UI handlers unless [notifyHandlers].
  static Future<SubscriptionOperationResult?> reconcilePlayStoreWithBackend({
    bool notifyHandlers = false,
  }) async {
    if (_reconcileRunning) return null;

    final billing = _billing;
    final verify = _verify;
    if (billing == null || verify == null) return null;
    if (!await billing.isAvailable) return null;

    _reconcileRunning = true;
    try {
      final purchases = await billing.querySubscriptionPurchases();
      if (purchases.isEmpty) return null;

      for (final purchase in purchases) {
        final token = PlayBillingService.purchaseToken(purchase);
        if (token == null || token.isEmpty) continue;
        if (_wasProcessed(purchase, token)) continue;

        final billingCycle = PlayBillingService.billingCycleFromPurchase(purchase);
        final result = await verify(
          productId: PlayBillingService.googleSubscriptionId,
          purchaseToken: token,
          billingCycle: billingCycle,
          transactionId: purchase.purchaseID,
        );

        if (result.success) {
          _rememberProcessedPurchase(purchase, token);
          if (purchase.pendingCompletePurchase) {
            await billing.completePurchase(purchase);
          }
          if (notifyHandlers) {
            await _onSuccess?.call(result);
          }
          return result;
        }
      }
    } finally {
      _reconcileRunning = false;
    }

    return null;
  }

  static void _rememberProcessedPurchase(
    PurchaseDetails purchase,
    String token,
  ) {
    final purchaseId = purchase.purchaseID ?? purchase.productID;
    _processedPurchaseIds.add('$purchaseId:$token');
  }

  static bool _wasProcessed(PurchaseDetails purchase, String token) {
    final purchaseId = purchase.purchaseID ?? purchase.productID;
    return _processedPurchaseIds.contains('$purchaseId:$token');
  }

  static Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    final billing = _billing;
    final verify = _verify;
    if (billing == null || verify == null) return;

    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.error:
          _onError?.call(
            purchase.error?.message ?? 'Thanh toán không thành công.',
          );
          continue;
        case PurchaseStatus.canceled:
          _onError?.call('Đã hủy thanh toán.');
          continue;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final token = PlayBillingService.purchaseToken(purchase);
          if (token == null || token.isEmpty) {
            _onError?.call('Không lấy được mã xác thực từ Google Play.');
            continue;
          }
          if (_wasProcessed(purchase, token)) continue;

          final basePlanId = _pendingBasePlanId;
          _pendingBasePlanId = null;

          final billingCycle = PlayBillingService.billingCycleFromBasePlanId(
            basePlanId ?? PlayBillingService.monthlyBasePlanId,
          );

          final verifyProductId =
              purchase.productID == PlayBillingService.googleSubscriptionId ||
                      purchase.productID.contains('healthpath')
                  ? PlayBillingService.googleSubscriptionId
                  : purchase.productID;

          final result = await verify(
            productId: verifyProductId,
            purchaseToken: token,
            billingCycle: billingCycle,
            transactionId: purchase.purchaseID,
          );

          if (result.success) {
            _rememberProcessedPurchase(purchase, token);
            if (purchase.pendingCompletePurchase) {
              await billing.completePurchase(purchase);
            }
            await _onSuccess?.call(result);
          } else {
            _onError?.call(result.message ?? 'Xác thực gói thất bại.');
          }
      }
    }
  }

  static Future<void> dispose() async {
    await _purchaseSub?.cancel();
    _purchaseSub = null;
    _started = false;
    _processedPurchaseIds.clear();
  }
}

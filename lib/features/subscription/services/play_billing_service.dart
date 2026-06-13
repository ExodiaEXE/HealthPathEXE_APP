import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// Gói Google Play Billing — query subscription + base plans và khởi tạo luồng mua.
class PlayBillingService {
  PlayBillingService({InAppPurchase? iap}) : _iap = iap ?? InAppPurchase.instance;

  /// Subscription product ID on Play Console (contains multiple base plans).
  static const String googleSubscriptionId = 'healthpath_subscription';

  final InAppPurchase _iap;

  Future<bool> get isAvailable async {
    if (!Platform.isAndroid) return false;
    try {
      return _iap.isAvailable();
    } catch (_) {
      return false;
    }
  }

  Future<ProductDetailsResponse> querySubscriptionProducts() {
    return _iap.queryProductDetails({googleSubscriptionId});
  }

  /// Maps Play base plan IDs (e.g. healthpath-premium-monthly) to store [ProductDetails].
  static Map<String, GooglePlayProductDetails> indexProductsByBasePlanId(
    Iterable<ProductDetails> products,
  ) {
    final indexed = <String, GooglePlayProductDetails>{};
    for (final product in products) {
      if (product is! GooglePlayProductDetails) continue;
      final basePlanId = basePlanIdOf(product);
      if (basePlanId != null && basePlanId.isNotEmpty) {
        indexed[basePlanId] = product;
      }
    }
    return indexed;
  }

  static String? basePlanIdOf(GooglePlayProductDetails details) {
    final index = details.subscriptionIndex;
    final offers = details.productDetails.subscriptionOfferDetails;
    if (index == null || offers == null || index >= offers.length) return null;
    return offers[index].basePlanId;
  }

  static String billingCycleFromBasePlanId(String basePlanId) {
    return basePlanId.contains('yearly') ? 'yearly' : 'monthly';
  }

  Future<bool> purchaseSubscription(GooglePlayProductDetails product) {
    final param = GooglePlayPurchaseParam(
      productDetails: product,
      offerToken: product.offerToken,
    );
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() => _iap.restorePurchases();

  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  Future<void> completePurchase(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);

  static String? purchaseToken(PurchaseDetails purchase) {
    final token = purchase.verificationData.serverVerificationData;
    if (token.isNotEmpty) return token;
    return purchase.verificationData.localVerificationData.isNotEmpty
        ? purchase.verificationData.localVerificationData
        : null;
  }

  void debugLog(String message) {
    if (kDebugMode) debugPrint('PlayBilling: $message');
  }
}

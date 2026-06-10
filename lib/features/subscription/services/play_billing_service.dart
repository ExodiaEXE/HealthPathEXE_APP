import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Gói Google Play Billing — query sản phẩm và khởi tạo luồng mua.
class PlayBillingService {
  PlayBillingService({InAppPurchase? iap}) : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  Future<bool> get isAvailable async {
    if (!Platform.isAndroid) return false;
    try {
      return _iap.isAvailable();
    } catch (_) {
      return false;
    }
  }

  Future<ProductDetailsResponse> queryProducts(Set<String> productIds) {
    return _iap.queryProductDetails(productIds);
  }

  Future<bool> purchase(ProductDetails product) {
    final param = PurchaseParam(productDetails: product);
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

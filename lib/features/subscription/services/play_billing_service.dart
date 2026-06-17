import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// Gói Google Play Billing — query subscription + base plans và khởi tạo luồng mua.
class PlayBillingService {
  PlayBillingService({InAppPurchase? iap}) : _iap = iap ?? InAppPurchase.instance;

  /// Subscription product ID on Play Console (contains multiple base plans).
  static const String googleSubscriptionId = 'healthpath_subscription';

  static const String monthlyBasePlanId = 'healthpath-premium-monthly';

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
  /// Prefers the standard base offer (no promotional offerId).
  static Map<String, GooglePlayProductDetails> indexProductsByBasePlanId(
    Iterable<ProductDetails> products,
  ) {
    final indexed = <String, GooglePlayProductDetails>{};
    for (final product in products) {
      if (product is! GooglePlayProductDetails) continue;
      final basePlanId = basePlanIdOf(product);
      if (basePlanId == null || basePlanId.isEmpty) continue;

      final current = indexed[basePlanId];
      if (current == null || _preferProduct(product, current)) {
        indexed[basePlanId] = product;
      }
    }
    return indexed;
  }

  static bool _preferProduct(
    GooglePlayProductDetails candidate,
    GooglePlayProductDetails existing,
  ) {
    final candidateOffer = _offerDetails(candidate);
    final existingOffer = _offerDetails(existing);
    final candidateIsBase = candidateOffer?.offerId == null ||
        candidateOffer!.offerId!.isEmpty;
    final existingIsBase =
        existingOffer?.offerId == null || existingOffer!.offerId!.isEmpty;
    if (candidateIsBase && !existingIsBase) return true;
    return false;
  }

  static SubscriptionOfferDetailsWrapper? _offerDetails(
    GooglePlayProductDetails details,
  ) {
    final index = details.subscriptionIndex;
    final offers = details.productDetails.subscriptionOfferDetails;
    if (index == null || offers == null || index >= offers.length) return null;
    return offers[index];
  }

  static GooglePlayProductDetails? pickBasePlanProduct(
    Map<String, GooglePlayProductDetails> indexed,
    String basePlanId,
  ) {
    final product = indexed[basePlanId];
    if (product == null) return null;
    final token = product.offerToken;
    if (token == null || token.isEmpty) {
      debugPrint('PlayBilling: missing offerToken for $basePlanId');
      return null;
    }
    return product;
  }

  static String? basePlanIdOf(GooglePlayProductDetails details) {
    final index = details.subscriptionIndex;
    final offers = details.productDetails.subscriptionOfferDetails;
    if (index == null || offers == null || index >= offers.length) return null;
    return offers[index].basePlanId;
  }

  static String billingCycleFromBasePlanId(String basePlanId) => 'monthly';

  Future<bool> purchaseSubscription(GooglePlayProductDetails product) {
    final param = GooglePlayPurchaseParam(
      productDetails: product,
      offerToken: product.offerToken,
    );
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  /// Returns the active Google Play subscription purchase, if any.
  Future<GooglePlayPurchaseDetails?> queryActiveSubscriptionPurchase() async {
    final purchases = await querySubscriptionPurchases();
    return purchases.isEmpty ? null : purchases.first;
  }

  /// All Google Play subscription purchases, newest first.
  Future<List<GooglePlayPurchaseDetails>> querySubscriptionPurchases() async {
    if (!Platform.isAndroid) return const [];
    try {
      final addition =
          _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await addition.queryPastPurchases();
      if (response.error != null) {
        debugLog('queryPastPurchases error: ${response.error}');
        return const [];
      }

      final purchases = response.pastPurchases
          .whereType<GooglePlayPurchaseDetails>()
          .where(
            (purchase) =>
                purchase.productID == googleSubscriptionId ||
                purchase.productID.contains('healthpath'),
          )
          .where(
            (purchase) =>
                purchase.status == PurchaseStatus.purchased ||
                purchase.status == PurchaseStatus.restored,
          )
          .toList()
        ..sort((a, b) {
          final aTime = int.tryParse(a.transactionDate ?? '') ?? 0;
          final bTime = int.tryParse(b.transactionDate ?? '') ?? 0;
          return bTime.compareTo(aTime);
        });

      return purchases;
    } catch (e) {
      debugLog('querySubscriptionPurchases failed: $e');
      return const [];
    }
  }

  static String billingCycleFromPurchase(GooglePlayPurchaseDetails purchase) =>
      'monthly';

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

  static bool isAutoRenewing(GooglePlayPurchaseDetails purchase) =>
      purchase.billingClientPurchase.isAutoRenewing;

  void debugLog(String message) {
    if (kDebugMode) debugPrint('PlayBilling: $message');
  }
}

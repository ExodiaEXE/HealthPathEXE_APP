import 'package:health/domain/entities/subscription_entities.dart';

abstract class SubscriptionRepository {
  bool get isOnline;

  Future<SubscriptionOperationResult> fetchPlans();

  Future<SubscriptionOperationResult?> fetchMySubscription();

  Future<SubscriptionOperationResult> fetchMyTransactions();

  Future<SubscriptionOperationResult> verifyPurchase({
    required String productId,
    required String purchaseToken,
    required String billingCycle,
    String? transactionId,
  });
}

import 'package:health/domain/entities/subscription_entities.dart';
import 'package:health/domain/repositories/subscription_repository.dart';

class FetchSubscriptionPlansUseCase {
  const FetchSubscriptionPlansUseCase(this._repository);

  final SubscriptionRepository _repository;

  Future<SubscriptionOperationResult> call() => _repository.fetchPlans();
}

class FetchMySubscriptionUseCase {
  const FetchMySubscriptionUseCase(this._repository);

  final SubscriptionRepository _repository;

  Future<SubscriptionOperationResult?> call() =>
      _repository.fetchMySubscription();
}

class FetchMyTransactionsUseCase {
  const FetchMyTransactionsUseCase(this._repository);

  final SubscriptionRepository _repository;

  Future<SubscriptionOperationResult> call() =>
      _repository.fetchMyTransactions();
}

class VerifySubscriptionPurchaseUseCase {
  const VerifySubscriptionPurchaseUseCase(this._repository);

  final SubscriptionRepository _repository;

  Future<SubscriptionOperationResult> call({
    required String productId,
    required String purchaseToken,
    required String billingCycle,
    String? transactionId,
  }) =>
      _repository.verifyPurchase(
        productId: productId,
        purchaseToken: purchaseToken,
        billingCycle: billingCycle,
        transactionId: transactionId,
      );
}

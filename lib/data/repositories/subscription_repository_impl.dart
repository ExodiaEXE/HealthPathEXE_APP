import 'package:health/core/network/api_client.dart';
import 'package:health/core/security/secure_storage_service.dart';
import 'package:health/domain/entities/subscription_entities.dart';
import 'package:health/domain/repositories/subscription_repository.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl({ApiClient? api, TokenStore? storage})
      : _api = api ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  final ApiClient _api;
  final TokenStore _storage;

  @override
  bool get isOnline => _api.hasBaseUrl;

  Future<ApiClient?> _authedClient() async {
    if (!isOnline) return null;
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty || token.startsWith('mock_')) {
      return null;
    }
    return _api.withBearer(token);
  }

  @override
  Future<SubscriptionOperationResult> fetchPlans() async {
    if (!isOnline) {
      return const SubscriptionOperationResult(
        success: true,
        plans: [],
        message: 'Chế độ ngoại tuyến.',
      );
    }

    try {
      final res = await _api.getJson('/api/Subscription/plans');
      if (res.json['success'] != true) {
        return SubscriptionOperationResult.fail(
          res.json['message'] as String? ?? 'Không tải được gói đăng ký.',
        );
      }
      final data = res.json['data'] as List<dynamic>? ?? [];
      final plans = data
          .map((e) => SubscriptionPlanRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      return SubscriptionOperationResult(success: true, plans: plans);
    } on ApiException catch (e) {
      return SubscriptionOperationResult.fail(e.message);
    }
  }

  @override
  Future<SubscriptionOperationResult?> fetchMySubscription() async {
    final client = await _authedClient();
    if (client == null) return null;

    try {
      final res = await client.getJson('/api/Subscription/my-subscription');
      if (res.json['success'] != true) return null;
      final data = res.json['data'];
      if (data == null) {
        return const SubscriptionOperationResult(success: true);
      }
      return SubscriptionOperationResult(
        success: true,
        subscription:
            UserSubscriptionRecord.fromJson(data as Map<String, dynamic>),
        message: res.json['message'] as String?,
      );
    } on ApiException {
      return null;
    } finally {
      client.close();
    }
  }

  @override
  Future<SubscriptionOperationResult> fetchMyTransactions() async {
    final client = await _authedClient();
    if (client == null) {
      return SubscriptionOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }

    try {
      final res = await client.getJson('/api/Subscription/my-transactions');
      if (res.json['success'] != true) {
        return SubscriptionOperationResult.fail(
          res.json['message'] as String? ?? 'Không tải được lịch sử.',
        );
      }
      final data = res.json['data'] as List<dynamic>? ?? [];
      final transactions = data
          .map((e) =>
              SubscriptionTransactionRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      return SubscriptionOperationResult(success: true, transactions: transactions);
    } on ApiException catch (e) {
      return SubscriptionOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<SubscriptionOperationResult> verifyPurchase({
    required String productId,
    required String purchaseToken,
    required String billingCycle,
    String? transactionId,
  }) async {
    if (!isOnline) {
      return SubscriptionOperationResult.fail(
        'Cần kết nối máy chủ để kích hoạt gói.',
      );
    }

    final client = await _authedClient();
    if (client == null) {
      return SubscriptionOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }

    try {
      final res = await client.postJson('/api/Subscription/verify-receipt', {
        'platform': 'GooglePlay',
        'productId': productId,
        'purchaseToken': purchaseToken,
        'billingCycle': billingCycle,
        if (transactionId != null) 'transactionId': transactionId,
      });
      if (res.json['success'] != true) {
        return SubscriptionOperationResult.fail(
          res.json['message'] as String? ?? 'Xác thực thanh toán thất bại.',
          errorCode: res.json['errorCode'] as String?,
        );
      }
      final data = res.json['data'] as Map<String, dynamic>?;
      return SubscriptionOperationResult(
        success: true,
        message: res.json['message'] as String?,
        subscription: data != null
            ? UserSubscriptionRecord.fromJson(data)
            : null,
      );
    } on ApiException catch (e) {
      return SubscriptionOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }
}

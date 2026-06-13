import 'dart:convert';

class SubscriptionPlanRecord {
  const SubscriptionPlanRecord({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.priceMonthly,
    required this.priceYearly,
    required this.currency,
    required this.features,
    this.googleProductId,
    this.appleProductId,
  });

  final String id;
  final String name;
  final String code;
  final String? description;
  final double priceMonthly;
  final double priceYearly;
  final String currency;
  final List<String> features;
  final String? googleProductId;
  final String? appleProductId;

  bool get isYearly => code.contains('yearly');

  factory SubscriptionPlanRecord.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'];
    List<String> features = const [];
    if (rawFeatures is String && rawFeatures.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawFeatures);
        if (decoded is List) {
          features = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        features = [rawFeatures];
      }
    } else if (rawFeatures is List) {
      features = rawFeatures.map((e) => e.toString()).toList();
    }

    return SubscriptionPlanRecord(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      description: json['description'] as String?,
      priceMonthly: (json['priceMonthly'] as num?)?.toDouble() ?? 0,
      priceYearly: (json['priceYearly'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'VND',
      features: features,
      googleProductId: json['googleProductId'] as String?,
      appleProductId: json['appleProductId'] as String?,
    );
  }
}

class UserSubscriptionRecord {
  const UserSubscriptionRecord({
    required this.id,
    required this.planName,
    required this.status,
    required this.billingCycle,
    required this.startedAt,
    this.expiresAt,
    this.paymentProvider,
    required this.isActive,
  });

  final String id;
  final String planName;
  final String status;
  final String billingCycle;
  final DateTime startedAt;
  final DateTime? expiresAt;
  final String? paymentProvider;
  final bool isActive;

  factory UserSubscriptionRecord.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionRecord(
      id: json['id']?.toString() ?? '',
      planName: json['planName'] as String? ?? '',
      status: json['status'] as String? ?? '',
      billingCycle: json['billingCycle'] as String? ?? 'monthly',
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      paymentProvider: json['paymentProvider'] as String?,
      isActive: json['isActiveSubscription'] == true,
    );
  }
}

class SubscriptionTransactionRecord {
  const SubscriptionTransactionRecord({
    required this.id,
    required this.planName,
    required this.platform,
    required this.status,
    required this.amount,
    required this.currency,
    required this.purchasedAt,
    this.expiresAt,
  });

  final String id;
  final String planName;
  final String platform;
  final String status;
  final double amount;
  final String currency;
  final DateTime purchasedAt;
  final DateTime? expiresAt;

  factory SubscriptionTransactionRecord.fromJson(Map<String, dynamic> json) {
    return SubscriptionTransactionRecord(
      id: json['id']?.toString() ?? '',
      planName: json['planName'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      status: json['status'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'VND',
      purchasedAt: DateTime.tryParse(json['purchasedAt'] as String? ?? '') ??
          DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
    );
  }
}

class SubscriptionOperationResult {
  const SubscriptionOperationResult({
    required this.success,
    this.message,
    this.errorCode,
    this.subscription,
    this.plans = const [],
    this.transactions = const [],
  });

  final bool success;
  final String? message;
  final String? errorCode;
  final UserSubscriptionRecord? subscription;
  final List<SubscriptionPlanRecord> plans;
  final List<SubscriptionTransactionRecord> transactions;

  factory SubscriptionOperationResult.fail(
    String message, {
    String? errorCode,
  }) =>
      SubscriptionOperationResult(
        success: false,
        message: message,
        errorCode: errorCode,
      );
}

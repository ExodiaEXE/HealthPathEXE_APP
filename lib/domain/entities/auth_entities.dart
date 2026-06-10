/// Kết quả thao tác xác thực — thuần domain, không phụ thuộc framework.
class AuthOperationResult {
  const AuthOperationResult({
    required this.success,
    this.message,
    this.errorCode,
    this.token,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.avatarUrl,
    this.isPremium = false,
    this.googleLinked = false,
    this.facebookLinked = false,
  });

  final bool success;
  final String? message;
  final String? errorCode;
  final String? token;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? avatarUrl;
  final bool isPremium;
  final bool googleLinked;
  final bool facebookLinked;

  factory AuthOperationResult.fail(String message, {String? errorCode}) =>
      AuthOperationResult(success: false, message: message, errorCode: errorCode);

  AuthOperationResult copyWith({
    bool? success,
    String? message,
    String? errorCode,
    String? token,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? avatarUrl,
    bool? isPremium,
    bool? googleLinked,
    bool? facebookLinked,
  }) {
    return AuthOperationResult(
      success: success ?? this.success,
      message: message ?? this.message,
      errorCode: errorCode ?? this.errorCode,
      token: token ?? this.token,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPremium: isPremium ?? this.isPremium,
      googleLinked: googleLinked ?? this.googleLinked,
      facebookLinked: facebookLinked ?? this.facebookLinked,
    );
  }
}

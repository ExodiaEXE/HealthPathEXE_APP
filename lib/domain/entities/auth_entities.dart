/// Kết quả thao tác xác thực — thuần domain, không phụ thuộc framework.
class AuthOperationResult {
  const AuthOperationResult({
    required this.success,
    this.message,
    this.errorCode,
    this.token,
    this.userName,
    this.userEmail,
    this.isPremium = false,
  });

  final bool success;
  final String? message;
  final String? errorCode;
  final String? token;
  final String? userName;
  final String? userEmail;
  final bool isPremium;

  factory AuthOperationResult.fail(String message, {String? errorCode}) =>
      AuthOperationResult(success: false, message: message, errorCode: errorCode);
}

/// Lọc thông báo hiển thị cho người dùng — không lộ chi tiết kỹ thuật.
abstract final class UserFacingMessage {
  static final RegExp _technicalPattern = RegExp(
    r'backend|restart\s|/api/|\bapi\b|exception|sql|hangfire|npgsql|'
    r'stack\s?trace|chi\s?tiết\s?lỗi|invalidoperation|'
    r'timeout|jwt|token|500|502|503|socket|connection|'
    r'jobstorage|efcore|postgres|nullreference|system\.',
    caseSensitive: false,
  );

  static String sanitize(
    String? message, {
    required String fallback,
  }) {
    if (message == null || message.trim().isEmpty) return fallback;
    final trimmed = message.trim();
    if (trimmed.length > 140) return fallback;
    if (_technicalPattern.hasMatch(trimmed)) return fallback;
    if (trimmed.contains('{') || trimmed.contains('}')) return fallback;
    return trimmed;
  }
}

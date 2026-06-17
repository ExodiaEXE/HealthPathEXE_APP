/// Kết quả đồng bộ plan 7 ngày lên backend.
class WeeklyPlanSyncResult {
  const WeeklyPlanSyncResult({
    required this.savedLocally,
    this.syncedTemplateCount = 0,
    this.skippedLockedDays = false,
    this.noAuth = false,
    this.offline = false,
    this.errorMessage,
    this.idRemapping = const {},
  });

  final bool savedLocally;
  final int syncedTemplateCount;
  final bool skippedLockedDays;
  final bool noAuth;
  final bool offline;
  final String? errorMessage;

  /// `custom-xxx` → UUID routine sau khi tạo trên máy chủ.
  final Map<String, String> idRemapping;

  bool get syncedToApi => syncedTemplateCount > 0;

  /// Thông báo ngắn gọn cho người dùng — không lộ chi tiết API.
  String get userMessage {
    if (!savedLocally) return 'Không lưu được routine. Vui lòng thử lại.';
    if (offline || noAuth) {
      return 'Đã lưu routine 7 ngày trên máy.';
    }
    if (syncedToApi) {
      return 'Đã lưu routine 7 ngày thành công.';
    }
    if (errorMessage != null) {
      return 'Đã lưu trên máy. Đồng bộ máy chủ thất bại, thử lại sau.';
    }
    return 'Đã lưu routine 7 ngày trên máy.';
  }
}

import 'package:health/domain/entities/companion_message.dart';

/// Nguồn phản hồi mock cho đồng hành ảo — chỉ tầng data truy cập.
abstract final class CompanionMockDataSource {
  static const quickChips = [
    CompanionQuickChip(emoji: '🌿', label: 'Thủ thỉ'),
    CompanionQuickChip(emoji: '🏠', label: 'Mở nhạc'),
    CompanionQuickChip(emoji: '📋', label: 'Cần nghỉ'),
    CompanionQuickChip(emoji: '⚙️', label: 'Tâm trạng'),
  ];

  static String greeting({String userName = 'Người dùng'}) =>
      'Chào $userName, mình là Xanh. Rất vui được gặp lại bạn! '
      'Hôm nay của bạn thế nào rồi? Có điều gì muốn chia sẻ không?';

  static Future<String> reply(String userMessage) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final lower = userMessage.toLowerCase();
    if (lower.contains('thủ thỉ') ||
        lower.contains('thu thi') ||
        lower.contains('thở') ||
        lower.contains('tho')) {
      return 'Hãy thử hít thở sâu 4 giây, giữ 4 giây, thở ra 6 giây. Lặp lại 3 lần nhé.';
    }
    if (lower.contains('nhạc') ||
        lower.contains('âm thanh') ||
        lower.contains('am thanh') ||
        lower.contains('mở nhạc')) {
      return 'Tôi gợi ý bạn nghe mục "Thiền" hoặc "Nhẹ nhàng" trong thư viện Âm thanh.';
    }
    if (lower.contains('nghỉ') ||
        lower.contains('mệt') ||
        lower.contains('met') ||
        lower.contains('cần nghỉ')) {
      return 'Hãy nghỉ 10 phút, uống nước ấm và chọn mức năng lượng "Mệt" trên Trang chủ.';
    }
    if (lower.contains('tâm trạng') || lower.contains('tam trang')) {
      return 'Bạn có thể chọn biểu cảm tâm trạng trên Trang chủ — mình sẽ gợi ý thói quen và nhạc phù hợp.';
    }
    return 'Tôi ở đây hỗ trợ bạn. Bạn có thể chọn gợi ý nhanh bên dưới hoặc mô tả cảm giác hiện tại.';
  }
}

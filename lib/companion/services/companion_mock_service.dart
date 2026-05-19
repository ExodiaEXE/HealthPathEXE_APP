import 'package:health/companion/models/companion_message.dart';

/// Mock companion replies until AI backend is ready.
class CompanionMockService {
  static const quickChips = [
    'Giup toi tho sau',
    'Goi y am thanh',
    'Toi can nghi ngoi',
    'Tam trang hom nay',
  ];

  Future<String> reply(String userMessage) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final lower = userMessage.toLowerCase();
    if (lower.contains('tho') || lower.contains('breath')) {
      return 'Hay thu hit tho sau 4 giay, giu 4 giay, tho ra 6 giay. Lap lai 3 lan nhe.';
    }
    if (lower.contains('nhac') || lower.contains('am thanh')) {
      return 'Toi goi y ban nghe muc "Thien" hoac "Nhe nhang" trong thu vien Am thanh.';
    }
    if (lower.contains('met') || lower.contains('nghi')) {
      return 'Hay nghi 10 phut, uong nuoc am va chon muc nang luong "Met" tren Trang chu.';
    }
    return 'Toi o day ho tro ban. Ban co the chon goi y nhanh ben duoi hoac mo ta cam giac hien tai.';
  }

  CompanionMessage userMessage(String text) => CompanionMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      );

  Future<CompanionMessage> assistantMessage(String userText) async {
    final replyText = await reply(userText);
    return CompanionMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_a',
      text: replyText,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }
}

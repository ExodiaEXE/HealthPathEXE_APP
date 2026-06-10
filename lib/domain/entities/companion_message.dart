/// Tin nhắn chat đồng hành — entity thuần domain.
class CompanionMessage {
  const CompanionMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
}

class CompanionQuickChip {
  const CompanionQuickChip({required this.emoji, required this.label});

  final String emoji;
  final String label;
}

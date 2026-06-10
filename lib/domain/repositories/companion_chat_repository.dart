import 'package:health/domain/entities/companion_message.dart';

abstract class CompanionChatRepository {
  String getGreeting({String userName = 'Người dùng'});
  List<CompanionQuickChip> getQuickChips();
  CompanionMessage createUserMessage(String text);
  Future<CompanionMessage> createAssistantReply(String userText);
}

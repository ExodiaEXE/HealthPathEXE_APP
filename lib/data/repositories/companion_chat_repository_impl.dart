import 'package:health/data/datasources/companion_mock_datasource.dart';
import 'package:health/domain/entities/companion_message.dart';
import 'package:health/domain/repositories/companion_chat_repository.dart';

class CompanionChatRepositoryImpl implements CompanionChatRepository {
  @override
  String getGreeting({String userName = 'Người dùng'}) =>
      CompanionMockDataSource.greeting(userName: userName);

  @override
  List<CompanionQuickChip> getQuickChips() =>
      CompanionMockDataSource.quickChips;

  @override
  CompanionMessage createUserMessage(String text) => CompanionMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      );

  @override
  Future<CompanionMessage> createAssistantReply(String userText) async {
    final reply = await CompanionMockDataSource.reply(userText);
    return CompanionMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_bot',
      text: reply,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }
}

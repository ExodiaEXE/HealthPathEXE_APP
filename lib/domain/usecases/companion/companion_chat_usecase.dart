import 'package:health/domain/entities/companion_message.dart';
import 'package:health/domain/repositories/companion_chat_repository.dart';

/// Use case chat đồng hành — gom các thao tác domain cho presentation.
class CompanionChatUseCase {
  const CompanionChatUseCase(this._repository);

  final CompanionChatRepository _repository;

  String greeting({String userName = 'Người dùng'}) =>
      _repository.getGreeting(userName: userName);

  List<CompanionQuickChip> quickChips() => _repository.getQuickChips();

  CompanionMessage userMessage(String text) =>
      _repository.createUserMessage(text);

  Future<CompanionMessage> assistantReply(String userText) =>
      _repository.createAssistantReply(userText);
}

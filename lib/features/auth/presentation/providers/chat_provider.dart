import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/ai_provider.dart';
import '../../../../core/services/ai_service.dart';
import '../../data/chat_repository.dart';
import '../../domain/chat_message.dart';
import '../../domain/chat_session.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

final chatSessionsProvider = StreamProvider<List<ChatSession>>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchSessions();
});

final chatMessagesProvider =
StreamProvider.family<List<ChatMessage>, String>((ref, sessionId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchMessages(sessionId);
});

class ChatController extends StateNotifier<AsyncValue<void>> {
  final ChatRepository _repo;
  final AIService _ai;

  ChatController(this._repo, this._ai) : super(const AsyncValue.data(null));

  static const String _systemPrompt = '''
Tu es un assistant d'étude pour étudiants. Tu réponds en français de manière claire, pédagogique et structurée.
Si la question est complexe, décompose ta réponse en étapes ou points clés.
Sois encourageant et motivant. Utilise du markdown (titres, listes, gras) pour structurer.
''';

  Future<String> createSession() async {
    return await _repo.createSession();
  }

  Future<void> sendMessage({
    required String sessionId,
    required String userMessage,
    required List<ChatMessage> currentMessages,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userMsg = ChatMessage(
        id: '',
        role: MessageRole.user,
        content: userMessage,
        timestamp: DateTime.now(),
      );
      await _repo.addMessage(sessionId: sessionId, message: userMsg);

      if (currentMessages.isEmpty) {
        await _generateSessionTitle(sessionId, userMessage);
      }

      final historyForAI = [
        ...currentMessages.map((m) => AIMessage(
          role: m.role == MessageRole.user
              ? AIRole.user
              : AIRole.assistant,
          content: m.content,
        )),
        AIMessage(role: AIRole.user, content: userMessage),
      ];

      try {
        final aiResponse = await _ai.generateChat(
          messages: historyForAI,
          systemPrompt: _systemPrompt,
        );

        final assistantMsg = ChatMessage(
          id: '',
          role: MessageRole.assistant,
          content: aiResponse,
          timestamp: DateTime.now(),
        );
        await _repo.addMessage(sessionId: sessionId, message: assistantMsg);
      } catch (e) {
        final errorMsg = ChatMessage(
          id: '',
          role: MessageRole.assistant,
          content: '❌ Erreur : impossible de joindre l\'IA. Réessaie.',
          timestamp: DateTime.now(),
          isError: true,
        );
        await _repo.addMessage(sessionId: sessionId, message: errorMsg);
        rethrow;
      }
    });
  }

  Future<void> _generateSessionTitle(
      String sessionId, String firstMessage) async {
    try {
      final title = await _ai.generateText(
        'Génère un titre TRÈS court (5 mots maximum, sans guillemets, sans ponctuation finale) pour une conversation qui commence par : "$firstMessage"',
      );
      final cleanTitle = title.trim().replaceAll(RegExp(r'["\.]'), '');
      await _repo.updateSessionTitle(
        sessionId: sessionId,
        title:
        cleanTitle.length > 50 ? cleanTitle.substring(0, 50) : cleanTitle,
      );
    } catch (_) {
      // Pas critique si le titre n'est pas généré
    }
  }

  Future<void> deleteSession(String sessionId) async {
    await _repo.deleteSession(sessionId);
  }
}

final chatControllerProvider =
StateNotifierProvider<ChatController, AsyncValue<void>>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  final ai = ref.watch(aiServiceProvider);
  return ChatController(repo, ai);
});
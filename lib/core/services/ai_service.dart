/// Contrat abstrait pour un service d'IA.
/// Permet de switcher facilement entre Gemini, OpenAI, Claude, etc.
abstract class AIService {
  /// Envoie un prompt simple et reçoit une réponse texte.
  Future<String> generateText(String prompt);

  /// Envoie une conversation (multi-tour) et reçoit la réponse de l'IA.
  Future<String> generateChat({
    required List<AIMessage> messages,
    String? systemPrompt,
  });

  /// Génère du JSON structuré (pour quiz, résumés structurés, etc.).
  Future<Map<String, dynamic>> generateJson({
    required String prompt,
    String? systemPrompt,
  });
}

/// Représente un message dans une conversation.
class AIMessage {
  final AIRole role;
  final String content;

  const AIMessage({required this.role, required this.content});
}

enum AIRole { user, assistant }
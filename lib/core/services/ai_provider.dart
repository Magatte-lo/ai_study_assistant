import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_service.dart';
import 'gemini_service.dart';

/// Provider du service IA.
/// Pour changer de fournisseur (OpenAI, Claude, etc.), il suffit de modifier
/// ce provider — le reste de l'app n'a rien à savoir.
final aiServiceProvider = Provider<AIService>((ref) {
  return GeminiService();
});
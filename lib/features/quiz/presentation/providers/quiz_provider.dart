import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/ai_provider.dart';
import '../../../../core/services/ai_service.dart';
import '../../data/quiz_repository.dart';
import '../../domain/quiz.dart';
import '../../domain/quiz_question.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository();
});

final quizzesProvider = StreamProvider<List<Quiz>>((ref) {
  final repo = ref.watch(quizRepositoryProvider);
  return repo.watchQuizzes();
});

/// État de la génération de quiz.
sealed class QuizGenerationState {
  const QuizGenerationState();
}

class QuizGenIdle extends QuizGenerationState {
  const QuizGenIdle();
}

class QuizGenLoading extends QuizGenerationState {
  const QuizGenLoading();
}

class QuizGenSuccess extends QuizGenerationState {
  final Quiz quiz;
  const QuizGenSuccess(this.quiz);
}

class QuizGenError extends QuizGenerationState {
  final String message;
  const QuizGenError(this.message);
}

class QuizController extends StateNotifier<QuizGenerationState> {
  final QuizRepository _repo;
  final AIService _ai;

  QuizController(this._repo, this._ai) : super(const QuizGenIdle());

  Future<void> generateQuiz({
    required String topic,
    required QuizDifficulty difficulty,
    required int questionCount,
  }) async {
    state = const QuizGenLoading();

    try {
      final systemPrompt = '''
Tu es un générateur de quiz pédagogiques pour étudiants.
Tu réponds UNIQUEMENT avec du JSON valide, sans markdown, sans texte avant ou après.

Format JSON attendu :
{
  "questions": [
    {
      "question": "Texte de la question ?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctIndex": 0,
      "explanation": "Explication courte de la réponse correcte (1-2 phrases)"
    }
  ]
}

Règles :
- Chaque question a EXACTEMENT 4 options
- correctIndex est l'index (0, 1, 2 ou 3) de la bonne réponse
- Les questions sont variées (pas toutes du même type)
- Adapte la difficulté au niveau demandé
- Réponds en français
- L'explication est claire et pédagogique
''';

      final difficultyText = switch (difficulty) {
        QuizDifficulty.easy => 'niveau facile (questions de base)',
        QuizDifficulty.medium => 'niveau moyen (questions intermédiaires)',
        QuizDifficulty.hard => 'niveau difficile (questions avancées)',
      };

      final response = await _ai.generateJson(
        prompt:
        'Génère un quiz de $questionCount questions QCM sur le sujet : "$topic". '
            'Difficulté : $difficultyText.',
        systemPrompt: systemPrompt,
      );

      final questionsRaw = response['questions'] as List? ?? [];
      if (questionsRaw.isEmpty) {
        state = const QuizGenError('L\'IA n\'a généré aucune question.');
        return;
      }

      final questions = questionsRaw
          .map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>))
          .where((q) => q.options.length == 4)
          .toList();

      if (questions.isEmpty) {
        state = const QuizGenError('Format de quiz invalide.');
        return;
      }

      final quiz = Quiz(
        id: '',
        topic: topic,
        difficulty: difficulty,
        questions: questions,
        createdAt: DateTime.now(),
      );

      final id = await _repo.addQuiz(quiz);
      state = QuizGenSuccess(quiz.copyWith(id: id));
    } catch (e) {
      state = QuizGenError('Erreur : $e');
    }
  }

  Future<void> submitResults({
    required String quizId,
    required List<int> userAnswers,
    required int score,
  }) async {
    await _repo.updateQuizResults(
      quizId: quizId,
      userAnswers: userAnswers,
      score: score,
    );
  }

  Future<void> deleteQuiz(String id) async {
    await _repo.deleteQuiz(id);
  }

  void reset() {
    state = const QuizGenIdle();
  }
}

final quizControllerProvider =
StateNotifierProvider<QuizController, QuizGenerationState>((ref) {
  return QuizController(
    ref.watch(quizRepositoryProvider),
    ref.watch(aiServiceProvider),
  );
});
import 'package:flutter/material.dart';

import '../../domain/quiz.dart';

class QuizResultsPage extends StatelessWidget {
  final Quiz quiz;

  const QuizResultsPage({super.key, required this.quiz});

  String get _scoreEmoji {
    final pct = (quiz.score! / quiz.questionCount) * 100;
    if (pct == 100) return '🏆';
    if (pct >= 80) return '🎉';
    if (pct >= 60) return '👍';
    if (pct >= 40) return '💪';
    return '📚';
  }

  String get _scoreMessage {
    final pct = (quiz.score! / quiz.questionCount) * 100;
    if (pct == 100) return 'Parfait ! Tu maîtrises le sujet !';
    if (pct >= 80) return 'Excellent travail !';
    if (pct >= 60) return 'Bon score, continue comme ça !';
    if (pct >= 40) return 'Pas mal, mais tu peux mieux faire.';
    return 'Faut réviser ce sujet 😉';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = quiz.score!;
    final total = quiz.questionCount;
    final pct = (score / total * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // En-tête score
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(_scoreEmoji, style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                Text(
                  '$score / $total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$pct%',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _scoreMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Corrections détaillées',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...List.generate(quiz.questions.length, (index) {
            final question = quiz.questions[index];
            final userAnswer = quiz.userAnswers![index];
            final isCorrect = userAnswer == question.correctIndex;
            return _buildQuestionReview(
              context,
              index,
              question,
              userAnswer,
              isCorrect,
            );
          }),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            icon: const Icon(Icons.home),
            label: const Text('Retour à l\'accueil'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionReview(
      BuildContext context,
      int index,
      dynamic question,
      int userAnswer,
      bool isCorrect,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.shade50
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                'Question ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.question,
            style: const TextStyle(fontWeight: FontWeight.w500, height: 1.3),
          ),
          const SizedBox(height: 12),
          _buildAnswerRow(
            'Ta réponse',
            userAnswer >= 0 ? question.options[userAnswer] : 'Aucune',
            isCorrect ? Colors.green : Colors.red,
          ),
          if (!isCorrect)
            _buildAnswerRow(
              'Bonne réponse',
              question.options[question.correctIndex],
              Colors.green,
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 18, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question.explanation,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label : ',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color, fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/quiz.dart';
import '../providers/quiz_provider.dart';
import 'quiz_results_page.dart';

class QuizPlayPage extends ConsumerStatefulWidget {
  final Quiz quiz;

  const QuizPlayPage({super.key, required this.quiz});

  @override
  ConsumerState<QuizPlayPage> createState() => _QuizPlayPageState();
}

class _QuizPlayPageState extends ConsumerState<QuizPlayPage> {
  int _currentIndex = 0;
  late List<int> _answers;
  int? _selectedOption;

  @override
  void initState() {
    super.initState();
    _answers = List.filled(widget.quiz.questions.length, -1);
  }

  void _selectOption(int index) {
    setState(() => _selectedOption = index);
  }

  Future<void> _nextQuestion() async {
    if (_selectedOption == null) return;

    _answers[_currentIndex] = _selectedOption!;

    if (_currentIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = _answers[_currentIndex] == -1
            ? null
            : _answers[_currentIndex];
      });
    } else {
      // Quiz terminé
      await _finishQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _selectedOption = _answers[_currentIndex] == -1
            ? null
            : _answers[_currentIndex];
      });
    }
  }

  Future<void> _finishQuiz() async {
    // Calcul du score
    int score = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      if (_answers[i] == widget.quiz.questions[i].correctIndex) {
        score++;
      }
    }

    // Sauvegarde dans Firestore
    await ref.read(quizControllerProvider.notifier).submitResults(
      quizId: widget.quiz.id,
      userAnswers: _answers,
      score: score,
    );

    if (!mounted) return;

    final completedQuiz = widget.quiz.copyWith(
      userAnswers: _answers,
      score: score,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultsPage(quiz: completedQuiz),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.quiz.questions[_currentIndex];
    final progress = (_currentIndex + 1) / widget.quiz.questions.length;
    final isLastQuestion = _currentIndex == widget.quiz.questions.length - 1;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1}/${widget.quiz.questions.length}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            final shouldExit = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Quitter le quiz ?'),
                content:
                const Text('Ton progrès actuel ne sera pas sauvegardé.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Continuer'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style:
                    TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Quitter'),
                  ),
                ],
              ),
            ) ??
                false;
            if (shouldExit && mounted) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: 4,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    question.question,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ...List.generate(question.options.length, (index) {
                    final isSelected = _selectedOption == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => _selectOption(index),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : Colors.grey.shade400,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check,
                                      color: Colors.white, size: 18)
                                      : Center(
                                    child: Text(
                                      String.fromCharCode(65 + index),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    question.options[index],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          // Boutons navigation
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentIndex > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _previousQuestion,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Précédent'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  if (_currentIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _selectedOption == null ? null : _nextQuestion,
                      icon: Icon(isLastQuestion
                          ? Icons.check_circle
                          : Icons.arrow_forward),
                      label: Text(isLastQuestion ? 'Terminer' : 'Suivant'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
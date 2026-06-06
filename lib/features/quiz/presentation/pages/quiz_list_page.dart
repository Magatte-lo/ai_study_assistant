import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/quiz.dart';
import '../providers/quiz_provider.dart';
import 'quiz_creation_page.dart';
import 'quiz_results_page.dart';

class QuizListPage extends ConsumerWidget {
  const QuizListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesAsync = ref.watch(quizzesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes quiz')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QuizCreationPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouveau quiz'),
      ),
      body: quizzesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
        data: (quizzes) {
          if (quizzes.isEmpty) return _buildEmpty(context);
          return ListView.separated(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: quizzes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              return Dismissible(
                key: ValueKey(quiz.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Supprimer ce quiz ?'),
                      content: const Text('Action irréversible.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.red),
                          child: const Text('Supprimer'),
                        ),
                      ],
                    ),
                  ) ??
                      false;
                },
                onDismissed: (_) {
                  ref.read(quizControllerProvider.notifier).deleteQuiz(quiz.id);
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _scoreColor(quiz).withValues(alpha: 0.15),
                    child: Icon(Icons.quiz, color: _scoreColor(quiz)),
                  ),
                  title: Text(
                    quiz.topic,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${quiz.difficulty.label} • ${quiz.questionCount} questions',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12),
                  ),
                  trailing: quiz.isCompleted
                      ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _scoreColor(quiz).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${quiz.score}/${quiz.questionCount}',
                      style: TextStyle(
                        color: _scoreColor(quiz),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                      : const Chip(
                    label: Text('Non terminé', style: TextStyle(fontSize: 11)),
                    padding: EdgeInsets.zero,
                  ),
                  onTap: () {
                    if (quiz.isCompleted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizResultsPage(quiz: quiz),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _scoreColor(Quiz quiz) {
    if (!quiz.isCompleted) return Colors.grey;
    final pct = (quiz.score! / quiz.questionCount) * 100;
    if (pct >= 80) return Colors.green;
    if (pct >= 50) return Colors.orange;
    return Colors.red;
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Aucun quiz',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Crée ton premier quiz IA\nsur n\'importe quel sujet',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
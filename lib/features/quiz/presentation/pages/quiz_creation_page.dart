import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/quiz.dart';
import '../providers/quiz_provider.dart';
import 'quiz_play_page.dart';

class QuizCreationPage extends ConsumerStatefulWidget {
  const QuizCreationPage({super.key});

  @override
  ConsumerState<QuizCreationPage> createState() => _QuizCreationPageState();
}

class _QuizCreationPageState extends ConsumerState<QuizCreationPage> {
  final _topicController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  QuizDifficulty _difficulty = QuizDifficulty.medium;
  int _questionCount = 5;

  @override
  void initState() {
    super.initState();
    // Reset l'état au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizControllerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(quizControllerProvider.notifier).generateQuiz(
      topic: _topicController.text.trim(),
      difficulty: _difficulty,
      questionCount: _questionCount,
    );

    if (!mounted) return;
    final state = ref.read(quizControllerProvider);

    if (state is QuizGenSuccess) {
      // Navigue vers la page de jeu
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizPlayPage(quiz: state.quiz),
        ),
      );
    } else if (state is QuizGenError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizControllerProvider);
    final isLoading = state is QuizGenLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau quiz')),
      body: SafeArea(
        child: isLoading
            ? _buildLoading()
            : SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Icon(Icons.quiz,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Sur quoi veux-tu être interrogé ?',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choisis un sujet précis pour un meilleur résultat',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                // Sujet
                const Text('Sujet du quiz',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _topicController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Photosynthèse, Révolution française...',
                    prefixIcon: Icon(Icons.topic_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Sujet requis';
                    }
                    if (value.trim().length < 3) {
                      return 'Au moins 3 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Difficulté
                const Text('Difficulté',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SegmentedButton<QuizDifficulty>(
                  segments: const [
                    ButtonSegment(
                      value: QuizDifficulty.easy,
                      label: Text('Facile'),
                      icon: Icon(Icons.sentiment_satisfied),
                    ),
                    ButtonSegment(
                      value: QuizDifficulty.medium,
                      label: Text('Moyen'),
                      icon: Icon(Icons.sentiment_neutral),
                    ),
                    ButtonSegment(
                      value: QuizDifficulty.hard,
                      label: Text('Difficile'),
                      icon: Icon(Icons.sentiment_very_dissatisfied),
                    ),
                  ],
                  selected: {_difficulty},
                  onSelectionChanged: (selection) {
                    setState(() => _difficulty = selection.first);
                  },
                ),
                const SizedBox(height: 24),

                // Nombre de questions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Nombre de questions',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_questionCount',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _questionCount.toDouble(),
                  min: 3,
                  max: 15,
                  divisions: 12,
                  label: '$_questionCount questions',
                  onChanged: (value) {
                    setState(() => _questionCount = value.round());
                  },
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _generate,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text(
                      'Générer le quiz',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome,
                size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Génération du quiz...',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'L\'IA prépare tes questions sur ${_topicController.text}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/ai_provider.dart';
import '../../../auth/presentation/pages/chat_list_page.dart';
import '../providers/auth_provider.dart';
import '../../../pdf_summary/presentation/pages/pdf_summary_list_page.dart';
class HomePlaceholderPage extends ConsumerStatefulWidget {
  const HomePlaceholderPage({super.key});

  @override
  ConsumerState<HomePlaceholderPage> createState() =>
      _HomePlaceholderPageState();
}

class _HomePlaceholderPageState extends ConsumerState<HomePlaceholderPage> {
  String? _aiResponse;
  bool _isLoading = false;

  Future<void> _testAI() async {
    setState(() {
      _isLoading = true;
      _aiResponse = null;
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final response = await aiService.generateText(
        'Dis bonjour en 1 phrase amusante. Réponds en français.',
      );
      if (!mounted) return;
      setState(() => _aiResponse = response);
    } catch (e) {
      if (!mounted) return;
      setState(() => _aiResponse = '❌ Erreur : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    final authController = ref.read(authControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Study Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () async => authController.signOut(),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur : $err')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Pas d\'utilisateur connecté'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Salut ${user.displayName ?? user.email} 👋',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bienvenue dans ton espace d\'étude IA.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),

                // ============ Bouton test IA (temporaire) ============
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Test Gemini AI',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _testAI,
                        icon: _isLoading
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.send),
                        label: Text(
                          _isLoading ? 'En cours...' : 'Tester Gemini',
                        ),
                      ),
                      if (_aiResponse != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_aiResponse!),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                Text(
                  'Features',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // ============ Features ============
                _featureTile(
                  context,
                  Icons.chat_bubble_outline,
                  'Chat IA',
                  'Pose des questions à ton tuteur IA',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChatListPage(),
                      ),
                    );
                  },
                ),
                _featureTile(
                  context,
                  Icons.picture_as_pdf_outlined,
                  'Résumé PDF',
                  'Résume tes documents en un clic',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PdfSummaryListPage()),
                    );
                  },
                ),
                _featureTile(
                  context,
                  Icons.quiz_outlined,
                  'Quiz IA',
                  'Génère des quiz personnalisés',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bientôt disponible (étape 8) 🧠'),
                      ),
                    );
                  },
                ),
                _featureTile(
                  context,
                  Icons.history,
                  'Historique',
                  'Retrouve toutes tes sessions',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bientôt disponible (étape 9) 📊'),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _featureTile(
      BuildContext context,
      IconData icon,
      String title,
      String subtitle, {
        VoidCallback? onTap,
      }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
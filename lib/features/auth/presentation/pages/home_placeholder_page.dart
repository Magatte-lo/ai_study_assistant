import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';

class HomePlaceholderPage extends ConsumerWidget {
  const HomePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final authController = ref.read(authControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Study Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () async {
              await authController.signOut();
            },
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
          return Padding(
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
                  'Tu es connecté ! Les features arrivent bientôt :',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                _featureTile(
                  context,
                  Icons.chat_bubble_outline,
                  'Chat IA',
                  'Pose des questions à ton tuteur IA',
                ),
                _featureTile(
                  context,
                  Icons.picture_as_pdf_outlined,
                  'Résumé PDF',
                  'Résume tes documents en un clic',
                ),
                _featureTile(
                  context,
                  Icons.quiz_outlined,
                  'Quiz IA',
                  'Génère des quiz personnalisés',
                ),
                _featureTile(
                  context,
                  Icons.history,
                  'Historique',
                  'Retrouve toutes tes sessions',
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
      String subtitle,
      ) {
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
      ),
    );
  }
}
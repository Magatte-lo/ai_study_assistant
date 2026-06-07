import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../pdf_summary/presentation/pages/pdf_summary_list_page.dart';
import '../../../quiz/presentation/pages/quiz_list_page.dart';
import '../providers/auth_provider.dart';
import 'chat_list_page.dart';

class HomePlaceholderPage extends ConsumerWidget {
  const HomePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final authController = ref.read(authControllerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur : $err')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Pas d\'utilisateur connecté'));
          }
          final displayName = user.displayName ?? user.email.split('@').first;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Déconnexion',
                    onPressed: () => authController.signOut(),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'AI Study Assistant',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Salut $displayName ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Prêt à apprendre aujourd\'hui ?',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      'Fonctionnalités',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FeatureCard(
                      icon: Icons.chat_bubble_outline,
                      color: const Color(0xFF6366F1),
                      title: 'Chat IA',
                      subtitle: 'Pose toutes tes questions à ton tuteur IA',
                      onTap: () => _navigate(context, const ChatListPage()),
                    ),
                    _FeatureCard(
                      icon: Icons.picture_as_pdf_outlined,
                      color: const Color(0xFFEF4444),
                      title: 'Résumé PDF',
                      subtitle: 'Résume tes documents en quelques secondes',
                      onTap: () =>
                          _navigate(context, const PdfSummaryListPage()),
                    ),
                    _FeatureCard(
                      icon: Icons.quiz_outlined,
                      color: const Color(0xFFF59E0B),
                      title: 'Quiz IA',
                      subtitle: 'Génère des quiz sur n\'importe quel sujet',
                      onTap: () => _navigate(context, const QuizListPage()),
                    ),
                    _FeatureCard(
                      icon: Icons.history,
                      color: const Color(0xFF10B981),
                      title: 'Historique',
                      subtitle: 'Retrouve toutes tes sessions',
                      onTap: () => _navigate(context, const HistoryPage()),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Text(
                        '✨',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
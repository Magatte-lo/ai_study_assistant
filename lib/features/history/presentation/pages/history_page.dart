import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/domain/chat_session.dart';
import '../../../auth/presentation/pages/chat_page.dart';
import '../../../auth/presentation/providers/chat_provider.dart';
import '../../../pdf_summary/domain/pdf_summary.dart';
import '../../../pdf_summary/presentation/providers/pdf_summary_provider.dart';
import '../../../pdf_summary/presentation/widgets/summary_content.dart';
import '../../../quiz/domain/quiz.dart';
import '../../../quiz/presentation/pages/quiz_results_page.dart';
import '../../../quiz/presentation/providers/quiz_provider.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Historique'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Chats'),
              Tab(icon: Icon(Icons.picture_as_pdf_outlined), text: 'PDF'),
              Tab(icon: Icon(Icons.quiz_outlined), text: 'Quiz'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ChatsTab(),
            _PdfsTab(),
            _QuizzesTab(),
          ],
        ),
      ),
    );
  }
}

// ============ Onglet Chats ============
class _ChatsTab extends ConsumerWidget {
  const _ChatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(chatSessionsProvider);

    return sessionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erreur: $err')),
      data: (sessions) {
        if (sessions.isEmpty) {
          return _buildEmpty(
            icon: Icons.chat_outlined,
            title: 'Aucune conversation',
            subtitle: 'Lance ton premier chat depuis l\'accueil',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: sessions.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) => _ChatTile(session: sessions[index]),
        );
      },
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatSession session;
  const _ChatTile({required this.session});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        child: Icon(
          Icons.chat_bubble_outline,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        session.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: session.lastMessagePreview != null
          ? Text(
        session.lastMessagePreview!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      )
          : null,
      trailing: Text(
        DateFormat('dd/MM HH:mm').format(session.updatedAt),
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(sessionId: session.id),
          ),
        );
      },
    );
  }
}

// ============ Onglet PDF ============
class _PdfsTab extends ConsumerWidget {
  const _PdfsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(pdfSummariesProvider);

    return summariesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erreur: $err')),
      data: (summaries) {
        if (summaries.isEmpty) {
          return _buildEmpty(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Aucun résumé PDF',
            subtitle: 'Génère ton premier résumé depuis l\'accueil',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: summaries.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) =>
              _PdfTile(summary: summaries[index]),
        );
      },
    );
  }
}

class _PdfTile extends StatelessWidget {
  final PdfSummary summary;
  const _PdfTile({required this.summary});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        child: Icon(
          Icons.picture_as_pdf,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        summary.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${summary.pageCount} pages • ${DateFormat('dd/MM HH:mm').format(summary.createdAt)}',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(
                title: Text(
                  summary.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              body: SummaryContent(summary: summary),
            ),
          ),
        );
      },
    );
  }
}

// ============ Onglet Quiz ============
class _QuizzesTab extends ConsumerWidget {
  const _QuizzesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesAsync = ref.watch(quizzesProvider);

    return quizzesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erreur: $err')),
      data: (quizzes) {
        if (quizzes.isEmpty) {
          return _buildEmpty(
            icon: Icons.quiz_outlined,
            title: 'Aucun quiz',
            subtitle: 'Crée ton premier quiz depuis l\'accueil',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: quizzes.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) => _QuizTile(quiz: quizzes[index]),
        );
      },
    );
  }
}

class _QuizTile extends StatelessWidget {
  final Quiz quiz;
  const _QuizTile({required this.quiz});

  Color _scoreColor() {
    if (!quiz.isCompleted) return Colors.grey;
    final pct = (quiz.score! / quiz.questionCount) * 100;
    if (pct >= 80) return Colors.green;
    if (pct >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor();
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(Icons.quiz, color: color),
      ),
      title: Text(
        quiz.topic,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${quiz.difficulty.label} • ${quiz.questionCount} questions',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: quiz.isCompleted
          ? Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${quiz.score}/${quiz.questionCount}',
          style: TextStyle(
            color: color,
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
    );
  }
}

// ============ Empty state helper ============
Widget _buildEmpty({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    ),
  );
}
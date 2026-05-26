import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/pdf_summary.dart';
import '../providers/pdf_summary_provider.dart';
import '../widgets/summary_content.dart';
import 'pdf_summary_page.dart';

class PdfSummaryListPage extends ConsumerWidget {
  const PdfSummaryListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(pdfSummariesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes résumés PDF')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(pdfSummaryControllerProvider.notifier).reset();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PdfSummaryPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouveau résumé'),
      ),
      body: summariesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
        data: (summaries) {
          if (summaries.isEmpty) return _buildEmpty(context);
          return ListView.separated(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: summaries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final summary = summaries[index];
              return Dismissible(
                key: ValueKey(summary.id),
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
                      title: const Text('Supprimer ce résumé ?'),
                      content:
                      const Text('Cette action est irréversible.'),
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
                  ref
                      .read(pdfSummaryControllerProvider.notifier)
                      .deleteSummary(summary.id);
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
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
                    '${summary.pageCount} pages • ${DateFormat('dd/MM/yyyy HH:mm').format(summary.createdAt)}',
                    style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _SummaryDetailPage(summary: summary),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf,
                size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Aucun résumé',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Crée ton premier résumé PDF\nen un clic',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryDetailPage extends StatelessWidget {
  final PdfSummary summary;
  const _SummaryDetailPage({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(summary.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SummaryContent(summary: summary),
    );
  }
}
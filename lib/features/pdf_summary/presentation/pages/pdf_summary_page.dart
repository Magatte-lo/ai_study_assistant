import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pdf_summary_provider.dart';
import '../widgets/pdf_picker_card.dart';
import '../widgets/summary_content.dart';

class PdfSummaryPage extends ConsumerStatefulWidget {
  const PdfSummaryPage({super.key});

  @override
  ConsumerState<PdfSummaryPage> createState() => _PdfSummaryPageState();
}

class _PdfSummaryPageState extends ConsumerState<PdfSummaryPage> {
  Future<void> _pickAndSummarize() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.first.path;
    final fileName = result.files.first.name;
    if (filePath == null) return;

    final file = File(filePath);
    await ref
        .read(pdfSummaryControllerProvider.notifier)
        .generateFromFile(file, fileName);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pdfSummaryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résumé PDF'),
        actions: [
          if (state is PdfSuccess || state is PdfError)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Nouveau résumé',
              onPressed: () {
                ref.read(pdfSummaryControllerProvider.notifier).reset();
              },
            ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(PdfSummaryState state) {
    return switch (state) {
      PdfIdle() => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            PdfPickerCard(onPick: _pickAndSummarize),
            const SizedBox(height: 24),
            _buildInfoBox(),
          ],
        ),
      ),
      PdfExtracting() => _buildLoading(
        icon: Icons.find_in_page,
        title: 'Extraction du texte...',
        subtitle: 'Lecture des pages du PDF',
      ),
      PdfSummarizing(pageCount: final pages, charCount: final chars) =>
          _buildLoading(
            icon: Icons.auto_awesome,
            title: 'Génération du résumé...',
            subtitle:
            '$pages pages • ${(chars / 1000).toStringAsFixed(1)}k caractères\nL\'IA analyse ton document',
          ),
      PdfSuccess(:final summary) => SummaryContent(summary: summary),
      PdfError(:final message) => _buildError(message),
    };
  }

  Widget _buildLoading({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Oops, ça a planté',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(pdfSummaryControllerProvider.notifier).reset();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Comment ça marche',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow('1.', 'Sélectionne un fichier PDF depuis ton téléphone'),
          _infoRow('2.', 'Le texte est extrait localement (vie privée 🔒)'),
          _infoRow('3.', 'L\'IA analyse et génère un résumé structuré'),
          _infoRow('4.', 'Tu peux retrouver tes résumés dans l\'historique'),
        ],
      ),
    );
  }

  Widget _infoRow(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(number,
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
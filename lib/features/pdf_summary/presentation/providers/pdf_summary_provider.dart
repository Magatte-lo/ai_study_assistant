import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/ai_provider.dart';
import '../../../../core/services/ai_service.dart';
import '../../data/pdf_summary_repository.dart';
import '../../domain/pdf_summary.dart';
import '../../domain/pdf_text_extractor.dart';

final pdfSummaryRepositoryProvider = Provider<PdfSummaryRepository>((ref) {
  return PdfSummaryRepository();
});

final pdfTextExtractorProvider = Provider<PdfTextExtractor>((ref) {
  return PdfTextExtractor();
});

final pdfSummariesProvider = StreamProvider<List<PdfSummary>>((ref) {
  final repo = ref.watch(pdfSummaryRepositoryProvider);
  return repo.watchSummaries();
});

/// État du processus de génération de résumé.
sealed class PdfSummaryState {
  const PdfSummaryState();
}

class PdfIdle extends PdfSummaryState {
  const PdfIdle();
}

class PdfExtracting extends PdfSummaryState {
  const PdfExtracting();
}

class PdfSummarizing extends PdfSummaryState {
  final int pageCount;
  final int charCount;
  const PdfSummarizing({required this.pageCount, required this.charCount});
}

class PdfSuccess extends PdfSummaryState {
  final PdfSummary summary;
  const PdfSuccess(this.summary);
}

class PdfError extends PdfSummaryState {
  final String message;
  const PdfError(this.message);
}

class PdfSummaryController extends StateNotifier<PdfSummaryState> {
  final PdfSummaryRepository _repo;
  final PdfTextExtractor _extractor;
  final AIService _ai;

  PdfSummaryController(this._repo, this._extractor, this._ai)
      : super(const PdfIdle());

  static const String _systemPrompt = '''
Tu es un assistant pédagogique expert en résumés de documents pour étudiants.

Tu vas recevoir le texte d'un document PDF. Tu dois produire un résumé STRUCTURÉ en français avec EXACTEMENT ce format JSON :

{
  "summary": "Un résumé complet en markdown (300-600 mots), avec des titres ## et des listes pour structurer.",
  "keyPoints": ["Point clé 1", "Point clé 2", "Point clé 3", "Point clé 4", "Point clé 5"]
}

Règles :
- Le summary utilise du markdown (## pour les sections, ** pour gras, - pour listes)
- keyPoints contient 5 à 8 points essentiels, courts (1 phrase chacun)
- Réponds UNIQUEMENT avec le JSON, rien d'autre
''';

  Future<void> generateFromFile(File pdfFile, String fileName) async {
    try {
      // 1. Extraction du texte
      state = const PdfExtracting();
      final extracted = await _extractor.extractFromFile(pdfFile);

      if (extracted.text.trim().isEmpty) {
        state = const PdfError(
            'Impossible d\'extraire du texte de ce PDF. Est-il scanné (image) ?');
        return;
      }

      // 2. Appel à l'IA
      state = PdfSummarizing(
        pageCount: extracted.pageCount,
        charCount: extracted.charCount,
      );

      final response = await _ai.generateJson(
        prompt:
        'Voici le contenu du document à résumer :\n\n${extracted.text}',
        systemPrompt: _systemPrompt,
      );

      final summaryText = response['summary'] as String? ?? '';
      final keyPoints = List<String>.from(response['keyPoints'] as List? ?? []);

      if (summaryText.isEmpty) {
        state = const PdfError('L\'IA n\'a pas pu générer de résumé.');
        return;
      }

      // 3. Sauvegarde Firestore
      final summary = PdfSummary(
        id: '',
        fileName: fileName,
        pageCount: extracted.pageCount,
        charCount: extracted.charCount,
        summary: summaryText,
        keyPoints: keyPoints,
        createdAt: DateTime.now(),
      );

      final id = await _repo.addSummary(summary);

      state = PdfSuccess(PdfSummary(
        id: id,
        fileName: summary.fileName,
        pageCount: summary.pageCount,
        charCount: summary.charCount,
        summary: summary.summary,
        keyPoints: summary.keyPoints,
        createdAt: summary.createdAt,
      ));
    } catch (e) {
      state = PdfError('Erreur : $e');
    }
  }

  void reset() {
    state = const PdfIdle();
  }

  Future<void> deleteSummary(String id) async {
    await _repo.deleteSummary(id);
  }
}

final pdfSummaryControllerProvider =
StateNotifierProvider<PdfSummaryController, PdfSummaryState>((ref) {
  return PdfSummaryController(
    ref.watch(pdfSummaryRepositoryProvider),
    ref.watch(pdfTextExtractorProvider),
    ref.watch(aiServiceProvider),
  );
});
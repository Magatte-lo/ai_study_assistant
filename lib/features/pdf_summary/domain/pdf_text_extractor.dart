import 'dart:io';

import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;

/// Résultat de l'extraction d'un PDF.
class ExtractedPdf {
  final String text;
  final int pageCount;
  final int charCount;

  ExtractedPdf({
    required this.text,
    required this.pageCount,
    required this.charCount,
  });
}

/// Service qui extrait le texte d'un fichier PDF.
class PdfTextExtractor {
  /// Limite max de caractères à envoyer à l'IA (sécurité coût/quota).
  static const int maxCharsForAI = 80000;

  Future<ExtractedPdf> extractFromFile(File file) async {
    final bytes = await file.readAsBytes();
    final document = syncfusion.PdfDocument(inputBytes: bytes);

    try {
      final pageCount = document.pages.count;
      final extractor = syncfusion.PdfTextExtractor(document);
      final fullText = extractor.extractText();

      final truncated = fullText.length > maxCharsForAI
          ? '${fullText.substring(0, maxCharsForAI)}\n\n[...texte tronqué pour le résumé...]'
          : fullText;

      return ExtractedPdf(
        text: truncated.trim(),
        pageCount: pageCount,
        charCount: fullText.length,
      );
    } finally {
      document.dispose();
    }
  }
}
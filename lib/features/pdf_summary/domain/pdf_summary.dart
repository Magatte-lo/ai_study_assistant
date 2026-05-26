import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class PdfSummary extends Equatable {
  final String id;
  final String fileName;
  final int pageCount;
  final int charCount;
  final String summary; // Le résumé en markdown
  final List<String> keyPoints;
  final DateTime createdAt;

  const PdfSummary({
    required this.id,
    required this.fileName,
    required this.pageCount,
    required this.charCount,
    required this.summary,
    required this.keyPoints,
    required this.createdAt,
  });

  factory PdfSummary.fromMap(String id, Map<String, dynamic> map) {
    return PdfSummary(
      id: id,
      fileName: map['fileName'] as String? ?? 'Document.pdf',
      pageCount: map['pageCount'] as int? ?? 0,
      charCount: map['charCount'] as int? ?? 0,
      summary: map['summary'] as String? ?? '',
      keyPoints: List<String>.from(map['keyPoints'] as List? ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'pageCount': pageCount,
      'charCount': charCount,
      'summary': summary,
      'keyPoints': keyPoints,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props =>
      [id, fileName, pageCount, charCount, summary, keyPoints, createdAt];
}
import 'package:equatable/equatable.dart';

class QuizQuestion extends Equatable {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      question: map['question'] as String? ?? '',
      options: List<String>.from(map['options'] as List? ?? []),
      correctIndex: map['correctIndex'] as int? ?? 0,
      explanation: map['explanation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
    };
  }

  @override
  List<Object?> get props => [question, options, correctIndex, explanation];
}
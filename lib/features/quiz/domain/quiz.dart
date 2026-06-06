import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'quiz_question.dart';

enum QuizDifficulty { easy, medium, hard }

extension QuizDifficultyX on QuizDifficulty {
  String get label {
    switch (this) {
      case QuizDifficulty.easy:
        return 'Facile';
      case QuizDifficulty.medium:
        return 'Moyen';
      case QuizDifficulty.hard:
        return 'Difficile';
    }
  }

  String get apiValue {
    switch (this) {
      case QuizDifficulty.easy:
        return 'easy';
      case QuizDifficulty.medium:
        return 'medium';
      case QuizDifficulty.hard:
        return 'hard';
    }
  }
}

class Quiz extends Equatable {
  final String id;
  final String topic;
  final QuizDifficulty difficulty;
  final List<QuizQuestion> questions;
  final List<int>? userAnswers; // index choisi par l'utilisateur pour chaque question
  final int? score; // null si non terminé
  final DateTime createdAt;

  const Quiz({
    required this.id,
    required this.topic,
    required this.difficulty,
    required this.questions,
    this.userAnswers,
    this.score,
    required this.createdAt,
  });

  bool get isCompleted => score != null;
  int get questionCount => questions.length;

  factory Quiz.fromMap(String id, Map<String, dynamic> map) {
    final difficultyStr = map['difficulty'] as String? ?? 'medium';
    final difficulty = QuizDifficulty.values.firstWhere(
          (d) => d.apiValue == difficultyStr,
      orElse: () => QuizDifficulty.medium,
    );

    return Quiz(
      id: id,
      topic: map['topic'] as String? ?? 'Quiz',
      difficulty: difficulty,
      questions: (map['questions'] as List? ?? [])
          .map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>))
          .toList(),
      userAnswers: (map['userAnswers'] as List?)?.cast<int>(),
      score: map['score'] as int?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'topic': topic,
      'difficulty': difficulty.apiValue,
      'questions': questions.map((q) => q.toMap()).toList(),
      'userAnswers': userAnswers,
      'score': score,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Quiz copyWith({
    String? id,
    String? topic,
    QuizDifficulty? difficulty,
    List<QuizQuestion>? questions,
    List<int>? userAnswers,
    int? score,
    DateTime? createdAt,
  }) {
    return Quiz(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      difficulty: difficulty ?? this.difficulty,
      questions: questions ?? this.questions,
      userAnswers: userAnswers ?? this.userAnswers,
      score: score ?? this.score,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, topic, difficulty, questions, userAnswers, score, createdAt];
}
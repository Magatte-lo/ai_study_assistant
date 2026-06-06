import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/quiz.dart';

class QuizRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  QuizRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection('users').doc(_userId).collection('quizzes');

  Stream<List<Quiz>> watchQuizzes() {
    return _ref.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => Quiz.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  Future<String> addQuiz(Quiz quiz) async {
    final doc = await _ref.add(quiz.toMap());
    return doc.id;
  }

  Future<void> updateQuizResults({
    required String quizId,
    required List<int> userAnswers,
    required int score,
  }) async {
    await _ref.doc(quizId).update({
      'userAnswers': userAnswers,
      'score': score,
    });
  }

  Future<void> deleteQuiz(String id) async {
    await _ref.doc(id).delete();
  }
}
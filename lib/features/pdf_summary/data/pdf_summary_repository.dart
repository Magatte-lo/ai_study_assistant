import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/pdf_summary.dart';

class PdfSummaryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PdfSummaryRepository({
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
      _firestore.collection('users').doc(_userId).collection('pdf_summaries');

  Stream<List<PdfSummary>> watchSummaries() {
    return _ref.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => PdfSummary.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  Future<String> addSummary(PdfSummary summary) async {
    final doc = await _ref.add(summary.toMap());
    return doc.id;
  }

  Future<void> deleteSummary(String id) async {
    await _ref.doc(id).delete();
  }
}
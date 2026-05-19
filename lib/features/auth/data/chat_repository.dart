import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/chat_message.dart';
import '../domain/chat_session.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ChatRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _sessionsRef =>
      _firestore.collection('users').doc(_userId).collection('chat_sessions');

  CollectionReference<Map<String, dynamic>> _messagesRef(String sessionId) =>
      _sessionsRef.doc(sessionId).collection('messages');

  Stream<List<ChatSession>> watchSessions() {
    return _sessionsRef
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatSession.fromMap(doc.id, doc.data()))
        .toList());
  }

  Stream<List<ChatMessage>> watchMessages(String sessionId) {
    return _messagesRef(sessionId)
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatMessage.fromMap(doc.id, doc.data()))
        .toList());
  }

  Future<String> createSession({String? title}) async {
    final docRef = await _sessionsRef.add({
      'title': title ?? 'Nouvelle conversation',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessagePreview': null,
    });
    return docRef.id;
  }

  Future<String> addMessage({
    required String sessionId,
    required ChatMessage message,
  }) async {
    final batch = _firestore.batch();

    final messageDoc = _messagesRef(sessionId).doc();
    batch.set(messageDoc, message.toMap());

    final preview = message.content.length > 80
        ? '${message.content.substring(0, 80)}...'
        : message.content;

    batch.update(_sessionsRef.doc(sessionId), {
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessagePreview': preview,
    });

    await batch.commit();
    return messageDoc.id;
  }

  Future<void> updateSessionTitle({
    required String sessionId,
    required String title,
  }) async {
    await _sessionsRef.doc(sessionId).update({'title': title});
  }

  Future<void> deleteSession(String sessionId) async {
    final messages = await _messagesRef(sessionId).get();
    final batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_sessionsRef.doc(sessionId));
    await batch.commit();
  }
}
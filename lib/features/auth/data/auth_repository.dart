import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/auth_exception.dart';
import '../domain/user_model.dart';

/// Repository qui gère toutes les opérations liées à l'authentification.
/// Sert d'abstraction entre Firebase et le reste de l'app.
class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream qui émet le UserModel actuel à chaque changement d'auth.
  /// On l'écoutera dans Riverpod pour savoir si l'utilisateur est connecté.
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return await _getUserFromFirestore(firebaseUser.uid) ??
          _userFromFirebase(firebaseUser);
    });
  }

  /// Récupère l'utilisateur actuellement connecté (peut être null).
  UserModel? get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return _userFromFirebase(user);
  }

  /// Inscription avec email et mot de passe.
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw AuthException(
          code: 'unknown',
          message: 'L\'inscription a échoué.',
        );
      }

      // Met à jour le displayName si fourni
      if (displayName != null && displayName.isNotEmpty) {
        await firebaseUser.updateDisplayName(displayName);
      }

      // Crée le UserModel et le sauvegarde dans Firestore
      final userModel = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email!,
        displayName: displayName,
        photoUrl: firebaseUser.photoURL,
        createdAt: DateTime.now(),
      );

      await _saveUserToFirestore(userModel);
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    }
  }

  /// Connexion avec email et mot de passe.
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw AuthException(
          code: 'unknown',
          message: 'La connexion a échoué.',
        );
      }

      // Récupère depuis Firestore ou fallback sur Firebase Auth
      return await _getUserFromFirestore(firebaseUser.uid) ??
          _userFromFirebase(firebaseUser);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    }
  }

  /// Déconnexion.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Envoie un email de réinitialisation de mot de passe.
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    }
  }

  // ============ Méthodes privées ============

  /// Convertit un User Firebase en UserModel de l'app.
  UserModel _userFromFirebase(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  /// Sauvegarde l'utilisateur dans Firestore (collection 'users').
  Future<void> _saveUserToFirestore(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  /// Récupère l'utilisateur depuis Firestore.
  Future<UserModel?> _getUserFromFirestore(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }
}
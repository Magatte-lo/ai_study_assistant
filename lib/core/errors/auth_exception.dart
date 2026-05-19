/// Exceptions personnalisées pour l'authentification.
/// Permet d'afficher des messages d'erreur clairs à l'utilisateur.
class AuthException implements Exception {
  final String message;
  final String code;

  AuthException({
    required this.message,
    required this.code,
  });

  /// Convertit un code Firebase Auth en message lisible par l'utilisateur
  factory AuthException.fromCode(String code) {
    switch (code) {
      case 'invalid-email':
        return AuthException(
          code: code,
          message: 'L\'adresse email n\'est pas valide.',
        );
      case 'user-disabled':
        return AuthException(
          code: code,
          message: 'Ce compte a été désactivé.',
        );
      case 'user-not-found':
      case 'invalid-credential':
        return AuthException(
          code: code,
          message: 'Email ou mot de passe incorrect.',
        );
      case 'wrong-password':
        return AuthException(
          code: code,
          message: 'Mot de passe incorrect.',
        );
      case 'email-already-in-use':
        return AuthException(
          code: code,
          message: 'Cet email est déjà utilisé par un autre compte.',
        );
      case 'weak-password':
        return AuthException(
          code: code,
          message: 'Le mot de passe est trop faible (6 caractères minimum).',
        );
      case 'operation-not-allowed':
        return AuthException(
          code: code,
          message: 'Cette opération n\'est pas autorisée.',
        );
      case 'too-many-requests':
        return AuthException(
          code: code,
          message: 'Trop de tentatives. Réessayez plus tard.',
        );
      case 'network-request-failed':
        return AuthException(
          code: code,
          message: 'Erreur de connexion. Vérifiez votre internet.',
        );
      default:
        return AuthException(
          code: code,
          message: 'Une erreur est survenue. Réessayez.',
        );
    }
  }

  @override
  String toString() => 'AuthException($code): $message';
}
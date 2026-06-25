import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Future<User?> signInWithGoogle() async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope('profile');

    // signInWithProvider : flux OAuth natif iOS/Android (Safari + retour via
    // l'URL scheme du reversed client ID). signInWithPopup est web uniquement.
    final result = await _auth.signInWithProvider(provider);
    return result.user;
  }

  static Future<User?> signInWithApple() async {
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');

    final result = await _auth.signInWithProvider(provider);
    return result.user;
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }
}

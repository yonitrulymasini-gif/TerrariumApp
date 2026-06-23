import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Future<User?> signInWithGoogle() async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope('profile');

    final result = await _auth.signInWithPopup(provider);
    return result.user;
  }

  static Future<User?> signInWithApple() async {
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');

    final result = await _auth.signInWithPopup(provider);
    return result.user;
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }
}

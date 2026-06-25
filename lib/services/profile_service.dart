import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cloudinary_service.dart';

/// Gère la photo de profil stockée dans Firestore (`users/{uid}.photoURL`).
class ProfileService {
  static final _db = FirebaseFirestore.instance;
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Stream de l'URL avatar : priorité à l'URL Firestore (stable),
  /// sinon fallback sur la photo Google de Firebase Auth.
  static Stream<String?> avatarStream() {
    final uid = _uid;
    if (uid == null) return Stream.value(null);
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      final stored = doc.data()?['photoURL'] as String?;
      return stored ?? FirebaseAuth.instance.currentUser?.photoURL;
    });
  }

  /// Upload une nouvelle photo de profil et l'enregistre dans Firestore + Auth.
  static Future<void> updateAvatar(Uint8List bytes, String mime) async {
    final uid = _uid;
    if (uid == null) return;
    final url = await CloudinaryService.upload(
      bytes, mime,
      transform: 'f_auto,q_auto,w_400,h_400,c_fill,g_face',
    );
    if (url == null) throw Exception('Upload échoué');
    await _db.collection('users').doc(uid).set(
      {'photoURL': url}, SetOptions(merge: true));
    await FirebaseAuth.instance.currentUser?.updatePhotoURL(url);
  }
}

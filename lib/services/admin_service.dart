import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Identifie les administrateurs via le champ `role: 'admin'` du profil
/// Firestore (`users/{uid}.role`). Aucun email en dur : le rôle se règle
/// dans la console Firebase, et la même vérification est faite côté règles.
class AdminService extends ChangeNotifier {
  static final AdminService instance = AdminService._();
  AdminService._();

  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  /// Recharge le rôle de l'utilisateur courant (à appeler au démarrage et à
  /// chaque changement d'authentification).
  Future<void> load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _set(false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      _set(doc.data()?['role'] == 'admin');
    } catch (_) {
      _set(false); // hors-ligne / pas de profil → non-admin
    }
  }

  void _set(bool value) {
    if (_isAdmin != value) {
      _isAdmin = value;
      notifyListeners();
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'theme_service.dart';

/// Gère FCM : permissions, token, écoute des messages entrants
class NotificationService {
  static final _fcm = FirebaseMessaging.instance;
  static final _db = FirebaseFirestore.instance;
  static bool _inited = false;

  /// À appeler une fois après le login. Idempotent : ne s'exécute qu'une seule fois.
  static Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    if (_inited) return;
    _inited = true;

    // Ne demande la permission que si elle n'a jamais été décidée
    final settings = await _fcm.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      await _fcm.requestPermission(alert: true, badge: true, sound: true);
    }

    // Sauvegarde le token FCM dans Firestore pour que le backend puisse notifier
    await _saveToken();
    _fcm.onTokenRefresh.listen(_saveToken);

    // Message reçu quand l'app est au premier plan
    FirebaseMessaging.onMessage.listen((msg) {
      _showInAppBanner(msg, navigatorKey);
    });

    // Message cliqué depuis la notification (app en arrière-plan ou fermée)
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _handleTap(msg, navigatorKey);
    });

    // Message qui a ouvert l'app depuis fermée
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleTap(initial, navigatorKey);
  }

  static Future<void> _saveToken([String? token]) async {
    token ??= await _fcm.getToken();
    if (token == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set(
      {'fcmToken': token, 'tokenUpdatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  static void _showInAppBanner(RemoteMessage msg, GlobalKey<NavigatorState> nav) {
    final ctx = nav.currentContext;
    if (ctx == null) return;
    final title = msg.notification?.title ?? '';
    final body = msg.notification?.body ?? '';
    if (title.isEmpty && body.isEmpty) return;

    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
          if (body.isNotEmpty)
            Text(body, style: const TextStyle(fontSize: 13, color: Colors.white70)),
        ],
      ),
      backgroundColor: ThemeService.instance.colors.card,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 4),
    ));
  }

  static void _handleTap(RemoteMessage msg, GlobalKey<NavigatorState> nav) {
    // Navigation selon le type d'alerte
    final type = msg.data['type'];
    if (type == 'alert' && msg.data['deviceId'] != null) {
      nav.currentState?.pushNamed('/home');
    }
  }
}

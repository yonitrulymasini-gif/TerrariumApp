import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

/// Gère les deep links entrants : terraapp://setup?device=ESP32_XXX
/// ou https://terraapp.fr/setup?device=ESP32_XXX
class DeepLinkService {
  static final _appLinks = AppLinks();

  /// Démarre l'écoute des liens et navigue vers le flow d'appairage si besoin.
  static void listen(GlobalKey<NavigatorState> navigatorKey) {
    // Lien initial (app ouverte depuis un lien)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handle(uri, navigatorKey);
    });

    // Liens entrants pendant que l'app tourne
    _appLinks.uriLinkStream.listen((uri) {
      _handle(uri, navigatorKey);
    });
  }

  static void _handle(Uri uri, GlobalKey<NavigatorState> navigatorKey) {
    if (uri.pathSegments.contains('setup')) {
      final deviceId = uri.queryParameters['device'];
      if (deviceId != null && deviceId.isNotEmpty) {
        navigatorKey.currentState?.pushNamed('/pair', arguments: deviceId);
      }
    }
  }
}

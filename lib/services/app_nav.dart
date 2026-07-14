import 'package:flutter/foundation.dart';
import 'scenario_service.dart';

/// Gère la navigation entre les onglets du shell + les intentions de partage.
class AppNav extends ChangeNotifier {
  AppNav._();
  static final AppNav instance = AppNav._();

  // Index des onglets : 0 Accueil, 1 Mesures, 2 Communauté, 3 Scénarios, 4 Profil
  static const int communityTab = 2;

  int _tab = 0;
  int get tab => _tab;

  /// Scénario en attente de partage (déclenche l'ouverture du composer).
  TerraScenario? pendingScenario;

  void goToTab(int i) {
    if (_tab == i) return;
    _tab = i;
    notifyListeners();
  }

  /// Remet la navigation sur l'Accueil (onglet 0). À appeler à l'entrée dans
  /// l'app après connexion/inscription et à la déconnexion, car ce singleton
  /// conserve l'onglet pour toute la durée de vie du process.
  void reset() {
    pendingScenario = null;
    _tab = 0;
  }

  /// Bascule sur l'onglet Communauté avec un scénario à partager.
  void shareScenario(TerraScenario s) {
    pendingScenario = s;
    _tab = communityTab;
    notifyListeners();
  }

  /// Récupère et efface le scénario en attente (consommé par le composer).
  TerraScenario? consumePendingScenario() {
    final s = pendingScenario;
    pendingScenario = null;
    return s;
  }
}

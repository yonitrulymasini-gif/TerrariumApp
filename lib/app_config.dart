/// Configuration globale de l'app.
///
/// kDemoMode : permet de tester l'app sans matériel (ESP32) ni dépendre de
/// Firestore. En démo, l'appairage ajoute un appareil localement et la
/// télémétrie est simulée. Passer à false en production (vrai boîtier).
const bool kDemoMode = true;

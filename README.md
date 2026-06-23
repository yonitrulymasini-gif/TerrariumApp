# Terra 🌿 — Flutter App

Clone fidèle du design Lovable en Flutter.

## Structure du projet

```
lib/
├── main.dart                    # Point d'entrée
├── theme/
│   └── app_theme.dart           # ⭐ Toutes les couleurs & styles → modifie ici
├── widgets/
│   ├── terra_button.dart        # Bouton vert, Toggle switch, TerraCard
│   └── bottom_nav.dart          # Barre de navigation bas
└── screens/
    ├── onboarding_screen.dart   # 4 slides animés
    ├── login_screen.dart        # Connexion
    ├── main_shell.dart          # Conteneur avec bottom nav
    ├── home_screen.dart         # Accueil + prises rapides
    ├── mesures_screen.dart      # Capteurs + contrôle prises
    ├── communaute_screen.dart   # Feed communauté
    ├── scenarios_screen.dart    # Automatisations
    └── profil_screen.dart       # Mon compte
```

## Installation

### Prérequis
- Flutter SDK ≥ 3.0 : https://flutter.dev/docs/get-started/install
- Android Studio ou VS Code avec l'extension Flutter

### Lancer le projet

```bash
# 1. Installe les dépendances
flutter pub get

# 2. Lance sur un émulateur ou téléphone
flutter run

# 3. Build APK Android
flutter build apk --release

# 4. Build iOS (Mac uniquement)
flutter build ipa
```

## Personnalisation rapide

### Changer les couleurs → `lib/theme/app_theme.dart`
```dart
static const accentGreen = Color(0xFF9DC98D);   // Couleur bouton principal
static const bg = Color(0xFF0B1A10);             // Fond principal
static const liveGreen = Color(0xFF4ADE80);      // Vert "En ligne"
```

### Changer le nom d'utilisateur → `lib/screens/home_screen.dart`
```dart
Text('Yoni', style: AppTextStyles.serif28),  // ligne ~47
```

### Ajouter un scénario → `lib/screens/scenarios_screen.dart`
```dart
// Ajoute dans la liste _scenarios :
{
  'name': 'Mon scénario',
  'sub': 'Description courte',
  'icon': Icons.bolt_outlined,
  'color': const Color(0xFF4ADE80),
  'bg': const Color(0x264ADE80),
  'active': false,
},
```

### Connecter l'ESP32 (MQTT)
Pour les vraies données, ajoute le package `mqtt_client` dans `pubspec.yaml` :
```yaml
mqtt_client: ^10.0.0
```
Puis crée un service dans `lib/services/mqtt_service.dart`.

## Packages utilisés
- `google_fonts` — polices DM Serif Display + Inter

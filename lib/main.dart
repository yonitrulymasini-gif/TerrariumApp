import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:media_kit/media_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pairing_screen.dart';
import 'services/deep_link_service.dart';
import 'services/device_service.dart';
import 'services/notification_service.dart';
import 'services/camera_service.dart';
import 'services/theme_service.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await ThemeService.instance.load();
  await CameraService.instance.load();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const TerraApp());
}

class TerraApp extends StatefulWidget {
  const TerraApp({super.key});

  @override
  State<TerraApp> createState() => _TerraAppState();
}

class _TerraAppState extends State<TerraApp> {
  bool _notifInited = false;

  void _onDevicesChanged() {
    if (!_notifInited && DeviceService.instance.hasDevice) {
      _notifInited = true;
      NotificationService.init(_navigatorKey);
    }
  }

  @override
  void dispose() {
    DeviceService.instance.removeListener(_onDevicesChanged);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    DeepLinkService.listen(_navigatorKey);
    // Démarre le stream des devices dès que l'auth change
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        DeviceService.instance.startListening();
        // Notifs uniquement si l'user a déjà un device.
        // removeListener d'abord pour éviter un double enregistrement
        // (authStateChanges peut émettre plusieurs fois).
        DeviceService.instance.removeListener(_onDevicesChanged);
        DeviceService.instance.addListener(_onDevicesChanged);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (_, __) {
        final colors = ThemeService.instance.colors;
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: colors.isLight ? Brightness.dark : Brightness.light,
        ));
        return MaterialApp(
          title: 'Terra',
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(colors),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('fr')],
          home: const OnboardingScreen(),
          onGenerateRoute: (settings) {
            if (settings.name == '/pair') {
              final deviceId = settings.arguments as String?;
              return MaterialPageRoute(
                builder: (_) => PairingScreen(prefillDeviceId: deviceId),
              );
            }
            return null;
          },
        );
      },
    );
  }
}

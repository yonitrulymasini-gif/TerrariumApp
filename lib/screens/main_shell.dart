import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/app_nav.dart';
import '../widgets/bottom_nav.dart';
import 'home_screen.dart';
import 'mesures_screen.dart';
import 'communaute_screen.dart';
import 'scenarios_screen.dart';
import 'profil_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int get _index => AppNav.instance.tab;

  @override
  void initState() {
    super.initState();
    ThemeService.instance.addListener(_onTheme);
    AppNav.instance.addListener(_onTheme);
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onTheme);
    AppNav.instance.removeListener(_onTheme);
    super.dispose();
  }

  void _onTheme() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    // Clavier ouvert → on masque la navbar (sinon elle flotte au-dessus).
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    // Non-const VOLONTAIRE : de nouvelles instances à chaque build pour que les
    // écrans se reconstruisent quand le thème change (l'état est préservé par
    // position dans l'IndexedStack). Ne pas remettre `const` ici.
    // ignore: prefer_const_constructors
    final screens = <Widget>[
      // ignore: prefer_const_constructors
      HomeScreen(),
      // ignore: prefer_const_constructors
      MesuresScreen(),
      // ignore: prefer_const_constructors
      CommunauteScreen(),
      // ignore: prefer_const_constructors
      ScenariosScreen(),
      // ignore: prefer_const_constructors
      ProfilScreen(),
    ];
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: c.bg)),
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.9), radius: 1.1,
              colors: [c.radialTop.withValues(alpha: 0.5), Colors.transparent],
            ),
          ))),
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, 1.3), radius: 1.1,
              colors: [c.radialBottom.withValues(alpha: 0.4), Colors.transparent],
            ),
          ))),
          IndexedStack(index: _index, children: screens),
          if (!keyboardOpen)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: TerraBottomNav(
                currentIndex: _index,
                onTap: (i) => AppNav.instance.goToTab(i),
              ),
            ),
        ],
      ),
    );
  }
}

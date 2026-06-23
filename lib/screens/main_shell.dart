import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
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
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    MesuresScreen(),
    CommunauteScreen(),
    ScenariosScreen(),
    ProfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fond lumineux jungle commun à tous les écrans
          Positioned.fill(child: ColoredBox(color: AppColors.bg)),
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.9), radius: 1.1,
              colors: [const Color(0xFF1F3D2B).withValues(alpha: 0.5), Colors.transparent],
            ),
          ))),
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, 1.3), radius: 1.1,
              colors: [const Color(0xFF162318).withValues(alpha: 0.4), Colors.transparent],
            ),
          ))),
          IndexedStack(index: _index, children: _screens),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: TerraBottomNav(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
            ),
          ),
        ],
      ),
    );
  }
}

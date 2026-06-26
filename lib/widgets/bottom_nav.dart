import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class TerraBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const TerraBottomNav({super.key, required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Accueil'),
    _NavItem(icon: Icons.show_chart_outlined, activeIcon: Icons.show_chart, label: 'Mesures'),
    _NavItem(icon: Icons.people_outline, activeIcon: Icons.people_rounded, label: 'Communauté'),
    _NavItem(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome, label: 'Scénarios'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final themeColor = ThemeService.instance.colors.primary;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 16),
      child: _GlassContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / _items.length;
              return Stack(
                children: [
                  // Pill active qui glisse
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOutCubic,
                    left: currentIndex * itemWidth + 4,
                    width: itemWidth - 8,
                    top: 3, bottom: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            themeColor.withValues(alpha: 0.32),
                            themeColor.withValues(alpha: 0.16),
                          ],
                        ),
                        border: Border.all(
                          color: themeColor.withValues(alpha: 0.40),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: themeColor.withValues(alpha: 0.20),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Items
                  Row(
                    children: List.generate(_items.length, (i) {
                      final active = i == currentIndex;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => onTap(i),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              AnimatedScale(
                                scale: active ? 1.15 : 1.0,
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOutBack,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    active ? _items[i].activeIcon : _items[i].icon,
                                    key: ValueKey(active),
                                    size: 22,
                                    color: active
                                        ? themeColor
                                        : Colors.white.withValues(alpha: 0.60),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                                  color: active
                                      ? themeColor
                                      : Colors.white.withValues(alpha: 0.55),
                                ),
                                child: Text(_items[i].label, overflow: TextOverflow.ellipsis, maxLines: 1),
                              ),
                            ]),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  const _GlassContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    final themeColor = ThemeService.instance.colors.primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 50,
            spreadRadius: -8,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: themeColor.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  themeColor.withValues(alpha: 0.10),
                  themeColor.withValues(alpha: 0.03),
                ],
              ),
              border: Border.all(
                color: themeColor.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  Colors.white.withValues(alpha: 0.07),
                  Colors.transparent,
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xCC0D1A10),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 32, offset: const Offset(0, 8)),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / _items.length;
                return Stack(
                  children: [
                    // Pill qui glisse
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      left: currentIndex * itemWidth + 4,
                      width: itemWidth - 8,
                      top: 0, bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(28),
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
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    active ? _items[i].activeIcon : _items[i].icon,
                                    key: ValueKey(active),
                                    size: 24,
                                    color: active ? AppColors.primary : Colors.white.withValues(alpha: 0.45),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _items[i].label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                                    color: active ? AppColors.primary : Colors.white.withValues(alpha: 0.45),
                                  ),
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
      ),
    );
  }
}

class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

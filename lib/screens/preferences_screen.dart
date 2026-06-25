import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});
  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  String get _theme => ThemeService.instance.name;

  @override
  void initState() {
    super.initState();
    ThemeService.instance.addListener(_onChange);
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  Future<void> _selectTheme(String value) =>
      ThemeService.instance.setTheme(value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeService.instance.colors.bg,
      body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(Icons.arrow_back, color: AppColors.textSecondary, size: 22),
            ),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('PARAMÈTRES', style: AppTextStyles.eyebrow),
              Text('Préférences', style: AppTextStyles.serif28),
            ]),
          ]),
        ),
        const SizedBox(height: 28),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('THÈME', style: AppTextStyles.eyebrow),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _ThemeCard(
                name: 'Jungle',
                icon: Icons.eco_outlined,
                bg: const Color(0xFF0D1F14),
                accent: const Color(0xFF4CAF72),
                selected: _theme == 'jungle',
                onTap: () => _selectTheme('jungle'),
              )),
              const SizedBox(width: 14),
              Expanded(child: _ThemeCard(
                name: 'Désert',
                icon: Icons.wb_sunny_outlined,
                bg: const Color(0xFF1F1508),
                accent: const Color(0xFFD48B3A),
                selected: _theme == 'desert',
                onTap: () => _selectTheme('desert'),
              )),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _ThemeCard(
                name: 'Océan',
                icon: Icons.water_outlined,
                bg: const Color(0xFF050E1A),
                accent: const Color(0xFF38BDF8),
                selected: _theme == 'ocean',
                onTap: () => _selectTheme('ocean'),
              )),
              const SizedBox(width: 14),
              Expanded(child: _ThemeCard(
                name: 'Roche',
                icon: Icons.landscape_outlined,
                bg: const Color(0xFF0E1012),
                accent: const Color(0xFF94A3B8),
                selected: _theme == 'roche',
                onTap: () => _selectTheme('roche'),
              )),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _ThemeCard(
                name: 'Nuit',
                icon: Icons.nightlight_outlined,
                bg: const Color(0xFF07091A),
                accent: const Color(0xFF9D8DF5),
                selected: _theme == 'nuit',
                onTap: () => _selectTheme('nuit'),
              )),
              const SizedBox(width: 14),
              Expanded(child: _ThemeCard(
                name: 'Jour',
                icon: Icons.wb_sunny_outlined,
                bg: const Color(0xFFF5F2EC),
                accent: const Color(0xFF2C6B3E),
                selected: _theme == 'jour',
                onTap: () => _selectTheme('jour'),
              )),
            ]),
          ]),
        ),
      ])),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color bg;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.name, required this.icon, required this.bg,
    required this.accent, required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accent;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 140,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? accent : AppColors.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected ? [BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))] : [],
          ),
          child: Stack(children: [
            Positioned(bottom: -20, right: -20, child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(shape: BoxShape.circle, color: effectiveAccent.withValues(alpha: 0.08)),
            )),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: effectiveAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: effectiveAccent),
                ),
                const Spacer(),
                Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: effectiveAccent)),
                const SizedBox(height: 2),
                Text(selected ? 'Actif' : 'Inactif',
                    style: TextStyle(fontSize: 11, color: effectiveAccent.withValues(alpha: 0.7))),
              ]),
            ),

            if (selected) Positioned(top: 12, right: 12, child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 13, color: Colors.white),
            )),
          ]),
        ),
      ),
    );
  }
}

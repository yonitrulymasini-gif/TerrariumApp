import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ScenariosScreen extends StatefulWidget {
  const ScenariosScreen({super.key});
  @override
  State<ScenariosScreen> createState() => _ScenariosScreenState();
}

class _ScenariosScreenState extends State<ScenariosScreen> {
  final _enabled = [true, true, false, true];

  static const _scenarios = [
    {'icon': Icons.wb_sunny_outlined, 'name': 'Cycle jour', 'desc': 'Lampe UV ON de 8h à 20h'},
    {'icon': Icons.nightlight_round_outlined, 'name': 'Cycle nuit', 'desc': 'Chauffage ON si T° < 22°C'},
    {'icon': Icons.water_drop_outlined, 'name': 'Brumisation', 'desc': 'Brumisateur 30s toutes les 4h'},
    {'icon': Icons.thermostat_outlined, 'name': 'Alerte canicule', 'desc': 'Ventilateur ON si T° > 32°C'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 120),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('AUTOMATISATIONS', style: AppTextStyles.eyebrow),
                const SizedBox(height: 6),
                Text('Scénarios', style: AppTextStyles.serif28),
              ]),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.primary,
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: Offset(0, 4))],
                ),
                child: const Icon(Icons.add, color: AppColors.bg, size: 22),
              ),
            ]),
            const SizedBox(height: 20),

            Container(
              decoration: glassCard(radius: 24),
              padding: const EdgeInsets.all(18),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.auto_awesome_outlined, color: AppColors.accent, size: 20),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Idée', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  SizedBox(height: 4),
                  Text("Les scénarios déclenchent une action sur tes prises en fonction des capteurs ou de l'heure.",
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5)),
                ])),
              ]),
            ),
            const SizedBox(height: 20),

            const Text('EXEMPLES', style: AppTextStyles.eyebrow),
            const SizedBox(height: 12),

            for (int i = 0; i < _scenarios.length; i++) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: glassCard(radius: 20),
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _enabled[i] ? AppColors.primary.withValues(alpha: 0.20) : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(_scenarios[i]['icon'] as IconData, size: 20,
                          color: _enabled[i] ? AppColors.primary : AppColors.textMuted),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_scenarios[i]['name'] as String,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                      Text(_scenarios[i]['desc'] as String,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ])),
                    GestureDetector(
                      onTap: () => setState(() => _enabled[i] = !_enabled[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44, height: 26,
                        decoration: BoxDecoration(
                          color: _enabled[i] ? AppColors.primary : const Color(0xFF2A3A2A),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: _enabled[i] ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            width: 20, height: 20,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.bg,
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _outlets = [
    {'name': 'Prise 1', 'icon': Icons.power_outlined, 'state': false},
    {'name': 'Prise 2', 'icon': Icons.power_outlined, 'state': false},
    {'name': 'Prise 3', 'icon': Icons.power_outlined, 'state': false},
    {'name': 'Prise 4', 'icon': Icons.power_outlined, 'state': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 32, 0, 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Bonjour', style: AppTextStyles.eyebrow),
                            const SizedBox(height: 4),
                            Text('Yoni', style: AppTextStyles.serif28),
                          ],
                        ),
                        Stack(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: glassCard(radius: 22),
                              child: const Icon(Icons.notifications_outlined,
                                  color: AppColors.textPrimary, size: 20),
                            ),
                            Positioned(
                              top: 10, right: 10,
                              child: Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.accent,
                                  border: Border.all(color: AppColors.bg, width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Carte terrarium
                  _TerrariumCard(),
                  const SizedBox(height: 20),

                  // Prises rapides
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('PRISES RAPIDES', style: AppTextStyles.eyebrow),
                      Text('Tout voir',
                          style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.1,
                    ),
                    itemCount: _outlets.length,
                    itemBuilder: (_, i) {
                      final o = _outlets[i];
                      final isOn = o['state'] as bool;
                      final icon = o['icon'] as IconData;
                      return GestureDetector(
                        onTap: () => setState(() => _outlets[i]['state'] = !isOn),
                        child: Container(
                          decoration: glassCard(radius: 20).copyWith(
                            border: isOn
                                ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
                                : Border.all(color: const Color(0x40507850), width: 1),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: isOn
                                      ? AppColors.primary.withValues(alpha: 0.20)
                                      : Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(icon, size: 18,
                                    color: isOn ? AppColors.primary : AppColors.textMuted),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(o['name'] as String,
                                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 2),
                                    Text(isOn ? 'Allumé' : 'Éteint',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // CTA ajouter terrarium
                  Container(
                    width: double.infinity,
                    decoration: glassCard(radius: 24),
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 0),
                    child: Column(
                      children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                          child: const Icon(Icons.add, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(height: 12),
                        const Text('Ajoute un autre terrarium',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        const Text('Connecte ton ESP32 pour démarrer la surveillance',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.6)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 16, offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Text('Configurer',
                              style: GoogleFonts.inter(
                                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.bg)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TerrariumCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: glassCard(radius: 24),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 8)],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('En ligne',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary)),
                  ],
                ),
                const Text('Terrarium #1',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Row(
              children: [
                const Icon(Icons.eco_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Text('Jungle tropicale',
                    style: GoogleFonts.fraunces(fontSize: 22, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x18507850))),
            ),
            child: Row(
              children: [
                Expanded(child: _MetricCell(
                  icon: Icons.thermostat_outlined,
                  iconColor: Color(0xFFFB923C),
                  label: 'TEMPÉRATURE', unit: '°C',
                )),
                Container(width: 1, color: const Color(0x18507850)),
                Expanded(child: _MetricCell(
                  icon: Icons.water_drop_outlined,
                  iconColor: Color(0xFF38BDF8),
                  label: 'HUMIDITÉ', unit: '%',
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String unit;

  const _MetricCell({required this.icon, required this.iconColor, required this.label, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w500, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('—', style: GoogleFonts.fraunces(fontSize: 32, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _JungleBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(children: [
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
      ]),
    );
  }
}

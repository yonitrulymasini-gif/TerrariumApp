import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class MesuresScreen extends StatefulWidget {
  const MesuresScreen({super.key});
  @override
  State<MesuresScreen> createState() => _MesuresScreenState();
}

class _MesuresScreenState extends State<MesuresScreen> {
  final _states = [false, false, false, false];
  static const _relayNames = ['Lampe UV', 'Chauffage', 'Brumisateur', 'Ventilateur'];
  static const _relaySubs = ['Prise 1', 'Prise 2', 'Prise 3', 'Prise 4'];
  static const _relayIcons = [Icons.lightbulb_outline, Icons.local_fire_department_outlined, Icons.cloud_outlined, Icons.air_outlined];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 120),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('MESURES', style: AppTextStyles.eyebrow),
            const SizedBox(height: 6),
            Text('Dashboard', style: AppTextStyles.serif28),
            const SizedBox(height: 24),

            _SensorCard(icon: Icons.thermostat_outlined, iconColor: Color(0xFFFB923C), label: 'Température air', sensor: 'AM2320', value: '—', unit: '°C', large: true),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _SensorCard(icon: Icons.thermostat_outlined, iconColor: Color(0xFFFB923C), label: 'Sonde 1', sensor: 'DS18B20', value: '—', unit: '°C')),
              const SizedBox(width: 12),
              Expanded(child: _SensorCard(icon: Icons.thermostat_outlined, iconColor: Color(0xFFFB923C), label: 'Sonde 2', sensor: 'DS18B20', value: '—', unit: '°C')),
            ]),
            const SizedBox(height: 12),
            _SensorCard(icon: Icons.water_drop_outlined, iconColor: Color(0xFF38BDF8), label: 'Humidité', sensor: 'AM2320', value: '—', unit: '%', large: true),
            const SizedBox(height: 28),

            const Text('CONTRÔLE DES PRISES', style: AppTextStyles.eyebrow),
            const SizedBox(height: 12),

            for (int i = 0; i < 4; i++) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: glassCard(radius: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _states[i] ? AppColors.primary.withValues(alpha: 0.20) : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(_relayIcons[i], size: 20, color: _states[i] ? AppColors.primary : AppColors.textMuted),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_relayNames[i], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                      Text(_relaySubs[i], style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ])),
                    GestureDetector(
                      onTap: () => setState(() => _states[i] = !_states[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48, height: 28,
                        decoration: BoxDecoration(
                          color: _states[i] ? AppColors.primary : const Color(0xFF2A3A2A),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: _states[i] ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            width: 22, height: 22,
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

            const SizedBox(height: 8),
            const Center(child: Text('Connecte ton ESP32 via MQTT pour activer les données en direct',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.6))),
          ]),
        ),
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final IconData icon; final Color iconColor; final String label;
  final String sensor; final String value; final String unit; final bool large;
  const _SensorCard({required this.icon, required this.iconColor, required this.label,
      required this.sensor, required this.value, required this.unit, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: glassCard(radius: 20),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(icon, size: 14, color: iconColor), const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
          ]),
          Text(sensor, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ]),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(value, style: GoogleFonts.fraunces(fontSize: large ? 42 : 28, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(width: 4),
          Text(unit, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ]),
      ]),
    );
  }
}

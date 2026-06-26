import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../app_config.dart';
import '../services/device_service.dart';
import '../services/telemetry_service.dart';
import '../utils/fade_route.dart';
import 'pairing_screen.dart';
import 'qr_scanner_screen.dart';

class MesuresScreen extends StatefulWidget {
  const MesuresScreen({super.key});
  @override
  State<MesuresScreen> createState() => _MesuresScreenState();
}

class _MesuresScreenState extends State<MesuresScreen> {
  @override
  void initState() {
    super.initState();
    DeviceService.instance.addListener(_onDeviceChange);
  }

  @override
  void dispose() {
    DeviceService.instance.removeListener(_onDeviceChange);
    super.dispose();
  }

  void _onDeviceChange() => setState(() {});

  Future<void> _renameOutlet(BuildContext context, int index, String current) async {
    final ctrl = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ThemeService.instance.colors.card,
        title: Text('Renommer la prise', style: TextStyle(color: ThemeService.instance.colors.textPrimary, fontSize: 17)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: ThemeService.instance.colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Nom de la prise',
            hintStyle: TextStyle(color: ThemeService.instance.colors.textMuted),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: ThemeService.instance.colors.border)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: ThemeService.instance.colors.primary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: ThemeService.instance.colors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: Text('OK', style: TextStyle(color: ThemeService.instance.colors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null) DeviceService.instance.setOutletName(index, result);
  }


  @override
  Widget build(BuildContext context) {
    if (!DeviceService.instance.hasDevice) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 120),
            child: Column(children: [
              Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('DONNÉES', style: AppTextStyles.eyebrow),
                  const SizedBox(height: 6),
                  Text('Mesures', style: AppTextStyles.serif28),
                ]),
              ]),
              const Spacer(),
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ThemeService.instance.colors.primary.withValues(alpha: 0.10),
                  border: Border.all(color: ThemeService.instance.colors.primary.withValues(alpha: 0.25), width: 2),
                ),
                child: Icon(Icons.show_chart, size: 44, color: ThemeService.instance.colors.primary.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 28),
              Text('Connecte ton Terra', style: AppTextStyles.serif28),
              const SizedBox(height: 12),
              Text(
                'Les mesures sont disponibles\nuniquement avec un boîtier connecté.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: ThemeService.instance.colors.textMuted, height: 1.7),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).push(fadeRoute(const PairingScreen())),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: ThemeService.instance.colors.primary,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [BoxShadow(color: ThemeService.instance.colors.primary.withValues(alpha: 0.3),
                        blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  child: Text('Connecter un appareil', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.bg)),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () async {
                  final deviceId = await Navigator.of(context).push<String>(
                    MaterialPageRoute(builder: (_) => const QrScannerScreen(), fullscreenDialog: true),
                  );
                  if (deviceId != null && context.mounted) {
                    Navigator.of(context).push(fadeRoute(PairingScreen(prefillDeviceId: deviceId)));
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: ThemeService.instance.colors.border),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.qr_code_scanner, color: ThemeService.instance.colors.textSecondary, size: 18),
                    const SizedBox(width: 10),
                    Text('Scanner le QR code', style: TextStyle(fontSize: 15, color: ThemeService.instance.colors.textSecondary)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 120),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('MESURES', style: AppTextStyles.eyebrow),
            const SizedBox(height: 6),
            Text('Dashboard', style: AppTextStyles.serif28),
            const SizedBox(height: 24),

            StreamBuilder<TelemetryData>(
              stream: TelemetryService.stream(DeviceService.instance.devices.first.serialId),
              builder: (context, snap) {
                final data = snap.data ?? TelemetryData.empty();
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _SensorCard(icon: Icons.thermostat_outlined, iconColor: const Color(0xFFFB923C), label: 'Température air', value: data.tempDisplay, unit: '°C', large: true),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _SensorCard(label: 'Point Froid', value: data.tempWithOffset(-0.6), unit: '°C')),
                    const SizedBox(width: 12),
                    Expanded(child: _SensorCard(label: 'Point Chaud', value: data.tempWithOffset(0.9), unit: '°C')),
                  ]),
                  const SizedBox(height: 12),
                  _SensorCard(icon: Icons.water_drop_outlined, iconColor: const Color(0xFF38BDF8), label: 'Humidité', value: data.humidDisplay, unit: '%', large: true),
                ]);
              },
            ),
            const SizedBox(height: 28),

            Text('CONTRÔLE DES PRISES', style: AppTextStyles.eyebrow),
            const SizedBox(height: 12),

            for (int i = 0; i < DeviceService.instance.outlets.length; i++) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Builder(builder: (context) {
                  final outlet = DeviceService.instance.outlets[i];
                  final isOn = outlet.on;
                  return GestureDetector(
                    onLongPress: () => _renameOutlet(context, i, outlet.name),
                    child: Container(
                      decoration: glassCard(radius: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: isOn ? ThemeService.instance.colors.primary.withValues(alpha: 0.20) : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.power_outlined, size: 20, color: isOn ? ThemeService.instance.colors.primary : ThemeService.instance.colors.textMuted),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(outlet.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: ThemeService.instance.colors.textPrimary)),
                          Text('Appui long pour renommer', style: TextStyle(fontSize: 11, color: ThemeService.instance.colors.textMuted)),
                        ])),
                        GestureDetector(
                          onTap: () => DeviceService.instance.setOutletState(i, !isOn),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48, height: 28,
                            decoration: BoxDecoration(
                              color: isOn ? ThemeService.instance.colors.primary : AppColors.card,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 200),
                              alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                width: 22, height: 22,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(shape: BoxShape.circle, color: ThemeService.instance.colors.bg,
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  );
                }),
              ),
            ],

            const SizedBox(height: 8),
            Center(child: Text(
                kDemoMode
                    ? 'Mode démo — données simulées (pas de boîtier réel)'
                    : 'Connecte ton ESP32 via MQTT pour activer les données en direct',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: ThemeService.instance.colors.textMuted, height: 1.6))),
          ]),
        ),
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String label;
  final String value;
  final String unit;
  final bool large;
  const _SensorCard({this.icon, this.iconColor, required this.label,
      required this.value, required this.unit, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: glassCard(radius: 20),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: iconColor), const SizedBox(width: 6),
          ],
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ThemeService.instance.colors.textMuted)),
        ]),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(value, style: GoogleFonts.fraunces(fontSize: large ? 42 : 28, fontWeight: FontWeight.w500, color: ThemeService.instance.colors.textPrimary)),
          const SizedBox(width: 4),
          Text(unit, style: TextStyle(fontSize: 13, color: ThemeService.instance.colors.textMuted)),
        ]),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/device_service.dart';
import '../services/telemetry_service.dart';
import '../utils/fade_route.dart';
import '../services/app_nav.dart';
import 'alerts_screen.dart';
import 'pairing_screen.dart';
import 'qr_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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


  @override
  Widget build(BuildContext context) {
    if (!DeviceService.instance.hasDevice) {
      return _EmptyState();
    }

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
                            Text('Bonjour', style: AppTextStyles.eyebrow),
                            const SizedBox(height: 4),
                            Text('Yoni', style: AppTextStyles.serif28),
                          ],
                        ),
                        StreamBuilder<int>(
                          stream: AlertsScreen.unreadCount(),
                          builder: (ctx, snap) {
                            final count = snap.data ?? 0;
                            return GestureDetector(
                              onTap: () => Navigator.of(context).push(fadeRoute(const AlertsScreen())),
                              child: Stack(children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: glassCard(radius: 22),
                                  child: Icon(Icons.notifications_outlined,
                                      color: ThemeService.instance.colors.textPrimary, size: 20),
                                ),
                                if (count > 0) Positioned(
                                  top: 8, right: 8,
                                  child: Container(
                                    width: count > 9 ? 18 : 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(7),
                                      border: Border.all(color: ThemeService.instance.colors.bg, width: 1.5),
                                    ),
                                    child: Center(child: Text(
                                      count > 9 ? '9+' : '$count',
                                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: ThemeService.instance.colors.bg),
                                    )),
                                  ),
                                ),
                              ]),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Carte terrarium
                  _TerrariumCard(device: DeviceService.instance.devices.first),
                  const SizedBox(height: 20),

                  // Prises rapides
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PRISES RAPIDES', style: AppTextStyles.eyebrow),
                      GestureDetector(
                        onTap: () => AppNav.instance.goToTab(1),
                        child: Text('Tout voir',
                            style: TextStyle(fontSize: 13, color: ThemeService.instance.colors.primary, fontWeight: FontWeight.w500)),
                      ),
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
                    itemCount: DeviceService.instance.outlets.length,
                    itemBuilder: (_, i) {
                      final o = DeviceService.instance.outlets[i];
                      final isOn = o.on;
                      return GestureDetector(
                        onTap: () => DeviceService.instance.setOutletState(i, !isOn),
                        child: Container(
                          decoration: glassCard(radius: 20).copyWith(
                            border: isOn
                                ? Border.all(color: ThemeService.instance.colors.primary.withValues(alpha: 0.4))
                                : Border.all(color: AppColors.border, width: 1),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: isOn
                                      ? ThemeService.instance.colors.primary.withValues(alpha: 0.20)
                                      : Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.power_outlined, size: 18,
                                    color: isOn ? ThemeService.instance.colors.primary : ThemeService.instance.colors.textMuted),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(o.name,
                                        style: TextStyle(fontSize: 13, color: ThemeService.instance.colors.textPrimary, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 2),
                                    Text(isOn ? 'Allumé' : 'Éteint',
                                        style: TextStyle(fontSize: 11, color: ThemeService.instance.colors.textMuted)),
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
                            color: ThemeService.instance.colors.primary.withValues(alpha: 0.15),
                          ),
                          child: Icon(Icons.add, color: ThemeService.instance.colors.primary, size: 24),
                        ),
                        const SizedBox(height: 12),
                        Text('Ajoute un autre terrarium',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: ThemeService.instance.colors.textPrimary, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text('Connecte ton ESP32 pour démarrer la surveillance',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: ThemeService.instance.colors.textMuted, height: 1.6)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: ThemeService.instance.colors.primary,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: ThemeService.instance.colors.primary.withValues(alpha: 0.25),
                                blurRadius: 16, offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Text('Configurer',
                              style: GoogleFonts.inter(
                                fontSize: 14, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.bg)),
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
  final TerraDevice device;
  const _TerrariumCard({required this.device});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TelemetryData>(
      stream: TelemetryService.stream(device.serialId),
      builder: (context, snap) {
        final data = snap.data ?? TelemetryData.empty();
        final online = device.online;

        return Container(
          decoration: glassCard(radius: 24),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: online ? ThemeService.instance.colors.primary : ThemeService.instance.colors.textMuted,
                      boxShadow: online ? [BoxShadow(color: ThemeService.instance.colors.primary.withValues(alpha: 0.6), blurRadius: 8)] : [],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(online ? 'En ligne' : 'Hors ligne',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                          color: online ? ThemeService.instance.colors.primary : ThemeService.instance.colors.textMuted)),
                ]),
                Text(device.name, style: TextStyle(fontSize: 12, color: ThemeService.instance.colors.textMuted)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Row(children: [
                Icon(Icons.eco_outlined, color: ThemeService.instance.colors.primary, size: 22),
                const SizedBox(width: 10),
                Text('Jungle tropicale',
                    style: GoogleFonts.fraunces(fontSize: 22, color: ThemeService.instance.colors.textPrimary, fontWeight: FontWeight.w600)),
              ]),
            ),
            Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x18507850)))),
              child: Row(children: [
                Expanded(child: _MetricCell(
                  icon: Icons.thermostat_outlined,
                  iconColor: const Color(0xFFFB923C),
                  label: 'TEMPÉRATURE',
                  value: data.tempDisplay, unit: '°C',
                )),
                Container(width: 1, color: AppColors.borderLight),
                Expanded(child: _MetricCell(
                  icon: Icons.water_drop_outlined,
                  iconColor: const Color(0xFF38BDF8),
                  label: 'HUMIDITÉ',
                  value: data.humidDisplay, unit: '%',
                )),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

class _MetricCell extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;

  const _MetricCell({required this.icon, required this.iconColor, required this.label, required this.value, required this.unit});

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
              Text(label, style: TextStyle(fontSize: 10, color: ThemeService.instance.colors.textMuted, fontWeight: FontWeight.w500, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: GoogleFonts.fraunces(fontSize: 32, color: ThemeService.instance.colors.textPrimary, fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              Text(unit, style: TextStyle(fontSize: 13, color: ThemeService.instance.colors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty state (aucun device associé) ──────────────────────────────────────

class _EmptyState extends StatelessWidget {
  // Pas de const : ce widget lit le thème et doit pouvoir se reconstruire.
  // ignore: prefer_const_constructors_in_immutables
  _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 120),
          child: Column(children: [
            // Header
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ACCUEIL', style: AppTextStyles.eyebrow),
                const SizedBox(height: 4),
                Text('Tableau de bord', style: AppTextStyles.serif28),
              ]),
            ]),

            const Spacer(),

            // Illustration centrale
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ThemeService.instance.colors.primary.withValues(alpha: 0.10),
                border: Border.all(color: ThemeService.instance.colors.primary.withValues(alpha: 0.25), width: 2),
              ),
              child: Icon(Icons.eco_outlined, size: 48, color: ThemeService.instance.colors.primary.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 28),
            Text('Connecte ton Terra', style: AppTextStyles.serif28),
            const SizedBox(height: 12),
            Text(
              'Scan le QR code dans ta boîte\npour appairer ton boîtier.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: ThemeService.instance.colors.textMuted, height: 1.7),
            ),

            const Spacer(),

            // CTA principal
            GestureDetector(
              onTap: () => Navigator.of(context).push(fadeRoute(const PairingScreen())),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: ThemeService.instance.colors.primary,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [BoxShadow(
                    color: ThemeService.instance.colors.primary.withValues(alpha: 0.3),
                    blurRadius: 20, offset: const Offset(0, 6),
                  )],
                ),
                child: Text('Connecter un appareil',
                    textAlign: TextAlign.center,
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
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/device_service.dart';
import '../services/scenario_service.dart';
import '../services/app_nav.dart';
import '../utils/fade_route.dart';
import 'pairing_screen.dart';
import 'qr_scanner_screen.dart';
import 'scenario_edit_screen.dart';

class ScenariosScreen extends StatefulWidget {
  const ScenariosScreen({super.key});
  @override
  State<ScenariosScreen> createState() => _ScenariosScreenState();
}

class _ScenariosScreenState extends State<ScenariosScreen> {
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
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 120),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('AUTOMATISATIONS', style: AppTextStyles.eyebrow),
                  const SizedBox(height: 6),
                  Text('Scénarios', style: AppTextStyles.serif28),
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
                child: Icon(Icons.auto_awesome_outlined, size: 44, color: ThemeService.instance.colors.primary.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 28),
              Text('Connecte ton Terra', style: AppTextStyles.serif28),
              const SizedBox(height: 12),
              Text(
                'Les scénarios sont disponibles\nuniquement avec un boîtier connecté.',
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AUTOMATISATIONS', style: AppTextStyles.eyebrow),
                const SizedBox(height: 6),
                Text('Scénarios', style: AppTextStyles.serif28),
              ]),
              GestureDetector(
                onTap: () => Navigator.of(context).push(fadeRoute(const ScenarioEditScreen())),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: ThemeService.instance.colors.primary,
                    boxShadow: [BoxShadow(color: ThemeService.instance.colors.primary.withValues(alpha: 0.3),
                        blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: Icon(Icons.add, color: ThemeService.instance.colors.bg, size: 22),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: StreamBuilder<List<TerraScenario>>(
              stream: ScenarioService.stream(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: ThemeService.instance.colors.primary));
                }
                final scenarios = snap.data ?? [];

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Bannière info
                    Container(
                      decoration: glassCard(radius: 24),
                      padding: const EdgeInsets.all(18),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.auto_awesome_outlined, color: AppColors.accent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Comment ça marche ?',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.textPrimary)),
                          const SizedBox(height: 4),
                          Text("Un scénario déclenche une action sur tes prises selon la température, l'humidité ou l'heure.",
                              style: TextStyle(fontSize: 13, color: ThemeService.instance.colors.textMuted, height: 1.5)),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    if (scenarios.isEmpty) ...[
                      const SizedBox(height: 40),
                      Center(child: Column(children: [
                        Icon(Icons.auto_awesome_outlined, size: 48,
                            color: ThemeService.instance.colors.textMuted.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text('Aucun scénario',
                            style: TextStyle(fontSize: 16, color: ThemeService.instance.colors.textMuted)),
                        const SizedBox(height: 8),
                        Text('Appuie sur + pour en créer un.',
                            style: TextStyle(fontSize: 13, color: ThemeService.instance.colors.textHint)),
                      ])),
                    ] else ...[
                      Text('MES SCÉNARIOS', style: AppTextStyles.eyebrow),
                      const SizedBox(height: 12),
                      ...scenarios.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ScenarioRow(scenario: s),
                      )),
                    ],
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _ScenarioRow extends StatelessWidget {
  final TerraScenario scenario;
  const _ScenarioRow({required this.scenario});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(fadeRoute(ScenarioEditScreen(existing: scenario))),
      onLongPress: () => _showOptions(context),
      child: Container(
        decoration: glassCard(radius: 20),
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: scenario.enabled
                  ? ThemeService.instance.colors.primary.withValues(alpha: 0.20)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(scenario.icon, size: 20,
                color: scenario.enabled ? ThemeService.instance.colors.primary : ThemeService.instance.colors.textMuted),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(scenario.name,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: ThemeService.instance.colors.textPrimary)),
            Text(scenario.description,
                style: TextStyle(fontSize: 12, color: ThemeService.instance.colors.textMuted)),
          ])),
          const SizedBox(width: 8),
          // Bouton partager
          GestureDetector(
            onTap: () => AppNav.instance.shareScenario(scenario),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: ThemeService.instance.colors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.ios_share, size: 17, color: ThemeService.instance.colors.primary),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => ScenarioService.toggle(scenario.id, !scenario.enabled),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 26,
              decoration: BoxDecoration(
                color: scenario.enabled ? ThemeService.instance.colors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(13),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: scenario.enabled ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20, height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: ThemeService.instance.colors.bg,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeService.instance.colors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(color: ThemeService.instance.colors.border, borderRadius: BorderRadius.circular(2))),
          ListTile(
            leading: Icon(Icons.edit_outlined, color: ThemeService.instance.colors.textSecondary),
            title: Text('Modifier', style: TextStyle(color: ThemeService.instance.colors.textPrimary)),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(fadeRoute(ScenarioEditScreen(existing: scenario)));
            },
          ),
          ListTile(
            leading: Icon(Icons.ios_share, color: ThemeService.instance.colors.primary),
            title: Text('Partager', style: TextStyle(color: ThemeService.instance.colors.primary)),
            onTap: () {
              Navigator.of(context).pop();
              AppNav.instance.shareScenario(scenario);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.red),
            title: const Text('Supprimer', style: TextStyle(color: AppColors.red)),
            onTap: () {
              Navigator.of(context).pop();
              ScenarioService.delete(scenario.id);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

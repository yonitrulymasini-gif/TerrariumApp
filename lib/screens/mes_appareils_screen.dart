import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/device_service.dart';
import '../utils/fade_route.dart';
import '../widgets/terra_confirm_dialog.dart';
import 'pairing_screen.dart';
import 'qr_scanner_screen.dart';

class MesAppareilsScreen extends StatefulWidget {
  const MesAppareilsScreen({super.key});
  @override
  State<MesAppareilsScreen> createState() => _MesAppareilsScreenState();
}

class _MesAppareilsScreenState extends State<MesAppareilsScreen> {
  @override
  void initState() {
    super.initState();
    ThemeService.instance.addListener(_onThemeChange);
    DeviceService.instance.addListener(_onChange);
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onThemeChange);
    DeviceService.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  Future<void> _removeDevice(TerraDevice device) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeService.instance.colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Supprimer l\'appareil',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
        content: Text('Supprimer "${device.name}" de ton compte ?',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Annuler', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DeviceService.instance.removeDevice(device.serialId);
    }
  }

  Future<void> _renameDevice(TerraDevice device) async {
    final name = await showTerraInputDialog(
      context,
      icon: Icons.eco_outlined,
      title: 'Renommer le terrarium',
      message: 'Choisis un nouveau titre pour ce terrarium.',
      hint: 'Nom du terrarium',
      initialValue: device.name,
      confirmLabel: 'Enregistrer',
    );
    if (name != null && name.trim().isNotEmpty) {
      await DeviceService.instance.setDeviceName(device.serialId, name.trim());
    }
  }

  void _onThemeChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final devices = DeviceService.instance.devices;

    return Scaffold(
      backgroundColor: ThemeService.instance.colors.bg,
      body: SafeArea(child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(Icons.arrow_back, color: AppColors.textSecondary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('PARAMÈTRES', style: AppTextStyles.eyebrow),
              Text('Mes appareils', style: AppTextStyles.serif28),
            ])),
          ]),
        ),
        const SizedBox(height: 24),

        Expanded(child: devices.isEmpty
            ? _EmptyDevices(
                onConnect: () => Navigator.of(context).push(fadeRoute(const PairingScreen())),
                onScan: () async {
                  final id = await Navigator.of(context).push<String>(
                    MaterialPageRoute(builder: (_) => const QrScannerScreen(), fullscreenDialog: true));
                  if (id != null && context.mounted) {
                    Navigator.of(context).push(fadeRoute(PairingScreen(prefillDeviceId: id)));
                  }
                },
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  ...devices.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: glassCard(radius: 20),
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: (d.online ? ThemeService.instance.colors.primary : AppColors.textMuted).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.eco_outlined, size: 22,
                              color: d.online ? ThemeService.instance.colors.primary : AppColors.textMuted),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(d.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const SizedBox(height: 3),
                          Row(children: [
                            Container(
                              width: 7, height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: d.online ? ThemeService.instance.colors.primary : AppColors.textMuted,
                                boxShadow: d.online ? [BoxShadow(color: ThemeService.instance.colors.primary.withValues(alpha: 0.5), blurRadius: 6)] : [],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(d.online ? 'En ligne' : 'Hors ligne',
                                style: TextStyle(fontSize: 12,
                                    color: d.online ? ThemeService.instance.colors.primary : AppColors.textMuted)),
                            const SizedBox(width: 10),
                            Text('· ${d.serialId}',
                                style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                          ]),
                        ])),
                        GestureDetector(
                          onTap: () => _renameDevice(d),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: ThemeService.instance.colors.primary.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.edit_outlined, size: 17, color: ThemeService.instance.colors.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _removeDevice(d),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.red.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.delete_outline, size: 17, color: AppColors.red),
                          ),
                        ),
                      ]),
                    ),
                  )),

                  // Ajouter un appareil
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(fadeRoute(const PairingScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: ThemeService.instance.colors.border, style: BorderStyle.solid),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add, color: ThemeService.instance.colors.primary, size: 18),
                        SizedBox(width: 8),
                        Text('Ajouter un appareil',
                            style: TextStyle(fontSize: 15, color: ThemeService.instance.colors.primary, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  ),
                ],
              )),
      ])),
    );
  }
}

class _EmptyDevices extends StatelessWidget {
  final VoidCallback onConnect;
  final VoidCallback onScan;
  const _EmptyDevices({required this.onConnect, required this.onScan});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(shape: BoxShape.circle,
            color: ThemeService.instance.colors.primary.withValues(alpha: 0.10),
            border: Border.all(color: ThemeService.instance.colors.primary.withValues(alpha: 0.25), width: 2)),
        child: Icon(Icons.eco_outlined, size: 36, color: ThemeService.instance.colors.primary.withValues(alpha: 0.7)),
      ),
      const SizedBox(height: 20),
      Text('Aucun appareil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      Text('Scan le QR code dans ta boîte\npour appairer ton boîtier.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.6)),
      const SizedBox(height: 32),
      GestureDetector(
        onTap: onConnect,
        child: Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: ThemeService.instance.colors.primary, borderRadius: BorderRadius.circular(50),
              boxShadow: [BoxShadow(color: ThemeService.instance.colors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))]),
          child: Text('Connecter un appareil', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.bg)),
        ),
      ),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: onScan,
        child: Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), border: Border.all(color: ThemeService.instance.colors.border)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.qr_code_scanner, color: AppColors.textSecondary, size: 17),
            const SizedBox(width: 8),
            Text('Scanner le QR code', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          ]),
        ),
      ),
    ]),
  );
}

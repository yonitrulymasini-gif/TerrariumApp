import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/camera_service.dart';
import 'qr_scanner_screen.dart';

/// Écran plein écran pour connecter une caméra IP (URL RTSP),
/// calqué sur le flow "Connecte ton Terra" du boîtier.
class CameraConnectScreen extends StatefulWidget {
  const CameraConnectScreen({super.key});

  @override
  State<CameraConnectScreen> createState() => _CameraConnectScreenState();
}

class _CameraConnectScreenState extends State<CameraConnectScreen> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: CameraService.instance.rtspUrl ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _scanQr() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(
          promptText: 'Scanne le QR code\naffiché sur ta caméra IP',
          invalidMessage: 'QR code invalide : aucune URL RTSP trouvée',
          extractor: QrScannerScreen.extractCameraUrl,
        ),
        fullscreenDialog: true,
      ),
    );
    if (result != null) setState(() => _ctrl.text = result);
  }

  Future<void> _connect() async {
    final url = _ctrl.text.trim();
    if (url.isEmpty) return;
    await CameraService.instance.setUrl(url);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    await CameraService.instance.clear();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(children: [
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
          gradient: RadialGradient(center: const Alignment(0, -0.9), radius: 1.1,
              colors: [AppColors.canopy.withValues(alpha: 0.5), Colors.transparent]),
        ))),
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
          gradient: RadialGradient(center: const Alignment(0, 1.3), radius: 1.1,
              colors: [AppColors.card.withValues(alpha: 0.4), Colors.transparent]),
        ))),
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Text('Retour', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(28, 24, 28, 40 + bottomInset),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: AppColors.canopy, borderRadius: BorderRadius.circular(18)),
                    child: Icon(Icons.videocam_outlined, color: AppColors.iconGreen, size: 30),
                  ),
                  const SizedBox(height: 24),
                  Text('Connecte ta caméra', style: AppTextStyles.serif28),
                  const SizedBox(height: 8),
                  Text('Entre l\'URL RTSP de ta caméra IP\nou scanne le QR code affiché dessus.',
                      style: TextStyle(fontSize: 15, color: AppColors.textMuted, height: 1.6)),
                  const SizedBox(height: 40),

                  Text('URL RTSP', style: AppTextStyles.eyebrow),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: c.card, borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: c.border),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      keyboardType: TextInputType.url,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'rtsp://192.168.1.100:554/stream',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        prefixIcon: Icon(Icons.link, color: AppColors.textMuted, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 17),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: _connect,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: c.primary,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.3),
                            blurRadius: 16, offset: const Offset(0, 4))],
                      ),
                      child: Text('Connecter une caméra', textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.bg)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _scanQr,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: c.border),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.qr_code_scanner, color: AppColors.textSecondary, size: 17),
                        const SizedBox(width: 8),
                        Text('Scanner le QR code', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                      ]),
                    ),
                  ),
                  if (CameraService.instance.hasCamera) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _remove,
                      child: Center(
                        child: Text('Supprimer la caméra',
                            style: TextStyle(fontSize: 14, color: AppColors.red, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

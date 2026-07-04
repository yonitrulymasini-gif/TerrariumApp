import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/device_service.dart';
import '../utils/fade_route.dart';
import 'main_shell.dart';
import 'qr_scanner_screen.dart';

class PairingScreen extends StatefulWidget {
  final String? prefillDeviceId;
  const PairingScreen({super.key, this.prefillDeviceId});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  int _step = 0; // 0: device ID, 1: wifi, 2: connexion, 3: succès

  final _deviceCtrl = TextEditingController();
  final _ssidCtrl = TextEditingController();
  final _wifiPassCtrl = TextEditingController();
  bool _obscureWifi = true;
  bool _connecting = false; // ignore: unused_field

  @override
  void initState() {
    super.initState();
    ThemeService.instance.addListener(_onThemeChange);
    if (widget.prefillDeviceId != null) {
      _deviceCtrl.text = widget.prefillDeviceId!;
    }
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onThemeChange);
    _deviceCtrl.dispose();
    _ssidCtrl.dispose();
    _wifiPassCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0 && _deviceCtrl.text.trim().isEmpty) return;
    if (_step == 1 && (_ssidCtrl.text.trim().isEmpty)) return;
    if (_step == 1) { _startConnecting(); return; }
    setState(() => _step++);
  }

  Future<void> _startConnecting() async {
    setState(() { _step = 2; _connecting = true; });
    // Simule la connexion (à remplacer par vrai appel MQTT/API)
    await Future.delayed(const Duration(seconds: 3));
    DeviceService.instance.addDevice(TerraDevice(
      serialId: _deviceCtrl.text.trim(),
      name: 'Terrarium #${DeviceService.instance.devices.length + 1}',
      online: true,
    ));
    if (mounted) setState(() { _step = 3; _connecting = false; });
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(fadeRoute(const MainShell()), (_) => false);
  }

  void _onThemeChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeService.instance.colors.bg,
      body: Stack(children: [
        // Fond jungle
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
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                if (_step < 3)
                  GestureDetector(
                    onTap: () {
                      if (_step == 0) Navigator.of(context).pop();
                      else setState(() => _step--);
                    },
                    child: Text('Retour', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ),
                const Spacer(),
                if (_step < 3) _StepDots(current: _step, total: 2),
              ]),
            ),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(anim),
                    child: child,
                  ),
                ),
                child: _buildStep(),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _StepDeviceId(key: const ValueKey(0), ctrl: _deviceCtrl, onNext: _next);
      case 1: return _StepWifi(key: const ValueKey(1), ssidCtrl: _ssidCtrl,
          passCtrl: _wifiPassCtrl, obscure: _obscureWifi,
          onToggleObscure: () => setState(() => _obscureWifi = !_obscureWifi),
          onNext: _next);
      case 2: return _StepConnecting(key: const ValueKey(2));
      case 3: return _StepSuccess(key: const ValueKey(3), onHome: _goHome);
      default: return const SizedBox.shrink();
    }
  }
}

// ── Étape 1 : ID de l'appareil ──────────────────────────────────────────────

class _StepDeviceId extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onNext;
  const _StepDeviceId({super.key, required this.ctrl, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(28, 40, 28, 40 + bottomInset),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(color: AppColors.canopy, borderRadius: BorderRadius.circular(18)),
          child: Icon(Icons.qr_code_rounded, color: AppColors.iconGreen, size: 30),
        ),
        const SizedBox(height: 24),
        Text('Connecte ton Terra', style: AppTextStyles.serif28),
        const SizedBox(height: 8),
        Text('Entre l\'ID inscrit sous ton boîtier\nou scanne le QR code à l\'intérieur.',
            style: TextStyle(fontSize: 15, color: AppColors.textMuted, height: 1.6)),
        const SizedBox(height: 40),

        Text('ID DE L\'APPAREIL', style: AppTextStyles.eyebrow),
        const SizedBox(height: 10),
        _PairInput(
          ctrl: ctrl,
          hint: 'ESP32_XXXXXXXX',
          icon: Icons.memory_outlined,
          inputFormatters: [UpperCaseFormatter()],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final result = await Navigator.of(context).push<String>(
              MaterialPageRoute(builder: (_) => const QrScannerScreen(), fullscreenDialog: true),
            );
            if (result != null) ctrl.text = result;
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: ThemeService.instance.colors.border),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.qr_code_scanner, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 10),
              Text('Scanner le QR code', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            ]),
          ),
        ),
        const SizedBox(height: 32),
        _PairButton(label: 'Suivant', onTap: onNext),
      ]),
    );
  }
}

// ── Étape 2 : WiFi ──────────────────────────────────────────────────────────

class _StepWifi extends StatelessWidget {
  final TextEditingController ssidCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onNext;
  const _StepWifi({super.key, required this.ssidCtrl, required this.passCtrl,
      required this.obscure, required this.onToggleObscure, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(28, 40, 28, 40 + bottomInset),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(color: AppColors.canopy, borderRadius: BorderRadius.circular(18)),
          child: Icon(Icons.wifi_rounded, color: AppColors.iconGreen, size: 30),
        ),
        const SizedBox(height: 24),
        Text('Config WiFi', style: AppTextStyles.serif28),
        const SizedBox(height: 8),
        Text('Ton ESP32 va se connecter à ton réseau.\nUtilise le WiFi 2.4GHz.',
            style: TextStyle(fontSize: 15, color: AppColors.textMuted, height: 1.6)),
        const SizedBox(height: 40),

        Text('NOM DU RÉSEAU (SSID)', style: AppTextStyles.eyebrow),
        const SizedBox(height: 10),
        _PairInput(ctrl: ssidCtrl, hint: 'Mon WiFi', icon: Icons.wifi_outlined),
        const SizedBox(height: 20),

        Text('MOT DE PASSE', style: AppTextStyles.eyebrow),
        const SizedBox(height: 10),
        _PairInput(
          ctrl: passCtrl, hint: '••••••••',
          icon: Icons.lock_outline, obscure: obscure,
          suffix: GestureDetector(
            onTap: onToggleObscure,
            child: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textMuted, size: 18),
          ),
        ),
        const SizedBox(height: 32),
        _PairButton(label: 'Connecter', onTap: onNext),
      ]),
    );
  }
}

// ── Étape 3 : Connexion en cours ────────────────────────────────────────────

class _StepConnecting extends StatelessWidget {
  const _StepConnecting({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(28, 40, 28, 40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(
          width: 64, height: 64,
          child: CircularProgressIndicator(
            strokeWidth: 3, color: ThemeService.instance.colors.primary,
          ),
        ),
        SizedBox(height: 32),
        Text('Connexion en cours…', style: TextStyle(fontSize: 20, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
        SizedBox(height: 12),
        Text('Ton ESP32 se connecte au WiFi\net s\'enregistre sur nos serveurs.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.6)),
      ]),
    );
  }
}

// ── Étape 4 : Succès ────────────────────────────────────────────────────────

class _StepSuccess extends StatelessWidget {
  final VoidCallback onHome;
  const _StepSuccess({super.key, required this.onHome});

  @override
  Widget build(BuildContext context) {
    final prenom = FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 40),
      child: Column(children: [
        const Spacer(),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ThemeService.instance.colors.primary.withValues(alpha: 0.15),
            border: Border.all(color: ThemeService.instance.colors.primary.withValues(alpha: 0.4), width: 2),
          ),
          child: Icon(Icons.check_rounded, color: ThemeService.instance.colors.primary, size: 40),
        ),
        const SizedBox(height: 28),
        Text('Connecté !', style: AppTextStyles.serif28),
        const SizedBox(height: 12),
        Text(
          prenom.isNotEmpty
              ? 'Bien joué, $prenom !\nTon terrarium est en ligne et prêt.'
              : 'Ton terrarium est en ligne et prêt.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: AppColors.textMuted, height: 1.6),
        ),
        const Spacer(),
        _PairButton(label: 'Voir mon tableau de bord', onTap: onHome),
      ]),
    );
  }
}

// ── Widgets partagés ────────────────────────────────────────────────────────

class _PairInput extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;

  const _PairInput({required this.ctrl, required this.hint, required this.icon,
      this.obscure = false, this.suffix, this.inputFormatters});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeService.instance.colors.card, borderRadius: BorderRadius.circular(50),
        border: Border.all(color: ThemeService.instance.colors.border),
      ),
      child: TextField(
        controller: ctrl, obscureText: obscure,
        inputFormatters: inputFormatters,
        style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 15),
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
          suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.only(right: 16), child: suffix) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 17),
        ),
      ),
    );
  }
}

class _PairButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PairButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: ThemeService.instance.colors.primary,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [BoxShadow(color: ThemeService.instance.colors.primary.withValues(alpha: 0.3),
              blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.bg)),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  final int current;
  final int total;
  const _StepDots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(children: List.generate(total + 1, (i) => Container(
      margin: const EdgeInsets.only(left: 6),
      width: i == current ? 20 : 6, height: 6,
      decoration: BoxDecoration(
        color: i == current ? ThemeService.instance.colors.primary : ThemeService.instance.colors.border,
        borderRadius: BorderRadius.circular(3),
      ),
    )));
  }
}

class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) =>
      n.copyWith(text: n.text.toUpperCase(), selection: n.selection);
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import '../widgets/terra_button.dart';
import '../services/auth_service.dart';
import '../utils/fade_route.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loadingGoogle = false;
  bool _loadingApple = false;
  bool _loadingEmail = false;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _goHome() => Navigator.of(context).pushReplacement(fadeRoute(const MainShell()));
  void _goBack() => Navigator.of(context).pushReplacement(fadeRoute(const OnboardingScreen()));

  Future<void> _signInGoogle() async {
    setState(() => _loadingGoogle = true);
    try {
      final user = await AuthService.signInWithGoogle();
      if (user != null && mounted) _goHome();
    } catch (_) {
      if (mounted) _showError('Connexion Google impossible');
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  Future<void> _signInApple() async {
    setState(() => _loadingApple = true);
    try {
      final user = await AuthService.signInWithApple();
      if (user != null && mounted) _goHome();
    } catch (_) {
      if (mounted) _showError('Connexion Apple impossible');
    } finally {
      if (mounted) setState(() => _loadingApple = false);
    }
  }

  Future<void> _signInEmail() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    setState(() => _loadingEmail = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (mounted) _goHome();
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(e.message ?? 'Erreur de connexion');
    } finally {
      if (mounted) setState(() => _loadingEmail = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: _goBack,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(children: [
                const Icon(Icons.arrow_back, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 6),
                const Text('Retour', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ]),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
              child: Column(children: [
                Container(
                  width: 72, height: 72,
                  decoration: const BoxDecoration(color: Color(0xFF1E3626), shape: BoxShape.circle),
                  child: const Icon(Icons.eco, color: AppColors.iconGreen, size: 36),
                ),
                const SizedBox(height: 24),
                Text('Bon retour', style: AppTextStyles.serif32),
                const SizedBox(height: 8),
                const Text('Connecte-toi à ta jungle',
                    style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
                const SizedBox(height: 36),

                _SocialButton(onTap: _signInGoogle, loading: _loadingGoogle,
                    logo: const _GoogleLogo(), label: 'Continuer avec Google'),
                const SizedBox(height: 12),
                _SocialButton(onTap: _signInApple, loading: _loadingApple,
                    logo: const _AppleLogo(),
                    label: 'Continuer avec Apple'),
                const SizedBox(height: 28),

                Row(children: [
                  Expanded(child: Container(height: 1, color: AppColors.borderLight)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('ou', style: TextStyle(color: AppColors.textHint, fontSize: 13))),
                  Expanded(child: Container(height: 1, color: AppColors.borderLight)),
                ]),
                const SizedBox(height: 28),

                _TerraInput(hint: 'Adresse e-mail', icon: Icons.mail_outline, controller: _emailCtrl),
                const SizedBox(height: 12),
                _TerraInput(hint: 'Mot de passe', icon: Icons.lock_outline, obscure: true, controller: _passCtrl),
                const SizedBox(height: 16),

                TerraButton(label: _loadingEmail ? '...' : 'Se connecter',
                    onTap: _loadingEmail ? () {} : _signInEmail),
                const SizedBox(height: 20),

                RichText(text: const TextSpan(
                  text: 'Pas encore de compte ? ',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  children: [TextSpan(text: 'Inscris-toi',
                      style: TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.w500))],
                )),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool loading;
  final Widget logo;
  final String label;
  const _SocialButton({required this.onTap, required this.loading, required this.logo, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: const Color(0xFF192D1E),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.border),
        ),
        child: loading
            ? const Center(child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary)))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 22, height: 22, child: logo),
                const SizedBox(width: 12),
                Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              ]),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.18 1.48-4.97 2.31-8.16 2.31-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
  <path fill="none" d="M0 0h48v48H0z"/>
</svg>''';

  @override
  Widget build(BuildContext context) => SvgPicture.string(_svg);
}

class _AppleLogo extends StatelessWidget {
  const _AppleLogo();

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 814 1000">
  <path fill="white" d="M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 134.2 202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 123.1s-85.5-39.5-164-39.5c-76 0-103.7 40.8-165.9 40.8s-105-57.8-155.5-127.4C46 790.7 0 663 0 541.8c0-207.3 130.3-316.7 260.6-316.7 67.4 0 123.5 44.4 165.3 44.4 39.5 0 101.1-47 176.3-47 28.5 0 130.9 2.6 198.3 99.2zm-234-181.5c31.1-36.9 53.1-88.1 53.1-139.3 0-7.1-.6-14.3-1.9-20.1-50.6 1.9-110.8 33.7-147.1 75.8-28.5 32.4-55.1 83.6-55.1 135.5 0 7.8 1.3 15.6 1.9 18.1 3.2.6 8.4 1.3 13.6 1.3 45.4 0 102.5-30.4 135.5-71.3z"/>
</svg>''';

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: SvgPicture.string(_svg),
  );
}

class _TerraInput extends StatelessWidget {
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextEditingController controller;
  const _TerraInput({required this.hint, required this.icon, this.obscure = false, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller, obscureText: obscure,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 15),
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 17),
        ),
      ),
    );
  }
}

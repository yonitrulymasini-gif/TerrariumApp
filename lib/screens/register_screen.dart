import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import '../widgets/terra_button.dart';
import '../services/auth_service.dart';
import '../utils/fade_route.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'profile_questions_screen.dart';

/// Inscription épurée — même esprit que « Bon retour » : Google + un formulaire
/// minimal (prénom, email, mot de passe). Les infos détaillées (date de
/// naissance, téléphone, pays…) sont optionnelles et éditables plus tard.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loadingGoogle = false;
  bool _loadingEmail = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _goHome() => Navigator.of(context).pushReplacement(fadeRoute(const MainShell()));
  void _goBack() => Navigator.of(context).pushReplacement(fadeRoute(const OnboardingScreen()));
  void _goLogin() => Navigator.of(context).pushReplacement(fadeRoute(const LoginScreen()));
  // Après création du compte : place aux questions animées de profil.
  void _goQuestions() => Navigator.of(context).pushReplacement(fadeRoute(const ProfileQuestionsScreen()));

  bool _isValidEmail(String e) =>
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(e.trim());

  Future<void> _signUpGoogle() async {
    setState(() { _loadingGoogle = true; _error = null; });
    try {
      final user = await AuthService.signInWithGoogle();
      if (user == null) return;
      // Nouveau compte → questionnaire ; déjà onboardé → direct dans l'app.
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final onboarded = doc.exists && (doc.data()?['onboarded'] == true);
      if (!mounted) return;
      if (onboarded) _goHome(); else _goQuestions();
    } catch (_) {
      if (mounted) setState(() => _error = 'Connexion Google impossible.');
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  Future<void> _signUpEmail() async {
    if (!_isValidEmail(_emailCtrl.text)) { setState(() => _error = 'Adresse email invalide.'); return; }
    if (_passCtrl.text.length < 8) { setState(() => _error = 'Le mot de passe doit contenir au moins 8 caractères.'); return; }

    setState(() { _loadingEmail = true; _error = null; });
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(), password: _passCtrl.text);
      if (mounted) _goQuestions();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() {
        _error = switch (e.code) {
          'email-already-in-use' => 'Cet email est déjà utilisé.',
          'invalid-email'        => 'Adresse email invalide.',
          'weak-password'        => 'Mot de passe trop faible.',
          _                      => 'Inscription impossible. Réessaie.',
        };
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Inscription impossible. Réessaie.');
    } finally {
      if (mounted) setState(() => _loadingEmail = false);
    }
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
              child: Text('Retour', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ),
          ),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
            child: Column(children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(color: AppColors.canopy, shape: BoxShape.circle),
                child: Icon(Icons.eco, color: AppColors.iconGreen, size: 36),
              ),
              const SizedBox(height: 24),
              Text('Créer un compte', style: AppTextStyles.serif32),
              const SizedBox(height: 8),
              Text('Rejoins la communauté Terra',
                  style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
              const SizedBox(height: 36),

              _SocialButton(onTap: _signUpGoogle, loading: _loadingGoogle,
                  logo: const _GoogleLogo(), label: 'Continuer avec Google'),
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
              _TerraInput(hint: 'Mot de passe (8 caractères min.)', icon: Icons.lock_outline,
                  obscure: true, controller: _passCtrl),
              const SizedBox(height: 16),

              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: AppColors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.red))),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              TerraButton(label: _loadingEmail ? '...' : 'Créer mon compte',
                  onTap: _loadingEmail ? () {} : _signUpEmail),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: _goLogin,
                child: RichText(text: TextSpan(
                  text: 'Déjà un compte ? ',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  children: [TextSpan(text: 'Se connecter',
                      style: TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline, decorationColor: AppColors.accentGreen))],
                )),
              ),
            ]),
          )),
        ]),
      ),
    );
  }
}

// ── Widgets (mêmes styles que la page de connexion) ──────────────────────────

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
          color: AppColors.card,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.border),
        ),
        child: loading
            ? Center(child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary)))
            : SizedBox(
                width: 220,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: 22, height: 22, child: logo),
                  const SizedBox(width: 12),
                  Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                ]),
              ),
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

class _TerraInput extends StatefulWidget {
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextEditingController controller;
  const _TerraInput({required this.hint, required this.icon, this.obscure = false, required this.controller});

  @override
  State<_TerraInput> createState() => _TerraInputState();
}

class _TerraInputState extends State<_TerraInput> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: widget.controller, obscureText: _obscure,
        style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 15),
          prefixIcon: Icon(widget.icon, color: AppColors.textMuted, size: 20),
          suffixIcon: widget.obscure
              ? GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textMuted, size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 17),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/app_nav.dart';
import '../utils/fade_route.dart';
import 'main_shell.dart';
import 'register_screen.dart';

/// Questionnaire de profil après la création du compte.
/// Ambiance jungle (halos), badge emoji flottant, cartes riches, cascade
/// d'entrée, transitions directionnelles et écran de bienvenue animé.
class ProfileQuestionsScreen extends StatefulWidget {
  const ProfileQuestionsScreen({super.key});
  @override
  State<ProfileQuestionsScreen> createState() => _ProfileQuestionsScreenState();
}

class _ProfileQuestionsScreenState extends State<ProfileQuestionsScreen> {
  int _step = 0;
  bool _forward = true; // sens de la transition
  static const _total = 3;

  final _prenomCtrl = TextEditingController();
  String? _niveau;
  final Set<String> _animals = {};
  bool _saving = false;
  bool _welcome = false;

  static const _levels = [
    ('🌱', 'Débutant', 'Je découvre la terrariophilie'),
    ('🌿', 'Intermédiaire', 'Je connais déjà pas mal de choses'),
    ('🌳', 'Avancé', 'La terrariophilie, c\'est mon quotidien'),
  ];
  static const _animalsList = [
    ('🦎', 'Lézard'), ('🐍', 'Serpent'), ('🕷️', 'Araignée'),
    ('🐢', 'Tortue'), ('🐸', 'Amphibien'), ('🐾', 'Autre'),
  ];

  @override
  void initState() {
    super.initState();
    _prenomCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _prenomCtrl.dispose();
    super.dispose();
  }

  bool get _canNext {
    switch (_step) {
      case 0: return _prenomCtrl.text.trim().isNotEmpty;
      case 1: return _niveau != null;
      default: return true;
    }
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_step < _total - 1) {
      setState(() { _forward = true; _step++; });
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) setState(() { _forward = false; _step--; });
  }

  /// Retour depuis la 1ʳᵉ étape : annule l'inscription (compte supprimé)
  /// et ramène à l'écran « Créer un compte » — utile en cas de mauvais email.
  Future<void> _cancelSignup() async {
    final c = ThemeService.instance.colors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: c.border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 40, offset: const Offset(0, 16))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Icône dans un cercle lumineux
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.primary.withValues(alpha: 0.12),
                border: Border.all(color: c.primary.withValues(alpha: 0.35), width: 1.5),
                boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.2), blurRadius: 24)],
              ),
              child: Icon(Icons.restart_alt_rounded, color: c.primary, size: 30),
            ),
            const SizedBox(height: 18),
            Text('Recommencer\nl\'inscription ?',
                textAlign: TextAlign.center,
                style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w600,
                    color: c.textPrimary, height: 1.2)),
            const SizedBox(height: 10),
            Text('Ce compte sera annulé et tu repartiras de zéro.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: c.textMuted, height: 1.5)),
            const SizedBox(height: 22),
            // Bouton principal
            GestureDetector(
              onTap: () => Navigator.pop(ctx, true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: c.primary,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.3),
                      blurRadius: 16, offset: const Offset(0, 5))],
                ),
                child: Text('Recommencer', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.bg)),
              ),
            ),
            const SizedBox(height: 10),
            // Bouton secondaire
            GestureDetector(
              onTap: () => Navigator.pop(ctx, false),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: c.border),
                ),
                child: Text('Continuer ici', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: c.textSecondary)),
              ),
            ),
          ]),
        ),
      ),
    );
    if (confirm != true) return;
    try {
      // Supprime le compte fraîchement créé (pas de compte orphelin).
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (_) {
      // Suppression impossible (ex. reconnexion requise) → simple déconnexion.
      await FirebaseAuth.instance.signOut();
    }
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
          fadeRoute(const RegisterScreen()), (_) => false);
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final user = FirebaseAuth.instance.currentUser;
    try {
      if (user != null) {
        final prenom = _prenomCtrl.text.trim();
        await user.updateDisplayName(prenom);
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'prenom': prenom,
          if (user.email != null) 'email': user.email,
          if (_niveau != null) 'niveau': _niveau,
          if (_animals.isNotEmpty) 'animaux': _animals.toList(),
          'onboarded': true,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {
      // On entre quand même : le profil pourra être complété plus tard.
    }
    if (!mounted) return;
    setState(() { _saving = false; _welcome = true; });
    await Future.delayed(const Duration(milliseconds: 2100));
    if (mounted) {
      AppNav.instance.reset(); // nouveau compte → démarre sur l'Accueil
      Navigator.of(context).pushAndRemoveUntil(fadeRoute(const MainShell()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(children: [
        // Halos jungle — même ambiance que le reste de l'app
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
          gradient: RadialGradient(center: const Alignment(0, -0.9), radius: 1.1,
              colors: [c.radialTop.withValues(alpha: 0.5), Colors.transparent]),
        ))),
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
          gradient: RadialGradient(center: const Alignment(0, 1.3), radius: 1.1,
              colors: [c.radialBottom.withValues(alpha: 0.4), Colors.transparent]),
        ))),
        SafeArea(child: _welcome ? _WelcomeView(prenom: _prenomCtrl.text.trim()) : _buildQuestions()),
      ]),
    );
  }

  // ── Flux de questions ──────────────────────────────────────────────────────

  Widget _buildQuestions() {
    final last = _step == _total - 1;
    return Column(children: [
      // En-tête : retour + progression segmentée
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Row(children: [
          // Étape 1 : retour = annuler l'inscription (mauvais email…).
          // Étapes suivantes : retour = question précédente.
          SizedBox(width: 36, child: GestureDetector(
            onTap: _step > 0 ? _back : _cancelSignup,
            child: Icon(Icons.arrow_back, color: AppColors.textSecondary, size: 22),
          )),
          Expanded(child: _SegmentedProgress(step: _step, total: _total)),
          SizedBox(width: 36, child: Align(alignment: Alignment.centerRight,
              child: Text('${_step + 1}/$_total',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)))),
        ]),
      ),

      // Contenu — transition directionnelle
      Expanded(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(
                begin: Offset(_forward ? 0.12 : -0.12, 0), end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: KeyedSubtree(key: ValueKey(_step), child: _buildStep()),
        ),
      ),

      // Bouton principal
      Padding(
        padding: const EdgeInsets.fromLTRB(28, 4, 28, 24),
        child: GestureDetector(
          onTap: (_canNext && !_saving) ? _next : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
              color: _canNext ? AppColors.primary : AppColors.card,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: _canNext ? AppColors.primary : AppColors.border),
              boxShadow: _canNext
                  ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 20, offset: const Offset(0, 6))]
                  : [],
            ),
            child: _saving
                ? Center(child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg)))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(last ? 'Terminer' : 'Continuer',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                            color: _canNext ? AppColors.bg : AppColors.textMuted)),
                    const SizedBox(width: 8),
                    Icon(last ? Icons.check_rounded : Icons.arrow_forward_rounded,
                        size: 18, color: _canNext ? AppColors.bg : AppColors.textMuted),
                  ]),
          ),
        ),
      ),
    ]);
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _stepName();
      case 1: return _stepLevel();
      default: return _stepAnimals();
    }
  }

  /// Gabarit d'étape : badge flottant + eyebrow + titre + sous-titre + contenu
  /// en cascade, le tout centré verticalement.
  Widget _stepShell({
    required String eyebrow,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _FadeInUp(delay: const Duration(milliseconds: 60),
              child: Text(eyebrow, style: AppTextStyles.eyebrow)),
          const SizedBox(height: 8),
          _FadeInUp(delay: const Duration(milliseconds: 110),
              child: Text(title, style: GoogleFonts.fraunces(
                  fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
          const SizedBox(height: 8),
          _FadeInUp(delay: const Duration(milliseconds: 160),
              child: Text(subtitle,
                  style: TextStyle(fontSize: 15, color: AppColors.textMuted, height: 1.5))),
          const SizedBox(height: 26),
          for (int i = 0; i < children.length; i++)
            _FadeInUp(delay: Duration(milliseconds: 220 + i * 80), child: children[i]),
        ]),
      ),
    );
  }

  Widget _stepName() {
    final prenom = _prenomCtrl.text.trim();
    return _stepShell(
      eyebrow: 'FAISONS CONNAISSANCE',
      title: 'Comment tu t\'appelles ?',
      subtitle: 'On personnalise ta jungle.',
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.card, borderRadius: BorderRadius.circular(50),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _prenomCtrl, autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) { if (_canNext) _next(); },
            style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Ton prénom',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 17, fontWeight: FontWeight.w400),
              prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
        // Petit clin d'œil qui apparaît quand on tape
        AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: prenom.isEmpty ? 0 : 1,
          child: Padding(
            padding: const EdgeInsets.only(top: 14, left: 6),
            child: Text('Enchanté, $prenom !',
                style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w500)),
          ),
        ),
      ],
    );
  }

  Widget _stepLevel() {
    return _stepShell(
      eyebrow: 'TON EXPÉRIENCE',
      title: 'Quel est ton niveau ?',
      subtitle: 'Pour adapter les conseils et les fiches.',
      children: [
        for (final l in _levels)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LevelCard(
              emoji: l.$1, title: l.$2, description: l.$3,
              selected: _niveau == l.$2,
              onTap: () => setState(() => _niveau = l.$2),
            ),
          ),
      ],
    );
  }

  Widget _stepAnimals() {
    return _stepShell(
      eyebrow: 'TES COMPAGNONS',
      title: 'Qui vit dans ta jungle ?',
      subtitle: 'Plusieurs choix possibles.',
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final w = (constraints.maxWidth - 12) / 2;
          return Wrap(spacing: 12, runSpacing: 12, children: [
            for (final a in _animalsList)
              SizedBox(width: w, child: _AnimalCard(
                emoji: a.$1, label: a.$2,
                selected: _animals.contains(a.$2),
                onTap: () => setState(() {
                  if (!_animals.add(a.$2)) _animals.remove(a.$2);
                }),
              )),
          ]);
        }),
      ],
    );
  }
}

// ── Écran de bienvenue ────────────────────────────────────────────────────────

class _WelcomeView extends StatelessWidget {
  final String prenom;
  const _WelcomeView({required this.prenom});

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Onde qui s'étend derrière le check
        SizedBox(width: 150, height: 150, child: Stack(alignment: Alignment.center, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Container(
              width: 150 * v, height: 150 * v,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: (1 - v) * 0.5), width: 2),
              ),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.45), width: 2),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 30, spreadRadius: 2)],
              ),
              child: Icon(Icons.check_rounded, color: AppColors.primary, size: 48),
            ),
          ),
        ])),
        const SizedBox(height: 24),
        _FadeInUp(delay: const Duration(milliseconds: 350),
            child: Text('Bienvenue${prenom.isNotEmpty ? ', $prenom' : ''} !',
                textAlign: TextAlign.center,
                style: GoogleFonts.fraunces(fontSize: 30, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary))),
        const SizedBox(height: 10),
        _FadeInUp(delay: const Duration(milliseconds: 520),
            child: Text('On prépare ta jungle…',
                style: TextStyle(fontSize: 15, color: AppColors.textMuted))),
      ]),
    ));
  }
}

// ── Composants ────────────────────────────────────────────────────────────────

/// Fondu + glissement vers le haut après [delay].
class _FadeInUp extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _FadeInUp({required this.child, this.delay = Duration.zero});
  @override
  State<_FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<_FadeInUp> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () { if (mounted) _c.forward(); });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: curve,
      builder: (_, child) => Opacity(
        opacity: curve.value,
        child: Transform.translate(offset: Offset(0, (1 - curve.value) * 20), child: child),
      ),
      child: widget.child,
    );
  }
}

/// Progression en segments arrondis (rempli / actif / à venir).
class _SegmentedProgress extends StatelessWidget {
  final int step;
  final int total;
  const _SegmentedProgress({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      for (int i = 0; i < total; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          height: 5,
          decoration: BoxDecoration(
            color: i <= step ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(3),
            boxShadow: i == step
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 8)]
                : [],
          ),
        )),
      ],
    ]);
  }
}

/// Carte de niveau : emoji dans une pastille + titre + description + radio.
class _LevelCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  const _LevelCard({required this.emoji, required this.title, required this.description,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1),
            boxShadow: selected
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 18, offset: const Offset(0, 4))]
                : [],
          ),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 46, height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.05),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primary : AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(description, style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            ])),
            // Radio animée
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                    color: selected ? AppColors.primary : AppColors.textMuted.withValues(alpha: 0.5),
                    width: 1.5),
              ),
              child: selected
                  ? Icon(Icons.check, size: 14, color: AppColors.bg)
                  : null,
            ),
          ]),
        ),
      ),
    );
  }
}

/// Carte reptile : grand emoji + label, badge check en coin quand sélectionnée.
class _AnimalCard extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _AnimalCard({required this.emoji, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1),
            boxShadow: selected
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 18, offset: const Offset(0, 4))]
                : [],
          ),
          child: Stack(children: [
            Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: double.infinity,
                    child: Text(emoji, textAlign: TextAlign.center, style: const TextStyle(fontSize: 32))),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity,
                    child: Text(label, textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                            color: selected ? AppColors.primary : AppColors.textPrimary))),
              ]),
            Positioned(top: 0, right: 10, child: AnimatedScale(
              scale: selected ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: Icon(Icons.check_circle, size: 18, color: AppColors.primary),
            )),
          ]),
        ),
      ),
    );
  }
}

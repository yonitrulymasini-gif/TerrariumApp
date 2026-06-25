import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import '../utils/fade_route.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _step = 0;

  // Breathing/pulse animation (pulse-glow CSS)
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Leaf sway animation
  late AnimationController _swayCtrl;
  late Animation<double> _swayAnim;

  // Content fade/slide (animate-in fade-in slide-in-from-bottom-4)
  late AnimationController _contentCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  static const _slides = [
    _SlideData(
      icon: Icons.eco_outlined,
      title: 'Bienvenue dans Terra',
      text: 'Ton terrarium connecté tient désormais dans ta poche. Une jungle vivante à portée de doigt.',
      accent: 'leaf',
    ),
    _SlideData(
      icon: Icons.monitor_heart_outlined,
      title: 'Surveille en temps réel',
      text: 'Température, humidité, état des prises — tout est synchronisé via tes capteurs',
      accent: 'sun',
    ),
    _SlideData(
      icon: Icons.auto_awesome_outlined,
      title: 'Automatise sans coder',
      text: "Crée des scénarios : lampe le matin, brumisation l'après-midi, chauffage la nuit.",
      accent: 'leaf',
    ),
    _SlideData(
      icon: Icons.people_outline,
      title: 'Partage ta jungle',
      text: 'Rejoins une communauté de terrariophiles passionnés. Échange photos, conseils et configs.',
      accent: 'sun',
    ),
  ];

  @override
  void initState() {
    super.initState();

    // pulse-glow: 0→1→0 en boucle (comme CSS 0%,100% identiques)
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: false);
    _pulseAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    ]).animate(_pulseCtrl);

    // leaf-sway: -3deg → 3deg + translateY 4px en 4s loop
    _swayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);
    _swayAnim = Tween<double>(begin: -1, end: 1).animate(
      CurvedAnimation(parent: _swayCtrl, curve: Curves.easeInOut),
    );

    // Content fade+slide entrée
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 16, end: 0).animate(
      CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut),
    );
    _contentCtrl.forward();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _swayCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _goToStep(int i) async {
    await _contentCtrl.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
    if (!mounted) return;
    setState(() => _step = i);
    _contentCtrl.forward(from: 0);
  }

  void _next() {
    if (_step < _slides.length - 1) {
      _goToStep(_step + 1);
    } else {
      Navigator.of(context).pushReplacement(
        fadeRoute(const LoginScreen()),
      );
    }
  }

  void _skip() {
    Navigator.of(context).pushReplacement(
      fadeRoute(const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_step];
    final isLeaf = slide.accent == 'leaf';
    final circleColor = isLeaf ? AppColors.primary : AppColors.accent;

    return GestureDetector(
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -200 && _step < _slides.length - 1) _goToStep(_step + 1);
        if (v > 200 && _step > 0) _goToStep(_step - 1);
      },
      child: Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Jungle gradient background (réplique du bg-jungle-gradient CSS)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.8),
                  radius: 1.2,
                  colors: [
                    AppColors.canopy.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.6],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 1.2),
                  radius: 1.2,
                  colors: [
                    AppColors.card.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.6],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Bouton retour (invisible sur la 1ère slide)
                        GestureDetector(
                          onTap: _step > 0 ? () => _goToStep(_step - 1) : null,
                          child: AnimatedOpacity(
                            opacity: _step > 0 ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Text('Retour', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(text: 'Terra', style: AppTextStyles.logo),
                              TextSpan(text: '.', style: AppTextStyles.logo.copyWith(color: AppColors.primary)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _skip,
                          child: Text(
                            'Passer',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contenu (fade-in + slide-in-from-bottom)
                  Expanded(
                    child: AnimatedBuilder(
                        animation: Listenable.merge([_fadeAnim, _slideAnim, _pulseAnim, _swayAnim]),
                        builder: (_, __) {
                          return Opacity(
                            opacity: _fadeAnim.value.clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(0, _slideAnim.value),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Cercle avec pulse-glow
                                  SizedBox(
                                    width: 200,
                                    height: 200,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Cercle principal avec pulse-glow
                                        // CSS: 0% box-shadow 0 0 0 0 primary/0.4 → 50% box-shadow 0 0 0 12px primary/0
                                        Container(
                                          width: 128,
                                          height: 128,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: circleColor.withValues(alpha: 0.20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: circleColor.withValues(
                                                  alpha: (0.4 * (1 - _pulseAnim.value)).clamp(0, 1),
                                                ),
                                                blurRadius: 0,
                                                spreadRadius: 12 * _pulseAnim.value,
                                              ),
                                            ],
                                          ),
                                          child: Transform.rotate(
                                            angle: _swayAnim.value * 0.052, // ±3 degrés
                                            child: Transform.translate(
                                              offset: Offset(0, _swayAnim.value.abs() * -4),
                                              child: Icon(
                                                slide.icon,
                                                size: 56,
                                                color: circleColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 40),

                                  Text(
                                    slide.title,
                                    style: GoogleFonts.fraunces(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      height: 1.2,
                                      letterSpacing: -0.3,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                  const SizedBox(height: 12),

                                  Text(
                                    slide.text,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textMuted,
                                      height: 1.65,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                    ),
                  ),

                  // Dots
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (i) {
                        final active = i == _step;
                        return GestureDetector(
                          onTap: () => _goToStep(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: active ? 32 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: active
                                  ? AppColors.primary
                                  : AppColors.textMuted.withValues(alpha: 0.4),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Bouton
                  GestureDetector(
                    onTap: _next,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.20),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _step < _slides.length - 1 ? 'Continuer' : 'Commencer',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.bg,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

class _SlideData {
  final IconData icon;
  final String title;
  final String text;
  final String accent;

  const _SlideData({
    required this.icon,
    required this.title,
    required this.text,
    required this.accent,
  });
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // oklch(0.18 0.025 150) → #0F1F14
  static const bg = Color(0xFF0F1F14);
  // oklch(0.235 0.03 150) → card légèrement surélevé
  static const card = Color(0xFF162318);
  static const cardDark = Color(0xFF111C15);

  // oklch(0.78 0.13 140) → primary leaf green #7BC47F
  static const primary = Color(0xFF7BC47F);
  static const accentGreen = Color(0xFF7BC47F);
  static const liveGreen = Color(0xFF7BC47F);
  static const iconGreen = Color(0xFF7BC47F);

  // oklch(0.7 0.14 85) → accent amber #C8A84B
  static const accent = Color(0xFFC8A84B);
  static const yellow = Color(0xFFC8A84B);

  // oklch(0.32 0.045 145) → canopy #1F3D2B
  static const canopy = Color(0xFF1F3D2B);
  static const circleGreen = Color(0xFF1F3D2B);
  static const circleYellow = Color(0xFF3A2E10);

  // Text
  // oklch(0.96 0.02 145) → foreground ~#E8F5E9
  static const textPrimary = Color(0xFFE8F5E9);
  // oklch(0.72 0.025 145) → muted foreground
  static const textSecondary = Color(0xFFAABBAA);
  static const textMuted = Color(0xFF7A8F7A);
  static const textHint = Color(0xFF4A5A4A);

  // Destructive oklch(0.62 0.22 25) → red
  static const red = Color(0xFFDC4444);
  static const redBg = Color(0x20DC4444);

  // oklch(0.32 0.03 150 / 0.6) → border
  static const border = Color(0x40304830);
  static const borderLight = Color(0x18304830);
}

class AppTextStyles {
  // Fraunces = la vraie police de la référence (display)
  static TextStyle get serif32 => GoogleFonts.fraunces(
    fontSize: 32, color: AppColors.textPrimary, fontWeight: FontWeight.w600,
  );
  static TextStyle get serif30 => GoogleFonts.fraunces(
    fontSize: 30, color: AppColors.textPrimary, fontWeight: FontWeight.w600,
  );
  static TextStyle get serif28 => GoogleFonts.fraunces(
    fontSize: 28, color: AppColors.textPrimary, fontWeight: FontWeight.w600,
  );
  static TextStyle get serif26 => GoogleFonts.fraunces(
    fontSize: 26, color: AppColors.textPrimary, fontWeight: FontWeight.w600,
  );
  static TextStyle get logo => GoogleFonts.fraunces(
    fontSize: 20, color: AppColors.textPrimary, fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );

  static const TextStyle body15 = TextStyle(
    fontSize: 15, color: AppColors.textPrimary,
  );
  static const TextStyle body14 = TextStyle(
    fontSize: 14, color: AppColors.textPrimary,
  );
  static const TextStyle body13 = TextStyle(
    fontSize: 13, color: AppColors.textSecondary,
  );
  static const TextStyle caption12 = TextStyle(
    fontSize: 12, color: AppColors.textMuted,
  );
  static const TextStyle eyebrow = TextStyle(
    fontSize: 11, color: AppColors.textMuted,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
  );
}

// Décoration glass-card (réplique du CSS source)
BoxDecoration glassCard({double radius = 24}) => BoxDecoration(
  gradient: const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xD9182E1E), Color(0xB3122018)],
  ),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: const Color(0x40507850), width: 1),
);

class _FadeTransitionBuilder extends PageTransitionsBuilder {
  const _FadeTransitionBuilder();
  @override
  Widget buildTransitions<T>(_, __, Animation<double> animation, ___, Widget child) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      child: child,
    );
  }
}

ThemeData buildAppTheme() {
  return ThemeData(
    scaffoldBackgroundColor: AppColors.bg,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.bg,
      primary: AppColors.primary,
    ),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final p in TargetPlatform.values) p: const _FadeTransitionBuilder(),
      },
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/theme_service.dart';

class AppColors {
  // Dynamic — toutes les couleurs UI lisent le thème actif
  static Color get bg           => ThemeService.instance.colors.bg;
  static Color get card         => ThemeService.instance.colors.card;
  static Color get cardDark     => ThemeService.instance.colors.bg;
  static Color get primary      => ThemeService.instance.colors.primary;
  static Color get accentGreen  => ThemeService.instance.colors.primary;
  static Color get liveGreen    => ThemeService.instance.colors.primary;
  static Color get iconGreen    => ThemeService.instance.colors.primary;
  static Color get accent       => ThemeService.instance.colors.accent;
  static Color get yellow       => ThemeService.instance.colors.accent;
  static Color get canopy       => ThemeService.instance.colors.radialTop;
  static Color get circleGreen  => ThemeService.instance.colors.radialTop;
  static Color get circleYellow => ThemeService.instance.colors.radialBottom;
  static Color get border       => ThemeService.instance.colors.border;
  static Color get borderLight  => ThemeService.instance.colors.border.withValues(alpha: 0.4);
  static Color get textPrimary  => ThemeService.instance.colors.textPrimary;
  static Color get textSecondary=> ThemeService.instance.colors.textSecondary;
  static Color get textMuted    => ThemeService.instance.colors.textMuted;
  static Color get textHint     => ThemeService.instance.colors.textHint;

  // Constantes fixes
  static const red   = Color(0xFFDC4444);
  static const redBg = Color(0x20DC4444);
}

class AppTextStyles {
  static Color get _p => ThemeService.instance.colors.textPrimary;
  static Color get _s => ThemeService.instance.colors.textSecondary;
  static Color get _m => ThemeService.instance.colors.textMuted;

  static TextStyle get serif32 => GoogleFonts.fraunces(
    fontSize: 32, color: _p, fontWeight: FontWeight.w600,
  );
  static TextStyle get serif30 => GoogleFonts.fraunces(
    fontSize: 30, color: _p, fontWeight: FontWeight.w600,
  );
  static TextStyle get serif28 => GoogleFonts.fraunces(
    fontSize: 28, color: _p, fontWeight: FontWeight.w600,
  );
  static TextStyle get serif26 => GoogleFonts.fraunces(
    fontSize: 26, color: _p, fontWeight: FontWeight.w600,
  );
  static TextStyle get logo => GoogleFonts.fraunces(
    fontSize: 20, color: _p, fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );

  static TextStyle get body15 => TextStyle(fontSize: 15, color: _p);
  static TextStyle get body14 => TextStyle(fontSize: 14, color: _p);
  static TextStyle get body13 => TextStyle(fontSize: 13, color: _s);
  static TextStyle get caption12 => TextStyle(fontSize: 12, color: _m);
  static TextStyle get eyebrow => TextStyle(
    fontSize: 11, color: _m,
    fontWeight: FontWeight.w500, letterSpacing: 1.5,
  );
}

BoxDecoration glassCard({double radius = 24}) {
  final c = ThemeService.instance.colors;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [c.card.withValues(alpha: 0.85), c.bg.withValues(alpha: 0.7)],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: c.border, width: 1),
  );
}

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

ThemeData buildAppTheme(TerraThemeColors colors) {
  final scheme = colors.isLight
      ? ColorScheme.light(surface: colors.bg, primary: colors.primary, onSurface: colors.textPrimary)
      : ColorScheme.dark(surface: colors.bg, primary: colors.primary, onSurface: colors.textPrimary);
  return ThemeData(
    scaffoldBackgroundColor: colors.bg,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: scheme,
    dialogTheme: DialogThemeData(backgroundColor: colors.card),
    // Snackbars lisibles sur tous les thèmes (texte assorti au fond de carte).
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.card,
      contentTextStyle: TextStyle(color: colors.textPrimary, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final p in TargetPlatform.values) p: const _FadeTransitionBuilder(),
      },
    ),
  );
}

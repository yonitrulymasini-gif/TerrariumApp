import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TerraThemeColors {
  final Color bg;
  final Color card;
  final Color primary;
  final Color accent;
  final Color border;
  final Color radialTop;
  final Color radialBottom;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textHint;
  final bool isLight;

  const TerraThemeColors({
    required this.bg, required this.card, required this.primary,
    required this.accent, required this.border,
    required this.radialTop, required this.radialBottom,
    this.textPrimary   = const Color(0xFFE8F5E9),
    this.textSecondary = const Color(0xFFAABBAA),
    this.textMuted     = const Color(0xFF7A8F7A),
    this.textHint      = const Color(0xFF4A5A4A),
    this.isLight       = false,
  });
}

const jungleTheme = TerraThemeColors(
  bg:           Color(0xFF0F1F14),
  card:         Color(0xFF162318),
  primary:      Color(0xFF7BC47F),
  accent:       Color(0xFFC8A84B),
  border:       Color(0x40304830),
  radialTop:    Color(0xFF1F3D2B),
  radialBottom: Color(0xFF162318),
);

const desertTheme = TerraThemeColors(
  bg:           Color(0xFF1A0F05),
  card:         Color(0xFF261508),
  primary:      Color(0xFFD4893A),
  accent:       Color(0xFFF0C060),
  border:       Color(0x40604020),
  radialTop:    Color(0xFF3D2010),
  radialBottom: Color(0xFF261508),
);

const oceanTheme = TerraThemeColors(
  bg:           Color(0xFF050E1A),
  card:         Color(0xFF0A1828),
  primary:      Color(0xFF38BDF8),
  accent:       Color(0xFF2DD4BF),
  border:       Color(0x401A3C5A),
  radialTop:    Color(0xFF0D2A4A),
  radialBottom: Color(0xFF0A1828),
);

const rocheTheme = TerraThemeColors(
  bg:           Color(0xFF0E1012),
  card:         Color(0xFF171A1C),
  primary:      Color(0xFF94A3B8),
  accent:       Color(0xFFB8C8D8),
  border:       Color(0x40283038),
  radialTop:    Color(0xFF1E2830),
  radialBottom: Color(0xFF171A1C),
);

const nuitTheme = TerraThemeColors(
  bg:           Color(0xFF07091A),
  card:         Color(0xFF0E1130),
  primary:      Color(0xFF9D8DF5),
  accent:       Color(0xFFC4B5FD),
  border:       Color(0x40201E5A),
  radialTop:    Color(0xFF151240),
  radialBottom: Color(0xFF0E1130),
);

const jourTheme = TerraThemeColors(
  bg:            Color(0xFFF5F2EC),
  card:          Color(0xFFECE8E0),
  primary:       Color(0xFF2C6B3E),
  accent:        Color(0xFF4A9060),
  border:        Color(0x40B8B0A0),
  radialTop:     Color(0xFFD8EAD8),
  radialBottom:  Color(0xFFECE8E0),
  textPrimary:   Color(0xFF1A2B1F),
  textSecondary: Color(0xFF3A5445),
  textMuted:     Color(0xFF586E5C),
  textHint:      Color(0xFF8A9E8A),
  isLight:       true,
);

const _themes = {
  'jungle': jungleTheme,
  'desert': desertTheme,
  'ocean':  oceanTheme,
  'roche':  rocheTheme,
  'nuit':   nuitTheme,
  'jour':   jourTheme,
};

class ThemeService extends ChangeNotifier {
  static final instance = ThemeService._();
  ThemeService._();

  String _name = 'jungle';
  String get name => _name;
  TerraThemeColors get colors => _themes[_name] ?? jungleTheme;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _name = p.getString('app_theme') ?? 'jungle';
    notifyListeners();
  }

  Future<void> setTheme(String name) async {
    _name = name;
    notifyListeners();
    (await SharedPreferences.getInstance()).setString('app_theme', name);
  }
}

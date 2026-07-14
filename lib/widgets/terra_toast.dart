import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';

/// Affiche un toast stylé Terra (succès vert / erreur rouge) : pilule flottante
/// avec icône dans un cercle teinté, ombre et bordure d'accent — bien plus
/// joli que le SnackBar par défaut.
///
/// Passe soit un [BuildContext], soit un [ScaffoldMessengerState] (utile quand
/// l'écran d'origine a été fermé, ex. après un pop).
void showTerraToast(
  dynamic contextOrMessenger,
  String message, {
  bool error = false,
}) {
  final ScaffoldMessengerState messenger = contextOrMessenger is ScaffoldMessengerState
      ? contextOrMessenger
      : ScaffoldMessenger.of(contextOrMessenger as BuildContext);

  final c = ThemeService.instance.colors;
  final accent = error ? AppColors.red : c.primary;
  final icon = error ? Icons.error_outline_rounded : Icons.check_circle_rounded;

  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      duration: const Duration(milliseconds: 2600),
      content: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 32, offset: const Offset(0, 12)),
            BoxShadow(color: accent.withValues(alpha: 0.14),
                blurRadius: 22, spreadRadius: -4),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Flexible(child: Text(message,
              style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w500, height: 1.3))),
        ]),
      ),
    ));
}

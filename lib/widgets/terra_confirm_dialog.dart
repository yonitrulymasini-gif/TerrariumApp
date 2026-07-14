import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';

/// Dialog de confirmation stylé Terra : icône dans un cercle lumineux,
/// titre serif, boutons pilule. Renvoie true si l'action est confirmée.
/// [destructive] passe l'accent en rouge (suppressions…).
Future<bool?> showTerraConfirmDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Annuler',
  bool destructive = false,
}) {
  final c = ThemeService.instance.colors;
  final accent = destructive ? AppColors.red : c.primary;

  return showDialog<bool>(
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
              color: accent.withValues(alpha: 0.12),
              border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
              boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.2), blurRadius: 24)],
            ),
            child: Icon(icon, color: accent, size: 30),
          ),
          const SizedBox(height: 18),
          Text(title,
              textAlign: TextAlign.center,
              style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w600,
                  color: c.textPrimary, height: 1.2)),
          const SizedBox(height: 10),
          Text(message,
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
                color: accent,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.3),
                    blurRadius: 16, offset: const Offset(0, 5))],
              ),
              child: Text(confirmLabel, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                      color: destructive ? Colors.white : c.bg)),
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
              child: Text(cancelLabel, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: c.textSecondary)),
            ),
          ),
        ]),
      ),
    ),
  );
}

/// Dialog de saisie stylé Terra : icône dans un cercle lumineux, titre serif,
/// champ texte pilule, boutons pilule. Renvoie le texte saisi, ou null si annulé.
Future<String?> showTerraInputDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  String? message,
  required String hint,
  String initialValue = '',
  String confirmLabel = 'OK',
  String cancelLabel = 'Annuler',
}) {
  final c = ThemeService.instance.colors;
  final ctrl = TextEditingController(text: initialValue);

  return showDialog<String>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SingleChildScrollView(child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: c.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 40, offset: const Offset(0, 16))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.primary.withValues(alpha: 0.12),
              border: Border.all(color: c.primary.withValues(alpha: 0.35), width: 1.5),
              boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.2), blurRadius: 24)],
            ),
            child: Icon(icon, color: c.primary, size: 30),
          ),
          const SizedBox(height: 18),
          Text(title,
              textAlign: TextAlign.center,
              style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w600,
                  color: c.textPrimary, height: 1.2)),
          if (message != null) ...[
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: c.textMuted, height: 1.5)),
          ],
          const SizedBox(height: 22),
          Container(
            decoration: BoxDecoration(
              color: c.bg,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: c.border),
            ),
            child: TextField(
              controller: ctrl,
              autofocus: true,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: c.textMuted, fontSize: 15),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v),
            ),
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: () => Navigator.pop(ctx, ctrl.text),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.3),
                    blurRadius: 16, offset: const Offset(0, 5))],
              ),
              child: Text(confirmLabel, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.bg)),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.pop(ctx, null),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: c.border),
              ),
              child: Text(cancelLabel, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: c.textSecondary)),
            ),
          ),
        ]),
      )),
    ),
  ).then((v) { ctrl.dispose(); return v; });
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../theme/app_theme.dart';
import '../services/theme_service.dart';

/// Calendrier custom Terra (feuille du bas) : en-tête serif, cases arrondies,
/// jour sélectionné en pastille d'accent, aujourd'hui cerclé. Renvoie la date
/// choisie (jour), ou null si annulé.
Future<DateTime?> showTerraDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  required Color accent,
}) {
  DateTime dOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _TerraCalendarSheet(
      initialDate: dOnly(initialDate),
      firstDate: dOnly(firstDate),
      lastDate: dOnly(lastDate),
      accent: accent,
    ),
  );
}

class _TerraCalendarSheet extends StatefulWidget {
  final DateTime initialDate, firstDate, lastDate;
  final Color accent;
  const _TerraCalendarSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.accent,
  });

  @override
  State<_TerraCalendarSheet> createState() => _TerraCalendarSheetState();
}

class _TerraCalendarSheetState extends State<_TerraCalendarSheet> {
  late DateTime _selected = widget.initialDate;
  late DateTime _month = DateTime(widget.initialDate.year, widget.initialDate.month);

  DateTime get _firstMonth => DateTime(widget.firstDate.year, widget.firstDate.month);
  DateTime get _lastMonth => DateTime(widget.lastDate.year, widget.lastDate.month);

  bool get _canPrev => _month.isAfter(_firstMonth);
  bool get _canNext => _month.isBefore(_lastMonth);

  bool _inRange(DateTime d) =>
      !d.isBefore(widget.firstDate) && !d.isAfter(widget.lastDate);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    final today = DateTime.now();

    // Cases du mois (lundi en premier).
    final firstOfMonth = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = (firstOfMonth.weekday - 1) % 7; // Lun=0 … Dim=6

    final cells = <Widget>[];
    for (int i = 0; i < leading; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_month.year, _month.month, day);
      final enabled = _inRange(date);
      final selected = _sameDay(date, _selected);
      final isToday = _sameDay(date, today);

      cells.add(GestureDetector(
        onTap: enabled ? () => setState(() => _selected = date) : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.all(3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected ? widget.accent : (enabled ? c.bg : Colors.transparent),
            border: Border.all(
              color: selected
                  ? widget.accent
                  : (isToday
                      ? widget.accent.withValues(alpha: 0.7)
                      : (enabled ? c.border : Colors.transparent)),
              width: isToday && !selected ? 1.4 : 1,
            ),
          ),
          child: Text('$day',
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected || isToday ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? c.bg
                    : enabled
                        ? c.textPrimary
                        : c.textHint.withValues(alpha: 0.5),
              )),
        ),
      ));
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: c.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 40, offset: const Offset(0, 16))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: c.border, borderRadius: BorderRadius.circular(50))),
          const SizedBox(height: 16),

          // Date sélectionnée (grand, serif)
          Align(
            alignment: Alignment.centerLeft,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('CHOISIR UN JOUR', style: AppTextStyles.eyebrow),
              const SizedBox(height: 4),
              Text(
                _capitalize(DateFormat('EEEE d MMMM', 'fr').format(_selected)),
                style: GoogleFonts.fraunces(fontSize: 24, fontWeight: FontWeight.w600, color: c.textPrimary),
              ),
            ]),
          ),
          const SizedBox(height: 18),

          // En-tête mois + navigation (centré, serif)
          Row(children: [
            _NavBtn(icon: Icons.chevron_left, enabled: _canPrev, color: c,
                onTap: () => setState(() => _month = DateTime(_month.year, _month.month - 1))),
            Expanded(child: Center(
              child: RichText(text: TextSpan(children: [
                TextSpan(text: _capitalize(DateFormat('MMMM', 'fr').format(_month)),
                    style: GoogleFonts.fraunces(fontSize: 19, fontWeight: FontWeight.w700, color: c.textPrimary)),
                TextSpan(text: ' ${_month.year}',
                    style: GoogleFonts.fraunces(fontSize: 19, fontWeight: FontWeight.w500, color: c.textMuted)),
              ])),
            )),
            _NavBtn(icon: Icons.chevron_right, enabled: _canNext, color: c,
                onTap: () => setState(() => _month = DateTime(_month.year, _month.month + 1))),
          ]),
          const SizedBox(height: 14),

          // Jours de la semaine
          Row(children: [
            for (final d in const ['L', 'M', 'M', 'J', 'V', 'S', 'D'])
              Expanded(child: Center(child: Text(d,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textMuted)))),
          ]),
          const SizedBox(height: 6),

          // Grille des jours
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.0,
            children: cells,
          ),
          const SizedBox(height: 16),

          // Actions
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: c.border),
                ),
                child: Text('Annuler', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: c.textSecondary)),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context, _selected),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: widget.accent,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [BoxShadow(color: widget.accent.withValues(alpha: 0.3),
                      blurRadius: 16, offset: const Offset(0, 5))],
                ),
                child: Text('Valider', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.bg)),
              ),
            )),
          ]),
        ]),
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final dynamic color;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.enabled, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.bg,
          border: Border.all(color: c.border),
        ),
        child: Icon(icon, size: 20,
            color: enabled ? c.textPrimary : c.textHint.withValues(alpha: 0.4)),
      ),
    );
  }
}

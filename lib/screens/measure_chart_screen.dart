import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/telemetry_service.dart';
import '../widgets/terra_date_picker.dart';

/// Graphique en direct d'une mesure (température, humidité…).
/// Les données viennent de l'historique du TelemetryService, mis à jour en
/// temps réel.
class MeasureChartScreen extends StatefulWidget {
  final String serialId;
  final String title;
  final String unit;
  final Color accent;
  final double? Function(TelemetryData) selector;

  const MeasureChartScreen({
    super.key,
    required this.serialId,
    required this.title,
    required this.unit,
    required this.accent,
    required this.selector,
  });

  @override
  State<MeasureChartScreen> createState() => _MeasureChartScreenState();
}

class _MeasureChartScreenState extends State<MeasureChartScreen> {
  StreamSubscription? _sub;

  /// Fenêtre de temps affichée (vue "en direct").
  Duration _window = const Duration(minutes: 30);
  static const _windows = [
    (Duration(minutes: 30), '30 min'),
    (Duration(hours: 1), '1 h'),
    (Duration(hours: 6), '6 h'),
    (Duration(hours: 24), '24 h'),
  ];

  /// Jour précis sélectionné au calendrier (null = vue en direct).
  DateTime? _day;

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final picked = await showTerraDatePicker(
      context,
      initialDate: _day ?? now,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now,
      accent: widget.accent,
    );
    if (picked == null) return;
    final today = DateTime(now.year, now.month, now.day);
    final sel = DateTime(picked.year, picked.month, picked.day);
    setState(() {
      _day = sel == today ? null : sel;
      // Un jour choisi = journée entière par défaut (on peut ensuite affiner).
      if (_day != null) _window = const Duration(hours: 24);
    });
  }

  @override
  void initState() {
    super.initState();
    // Chaque nouvelle mesure enrichit l'historique → on redessine.
    _sub = TelemetryService.stream(widget.serialId).listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;

    final List<(DateTime, double)> points;
    // Domaine temporel de l'axe X (jour choisi = axe fixe 00:00:00 → 23:59:59).
    DateTime? domainStart, domainEnd;
    if (_day != null) {
      // Jour choisi (toujours un jour passé) : la journée va de 00:00:00 à
      // 23:59:59. En 24 h on montre tout le jour ; sinon les DERNIÈRES `_window`
      // (ex. 30 min = 23:29:59 → 23:59:59).
      final dayStart = _day!;
      final end = dayStart.add(const Duration(hours: 23, minutes: 59, seconds: 59));
      final start = _window >= const Duration(hours: 24) ? dayStart : end.subtract(_window);
      domainStart = start;
      domainEnd = end;
      points = [
        for (final d in TelemetryService.history)
          if (widget.selector(d) != null &&
              d.updatedAt != null &&
              !d.updatedAt!.isBefore(start) &&
              !d.updatedAt!.isAfter(end))
            (d.updatedAt!, widget.selector(d)!),
      ];
    } else {
      final cutoff = DateTime.now().subtract(_window);
      points = [
        for (final d in TelemetryService.history)
          if (widget.selector(d) != null &&
              d.updatedAt != null &&
              d.updatedAt!.isAfter(cutoff))
            (d.updatedAt!, widget.selector(d)!),
      ];
    }
    final values = [for (final p in points) p.$2];
    final current = values.isNotEmpty ? values.last : null;
    final lo = values.isNotEmpty ? values.reduce(min) : null;
    final hi = values.isNotEmpty ? values.reduce(max) : null;
    final avg = values.isNotEmpty
        ? values.reduce((a, b) => a + b) / values.length
        : null;

    String fmt(double? v) => v == null ? '—' : v.toStringAsFixed(1);

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(children: [
        // Halos jungle
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
          gradient: RadialGradient(center: const Alignment(0, -0.9), radius: 1.1,
              colors: [c.radialTop.withValues(alpha: 0.5), Colors.transparent]),
        ))),
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
          gradient: RadialGradient(center: const Alignment(0, 1.3), radius: 1.1,
              colors: [c.radialBottom.withValues(alpha: 0.4), Colors.transparent]),
        ))),

        SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text('Retour', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ),
            const SizedBox(height: 20),

            Text('MESURES', style: AppTextStyles.eyebrow),
            const SizedBox(height: 6),
            Text(widget.title, style: AppTextStyles.serif28),
            const SizedBox(height: 16),

            // Valeur actuelle
            Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic, children: [
              Text(fmt(current),
                  style: GoogleFonts.fraunces(fontSize: 48, fontWeight: FontWeight.w600,
                      color: c.textPrimary)),
              const SizedBox(width: 6),
              Text(widget.unit, style: TextStyle(fontSize: 16, color: c.textMuted)),
              const Spacer(),
              // Pastille "en direct" — ou le jour consulté (✕ pour revenir)
              if (_day == null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.accent)),
                    const SizedBox(width: 6),
                    Text('En direct', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: widget.accent)),
                  ]),
                )
              else
                GestureDetector(
                  onTap: () => setState(() => _day = null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: widget.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: widget.accent.withValues(alpha: 0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.calendar_month_outlined, size: 12, color: widget.accent),
                      const SizedBox(width: 5),
                      Text(DateFormat('EEE d MMM', 'fr').format(_day!),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                              color: widget.accent)),
                      const SizedBox(width: 5),
                      Icon(Icons.close, size: 12, color: widget.accent),
                    ]),
                  ),
                ),
            ]),
            const SizedBox(height: 18),

            // Min / Moyenne / Max
            Row(children: [
              Expanded(child: _StatTile(label: 'Min', value: fmt(lo), unit: widget.unit)),
              const SizedBox(width: 10),
              Expanded(child: _StatTile(label: 'Moyenne', value: fmt(avg), unit: widget.unit)),
              const SizedBox(width: 10),
              Expanded(child: _StatTile(label: 'Max', value: fmt(hi), unit: widget.unit)),
            ]),
            const SizedBox(height: 14),

            // Choix de la période + calendrier
            Row(children: [
              for (final w in _windows) ...[
                Expanded(child: Builder(builder: (context) {
                  final selected = _window == w.$1;
                  return GestureDetector(
                    // Garde le jour choisi s'il y en a un ; sinon vue en direct.
                    onTap: () => setState(() => _window = w.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? widget.accent.withValues(alpha: 0.16) : c.card,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                            color: selected ? widget.accent : c.border,
                            width: selected ? 1.3 : 1),
                      ),
                      child: Text(w.$2, textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: selected ? widget.accent : c.textMuted)),
                    ),
                  );
                })),
                const SizedBox(width: 8),
              ],
              // Choisir un jour précis
              GestureDetector(
                onTap: _pickDay,
                child: Container(
                  width: 36, height: 34,
                  decoration: BoxDecoration(
                    color: _day != null ? widget.accent.withValues(alpha: 0.16) : c.card,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                        color: _day != null ? widget.accent : c.border,
                        width: _day != null ? 1.3 : 1),
                  ),
                  child: Icon(Icons.calendar_month_outlined, size: 17,
                      color: _day != null ? widget.accent : c.textMuted),
                ),
              ),
            ]),
            const SizedBox(height: 14),

            // Courbe interactive — occupe tout l'espace restant
            Expanded(child: Container(
              width: double.infinity,
              decoration: glassCard(radius: 20),
              padding: const EdgeInsets.fromLTRB(8, 16, 12, 8),
              child: values.length < 2
                  ? Center(child: Text('Pas encore de données sur cette période…',
                      style: TextStyle(fontSize: 13, color: c.textMuted)))
                  : _InteractiveChart(
                      points: points,
                      unit: widget.unit,
                      accent: widget.accent,
                      gridColor: c.border,
                      labelColor: c.textMuted,
                      cardColor: c.card,
                      textColor: c.textPrimary,
                      domainStart: domainStart,
                      domainEnd: domainEnd,
                    ),
            )),
            const SizedBox(height: 10),
            Center(child: Text(
                _day != null
                    ? 'Historique du ${DateFormat('EEEE d MMMM', 'fr').format(_day!)} · appuie sur la courbe'
                    : 'Appuie sur la courbe pour un point précis',
                style: TextStyle(fontSize: 11, color: c.textHint))),
          ]),
        )),
      ]),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _StatTile({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return Container(
      decoration: glassCard(radius: 16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 11, color: c.textMuted)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic, children: [
          Text(value, style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w600,
              color: c.textPrimary)),
          const SizedBox(width: 2),
          Text(unit, style: TextStyle(fontSize: 10, color: c.textMuted)),
        ]),
      ]),
    );
  }
}

/// Courbe interactive : appui/glissement affiche le point précis (valeur + heure).
class _InteractiveChart extends StatefulWidget {
  final List<(DateTime, double)> points;
  final String unit;
  final Color accent, gridColor, labelColor, cardColor, textColor;
  final DateTime? domainStart, domainEnd;

  const _InteractiveChart({
    required this.points,
    required this.unit,
    required this.accent,
    required this.gridColor,
    required this.labelColor,
    required this.cardColor,
    required this.textColor,
    this.domainStart,
    this.domainEnd,
  });

  @override
  State<_InteractiveChart> createState() => _InteractiveChartState();
}

class _InteractiveChartState extends State<_InteractiveChart> {
  Offset? _touch;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => setState(() => _touch = e.localPosition),
      onPointerMove: (e) => setState(() => _touch = e.localPosition),
      child: CustomPaint(
        size: Size.infinite,
        painter: _LineChartPainter(
          points: widget.points,
          unit: widget.unit,
          accent: widget.accent,
          gridColor: widget.gridColor,
          labelColor: widget.labelColor,
          cardColor: widget.cardColor,
          textColor: widget.textColor,
          touch: _touch,
          domainStart: widget.domainStart,
          domainEnd: widget.domainEnd,
        ),
      ),
    );
  }
}

/// Courbe : remplissage dégradé + trait, grille avec valeurs (unité à gauche),
/// heures en bas, point du relevé le plus récent, et lecture au toucher.
class _LineChartPainter extends CustomPainter {
  final List<(DateTime, double)> points;
  final String unit;
  final Color accent, gridColor, labelColor, cardColor, textColor;
  final Offset? touch;
  final DateTime? domainStart, domainEnd;

  _LineChartPainter({
    required this.points,
    required this.unit,
    required this.accent,
    required this.gridColor,
    required this.labelColor,
    required this.cardColor,
    required this.textColor,
    required this.touch,
    this.domainStart,
    this.domainEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final values = [for (final p in points) p.$2];
    final n = values.length;

    var lo = values.reduce(min);
    var hi = values.reduce(max);
    var pad = (hi - lo) * 0.2;
    if (pad < 0.4) pad = 0.4; // évite une courbe écrasée quand ça varie peu
    lo -= pad;
    hi += pad;

    const leftPad = 46.0;   // étiquettes de valeurs (avec unité)
    const bottomPad = 22.0; // étiquettes d'heures
    const topPad = 8.0;
    final chart = Rect.fromLTRB(leftPad, topPad, size.width - 8, size.height - bottomPad);

    // Axe X : soit un domaine temporel fixe (jour choisi → 00:00:00 à 23:59:59),
    // soit une répartition régulière par index (vue en direct).
    final domained = domainStart != null && domainEnd != null &&
        domainEnd!.isAfter(domainStart!);
    final totalMs =
        domained ? domainEnd!.difference(domainStart!).inMilliseconds : 0;
    double xAt(int i) {
      if (domained) {
        final off =
            points[i].$1.difference(domainStart!).inMilliseconds.clamp(0, totalMs);
        return chart.left + off / totalMs * chart.width;
      }
      return chart.left + i / (n - 1) * chart.width;
    }

    // ── Grille horizontale + valeurs (unité à gauche) ────────────────────────
    final gridPaint = Paint()..color = gridColor..strokeWidth = 1;
    final labelStyle = TextStyle(fontSize: 9.5, color: labelColor);
    for (int i = 0; i < 3; i++) {
      final t = i / 2;
      final y = chart.top + t * chart.height;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      final v = hi - t * (hi - lo);
      final tp = TextPainter(
        text: TextSpan(text: '${v.toStringAsFixed(1)}$unit', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 6, y - tp.height / 2));
    }

    // ── Étiquettes d'heures (axe X) ──────────────────────────────────────────
    const tickCount = 4; // 5 repères
    for (int k = 0; k <= tickCount; k++) {
      final t = k / tickCount;
      final String label;
      if (domained) {
        final at = domainStart!.add(Duration(milliseconds: (t * totalMs).round()));
        label = DateFormat('HH:mm').format(at);
      } else {
        final idx = (t * (n - 1)).round().clamp(0, n - 1);
        label = DateFormat('HH:mm').format(points[idx].$1);
      }
      final tp = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = chart.left + t * chart.width;
      final dx = k == 0
          ? chart.left
          : k == tickCount
              ? chart.right - tp.width
              : x - tp.width / 2;
      tp.paint(canvas, Offset(dx, chart.bottom + 6));
    }

    // ── Courbe ───────────────────────────────────────────────────────────────
    Offset pointAt(int i) {
      final y = chart.top + (1 - (values[i] - lo) / (hi - lo)) * chart.height;
      return Offset(xAt(i), y);
    }

    final line = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (int i = 1; i < n; i++) {
      line.lineTo(pointAt(i).dx, pointAt(i).dy);
    }

    final fill = Path.from(line)
      ..lineTo(pointAt(n - 1).dx, chart.bottom)
      ..lineTo(pointAt(0).dx, chart.bottom)
      ..close();
    canvas.drawPath(fill, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [accent.withValues(alpha: 0.28), accent.withValues(alpha: 0.0)],
      ).createShader(chart));

    canvas.drawPath(line, Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);

    // Dernier relevé : halo + point
    final last = pointAt(n - 1);
    canvas.drawCircle(last, 8, Paint()..color = accent.withValues(alpha: 0.25));
    canvas.drawCircle(last, 3.5, Paint()..color = accent);

    // ── Lecture au toucher ───────────────────────────────────────────────────
    if (touch != null) {
      final tx = touch!.dx.clamp(chart.left, chart.right);
      // Point le plus proche horizontalement (robuste avec l'axe temporel).
      int idx = 0;
      double bestD = double.infinity;
      for (int i = 0; i < n; i++) {
        final d = (xAt(i) - tx).abs();
        if (d < bestD) { bestD = d; idx = i; }
      }
      final p = pointAt(idx);

      // Ligne verticale
      canvas.drawLine(
        Offset(p.dx, chart.top), Offset(p.dx, chart.bottom),
        Paint()..color = accent.withValues(alpha: 0.5)..strokeWidth = 1,
      );
      // Point mis en évidence
      canvas.drawCircle(p, 9, Paint()..color = accent.withValues(alpha: 0.22));
      canvas.drawCircle(p, 5, Paint()..color = accent);
      canvas.drawCircle(p, 2.2, Paint()..color = cardColor);

      // Infobulle valeur + heure
      final valTp = TextPainter(
        text: TextSpan(children: [
          TextSpan(text: '${values[idx].toStringAsFixed(1)}$unit',
              style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w700)),
          TextSpan(text: '\n${DateFormat('HH:mm:ss').format(points[idx].$1)}',
              style: TextStyle(color: labelColor, fontSize: 10, fontWeight: FontWeight.w500)),
        ]),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      const padH = 10.0, padV = 7.0;
      final boxW = valTp.width + padH * 2;
      final boxH = valTp.height + padV * 2;
      var bx = p.dx - boxW / 2;
      bx = bx.clamp(chart.left, chart.right - boxW);
      var by = p.dy - boxH - 14;
      if (by < chart.top) by = p.dy + 14; // pas de place au-dessus → en dessous
      final box = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, boxW, boxH), const Radius.circular(10));
      canvas.drawRRect(box, Paint()..color = cardColor);
      canvas.drawRRect(box, Paint()
        ..color = accent.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
      valTp.paint(canvas, Offset(bx + padH, by + padV));
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.points.length != points.length ||
      old.touch != touch ||
      old.domainStart != domainStart ||
      old.domainEnd != domainEnd ||
      (points.isNotEmpty && old.points.isNotEmpty && old.points.last.$2 != points.last.$2) ||
      old.accent != accent;
}

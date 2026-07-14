import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/species_service.dart';
import 'species_detail_screen.dart';

/// Température : « Point froid … » passe sur une ligne à part.
String _fmtTemp(String v) {
  if (v.isEmpty) return v;
  var s = v.replaceAll(RegExp(r'\s*·\s*[Ff]roid'), '\nPoint froid');
  return s.replaceAll(' · ', '\n');
}

/// Liste (tempérament…) : chaque élément séparé par une virgule sur sa ligne.
String _fmtList(String v) => v.isEmpty ? v : v.replaceAll(', ', '\n');

/// Comparateur : deux espèces côte à côte (température, taille, difficulté…).
class ComparatorScreen extends StatefulWidget {
  final ReptileSpecies? initial;
  const ComparatorScreen({super.key, this.initial});

  @override
  State<ComparatorScreen> createState() => _ComparatorScreenState();
}

class _ComparatorScreenState extends State<ComparatorScreen> {
  ReptileSpecies? _a;
  ReptileSpecies? _b;

  @override
  void initState() {
    super.initState();
    _a = widget.initial;
  }

  Future<void> _pick(bool isA) async {
    final picked = await showModalBottomSheet<ReptileSpecies>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SpeciesPickerSheet(),
    );
    if (picked != null) setState(() => isA ? _a = picked : _b = picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(children: [
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
          gradient: RadialGradient(center: const Alignment(0, -0.9), radius: 1.1,
              colors: [c.radialTop.withValues(alpha: 0.4), Colors.transparent]),
        ))),

        SafeArea(child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(Icons.arrow_back, color: c.textSecondary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('REPTILES', style: AppTextStyles.eyebrow),
                Text('Comparateur', style: AppTextStyles.serif28),
              ])),
            ]),
          ),
          const SizedBox(height: 16),

          // Sélecteurs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(child: _SpeciesSlot(species: _a, onTap: () => _pick(true))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c.card,
                      border: Border.all(color: c.border)),
                  child: Text('VS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.textMuted)),
                ),
              ),
              Expanded(child: _SpeciesSlot(species: _b, onTap: () => _pick(false))),
            ]),
          ),
          const SizedBox(height: 18),

          Expanded(child: (_a == null || _b == null)
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.compare_arrows_rounded, size: 48, color: c.textMuted.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text('Choisis deux reptiles à comparer',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: c.textMuted, height: 1.5)),
                  ]),
                ))
              : ListView(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + MediaQuery.of(context).padding.bottom),
                  children: [
                    _CompareRow(label: 'Type', a: _a!.category, b: _b!.category),
                    _DiffRow(a: _a!, b: _b!),
                    _CompareRow(label: 'Taille adulte', a: _a!.adultSize, b: _b!.adultSize),
                    _CompareRow(label: 'Espérance de vie', a: _a!.lifespan, b: _b!.lifespan),
                    _CompareRow(label: 'Régime', a: _a!.diet, b: _b!.diet),
                    _CompareRow(label: 'Température',
                        a: _fmtTemp(_a!.tempRange), b: _fmtTemp(_b!.tempRange)),
                    _CompareRow(label: 'Humidité', a: _a!.humidityRange, b: _b!.humidityRange),
                    _CompareRow(label: 'Terrarium', a: _a!.terrarium, b: _b!.terrarium),
                    _CompareRow(label: 'Origine', a: _a!.origin, b: _b!.origin),
                    _CompareRow(label: 'Tempérament',
                        a: _fmtList(_a!.temperament), b: _fmtList(_b!.temperament)),
                  ],
                )),
        ])),
      ]),
    );
  }
}

/// Emplacement d'une espèce (photo + nom, ou invite à choisir).
class _SpeciesSlot extends StatelessWidget {
  final ReptileSpecies? species;
  final VoidCallback onTap;
  const _SpeciesSlot({required this.species, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: glassCard(radius: 18),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          AspectRatio(
            aspectRatio: 1.4,
            child: species == null
                ? Container(
                    color: c.card,
                    child: Icon(Icons.add_photo_alternate_outlined, color: c.textMuted, size: 30),
                  )
                : SpeciesVisual(species: species!),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(children: [
              Text(species?.commonName ?? 'Choisir…', maxLines: 1, overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: species == null ? c.textMuted : c.textPrimary)),
              const SizedBox(height: 2),
              Text(species == null ? 'Appuie pour sélectionner' : 'Changer',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10.5, color: c.primary)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Style commun à TOUTES les valeurs comparées (taille strictement identique).
const _valueStyle = TextStyle(
  fontSize: 13, height: 1.3, fontWeight: FontWeight.w600,
  fontFeatures: [FontFeature.tabularFigures()],
);

Widget _valueLabel(String text, {Color? color}) => Center(
  child: Text(text, textAlign: TextAlign.center,
      style: color == null ? _valueStyle : _valueStyle.copyWith(color: color)),
);

/// Une ligne de comparaison : label centré + les deux valeurs.
class _CompareRow extends StatelessWidget {
  final String label;
  final String a, b;
  const _CompareRow({required this.label, required this.a, required this.b});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return _RowShell(label: label,
        a: _valueLabel(a.isEmpty ? '—' : a, color: c.textPrimary),
        b: _valueLabel(b.isEmpty ? '—' : b, color: c.textPrimary));
  }
}

/// Ligne difficulté (même style, juste la couleur du niveau).
class _DiffRow extends StatelessWidget {
  final ReptileSpecies a, b;
  const _DiffRow({required this.a, required this.b});

  @override
  Widget build(BuildContext context) {
    return _RowShell(label: 'Difficulté',
        a: _valueLabel(speciesLevelLabel(a), color: speciesLevelColor(a)),
        b: _valueLabel(speciesLevelLabel(b), color: speciesLevelColor(b)));
  }
}

/// Cadre commun d'une ligne (label + deux valeurs séparées).
class _RowShell extends StatelessWidget {
  final String label;
  final Widget a, b;
  const _RowShell({required this.label, required this.a, required this.b});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: glassCard(radius: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(children: [
        Text(label.toUpperCase(),
            style: TextStyle(fontSize: 10.5, letterSpacing: 0.6, fontWeight: FontWeight.w700, color: c.textMuted)),
        const SizedBox(height: 8),
        IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: a)),
          Container(width: 1, color: c.border),
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: b)),
        ])),
      ]),
    );
  }
}

/// Feuille de sélection d'une espèce (recherche + liste).
class _SpeciesPickerSheet extends StatefulWidget {
  const _SpeciesPickerSheet();
  @override
  State<_SpeciesPickerSheet> createState() => _SpeciesPickerSheetState();
}

class _SpeciesPickerSheetState extends State<_SpeciesPickerSheet> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    final results = SpeciesService.search(_query);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: c.border),
      ),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 4, decoration: BoxDecoration(
            color: c.border, borderRadius: BorderRadius.circular(50))),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: c.bg, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.border),
            ),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(color: c.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Rechercher un reptile…',
                hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: c.textMuted, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        Expanded(child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final s = results[i];
            return GestureDetector(
              onTap: () => Navigator.pop(context, s),
              child: Container(
                decoration: BoxDecoration(
                  color: c.bg, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(children: [
                  SizedBox(width: 64, height: 56, child: SpeciesVisual(species: s)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.commonName, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary)),
                    Text(s.scientificName, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: c.textMuted)),
                  ])),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(Icons.add_circle_outline, size: 20, color: c.primary),
                  ),
                ]),
              ),
            );
          },
        )),
      ]),
    );
  }
}

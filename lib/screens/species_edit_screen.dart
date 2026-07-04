import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/species_service.dart';

/// Édition manuelle d'une fiche espèce : tous les champs sont modifiables et
/// enregistrés dans Firestore (la version éditée remplace la version intégrée).
class SpeciesEditScreen extends StatefulWidget {
  final ReptileSpecies species;
  const SpeciesEditScreen({super.key, required this.species});

  @override
  State<SpeciesEditScreen> createState() => _SpeciesEditScreenState();
}

class _SpeciesEditScreenState extends State<SpeciesEditScreen> {
  String _clean(String s) => s.trim() == '—' ? '' : s;

  late final _commonName = TextEditingController(text: widget.species.commonName);
  late final _adultSize = TextEditingController(text: _clean(widget.species.adultSize));
  late final _lifespan = TextEditingController(text: _clean(widget.species.lifespan));
  late final _diet = TextEditingController(text: _clean(widget.species.diet));
  late final _tempRange = TextEditingController(text: _clean(widget.species.tempRange));
  late final _humidityRange = TextEditingController(text: _clean(widget.species.humidityRange));
  late final _terrarium = TextEditingController(text: _clean(widget.species.terrarium));
  late final _origin = TextEditingController(text: _clean(widget.species.origin));
  late final _temperament = TextEditingController(text: _clean(widget.species.temperament));
  late final _description = TextEditingController(text: widget.species.description);
  late final _maleTraits = TextEditingController(text: widget.species.maleTraits.join('\n'));
  late final _femaleTraits = TextEditingController(text: widget.species.femaleTraits.join('\n'));
  late final _sexingNote = TextEditingController(text: widget.species.sexingNote);

  late String? _category =
      widget.species.category.isEmpty ? null : widget.species.category;
  late String? _difficulty =
      widget.species.difficulty.isEmpty ? null : widget.species.difficulty;
  late bool _professional = widget.species.professional;

  bool _saving = false;
  String? _error;

  static const _categories = ['Lézard', 'Serpent', 'Araignée', 'Tortue', 'Amphibien', 'Autre'];
  static const _difficulties = ['Débutant', 'Intermédiaire', 'Avancé'];

  @override
  void dispose() {
    for (final c in [_commonName, _adultSize, _lifespan, _diet, _tempRange,
        _humidityRange, _terrarium, _origin, _temperament, _description,
        _maleTraits, _femaleTraits, _sexingNote]) {
      c.dispose();
    }
    super.dispose();
  }

  String _orDash(TextEditingController c) => c.text.trim().isEmpty ? '—' : c.text.trim();
  List<String> _lines(TextEditingController c) =>
      c.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  Future<void> _save() async {
    if (_commonName.text.trim().isEmpty) {
      setState(() => _error = 'Le nom commun est obligatoire.');
      return;
    }
    if (_category == null || _difficulty == null) {
      setState(() => _error = 'Choisis la catégorie et le niveau.');
      return;
    }
    setState(() { _saving = true; _error = null; });

    final updated = ReptileSpecies(
      id: widget.species.id,
      commonName: _commonName.text.trim(),
      scientificName: widget.species.scientificName,
      category: _category!,
      emoji: widget.species.emoji,
      difficulty: _difficulty!,
      adultSize: _orDash(_adultSize),
      lifespan: _orDash(_lifespan),
      diet: _orDash(_diet),
      tempRange: _orDash(_tempRange),
      humidityRange: _orDash(_humidityRange),
      terrarium: _orDash(_terrarium),
      origin: _orDash(_origin),
      temperament: _orDash(_temperament),
      description: _description.text.trim(),
      maleTraits: _lines(_maleTraits),
      femaleTraits: _lines(_femaleTraits),
      sexingNote: _sexingNote.text.trim(),
      professional: _professional,
      imageUrl: widget.species.imageUrl,
    );

    try {
      await SpeciesService.saveSpecies(updated);
      if (mounted) Navigator.of(context).pop(updated);
    } on FirebaseException catch (e) {
      // Montre la vraie cause (ex. permission-denied = règles Firestore).
      if (mounted) setState(() { _saving = false; _error = 'Erreur Firestore : ${e.code}'; });
    } catch (e) {
      if (mounted) setState(() { _saving = false; _error = 'Erreur : $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Text('Annuler', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('FICHE ESPÈCE', style: AppTextStyles.eyebrow),
            const SizedBox(height: 6),
            Text('Modifier la fiche',
                style: GoogleFonts.fraunces(fontSize: 24, fontWeight: FontWeight.w600, color: c.textPrimary)),
            const SizedBox(height: 4),
            Text(widget.species.scientificName,
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: c.textMuted)),
          ]),
        ),

        Expanded(child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          children: [
            _EditField(label: 'Nom commun', ctrl: _commonName),

            const SizedBox(height: 18),
            Text('CATÉGORIE', style: AppTextStyles.eyebrow),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final cat in _categories)
                _Chip(label: cat, selected: _category == cat,
                    onTap: () => setState(() => _category = cat)),
            ]),

            const SizedBox(height: 18),
            Text('NIVEAU', style: AppTextStyles.eyebrow),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final d in _difficulties)
                _Chip(label: d, selected: _difficulty == d,
                    onTap: () => setState(() => _difficulty = d)),
            ]),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => setState(() => _professional = !_professional),
              child: Row(children: [
                Icon(_professional ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 20, color: _professional ? c.primary : c.textMuted),
                const SizedBox(width: 10),
                Expanded(child: Text('Certificat de capacité requis (professionnel)',
                    style: TextStyle(fontSize: 14, color: c.textSecondary))),
              ]),
            ),

            const SizedBox(height: 22),
            Text('CARACTÉRISTIQUES', style: AppTextStyles.eyebrow),
            const SizedBox(height: 10),
            _EditField(label: 'Taille adulte', ctrl: _adultSize, hint: 'ex. 20–25 cm'),
            _EditField(label: 'Espérance de vie', ctrl: _lifespan, hint: 'ex. 15–20 ans'),
            _EditField(label: 'Régime', ctrl: _diet, hint: 'ex. Insectivore'),
            _EditField(label: 'Température', ctrl: _tempRange, hint: 'ex. Point chaud 30–32 °C · froid 24–26 °C'),
            _EditField(label: 'Humidité', ctrl: _humidityRange, hint: 'ex. 30–40 %'),
            _EditField(label: 'Terrarium', ctrl: _terrarium, hint: 'ex. Désertique · 60×40 cm min.'),
            _EditField(label: 'Origine', ctrl: _origin, hint: 'ex. Asie centrale'),
            _EditField(label: 'Caractère', ctrl: _temperament, hint: 'ex. Docile, nocturne'),

            const SizedBox(height: 14),
            Text('À PROPOS', style: AppTextStyles.eyebrow),
            const SizedBox(height: 10),
            _EditField(label: 'Description', ctrl: _description, maxLines: 5,
                hint: 'Présentation de l\'espèce, conseils généraux…'),

            const SizedBox(height: 14),
            Text('MÂLE / FEMELLE', style: AppTextStyles.eyebrow),
            const SizedBox(height: 10),
            _EditField(label: 'Critères mâle (un par ligne)', ctrl: _maleTraits, maxLines: 4),
            _EditField(label: 'Critères femelle (un par ligne)', ctrl: _femaleTraits, maxLines: 4),
            _EditField(label: 'Note de sexage', ctrl: _sexingNote,
                hint: 'ex. Fiable à partir de 6 mois'),

            if (_error != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppColors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.red))),
                ]),
              ),
            ],

            const SizedBox(height: 18),
            GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: c.primary, borderRadius: BorderRadius.circular(50),
                  boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.3),
                      blurRadius: 18, offset: const Offset(0, 6))],
                ),
                child: _saving
                    ? Center(child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: c.bg)))
                    : Text('Enregistrer la fiche', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.bg)),
              ),
            ),
          ],
        )),
      ])),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String? hint;
  final int maxLines;
  const _EditField({required this.label, required this.ctrl, this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textSecondary)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(maxLines > 1 ? 16 : 14),
            border: Border.all(color: c.border),
          ),
          child: TextField(
            controller: ctrl,
            maxLines: maxLines,
            style: TextStyle(color: c.textPrimary, fontSize: 14, height: 1.5),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: c.textHint, fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.primary : c.card,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: selected ? c.primary : c.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: selected ? c.bg : c.textSecondary)),
      ),
    );
  }
}

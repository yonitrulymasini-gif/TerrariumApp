import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/inaturalist_service.dart';
import '../services/species_service.dart';

/// Ajout d'une espèce à l'encyclopédie :
/// recherche iNaturalist (nom + nom scientifique + photo) → choix de la
/// catégorie et du niveau → fiche créée dans Firestore. Les infos d'élevage
/// (températures, sexage…) seront complétées ensuite par Théo.
class SpeciesAddScreen extends StatefulWidget {
  const SpeciesAddScreen({super.key});
  @override
  State<SpeciesAddScreen> createState() => _SpeciesAddScreenState();
}

class _SpeciesAddScreenState extends State<SpeciesAddScreen> {
  final _searchCtrl = TextEditingController();
  List<INatTaxon> _results = [];
  bool _searching = false;
  bool _saving = false;

  INatTaxon? _selected;
  String? _category;
  String? _level;
  bool _professional = false;

  static const _categories = ['Lézard', 'Serpent', 'Araignée', 'Tortue', 'Amphibien', 'Autre'];
  static const _levels = ['Débutant', 'Intermédiaire', 'Avancé'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() { _searching = true; _selected = null; });
    final results = await INaturalistService.search(q);
    if (mounted) setState(() { _results = results; _searching = false; });
  }

  String _slug(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');

  Future<void> _save() async {
    final t = _selected;
    if (t == null || _category == null || _level == null) return;

    // Doublon ? (fiches intégrées + fiches déjà ajoutées)
    final exists = SpeciesService.all.any((s) =>
        s.scientificName.toLowerCase() == t.scientificName.toLowerCase());
    if (exists) {
      _toast('Cette espèce est déjà dans l\'encyclopédie.');
      return;
    }

    setState(() => _saving = true);
    try {
      await SpeciesService.addSpecies(ReptileSpecies(
        id: _slug(t.scientificName),
        commonName: t.commonName ?? t.scientificName,
        scientificName: t.scientificName,
        category: _category!,
        emoji: '🦎',
        difficulty: _level!,
        adultSize: '—',
        lifespan: '—',
        diet: '—',
        tempRange: '—',
        humidityRange: '—',
        terrarium: '—',
        origin: '—',
        temperament: '—',
        description: '',
        maleTraits: [],
        femaleTraits: [],
        sexingNote: '',
        professional: _professional,
        // Pas d'imageUrl : les photos iNaturalist se chargent automatiquement.
      ));
      if (!mounted) return;
      Navigator.of(context).pop();
    } on FirebaseException catch (e) {
      // permission-denied = règles Firestore à mettre à jour.
      if (mounted) {
        setState(() => _saving = false);
        _toast('Ajout impossible : ${e.code}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _toast('Ajout impossible : $e');
      }
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ThemeService.instance.colors.card,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    final canSave = _selected != null && _category != null && _level != null && !_saving;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text('Retour', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ENCYCLOPÉDIE', style: AppTextStyles.eyebrow),
            const SizedBox(height: 6),
            Text('Ajouter une espèce',
                style: GoogleFonts.fraunces(fontSize: 26, fontWeight: FontWeight.w600, color: c.textPrimary)),
            const SizedBox(height: 6),
            Text('Cherche l\'espèce, choisis la catégorie et le niveau.\nLes infos d\'élevage seront complétées ensuite.',
                style: TextStyle(fontSize: 13, color: c.textMuted, height: 1.5)),
          ]),
        ),
        const SizedBox(height: 16),

        // Recherche
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Expanded(child: Container(
              decoration: BoxDecoration(
                color: c.card, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border),
              ),
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: (_) => _search(),
                textInputAction: TextInputAction.search,
                style: TextStyle(color: c.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Nom commun ou scientifique…',
                  hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: c.textMuted, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _search,
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(14)),
                child: _searching
                    ? Padding(padding: const EdgeInsets.all(14),
                        child: CircularProgressIndicator(strokeWidth: 2, color: c.bg))
                    : Icon(Icons.search, color: c.bg, size: 22),
              ),
            ),
          ]),
        ),

        // Résultats + formulaire
        Expanded(child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            if (_results.isEmpty && !_searching)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(children: [
                  Icon(Icons.travel_explore, size: 44, color: c.textMuted.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text('Cherche une espèce sur iNaturalist',
                      style: TextStyle(fontSize: 14, color: c.textMuted)),
                  const SizedBox(height: 4),
                  Text('ex. « Python regius » ou « gecko »',
                      style: TextStyle(fontSize: 12, color: c.textHint)),
                ]),
              ),

            for (final t in _results) ...[
              _ResultTile(
                taxon: t,
                selected: _selected?.scientificName == t.scientificName,
                onTap: () => setState(() => _selected = t),
              ),
              const SizedBox(height: 10),
            ],

            // Formulaire une fois l'espèce choisie
            if (_selected != null) ...[
              const SizedBox(height: 10),
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
                for (final l in _levels)
                  _Chip(label: l, selected: _level == l,
                      onTap: () => setState(() => _level = l)),
              ]),
              const SizedBox(height: 18),
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
              const SizedBox(height: 24),
              GestureDetector(
                onTap: canSave ? _save : null,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: canSave ? 1 : 0.45,
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
                        : Text('Ajouter à l\'encyclopédie', textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.bg)),
                  ),
                ),
              ),
            ],
          ],
        )),
      ])),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final INatTaxon taxon;
  final bool selected;
  final VoidCallback onTap;
  const _ResultTile({required this.taxon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? c.primary.withValues(alpha: 0.12) : c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? c.primary : c.border, width: selected ? 1.5 : 1),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(width: 52, height: 52, child: taxon.photoUrl != null
                ? Image.network(taxon.photoUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(color: c.bg))
                : ColoredBox(color: c.bg,
                    child: Icon(Icons.image_outlined, size: 20, color: c.textMuted))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(taxon.commonName ?? taxon.scientificName,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: selected ? c.primary : c.textPrimary)),
            const SizedBox(height: 2),
            Text(taxon.scientificName, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: c.textMuted)),
          ])),
          if (selected) Icon(Icons.check_circle, size: 20, color: c.primary),
        ]),
      ),
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

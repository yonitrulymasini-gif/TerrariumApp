import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../widgets/terra_toast.dart';

/// Édition du profil : prénom, niveau et animaux préférés.
/// Reprend les mêmes options que le questionnaire d'accueil.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _prenomCtrl = TextEditingController();
  String? _niveau;
  final Set<String> _animals = {};
  bool _loading = true;
  bool _saving = false;

  static const _levels = [
    ('🌱', 'Débutant', 'Je découvre la terrariophilie'),
    ('🌿', 'Intermédiaire', 'Je connais déjà pas mal de choses'),
    ('🌳', 'Avancé', 'La terrariophilie, c\'est mon quotidien'),
  ];
  static const _animalsList = [
    ('🦎', 'Lézard'), ('🐍', 'Serpent'), ('🕷️', 'Araignée'),
    ('🐢', 'Tortue'), ('🐸', 'Amphibien'), ('🐾', 'Autre'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _prenomCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    _prenomCtrl.text = user?.displayName ?? '';
    try {
      final uid = user?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final data = doc.data();
        if (data != null) {
          if ((data['prenom'] as String?)?.isNotEmpty ?? false) {
            _prenomCtrl.text = data['prenom'];
          }
          _niveau = data['niveau'] as String?;
          _animals.addAll(List<String>.from(data['animaux'] ?? []));
        }
      }
    } catch (_) {
      // Hors-ligne / pas de profil : on garde les valeurs par défaut.
    }
    if (mounted) setState(() => _loading = false);
  }

  bool get _canSave => _prenomCtrl.text.trim().isNotEmpty && _niveau != null;

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);
    final prenom = _prenomCtrl.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    try {
      await user?.updateDisplayName(prenom);
      final uid = user?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'prenom': prenom,
          'niveau': _niveau,
          'animaux': _animals.toList(),
          'onboarded': true,
        }, SetOptions(merge: true));
      }
      if (mounted) {
        showTerraToast(context, 'Profil mis à jour ✓');
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showTerraToast(context, 'Impossible d\'enregistrer. Réessaie.', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(children: [
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
          gradient: RadialGradient(center: const Alignment(0, -0.9), radius: 1.1,
              colors: [c.radialTop.withValues(alpha: 0.5), Colors.transparent]),
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
                Text('PROFIL', style: AppTextStyles.eyebrow),
                Text('Modifier', style: AppTextStyles.serif28),
              ])),
            ]),
          ),
          const SizedBox(height: 8),

          Expanded(child: _loading
              ? Center(child: CircularProgressIndicator(color: c.primary))
              : SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Prénom
                    Text('PRÉNOM', style: AppTextStyles.eyebrow),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: c.card, borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: c.border),
                      ),
                      child: TextField(
                        controller: _prenomCtrl,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(color: c.textPrimary, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Ton prénom',
                          hintStyle: TextStyle(color: c.textMuted, fontSize: 15),
                          prefixIcon: Icon(Icons.person_outline, color: c.textMuted, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),

                    // Niveau
                    Text('NIVEAU', style: AppTextStyles.eyebrow),
                    const SizedBox(height: 10),
                    for (final l in _levels) ...[
                      _LevelTile(
                        emoji: l.$1, title: l.$2, subtitle: l.$3,
                        selected: _niveau == l.$2,
                        onTap: () => setState(() => _niveau = l.$2),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 16),

                    // Reptiles
                    Text('LES REPTILES DE TA JUNGLE', style: AppTextStyles.eyebrow),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final a in _animalsList)
                        _AnimalChip(
                          emoji: a.$1, label: a.$2,
                          selected: _animals.contains(a.$2),
                          onTap: () => setState(() =>
                              _animals.contains(a.$2) ? _animals.remove(a.$2) : _animals.add(a.$2)),
                        ),
                    ]),
                  ]),
                )),

          // Bouton enregistrer
          if (!_loading)
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + (bottomInset > 0 ? 0 : 0)),
              child: GestureDetector(
                onTap: (_canSave && !_saving) ? _save : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  decoration: BoxDecoration(
                    color: _canSave ? c.primary : c.card,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: _canSave ? c.primary : c.border),
                    boxShadow: _canSave
                        ? [BoxShadow(color: c.primary.withValues(alpha: 0.3),
                            blurRadius: 18, offset: const Offset(0, 6))]
                        : [],
                  ),
                  child: _saving
                      ? Center(child: SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: c.bg)))
                      : Text('Enregistrer', textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                              color: _canSave ? c.bg : c.textMuted)),
                ),
              ),
            ),
        ])),
      ]),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final String emoji, title, subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _LevelTile({required this.emoji, required this.title, required this.subtitle,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? c.primary.withValues(alpha: 0.12) : c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? c.primary : c.border, width: selected ? 1.4 : 1),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                color: selected ? c.primary : c.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 12.5, color: c.textMuted)),
          ])),
          if (selected) Icon(Icons.check_circle, size: 20, color: c.primary),
        ]),
      ),
    );
  }
}

class _AnimalChip extends StatelessWidget {
  final String emoji, label;
  final bool selected;
  final VoidCallback onTap;
  const _AnimalChip({required this.emoji, required this.label,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.primary.withValues(alpha: 0.14) : c.card,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: selected ? c.primary : c.border, width: selected ? 1.4 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
              color: selected ? c.primary : c.textSecondary)),
        ]),
      ),
    );
  }
}

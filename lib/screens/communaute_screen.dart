import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/community_service.dart';
import '../services/profile_service.dart';
import '../services/scenario_service.dart';
import '../services/app_nav.dart';
import '../services/species_service.dart';
import '../services/device_service.dart';
import '../services/admin_service.dart';
import '../services/favorites_service.dart';
import '../widgets/terra_toast.dart';
import '../widgets/terra_confirm_dialog.dart';
import '../widgets/fullscreen_image.dart';
import '../utils/fade_route.dart';
import 'species_detail_screen.dart';
import 'species_add_screen.dart';
import 'comparator_screen.dart';
import 'expert_profile_screen.dart';
import 'pairing_screen.dart';

class CommunauteScreen extends StatefulWidget {
  const CommunauteScreen({super.key});
  @override
  State<CommunauteScreen> createState() => _CommunauteScreenState();
}

class _CommunauteScreenState extends State<CommunauteScreen> {
  int _section = 0; // 0 = Général, 1 = Scénarios, 2 = Reptiles
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _sheetOpen = false;
  final _speciesCtrl = TextEditingController();
  String _speciesQuery = '';
  SpeciesFilter _filter = const SpeciesFilter();
  bool _favoritesOnly = false;

  // Préférences issues du questionnaire (pour « Suggéré pour toi »)
  String? _userNiveau;
  List<String> _userAnimals = [];

  @override
  void initState() {
    super.initState();
    AppNav.instance.addListener(_onNav);
    _loadPrefs();
    // Fiches ajoutées via l'app (Firestore) : écoute temps réel.
    SpeciesService.instance.init();
    SpeciesService.instance.addListener(_onSpeciesChange);
    FavoritesService.instance.addListener(_onSpeciesChange);
    AdminService.instance.addListener(_onSpeciesChange);
    // Au cas où un scénario serait déjà en attente à la création
    WidgetsBinding.instance.addPostFrameCallback((_) => _onNav());
  }

  void _onSpeciesChange() { if (mounted) setState(() {}); }

  Future<void> _loadPrefs() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data == null || !mounted) return;
      setState(() {
        _userNiveau = data['niveau'] as String?;
        _userAnimals = List<String>.from(data['animaux'] ?? []);
      });
    } catch (_) {
      // Pas de profil (invité…) → pas de suggestions, sans erreur.
    }
  }

  @override
  void dispose() {
    AppNav.instance.removeListener(_onNav);
    SpeciesService.instance.removeListener(_onSpeciesChange);
    FavoritesService.instance.removeListener(_onSpeciesChange);
    AdminService.instance.removeListener(_onSpeciesChange);
    _speciesCtrl.dispose();
    super.dispose();
  }

  void _onNav() {
    if (AppNav.instance.tab != AppNav.communityTab) return;
    final scenario = AppNav.instance.consumePendingScenario();
    if (scenario != null && mounted) {
      setState(() => _section = 1); // bascule sur Scénarios
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showNewPost(context, scenario: scenario);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var speciesResults = SpeciesService.search(_speciesQuery);
    if (!_filter.isEmpty) {
      speciesResults = speciesResults.where(_filter.matches).toList();
    }
    if (_favoritesOnly) {
      speciesResults = speciesResults.where((s) => FavoritesService.instance.isFavorite(s.id)).toList();
    }
    final suggestions = SpeciesService.suggestFor(niveau: _userNiveau, animaux: _userAnimals);
    // « Suggéré pour toi » reste visible pendant la recherche ; on ne le masque
    // que pour les vues ciblées (filtre actif ou mode Favoris).
    final showSuggestions = suggestions.isNotEmpty && _filter.isEmpty && !_favoritesOnly;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('COMMUNAUTÉ', style: AppTextStyles.eyebrow),
                  const SizedBox(height: 6),
                  Text('Explore', style: AppTextStyles.serif28),
                ]),
                const SizedBox(width: 44),
              ]),
            )),

            // ── Sélecteur Fil / Espèces ───────────────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: _SectionToggle(section: _section, onChanged: (s) => setState(() => _section = s)),
            )),

            if (_section == 2) ...[
              // ── Carte expert (frère passionné) ──────────────────────────
              // Pas de const : la carte lit les couleurs du thème et doit se
              // reconstruire quand il change.
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                // ignore: prefer_const_constructors
                child: _ExpertCarousel(),
              )),

              // ── Suggéré pour toi (selon le questionnaire) ────────────────
              if (showSuggestions) ...[
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(children: [
                    Icon(Icons.auto_awesome, size: 13, color: ThemeService.instance.colors.primary),
                    const SizedBox(width: 6),
                    Text('SUGGÉRÉ POUR TOI', style: AppTextStyles.eyebrow),
                  ]),
                )),
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SizedBox(
                    height: 182,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: suggestions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => _SuggestedCard(species: suggestions[i]),
                    ),
                  ),
                )),
              ],

              // ── Recherche + ajout + grille ──────────────────────────────
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(children: [
                  Expanded(child: Container(
                    decoration: BoxDecoration(
                      color: ThemeService.instance.colors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ThemeService.instance.colors.border),
                    ),
                    child: TextField(
                      controller: _speciesCtrl,
                      onChanged: (v) => setState(() => _speciesQuery = v),
                      style: TextStyle(color: ThemeService.instance.colors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un reptile…',
                        hintStyle: TextStyle(color: ThemeService.instance.colors.textMuted, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: ThemeService.instance.colors.textMuted, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  )),
                  if (AdminService.instance.isAdmin) ...[
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(fadeRoute(const SpeciesAddScreen())),
                      child: Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: ThemeService.instance.colors.border),
                          color: ThemeService.instance.colors.card,
                        ),
                        child: Icon(Icons.add, color: ThemeService.instance.colors.primary, size: 22),
                      ),
                    ),
                  ],
                ]),
              )),

              // ── Bouton Filtres ──────────────────────────────────────────
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(children: [
                  Expanded(child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                  _FilterButton(
                    active: !_filter.isEmpty,
                    count: _filter.count,
                    onTap: _openFilterSheet,
                  ),
                  const SizedBox(width: 10),
                  // Favoris
                  Builder(builder: (context) {
                    final c = ThemeService.instance.colors;
                    return GestureDetector(
                      onTap: () => setState(() => _favoritesOnly = !_favoritesOnly),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _favoritesOnly ? AppColors.red.withValues(alpha: 0.12) : c.card,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: _favoritesOnly ? AppColors.red : c.border),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_favoritesOnly ? Icons.favorite : Icons.favorite_border,
                              size: 16, color: _favoritesOnly ? AppColors.red : c.textSecondary),
                          const SizedBox(width: 7),
                          Text('Favoris', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: _favoritesOnly ? AppColors.red : c.textSecondary)),
                        ]),
                      ),
                    );
                  }),
                  const SizedBox(width: 10),
                  // Comparateur
                  Builder(builder: (context) {
                    final c = ThemeService.instance.colors;
                    return GestureDetector(
                      onTap: () => Navigator.of(context).push(fadeRoute(const ComparatorScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.compare_arrows_rounded, size: 16, color: c.textSecondary),
                          const SizedBox(width: 7),
                          Text('Comparer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: c.textSecondary)),
                        ]),
                      ),
                    );
                  }),
                  if (!_filter.isEmpty) ...[
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => setState(() => _filter = const SpeciesFilter()),
                      child: Text('Réinitialiser',
                          style: TextStyle(fontSize: 13, color: ThemeService.instance.colors.textMuted,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                    ]),
                  )),
                  const SizedBox(width: 10),
                  Text('${speciesResults.length} ${speciesResults.length > 1 ? 'espèces' : 'espèce'}',
                      style: TextStyle(fontSize: 12, color: ThemeService.instance.colors.textMuted)),
                ]),
              )),

              if (speciesResults.isEmpty)
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                  child: Column(children: [
                    Icon(_favoritesOnly ? Icons.favorite_border : Icons.search_off,
                        size: 44, color: ThemeService.instance.colors.textMuted.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text(_favoritesOnly ? 'Aucun favori pour l\'instant' : 'Aucun reptile trouvé',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: ThemeService.instance.colors.textMuted)),
                    if (_favoritesOnly) ...[
                      const SizedBox(height: 6),
                      Text('Appuie sur le ♥ d\'une fiche pour l\'ajouter.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: ThemeService.instance.colors.textHint)),
                    ],
                  ]),
                ))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.72),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => SpeciesCard(
                          key: ValueKey(speciesResults[i].id), species: speciesResults[i]),
                      childCount: speciesResults.length,
                      findChildIndexCallback: (key) {
                        final id = (key as ValueKey).value;
                        final idx = speciesResults.indexWhere((s) => s.id == id);
                        return idx < 0 ? null : idx;
                      },
                    ),
                  ),
                ),
            ] else if (_section == 0) ...[
              // ── Général : liste des salons ──────────────────────────────
              SliverToBoxAdapter(child: StreamBuilder<List<CommunityPost>>(
                stream: CommunityService.postsStream(),
                builder: (ctx, snap) {
                  final general = (snap.data ?? []).where((p) => p.scenario == null).toList();
                  int countFor(String key) => general.where((p) => p.category == key).length;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Column(children: [
                      for (final salon in PostCategory.salons) ...[
                        _SalonCard(
                          salon: salon,
                          count: countFor(salon.key),
                          onTap: () => Navigator.of(context).push(fadeRoute(SalonScreen(salon: salon))),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ]),
                  );
                },
              )),
            ] else ...[
              // ── Scénarios : flux de posts avec scénario ─────────────────
              StreamBuilder<List<CommunityPost>>(
                stream: CommunityService.postsStream(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return SliverToBoxAdapter(
                      child: Center(child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: ThemeService.instance.colors.primary),
                      )),
                    );
                  }
                  final posts = (snap.data ?? []).where((p) => p.scenario != null).toList();
                  if (posts.isEmpty) {
                    return SliverToBoxAdapter(child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                      child: Column(children: [
                        const SizedBox(height: 30),
                        Icon(Icons.auto_awesome_outlined,
                            size: 48, color: ThemeService.instance.colors.textMuted.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text('Aucun scénario partagé', textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: ThemeService.instance.colors.textMuted)),
                        const SizedBox(height: 8),
                        Text('Partage un scénario depuis l\'onglet Scénarios.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: ThemeService.instance.colors.textHint)),
                      ]),
                    ));
                  }
                  return SliverList(delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: EdgeInsets.fromLTRB(20, i == 0 ? 16 : 0, 20, 16),
                      child: _PostCard(post: posts[i]),
                    ),
                    childCount: posts.length,
                  ));
                },
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  void _showNewPost(BuildContext context, {TerraScenario? scenario}) {
    if (_sheetOpen) return; // déjà ouvert
    final messenger = ScaffoldMessenger.of(context);
    // Feuille PERSISTANTE (pas modale) : le fil reste scrollable derrière
    // pendant la rédaction du post.
    final ctrl = _scaffoldKey.currentState?.showBottomSheet(
      (ctx) => _NewPostSheet(messenger: messenger, scenario: scenario),
      backgroundColor: ThemeService.instance.colors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      elevation: 20,
    );
    _sheetOpen = ctrl != null;
    ctrl?.closed.whenComplete(() => _sheetOpen = false);
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<SpeciesFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SpeciesFilterSheet(initial: _filter),
    );
    if (result != null) setState(() => _filter = result);
  }
}

// ── Sélecteur de section (Général / Scénarios / Reptiles) ────────────────────

class _SectionToggle extends StatelessWidget {
  final int section;
  final ValueChanged<int> onChanged;
  const _SectionToggle({required this.section, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    Widget seg(int i, String label, IconData icon) {
      final sel = section == i;
      return Expanded(child: GestureDetector(
        onTap: () => onChanged(i),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? c.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 15, color: sel ? c.bg : c.textMuted),
            const SizedBox(width: 5),
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                    color: sel ? c.bg : c.textMuted))),
          ]),
        ),
      ));
    }
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.card, borderRadius: BorderRadius.circular(50),
        border: Border.all(color: c.border),
      ),
      child: Row(children: [
        seg(0, 'Général', Icons.chat_bubble_outline),
        seg(1, 'Scénarios', Icons.auto_awesome_outlined),
        seg(2, 'Reptiles', Icons.travel_explore),
      ]),
    );
  }
}

// ── Filtre des espèces (Reptiles) ────────────────────────────────────────────

/// Détermine la tranche de taille d'une espèce à partir de son texte
/// (« 20–25 cm », « 1,2–1,5 m »…). Renvoie null si la taille est inconnue.
String? speciesSizeBucket(String raw) {
  final s = raw.toLowerCase();
  final matches = RegExp(r'\d+(?:[.,]\d+)?').allMatches(s);
  if (matches.isEmpty) return null;
  double maxV = 0;
  for (final m in matches) {
    final v = double.tryParse(m.group(0)!.replaceAll(',', '.'));
    if (v != null && v > maxV) maxV = v;
  }
  if (maxV == 0) return null;
  final cm = s.contains('cm') ? maxV : maxV * 100;
  if (cm < 40) return 'Petit';
  if (cm <= 120) return 'Moyen';
  return 'Grand';
}

/// État immuable du filtre appliqué à la liste d'espèces.
class SpeciesFilter {
  final Set<String> types;
  final Set<String> difficulties;
  final Set<String> sizes;
  final bool certifOnly;
  final bool venomousOnly;

  const SpeciesFilter({
    this.types = const {},
    this.difficulties = const {},
    this.sizes = const {},
    this.certifOnly = false,
    this.venomousOnly = false,
  });

  bool get isEmpty =>
      types.isEmpty && difficulties.isEmpty && sizes.isEmpty && !certifOnly && !venomousOnly;

  int get count =>
      types.length + difficulties.length + sizes.length + (certifOnly ? 1 : 0) + (venomousOnly ? 1 : 0);

  bool matches(ReptileSpecies s) {
    if (types.isNotEmpty && !types.contains(s.category)) return false;
    if (difficulties.isNotEmpty && !difficulties.contains(s.difficulty)) return false;
    if (certifOnly && !s.professional) return false;
    if (venomousOnly && !s.venomous) return false;
    if (sizes.isNotEmpty && !sizes.contains(speciesSizeBucket(s.adultSize))) return false;
    return true;
  }
}

/// Bouton « Filtres » qui ouvre la feuille de filtres (avec pastille du nombre).
class _FilterButton extends StatelessWidget {
  final bool active;
  final int count;
  final VoidCallback onTap;
  const _FilterButton({required this.active, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? c.primary : c.card,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: active ? c.primary : c.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.tune, size: 16, color: active ? c.bg : c.textSecondary),
          const SizedBox(width: 8),
          Text('Filtres', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: active ? c.bg : c.textSecondary)),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(color: c.bg.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(50)),
              child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.bg)),
            ),
          ],
        ]),
      ),
    );
  }
}

// ── Feuille de filtres ───────────────────────────────────────────────────────

class _SpeciesFilterSheet extends StatefulWidget {
  final SpeciesFilter initial;
  const _SpeciesFilterSheet({required this.initial});

  @override
  State<_SpeciesFilterSheet> createState() => _SpeciesFilterSheetState();
}

class _SpeciesFilterSheetState extends State<_SpeciesFilterSheet> {
  late Set<String> _types = {...widget.initial.types};
  late Set<String> _difficulties = {...widget.initial.difficulties};
  late Set<String> _sizes = {...widget.initial.sizes};
  late bool _certif = widget.initial.certifOnly;
  late bool _venom = widget.initial.venomousOnly;

  static const _typeOptions = ['Lézard', 'Serpent', 'Araignée', 'Tortue', 'Amphibien', 'Autre'];
  static const _diffOptions = ['Débutant', 'Intermédiaire', 'Avancé'];
  static const _sizeOptions = {
    'Petit': '< 40 cm',
    'Moyen': '40 cm – 1,2 m',
    'Grand': '> 1,2 m',
  };

  int get _count =>
      _types.length + _difficulties.length + _sizes.length + (_certif ? 1 : 0) + (_venom ? 1 : 0);

  void _toggle(Set<String> set, String value) {
    setState(() => set.contains(value) ? set.remove(value) : set.add(value));
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: c.border),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 4, decoration: BoxDecoration(
            color: c.border, borderRadius: BorderRadius.circular(50))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
          child: Row(children: [
            Icon(Icons.tune_rounded, size: 22, color: c.primary),
            const SizedBox(width: 10),
            Text('Filtres', style: AppTextStyles.serif28),
            const Spacer(),
            if (_count > 0)
              GestureDetector(
                onTap: () => setState(() {
                  _types = {}; _difficulties = {}; _sizes = {}; _certif = false; _venom = false;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.close, size: 13, color: c.textMuted),
                    const SizedBox(width: 5),
                    Text('Effacer', style: TextStyle(fontSize: 12.5, color: c.textMuted, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
          ]),
        ),
        Flexible(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _section('Type'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in _typeOptions)
                _SelectChip(label: t, selected: _types.contains(t), onTap: () => _toggle(_types, t)),
            ]),
            const SizedBox(height: 22),

            _section('Difficulté'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final d in _diffOptions)
                _SelectChip(label: d, selected: _difficulties.contains(d), onTap: () => _toggle(_difficulties, d)),
            ]),
            const SizedBox(height: 22),

            _section('Taille adulte'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final e in _sizeOptions.entries)
                _SelectChip(label: e.key, subtitle: e.value,
                    selected: _sizes.contains(e.key), onTap: () => _toggle(_sizes, e.key)),
            ]),
            const SizedBox(height: 22),

            _section('Particularités'),
            _SwitchRow(
              icon: Icons.workspace_premium_outlined,
              label: 'Certificat de capacité requis',
              value: _certif,
              onChanged: (v) => setState(() => _certif = v),
            ),
            const SizedBox(height: 10),
            _SwitchRow(
              icon: Icons.warning_amber_rounded,
              label: 'Espèces venimeuses',
              value: _venom,
              onChanged: (v) => setState(() => _venom = v),
            ),
          ]),
        )),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
          child: GestureDetector(
            onTap: () => Navigator.pop(context, SpeciesFilter(
              types: _types, difficulties: _difficulties, sizes: _sizes,
              certifOnly: _certif, venomousOnly: _venom,
            )),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.3),
                    blurRadius: 16, offset: const Offset(0, 5))],
              ),
              child: Text(_count > 0 ? 'Afficher les résultats ($_count)' : 'Afficher les résultats',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.bg)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _section(String title) {
    final c = ThemeService.instance.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 2),
      child: Row(children: [
        Container(width: 3, height: 13,
            decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(50))),
        const SizedBox(width: 8),
        Text(title.toUpperCase(), style: AppTextStyles.eyebrow),
      ]),
    );
  }
}

class _SelectChip extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _SelectChip({required this.label, this.subtitle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.primary.withValues(alpha: 0.16) : c.bg,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected ? c.primary : c.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
              color: selected ? c.primary : c.textSecondary)),
          if (subtitle != null) ...[
            const SizedBox(width: 6),
            Text(subtitle!, style: TextStyle(fontSize: 11,
                color: selected ? c.primary.withValues(alpha: 0.75) : c.textMuted)),
          ],
        ]),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: value ? c.primary.withValues(alpha: 0.10) : c.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: value ? c.primary.withValues(alpha: 0.55) : c.border),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (value ? c.primary : c.textMuted).withValues(alpha: 0.15),
            ),
            child: Icon(icon, size: 19, color: value ? c.primary : c.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14,
              color: c.textPrimary, fontWeight: FontWeight.w500))),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: c.bg,
            activeTrackColor: c.primary,
          ),
        ]),
      ),
    );
  }
}

// ── Carte suggestion (liste horizontale « Suggéré pour toi ») ────────────────

class _SuggestedCard extends StatelessWidget {
  final ReptileSpecies species;
  const _SuggestedCard({required this.species});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(fadeRoute(SpeciesDetailScreen(species: species))),
      child: Container(
        width: 150,
        decoration: glassCard(radius: 18),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: 92, width: double.infinity, child: SpeciesVisual(species: species)),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(species.commonName, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary)),
              const SizedBox(height: 2),
              Text(species.scientificName, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: c.textMuted)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: speciesLevelColor(species).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(speciesLevelLabel(species),
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                        color: speciesLevelColor(species))),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Carrousel experts (au-dessus de la recherche Reptiles) ───────────────────

class _ExpertCarousel extends StatefulWidget {
  const _ExpertCarousel();

  @override
  State<_ExpertCarousel> createState() => _ExpertCarouselState();
}

class _ExpertCarouselState extends State<_ExpertCarousel> {
  final _pageCtrl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return Column(children: [
      SizedBox(
        height: 92,
        child: PageView.builder(
          controller: _pageCtrl,
          onPageChanged: (i) => setState(() => _page = i),
          itemCount: TerraExpert.all.length,
          itemBuilder: (_, i) => _ExpertCard(expert: TerraExpert.all[i]),
        ),
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < TerraExpert.all.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == _page ? 7 : 6,
            height: i == _page ? 7 : 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == _page
                  ? c.primary
                  : c.textMuted.withValues(alpha: 0.35),
            ),
          ),
      ]),
    ]);
  }
}

class _ExpertCard extends StatelessWidget {
  final TerraExpert expert;
  const _ExpertCard({required this.expert});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    final fallback = Container(
      width: 58, height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [c.primary, c.radialTop],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Icon(Icons.person, color: c.bg, size: 28),
    );
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          fadeRoute(ExpertProfileScreen(expert: expert))),
      child: Container(
        decoration: glassCard(radius: 20),
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          ClipOval(child: Image.asset(
            expert.imageAsset,
            width: 58, height: 58, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
          )),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.verified, size: 15, color: c.primary),
              const SizedBox(width: 5),
              Flexible(child: Text(expert.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary))),
            ]),
            const SizedBox(height: 4),
            Text(expert.cardDescription,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: c.textMuted, height: 1.45)),
          ])),
          Icon(Icons.chevron_right, size: 20, color: c.textMuted),
        ]),
      ),
    );
  }
}

// ── Écran d'un salon ─────────────────────────────────────────────────────────

class SalonScreen extends StatelessWidget {
  final PostCategory salon;
  const SalonScreen({super.key, required this.salon});

  void _newPost(BuildContext context) {
    final c = ThemeService.instance.colors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _NewPostSheet(messenger: ScaffoldMessenger.of(context), lockedSalon: salon.key),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return Scaffold(
      backgroundColor: c.bg,
      floatingActionButton: GestureDetector(
        onTap: () => _newPost(context),
        child: Container(
          width: 58, height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [c.primary, Color.lerp(c.primary, Colors.black, 0.18)!],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: c.primary.withValues(alpha: 0.40),
                  blurRadius: 22, spreadRadius: 1, offset: const Offset(0, 7)),
            ],
          ),
          child: Icon(Icons.add, color: c.bg, size: 28),
        ),
      ),
      body: SafeArea(child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(Icons.arrow_back, color: c.textSecondary, size: 22),
            ),
            const SizedBox(width: 14),
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(salon.icon, size: 21, color: c.primary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(salon.label, style: AppTextStyles.serif28),
              Text(salon.description, style: TextStyle(fontSize: 12.5, color: c.textMuted)),
            ])),
          ]),
        ),
        const SizedBox(height: 12),

        Expanded(child: StreamBuilder<List<CommunityPost>>(
          stream: CommunityService.postsStream(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: c.primary));
            }
            final posts = (snap.data ?? [])
                .where((p) => p.scenario == null && p.category == salon.key)
                .toList();
            if (posts.isEmpty) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(salon.icon, size: 48, color: c.textMuted.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('Rien dans ce salon pour l\'instant',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.textPrimary)),
                  const SizedBox(height: 8),
                  Text('Sois le premier à lancer la discussion ici.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: c.textMuted)),
                ]),
              ));
            }
            return ListView.builder(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 90 + MediaQuery.of(context).padding.bottom),
              itemCount: posts.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _PostCard(post: posts[i]),
              ),
            );
          },
        )),
      ])),
    );
  }
}

// ── Nouveau post ─────────────────────────────────────────────────────────────

class _NewPostSheet extends StatefulWidget {
  final ScaffoldMessengerState messenger;
  final TerraScenario? scenario;
  final String? lockedSalon; // salon imposé (post depuis un salon)
  const _NewPostSheet({required this.messenger, this.scenario, this.lockedSalon});
  @override
  State<_NewPostSheet> createState() => _NewPostSheetState();
}

class _NewPostSheetState extends State<_NewPostSheet> {
  final _ctrl = TextEditingController();
  XFile? _pickedFile;
  Uint8List? _imageBytes;
  bool _publishing = false;
  String? _error;
  late String _category = widget.lockedSalon ?? PostCategory.question.key;

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() { _pickedFile = picked; _imageBytes = bytes; });
    }
  }

  Future<void> _publish() async {
    if (_ctrl.text.trim().isEmpty && _pickedFile == null && widget.scenario == null) return;
    setState(() { _publishing = true; _error = null; });
    try {
      await CommunityService.createPost(_ctrl.text.trim(),
          pickedFile: _pickedFile, scenario: widget.scenario,
          category: widget.scenario != null ? 'scenario' : _category);
      final messenger = widget.messenger;
      Navigator.pop(context);
      showTerraToast(messenger, 'Post publié !');
    } catch (e) {
      if (mounted) setState(() { _publishing = false; _error = 'Erreur : $e'; });
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      // Clavier ouvert : petit espace au-dessus du clavier.
      // Clavier fermé : +96 pour passer au-dessus de la navbar flottante.
      padding: EdgeInsets.only(bottom: kb + (kb > 0 ? 12 : 96)),
      child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [

        // Handle + header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x14507850))),
          ),
          child: Row(children: [
            Expanded(
              child: Text('Nouveau post',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.textPrimary)),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: ThemeService.instance.colors.bg, shape: BoxShape.circle,
                  border: Border.all(color: ThemeService.instance.colors.border),
                ),
                child: Icon(Icons.close, size: 16, color: ThemeService.instance.colors.textMuted),
              ),
            ),
            const SizedBox(width: 12),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Avatar + champ texte
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _UserAvatar(size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _ctrl, maxLines: 6, minLines: 3, autofocus: true,
                  style: TextStyle(color: ThemeService.instance.colors.textPrimary, fontSize: 15, height: 1.6),
                  decoration: InputDecoration(
                    hintText: widget.scenario != null
                        ? 'Décris ton scénario, donne des conseils…'
                        : 'Partage ton setup, une astuce, une photo…',
                    hintStyle: TextStyle(color: ThemeService.instance.colors.textMuted, fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ]),

            // Sélecteur de salon (post général uniquement)
            if (widget.scenario == null && widget.lockedSalon == null) ...[
              const SizedBox(height: 16),
              Text('SALON', style: AppTextStyles.eyebrow),
              const SizedBox(height: 8),
              SizedBox(height: 34, child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final cat in PostCategory.salons) ...[
                    _PostCatChip(
                      category: cat,
                      selected: _category == cat.key,
                      onTap: () => setState(() => _category = cat.key),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              )),
            ],

            // Carte scénario joint
            if (widget.scenario != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ThemeService.instance.colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ThemeService.instance.colors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: ThemeService.instance.colors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.scenario!.icon, size: 20, color: ThemeService.instance.colors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.auto_awesome, size: 12, color: ThemeService.instance.colors.primary),
                      const SizedBox(width: 4),
                      Text('SCÉNARIO PARTAGÉ',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                              letterSpacing: 0.5, color: ThemeService.instance.colors.primary)),
                    ]),
                    const SizedBox(height: 4),
                    Text(widget.scenario!.name,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.textPrimary)),
                    Text(widget.scenario!.description,
                        style: TextStyle(fontSize: 12, color: ThemeService.instance.colors.textMuted)),
                  ])),
                ]),
              ),
            ],

            // Aperçu image
            if (_imageBytes != null) ...[
              const SizedBox(height: 14),
              Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.memory(_imageBytes!, width: double.infinity, height: 200, fit: BoxFit.cover),
                ),
                Positioned(top: 10, right: 10, child: GestureDetector(
                  onTap: () => setState(() { _imageBytes = null; _pickedFile = null; }),
                  child: Container(
                    width: 30, height: 30,
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                )),
              ]),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
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

            const SizedBox(height: 20),

            // Barre bas : icônes + publier
            Row(children: [
              _IconAction(icon: Icons.photo_library_outlined,
                  onTap: () => _pickImage(ImageSource.gallery)),
              const SizedBox(width: 8),
              _IconAction(icon: Icons.camera_alt_outlined,
                  onTap: () => _pickImage(ImageSource.camera)),
              const Spacer(),
              GestureDetector(
                onTap: _publishing ? null : _publish,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: ThemeService.instance.colors.primary,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [BoxShadow(color: ThemeService.instance.colors.primary.withValues(alpha: 0.35),
                        blurRadius: 14, offset: const Offset(0, 4))],
                  ),
                  child: _publishing
                      ? SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: ThemeService.instance.colors.bg))
                      : Text('Publier',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.bg)),
                ),
              ),
            ]),
          ]),
        ),
      ])),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final double size;
  const _UserAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email ?? '?';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final fallback = Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [ThemeService.instance.colors.primary, ThemeService.instance.colors.radialTop],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Text(initial,
          style: TextStyle(fontSize: size * 0.38, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.bg))),
    );
    return StreamBuilder<String?>(
      stream: ProfileService.avatarStream(),
      builder: (ctx, snap) {
        final photoURL = snap.data;
        if (photoURL == null) return fallback;
        return ClipOval(
          child: Image.network(photoURL, width: size, height: size, fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => fallback),
        );
      },
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: ThemeService.instance.colors.bg,
        shape: BoxShape.circle,
        border: Border.all(color: ThemeService.instance.colors.border),
      ),
      child: Icon(icon, size: 18, color: ThemeService.instance.colors.textSecondary),
    ),
  );
}

// ── Avatar d'un auteur (photo dénormalisée, sinon initiale) ──────────────────

class _AuthorAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double size;
  const _AuthorAvatar({required this.photoUrl, required this.name, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    final initial = Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [c.primary, c.radialTop],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w600, color: c.bg),
      )),
    );
    if (photoUrl == null || photoUrl!.isEmpty) return initial;
    return ClipOval(child: Image.network(
      photoUrl!, width: size, height: size, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => initial,
    ));
  }
}

// ── Catégories de posts ──────────────────────────────────────────────────────

/// Chip de sélection de catégorie (dans la feuille de nouveau post).
class _PostCatChip extends StatelessWidget {
  final PostCategory category;
  final bool selected;
  final VoidCallback onTap;
  const _PostCatChip({required this.category, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c.primary.withValues(alpha: 0.16) : c.bg,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: selected ? c.primary : c.border, width: selected ? 1.4 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(category.icon, size: 15, color: selected ? c.primary : c.textMuted),
          const SizedBox(width: 7),
          Text(category.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: selected ? c.primary : c.textSecondary)),
        ]),
      ),
    );
  }
}

/// Carte d'un salon dans la liste du fil « Général ».
class _SalonCard extends StatelessWidget {
  final PostCategory salon;
  final int count;
  final VoidCallback onTap;
  const _SalonCard({required this.salon, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: glassCard(radius: 20),
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(salon.icon, size: 24, color: c.primary),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(salon.label,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary)),
            const SizedBox(height: 2),
            Text(salon.description,
                style: TextStyle(fontSize: 12.5, color: c.textMuted)),
          ])),
          Text(count == 0 ? '—' : '$count',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textMuted)),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, size: 20, color: c.textMuted),
        ]),
      ),
    );
  }
}

// ── Post ─────────────────────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  final CommunityPost post;
  const _PostCard({required this.post});
  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _showComments = false;

  void _showOptions(BuildContext context) {
    final isOwn = widget.post.uid == FirebaseAuth.instance.currentUser?.uid;
    final c = ThemeService.instance.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Carte d'options
            Container(
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.border),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(height: 10),
                Container(width: 36, height: 4, decoration: BoxDecoration(
                    color: ThemeService.instance.colors.textHint, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 6),
                if (isOwn) ...[
                  _OptionTile(
                    icon: Icons.edit_outlined, label: 'Modifier le post',
                    subtitle: 'Changer le texte ou la photo',
                    onTap: () { Navigator.pop(context); _showEdit(context); },
                  ),
                  Divider(height: 1, color: c.border, indent: 64, endIndent: 16),
                  _OptionTile(
                    icon: Icons.delete_outline, label: 'Supprimer',
                    subtitle: 'Retirer définitivement ce post',
                    color: AppColors.red,
                    onTap: () { Navigator.pop(context); _confirmDelete(context); },
                  ),
                ] else
                  _OptionTile(
                    icon: Icons.flag_outlined, label: 'Signaler',
                    subtitle: 'Signaler un contenu inapproprié',
                    onTap: () { Navigator.pop(context); _showReport(context); },
                  ),
                const SizedBox(height: 6),
              ]),
            ),
            const SizedBox(height: 8),
            // Bouton Annuler
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.border),
                ),
                child: Text('Annuler', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.textPrimary)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showReport(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportSheet(
        onSubmit: (reason, details) async {
          try {
            await CommunityService.reportPost(widget.post.id, reason, details: details);
            showTerraToast(messenger, 'Merci, ton signalement a été envoyé.');
          } catch (_) {
            showTerraToast(messenger, 'Impossible d\'envoyer le signalement.', error: true);
          }
        },
      ),
    );
  }

  void _showEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeService.instance.colors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _EditPostSheet(post: widget.post),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showTerraConfirmDialog(
      context,
      icon: Icons.delete_outline,
      title: 'Supprimer le post',
      message: 'Cette action est irréversible. Ton post sera définitivement retiré.',
      confirmLabel: 'Supprimer',
      destructive: true,
    );
    if (ok == true) await CommunityService.deletePost(widget.post.id);
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final post = widget.post;
    final liked = post.likedBy.contains(currentUid);

    return Container(
      decoration: glassCard(radius: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
          child: Row(children: [
            currentUid == post.uid
                ? _UserAvatar(size: 40)
                : _AuthorAvatar(photoUrl: post.authorPhotoUrl, name: post.username, size: 40),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(post.username, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ThemeService.instance.colors.textPrimary)),
              Text(post.timeAgo, style: TextStyle(fontSize: 12, color: ThemeService.instance.colors.textMuted)),
            ])),
            GestureDetector(
              onTap: () => _showOptions(context),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.more_horiz, color: ThemeService.instance.colors.textMuted, size: 20),
              ),
            ),
          ]),
        ),

        // Caption
        if (post.caption.isNotEmpty) Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, post.imageUrl != null ? 10 : 14),
          child: Text(post.caption, style: TextStyle(fontSize: 14, color: ThemeService.instance.colors.textPrimary, height: 1.6)),
        ),

        // Image (tap → plein écran)
        if (post.imageUrl != null) GestureDetector(
          onTap: () => openFullscreenImage(context, post.imageUrl!),
          child: ClipRRect(
            borderRadius: post.caption.isEmpty
                ? const BorderRadius.vertical(top: Radius.circular(24))
                : BorderRadius.zero,
            child: Image.network(
              post.imageUrl!,
              width: double.infinity, height: 220, fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null ? child
                  : Container(height: 220, color: ThemeService.instance.colors.card,
                      child: Center(child: CircularProgressIndicator(color: ThemeService.instance.colors.primary, strokeWidth: 2))),
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),

        // Scénario joint
        if (post.scenario != null) Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: _SharedScenarioCard(scenario: post.scenario!),
        ),

        // Actions
        Container(
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x18507850)))),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(children: [
            GestureDetector(
              onTap: () => CommunityService.toggleLike(post.id, post.likedBy),
              child: Row(children: [
                Icon(liked ? Icons.favorite : Icons.favorite_border,
                    size: 20, color: liked ? AppColors.red : ThemeService.instance.colors.textSecondary),
                const SizedBox(width: 5),
                Text('${post.likes}', style: TextStyle(fontSize: 13, color: ThemeService.instance.colors.textSecondary)),
              ]),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () => setState(() => _showComments = !_showComments),
              child: Row(children: [
                Icon(Icons.chat_bubble_outline, size: 18,
                    color: _showComments ? ThemeService.instance.colors.primary : ThemeService.instance.colors.textSecondary),
                const SizedBox(width: 5),
                Text('${post.commentCount}', style: TextStyle(fontSize: 13,
                    color: _showComments ? ThemeService.instance.colors.primary : ThemeService.instance.colors.textSecondary)),
              ]),
            ),
          ]),
        ),

        // Comments section
        if (_showComments) _CommentsSection(postId: post.id),
      ]),
    );
  }
}

// ── Carte scénario joint à un post (avec import) ──────────────────────────────

class _SharedScenarioCard extends StatefulWidget {
  final SharedScenario scenario;
  const _SharedScenarioCard({required this.scenario});
  @override
  State<_SharedScenarioCard> createState() => _SharedScenarioCardState();
}

class _SharedScenarioCardState extends State<_SharedScenarioCard> {
  bool _importing = false;
  bool _imported = false;

  @override
  void initState() {
    super.initState();
    DeviceService.instance.addListener(_onDevice);
  }

  @override
  void dispose() {
    DeviceService.instance.removeListener(_onDevice);
    super.dispose();
  }

  void _onDevice() { if (mounted) setState(() {}); }

  void _goPair() => Navigator.of(context).push(fadeRoute(const PairingScreen()));

  Future<void> _import() async {
    if (!DeviceService.instance.hasDevice) return; // besoin d'un terrarium
    setState(() => _importing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await CommunityService.importSharedScenario(widget.scenario);
      if (mounted) setState(() { _importing = false; _imported = true; });
      showTerraToast(messenger, 'Scénario "${widget.scenario.name}" importé !');
    } catch (_) {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    final s = widget.scenario;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.primary.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(s.icon, size: 20, color: c.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.auto_awesome, size: 11, color: c.primary),
              const SizedBox(width: 4),
              Text('SCÉNARIO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 0.5, color: c.primary)),
            ]),
            const SizedBox(height: 2),
            Text(s.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.textPrimary)),
            Text(s.description, style: TextStyle(fontSize: 12, color: ThemeService.instance.colors.textMuted)),
          ])),
        ]),
        const SizedBox(height: 12),
        Builder(builder: (context) {
          final hasDevice = DeviceService.instance.hasDevice;
          // Outline si déjà importé OU si aucun appareil (état "verrouillé").
          final outlined = _imported || !hasDevice;
          return GestureDetector(
            onTap: _imported
                ? null
                : (!hasDevice ? _goPair : (_importing ? null : _import)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: outlined ? Colors.transparent : c.primary,
                borderRadius: BorderRadius.circular(50),
                border: outlined ? Border.all(color: c.primary.withValues(alpha: 0.4)) : null,
              ),
              child: _importing
                  ? Center(child: SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: c.bg)))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(
                        _imported ? Icons.check : (!hasDevice ? Icons.link_off : Icons.download_outlined),
                        size: 16, color: outlined ? c.primary : c.bg),
                      const SizedBox(width: 6),
                      Flexible(child: Text(
                        _imported
                            ? 'Importé'
                            : (!hasDevice ? 'Connecte ton Terra pour importer' : 'Importer ce scénario'),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: outlined ? c.primary : c.bg))),
                    ]),
            ),
          );
        }),
      ]),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? color;
  final VoidCallback onTap;
  const _OptionTile({required this.icon, required this.label, required this.onTap,
      this.subtitle, this.color});

  @override
  Widget build(BuildContext context) {
    final tint = color ?? ThemeService.instance.colors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: tint),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: tint)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: TextStyle(fontSize: 12, color: ThemeService.instance.colors.textMuted)),
            ],
          ])),
        ]),
      ),
    );
  }
}

// ── Signalement d'un post ─────────────────────────────────────────────────────

class _ReportSheet extends StatefulWidget {
  final Future<void> Function(String reason, String? details) onSubmit;
  const _ReportSheet({required this.onSubmit});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  static const _reasons = [
    'Contenu inapproprié',
    'Spam ou publicité',
    'Informations dangereuses',
    'Harcèlement ou haine',
    'Autre',
  ];

  String? _selected;
  final _detailsCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selected == null || _sending) return;
    setState(() => _sending = true);
    await widget.onSubmit(_selected!, _detailsCtrl.text);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
        child: Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.border),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 10),
            Container(width: 36, height: 4, decoration: BoxDecoration(
                color: c.textHint, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Icon(Icons.flag_outlined, size: 20, color: c.textPrimary),
                const SizedBox(width: 10),
                Text('Signaler ce post', style: TextStyle(fontSize: 17,
                    fontWeight: FontWeight.w600, color: c.textPrimary)),
              ]),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Align(alignment: Alignment.centerLeft,
                child: Text('Choisis un motif de signalement.',
                    style: TextStyle(fontSize: 13, color: c.textMuted)),
              ),
            ),
            for (final r in _reasons)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selected = r),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _selected == r ? c.primary : c.bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selected == r ? c.primary : c.border,
                      ),
                    ),
                    child: Text(r,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: _selected == r ? c.bg : c.textSecondary,
                        )),
                  ),
                ),
              ),
            if (_selected == 'Autre')
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: c.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.border),
                  ),
                  child: TextField(
                    controller: _detailsCtrl,
                    autofocus: true,
                    maxLines: 3,
                    minLines: 2,
                    style: TextStyle(color: c.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Précise le motif…',
                      hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: _selected == null ? null : _submit,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: _selected == null ? c.card : AppColors.red,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: _selected == null ? c.border : AppColors.red),
                  ),
                  child: _sending
                      ? Center(child: SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                      : Text('Envoyer le signalement', textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                              color: _selected == null ? c.textMuted : Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Annuler', style: TextStyle(fontSize: 14, color: c.textMuted)),
              ),
            ),
            const SizedBox(height: 4),
          ]),
        ),
      ),
    );
  }
}

// ── Éditeur de post (texte + photo) ───────────────────────────────────────────

class _EditPostSheet extends StatefulWidget {
  final CommunityPost post;
  const _EditPostSheet({required this.post});
  @override
  State<_EditPostSheet> createState() => _EditPostSheetState();
}

class _EditPostSheetState extends State<_EditPostSheet> {
  late final TextEditingController _ctrl;
  XFile? _newImage;
  Uint8List? _newImageBytes;
  bool _removeImage = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.post.caption);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery, imageQuality: 75, maxWidth: 1280, maxHeight: 1280);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() { _newImage = picked; _newImageBytes = bytes; _removeImage = false; });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final nav = Navigator.of(context);
    try {
      await CommunityService.updatePost(
        widget.post.id,
        caption: _ctrl.text.trim(),
        newImage: _newImage,
        removeImage: _removeImage,
      );
      nav.pop();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    // Détermine l'image à afficher : nouvelle > existante (sauf si supprimée)
    final hasImage = !_removeImage && (_newImageBytes != null || widget.post.imageUrl != null);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(top: false, child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Modifier le post',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.textPrimary)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: c.bg, shape: BoxShape.circle, border: Border.all(color: c.border)),
                  child: Icon(Icons.close, size: 16, color: c.textMuted),
                ),
              ),
            ]),
            const SizedBox(height: 18),

            // Champ texte
            TextField(
              controller: _ctrl, maxLines: 5, minLines: 3, autofocus: true,
              style: TextStyle(color: ThemeService.instance.colors.textPrimary, fontSize: 15, height: 1.6),
              decoration: InputDecoration(
                hintText: 'Modifie ton texte…',
                hintStyle: TextStyle(color: ThemeService.instance.colors.textMuted),
                filled: true, fillColor: c.bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.primary)),
              ),
            ),
            const SizedBox(height: 16),

            // Photo
            if (hasImage) ...[
              Text('PHOTO', style: AppTextStyles.eyebrow),
              const SizedBox(height: 8),
              Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _newImageBytes != null
                      ? Image.memory(_newImageBytes!, width: double.infinity, height: 180, fit: BoxFit.cover)
                      : Image.network(widget.post.imageUrl!, width: double.infinity, height: 180, fit: BoxFit.cover),
                ),
                // Boutons changer / supprimer la photo
                Positioned(top: 8, right: 8, child: Row(children: [
                  _CircleBtn(icon: Icons.swap_horiz, onTap: _pickImage),
                  const SizedBox(width: 8),
                  _CircleBtn(icon: Icons.delete_outline, color: AppColors.red,
                      onTap: () => setState(() { _removeImage = true; _newImage = null; _newImageBytes = null; })),
                ])),
              ]),
            ] else
              // Pas de photo → bouton ajouter
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 18, color: c.primary),
                    const SizedBox(width: 8),
                    Text('Ajouter une photo',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.primary)),
                  ]),
                ),
              ),

            const SizedBox(height: 20),

            // Enregistrer
            GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(50)),
                child: _saving
                    ? Center(child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: c.bg)))
                    : Text('Enregistrer', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.bg)),
              ),
            ),
          ]),
        ),
      )),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34, height: 34,
      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
      child: Icon(icon, size: 17, color: color ?? Colors.white),
    ),
  );
}

// ── Section commentaires ──────────────────────────────────────────────────────

class _CommentsSection extends StatefulWidget {
  final String postId;
  const _CommentsSection({required this.postId});
  @override
  State<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<_CommentsSection> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _deleteComment(BuildContext context, PostComment comment) async {
    try {
      await CommunityService.deleteComment(widget.postId, comment.id);
    } catch (e) {
      if (mounted) {
        showTerraToast(context, 'Suppression impossible du commentaire.', error: true);
      }
    }
  }

  Future<void> _send() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    await CommunityService.addComment(widget.postId, _ctrl.text);
    _ctrl.clear();
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x18507850)))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      StreamBuilder<List<PostComment>>(
        stream: CommunityService.commentsStream(widget.postId),
        builder: (ctx, snap) {
          final comments = snap.data ?? [];
          if (comments.isEmpty) return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('Aucun commentaire. Sois le premier !',
                style: TextStyle(fontSize: 12, color: ThemeService.instance.colors.textMuted)),
          );
          final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
          return Column(children: comments.map((c) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              c.uid == currentUid
                  ? _UserAvatar(size: 28)
                  : _AuthorAvatar(photoUrl: c.authorPhotoUrl, name: c.username, size: 28),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(c.username, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.textPrimary)),
                  const SizedBox(width: 6),
                  Text(c.timeAgo, style: TextStyle(fontSize: 11, color: ThemeService.instance.colors.textHint)),
                  const Spacer(),
                  if (c.uid == currentUid)
                    GestureDetector(
                      onTap: () => _deleteComment(context, c),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(Icons.delete_outline, size: 15, color: ThemeService.instance.colors.textHint),
                      ),
                    ),
                ]),
                const SizedBox(height: 2),
                Text(c.text, style: TextStyle(fontSize: 13, color: ThemeService.instance.colors.textPrimary, height: 1.5)),
              ])),
            ]),
          )).toList());
        },
      ),
      // Champ écriture
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Row(children: [
          _UserAvatar(size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: TextStyle(color: ThemeService.instance.colors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ajoute un commentaire…',
                hintStyle: TextStyle(color: ThemeService.instance.colors.textMuted, fontSize: 13),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: ThemeService.instance.colors.bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sending ? null : _send,
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(shape: BoxShape.circle, color: ThemeService.instance.colors.primary),
              child: _sending
                  ? Padding(padding: const EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2, color: ThemeService.instance.colors.bg))
                  : Icon(Icons.send_rounded, size: 16, color: ThemeService.instance.colors.bg),
            ),
          ),
        ]),
      ),
    ]),
  );
}

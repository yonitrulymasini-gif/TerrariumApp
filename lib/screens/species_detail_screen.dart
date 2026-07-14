import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/species_service.dart';
import '../services/inaturalist_service.dart';
import '../services/admin_service.dart';
import '../services/favorites_service.dart';
import '../utils/fade_route.dart';
import 'species_edit_screen.dart';

Color difficultyColor(String difficulty) {
  switch (difficulty) {
    case 'Débutant':
      return const Color(0xFF4CAF7D);
    case 'Intermédiaire':
      return const Color(0xFFFB923C);
    default:
      return AppColors.red;
  }
}

// Les espèces pro affichent "Professionnel" (en orange) au lieu de leur difficulté.
String speciesLevelLabel(ReptileSpecies s) => s.professional ? 'Professionnel' : s.difficulty;
Color speciesLevelColor(ReptileSpecies s) =>
    s.professional ? const Color(0xFFA98BE0) : difficultyColor(s.difficulty);

// ── Carte espèce (grille) ────────────────────────────────────────────────────

class SpeciesCard extends StatelessWidget {
  final ReptileSpecies species;
  const SpeciesCard({super.key, required this.species});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(fadeRoute(SpeciesDetailScreen(species: species))),
      child: Container(
        decoration: glassCard(radius: 20),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Visuel + bouton favori
          Stack(children: [
            AspectRatio(
              aspectRatio: 1.5,
              child: SpeciesVisual(species: species),
            ),
            Positioned(top: 8, right: 8, child: ListenableBuilder(
              listenable: FavoritesService.instance,
              builder: (_, __) {
                final fav = FavoritesService.instance.isFavorite(species.id);
                return GestureDetector(
                  onTap: () => FavoritesService.instance.toggle(species.id),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                    child: Icon(fav ? Icons.favorite : Icons.favorite_border,
                        color: fav ? AppColors.red : Colors.white, size: 17),
                  ),
                );
              },
            )),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(species.commonName, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary))),
                if (species.professional) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.workspace_premium_rounded, size: 16, color: Color(0xFFF4C430)),
                ],
              ]),
              const SizedBox(height: 2),
              Text(species.scientificName, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: c.textMuted)),
              const SizedBox(height: 8),
              _DifficultyChip(label: speciesLevelLabel(species), color: speciesLevelColor(species)),
              if (species.venomous) ...[
                const SizedBox(height: 6),
                const _VenomousBadge(),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class SpeciesVisual extends StatelessWidget {
  final ReptileSpecies species;
  const SpeciesVisual({super.key, required this.species});

  @override
  Widget build(BuildContext context) {
    final url = species.imageUrl;
    // Pas d'image locale → photo iNaturalist automatique.
    if (url == null || url.isEmpty) {
      return _INatFallback(species: species);
    }
    // URL en ligne (http…) ou fichier local (assets/…) — les deux marchent,
    // et en cas d'échec on retombe aussi sur iNaturalist.
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover, width: double.infinity,
        fadeInDuration: const Duration(milliseconds: 180),
        fadeOutDuration: const Duration(milliseconds: 180),
        placeholder: (_, __) => const _PhotoLoading(),
        errorWidget: (_, __, ___) => _INatFallback(species: species),
      );
    }
    return Image.asset(
      url,
      fit: BoxFit.cover, width: double.infinity,
      errorBuilder: (_, __, ___) => _INatFallback(species: species),
    );
  }
}

/// Photo iNaturalist chargée par nom scientifique (cache : 1 requête/espèce).
/// Le crédit CC est consultable via la bulle ⓘ de la galerie (fiche détail).
class _INatFallback extends StatefulWidget {
  final ReptileSpecies species;
  const _INatFallback({required this.species});

  @override
  State<_INatFallback> createState() => _INatFallbackState();
}

class _INatFallbackState extends State<_INatFallback> {
  // Future mémorisé : sinon un nouveau part à chaque rebuild (recherche) et
  // le FutureBuilder repart en « chargement » → l'image clignote.
  late Future<INatPhoto?> _future = INaturalistService.photoFor(widget.species.scientificName);

  @override
  void didUpdateWidget(_INatFallback old) {
    super.didUpdateWidget(old);
    if (old.species.scientificName != widget.species.scientificName) {
      _future = INaturalistService.photoFor(widget.species.scientificName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<INatPhoto?>(
      future: _future,
      builder: (context, snap) {
        // Recherche encore en cours → spinner, pas « pas de photo ».
        if (snap.connectionState != ConnectionState.done) return const _PhotoLoading();
        final photo = snap.data;
        if (photo == null) return const _NoPhotoPlaceholder();
        return CachedNetworkImage(
          // Vignette légère : les cartes n'ont pas besoin de la version medium.
          imageUrl: photo.smallUrl,
          fit: BoxFit.cover, width: double.infinity,
          fadeInDuration: const Duration(milliseconds: 180),
          fadeOutDuration: const Duration(milliseconds: 180),
          placeholder: (_, __) => const _PhotoLoading(),
          errorWidget: (_, __, ___) => const _NoPhotoPlaceholder(),
        );
      },
    );
  }
}

/// Pendant qu'une photo se télécharge : fond doux + petit spinner.
/// (Différent de « pas de photo », qui signifie qu'il n'en existe pas.)
class _PhotoLoading extends StatelessWidget {
  const _PhotoLoading();

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [c.radialTop.withValues(alpha: 0.4), c.card],
        ),
      ),
      child: Center(child: SizedBox(
        width: 22, height: 22,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: c.primary.withValues(alpha: 0.6)),
      )),
    );
  }
}

class _NoPhotoPlaceholder extends StatelessWidget {
  const _NoPhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [c.radialTop.withValues(alpha: 0.4), c.card],
        ),
      ),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.image_outlined, size: 26, color: c.textMuted.withValues(alpha: 0.5)),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('Pas de photo pour l\'instant', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: c.textMuted.withValues(alpha: 0.75))),
        ),
      ])),
    );
  }
}

class _ProBadge extends StatelessWidget {
  const _ProBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4C430),
        borderRadius: BorderRadius.circular(50),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.workspace_premium_outlined, size: 11, color: Colors.black87),
        SizedBox(width: 4),
        Text('Certificat', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.black87)),
      ]),
    );
  }
}

class _VenomousBadge extends StatelessWidget {
  const _VenomousBadge();
  @override
  Widget build(BuildContext context) {
    const color = AppColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(50),
      ),
      child: const Text('Venimeux',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final String label;
  final Color color;
  const _DifficultyChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── Galerie du header (photo locale + galerie iNaturalist, swipeable) ────────

class _SpeciesGallery extends StatefulWidget {
  final ReptileSpecies species;
  const _SpeciesGallery({required this.species});

  @override
  State<_SpeciesGallery> createState() => _SpeciesGalleryState();
}

class _SpeciesGalleryState extends State<_SpeciesGallery> {
  int _page = 0;
  bool _localOk = false; // la photo locale existe-t-elle vraiment ?

  @override
  void initState() {
    super.initState();
    _checkLocal();
  }

  /// Vérifie que l'asset local existe. Sinon on ne crée pas sa diapositive :
  /// son repli afficherait la 1ʳᵉ photo iNaturalist → doublon dans la galerie.
  Future<void> _checkLocal() async {
    final url = widget.species.imageUrl;
    if (url == null || url.isEmpty) return;
    if (url.startsWith('http')) {
      if (mounted) setState(() => _localOk = true);
      return;
    }
    try {
      await rootBundle.load(url);
      if (mounted) setState(() => _localOk = true);
    } catch (_) {
      // Asset manquant → diapositive locale ignorée.
    }
  }

  Widget _localSlide(String url) {
    // Pas de repli iNaturalist ici (déjà présent dans la galerie).
    if (url.startsWith('http')) {
      return CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, width: double.infinity,
          placeholder: (_, __) => const _PhotoLoading(),
          errorWidget: (_, __, ___) => const _NoPhotoPlaceholder());
    }
    return Image.asset(url, fit: BoxFit.cover, width: double.infinity,
        errorBuilder: (_, __, ___) => const _NoPhotoPlaceholder());
  }

  void _showCredit(String attribution) {
    final c = ThemeService.instance.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text('Crédit photo',
            style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('$attribution\nSource : iNaturalist',
            style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.6)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: TextStyle(color: c.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    final local = widget.species.imageUrl;

    return FutureBuilder<List<INatPhoto>>(
      future: INaturalistService.photosFor(widget.species.scientificName),
      builder: (context, snap) {
        final inat = snap.data ?? const <INatPhoto>[];
        final showLocal = _localOk && local != null && local.isNotEmpty;
        // Diapositives : la photo locale d'abord (si elle existe), puis la galerie.
        final slides = <Widget>[
          if (showLocal) _localSlide(local),
          for (final p in inat) _INatSlide(photo: p),
        ];
        // Crédit par diapositive (null pour la photo locale).
        final credits = <String?>[
          if (showLocal) null,
          for (final p in inat) p.attribution.isEmpty ? null : p.attribution,
        ];
        if (slides.isEmpty) {
          // Pas encore de local ni d'iNat (chargement ou introuvable).
          return _INatFallback(species: widget.species);
        }
        final page = _page.clamp(0, slides.length - 1);
        final credit = credits[page];

        return Stack(children: [
          Positioned.fill(child: slides.length == 1
              ? slides.first
              : PageView(
                  onPageChanged: (i) => setState(() => _page = i),
                  children: slides,
                )),
          // Pastilles de pagination
          if (slides.length > 1)
            Positioned(
              bottom: 10, left: 0, right: 0,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (int i = 0; i < slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == page ? 18 : 6, height: 6,
                    decoration: BoxDecoration(
                      color: i == page ? c.primary : Colors.white54,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ]),
            ),
          // Crédit photo (licence CC) : discret, affiché à la demande.
          if (credit != null)
            Positioned(
              bottom: 8, right: 8,
              child: GestureDetector(
                onTap: () => _showCredit(credit),
                child: Container(
                  width: 26, height: 26,
                  decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                  child: const Icon(Icons.info_outline, size: 15, color: Colors.white70),
                ),
              ),
            ),
        ]);
      },
    );
  }
}

class _INatSlide extends StatelessWidget {
  final INatPhoto photo;
  const _INatSlide({required this.photo});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: photo.url,
      fit: BoxFit.cover, width: double.infinity,
      fadeInDuration: const Duration(milliseconds: 180),
      fadeOutDuration: const Duration(milliseconds: 180),
      placeholder: (_, __) => const _PhotoLoading(),
      errorWidget: (_, __, ___) => const _NoPhotoPlaceholder(),
    );
  }
}

// ── Écran détail (fiche) ─────────────────────────────────────────────────────

class SpeciesDetailScreen extends StatefulWidget {
  final ReptileSpecies species;
  const SpeciesDetailScreen({super.key, required this.species});

  @override
  State<SpeciesDetailScreen> createState() => _SpeciesDetailScreenState();
}

class _SpeciesDetailScreenState extends State<SpeciesDetailScreen> {
  // La fiche affichée : remplacée par la version éditée après modification.
  late ReptileSpecies species = widget.species;

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<ReptileSpecies>(
        fadeRoute(SpeciesEditScreen(species: species)));
    if (updated != null && mounted) setState(() => species = updated);
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return Scaffold(
      backgroundColor: c.bg,
      body: CustomScrollView(slivers: [
        // Header visuel + bouton retour
        SliverToBoxAdapter(
          child: Stack(children: [
            SizedBox(height: 240, width: double.infinity,
                child: _SpeciesGallery(species: species)),
            SafeArea(child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                  ),
                ),
                Row(children: [
                  // Favori
                  ListenableBuilder(
                    listenable: FavoritesService.instance,
                    builder: (_, __) {
                      final fav = FavoritesService.instance.isFavorite(species.id);
                      return GestureDetector(
                        onTap: () => FavoritesService.instance.toggle(species.id),
                        child: Container(
                          width: 40, height: 40,
                          decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                          child: Icon(fav ? Icons.favorite : Icons.favorite_border,
                              color: fav ? AppColors.red : Colors.white, size: 20),
                        ),
                      );
                    },
                  ),
                  // Édition (réservée aux admins)
                  if (AdminService.instance.isAdmin) ...[
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _edit,
                      child: Container(
                        width: 40, height: 40,
                        decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                        child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ]),
              ]),
            )),
          ]),
        ),

        SliverToBoxAdapter(child: Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 40 + MediaQuery.of(context).padding.bottom),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Titre
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text(species.commonName,
                  style: GoogleFonts.fraunces(fontSize: 26, fontWeight: FontWeight.w600, color: c.textPrimary))),
              if (species.professional) ...[
                const SizedBox(width: 8),
                Padding(padding: const EdgeInsets.only(top: 6), child: const _ProBadge()),
              ],
            ]),
            const SizedBox(height: 4),
            Text(species.scientificName,
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: c.textMuted)),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              if (species.category.isNotEmpty) _Tag(species.category),
              if (species.difficulty.isNotEmpty)
                _DifficultyChip(label: speciesLevelLabel(species), color: speciesLevelColor(species)),
              if (species.venomous) const _VenomousBadge(),
            ]),

            if (species.professional) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFC97E1A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFC97E1A).withValues(alpha: 0.4)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.workspace_premium_outlined, size: 20, color: Color(0xFFD98A2B)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Certificat de capacité requis',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary)),
                    const SizedBox(height: 4),
                    Text("Espèce réservée aux détenteurs certifiés (certificat de capacité + autorisation d'établissement).",
                        style: TextStyle(fontSize: 12.5, color: c.textSecondary, height: 1.4)),
                  ])),
                ]),
              ),
            ],

            if (species.venomous) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFB5179E).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFB5179E).withValues(alpha: 0.4)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFB5179E)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Espèce venimeuse',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary)),
                    const SizedBox(height: 4),
                    Text("Ne jamais manipuler à mains nues. Protocole d'urgence et sérum antivenimeux obligatoires.",
                        style: TextStyle(fontSize: 12.5, color: c.textSecondary, height: 1.4)),
                  ])),
                ]),
              ),
            ],

            const SizedBox(height: 22),
            _StatsGrid(species: species),

            if (species.maleTraits.isNotEmpty || species.femaleTraits.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('MÂLE / FEMELLE', style: AppTextStyles.eyebrow),
              const SizedBox(height: 12),
              _SexingSection(species: species),
            ],

            const SizedBox(height: 24),
            Text('À PROPOS', style: AppTextStyles.eyebrow),
            const SizedBox(height: 10),
            if (species.description.isNotEmpty)
              Text(species.description,
                  style: TextStyle(fontSize: 14, color: c.textSecondary, height: 1.7))
            else
              // Fiche ajoutée via l'app, en attente des infos d'élevage.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.primary.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  Icon(Icons.edit_note, size: 18, color: c.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                      'Fiche en cours de rédaction — les informations d\'élevage arrivent bientôt.',
                      style: TextStyle(fontSize: 13, color: c.textSecondary, height: 1.5))),
                ]),
              ),
          ]),
        )),
      ]),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);
  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.primary)),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final ReptileSpecies species;
  const _StatsGrid({required this.species});

  @override
  Widget build(BuildContext context) {
    // Seules les infos réellement renseignées s'affichent (les fiches en
    // attente de rédaction n'ont que des « — »).
    final items = <List<dynamic>>[
      [Icons.straighten, 'Taille adulte', species.adultSize],
      [Icons.hourglass_bottom_outlined, 'Espérance de vie', species.lifespan],
      [Icons.restaurant_outlined, 'Régime', species.diet],
      [Icons.thermostat_outlined, 'Température', species.tempRange],
      [Icons.water_drop_outlined, 'Humidité', species.humidityRange],
      [Icons.crop_square, 'Terrarium', species.terrarium],
      [Icons.public, 'Origine', species.origin],
      [Icons.pets_outlined, 'Caractère', species.temperament],
    ].where((it) {
      final v = (it[2] as String).trim();
      return v.isNotEmpty && v != '—';
    }).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('CARACTÉRISTIQUES', style: AppTextStyles.eyebrow),
      const SizedBox(height: 12),
      for (final it in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _StatTile(icon: it[0] as IconData, label: it[1] as String, value: it[2] as String),
        ),
    ]);
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return Container(
      decoration: glassCard(radius: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: c.primary),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: c.textMuted, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13.5, color: c.textPrimary, fontWeight: FontWeight.w500, height: 1.3)),
        ])),
      ]),
    );
  }
}

class _SexingSection extends StatelessWidget {
  final ReptileSpecies species;
  const _SexingSection({required this.species});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return Column(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _SexColumn(
          symbol: '♂', label: 'Mâle', color: const Color(0xFF5B9BD5), traits: species.maleTraits)),
        const SizedBox(width: 12),
        Expanded(child: _SexColumn(
          symbol: '♀', label: 'Femelle', color: const Color(0xFFE08AB0), traits: species.femaleTraits)),
      ]),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.primary.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Icon(Icons.info_outline, size: 16, color: c.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(species.sexingNote,
              style: TextStyle(fontSize: 12.5, color: c.textSecondary, height: 1.4))),
        ]),
      ),
    ]);
  }
}

class _SexColumn extends StatelessWidget {
  final String symbol;
  final String label;
  final Color color;
  final List<String> traits;
  const _SexColumn({required this.symbol, required this.label, required this.color, required this.traits});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return Container(
      decoration: glassCard(radius: 16),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: Center(child: Text(symbol, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary)),
        ]),
        const SizedBox(height: 10),
        for (final t in traits)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(t, style: TextStyle(fontSize: 12.5, color: c.textSecondary, height: 1.4))),
            ]),
          ),
      ]),
    );
  }
}

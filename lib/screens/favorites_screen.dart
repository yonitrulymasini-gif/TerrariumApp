import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/species_service.dart';
import '../services/favorites_service.dart';
import 'species_detail_screen.dart';

/// Liste des espèces mises en favori.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    FavoritesService.instance.addListener(_onChange);
    SpeciesService.instance.addListener(_onChange);
  }

  @override
  void dispose() {
    FavoritesService.instance.removeListener(_onChange);
    SpeciesService.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() { if (mounted) setState(() {}); }

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    final favs = SpeciesService.all
        .where((s) => FavoritesService.instance.isFavorite(s.id))
        .toList();

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
                Text('Mes favoris', style: AppTextStyles.serif28),
              ])),
              if (favs.isNotEmpty)
                Text('${favs.length}',
                    style: TextStyle(fontSize: 13, color: c.textMuted)),
            ]),
          ),
          const SizedBox(height: 16),

          Expanded(child: favs.isEmpty
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.favorite_border, size: 48, color: c.textMuted.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text('Aucun favori pour l\'instant',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.textPrimary)),
                    const SizedBox(height: 8),
                    Text('Appuie sur le ♥ d\'une fiche reptile\npour la retrouver ici.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: c.textMuted, height: 1.5)),
                  ]),
                ))
              : GridView.builder(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + MediaQuery.of(context).padding.bottom),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.72),
                  itemCount: favs.length,
                  itemBuilder: (_, i) => SpeciesCard(key: ValueKey(favs[i].id), species: favs[i]),
                )),
        ])),
      ]),
    );
  }
}

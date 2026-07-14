import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/species_service.dart';

class TerraExpert {
  final String name;
  final String imageAsset;
  final String cardDescription;
  final String bio;
  final List<String> specialties;
  final String experience;
  final String? statValue;
  final String? statLabel;

  const TerraExpert({
    required this.name,
    required this.imageAsset,
    required this.cardDescription,
    required this.bio,
    required this.specialties,
    required this.experience,
    this.statValue,
    this.statLabel,
  });

  static const theo = TerraExpert(
    name: 'Théo Masini',
    imageAsset: 'assets/species/expert.jpg',
    cardDescription:
        "Passionné de terrariophilie depuis 10 ans, il fournit les informations de chaque fiche.",
    experience: '10 ans',
    bio:
        "Passionné de terrariophilie depuis 10 ans, Théo a fait de sa passion son quotidien. "
        "Des geckos aux iguanes en passant par les serpents, il a construit son expérience au fil "
        "des années d'élevage et d'aménagement de terrariums.\n\n"
        "C'est lui qui rédige et vérifie les informations d'élevage de chaque fiche de "
        "l'encyclopédie Terra : températures, humidité, sexage, conseils… tout passe entre ses mains "
        "avant d'arriver dans l'app.",
    specialties: ['Veridis', 'Morelia spilota cheynei', 'Terrarium'],
  );

  static const clement = TerraExpert(
    name: 'Clément Pigot',
    imageAsset: 'assets/species/clement.jpg',
    cardDescription:
        "Éleveur de skinks crocodiles aux yeux rouges et de pogonas, il maîtrise les espèces les plus pointues.",
    experience: '10 ans',
    bio:
        "Terrariophile depuis 10 ans, Clément a développé une véritable expertise sur des espèces "
        "aussi exigeantes que fascinantes. Le skink crocodile aux yeux rouges, les pogonas et bien "
        "d'autres n'ont plus de secrets pour lui.\n\n"
        "De l'aménagement du terrarium aux paramètres d'élevage, il partage les bons réflexes acquis "
        "au fil des années pour garder ses reptiles en pleine santé.",
    specialties: ['Skink crocodile aux yeux rouges', 'Pogona', 'Terrarium'],
  );

  static const quentin = TerraExpert(
    name: 'Quentin Pohu',
    imageAsset: 'assets/species/quentin.jpg',
    cardDescription:
        "Passionné d'insectes et de terrariums bioactifs depuis 8 ans, il partage son expertise.",
    experience: '8 ans',
    bio:
        "Quentin s'est spécialisé dans l'univers des insectes et des terrariums bioactifs. "
        "Isopodes, phasmes, coléoptères ou fourmis : il connaît leurs besoins en élevage, "
        "substrat et microfaune associée.\n\n"
        "Il accompagne aussi la création de terrariums bioactifs — plantes, décomposeurs, "
        "cycle du sol — pour des écosystèmes durables et vivants.",
    specialties: ['Insectes', 'Terra bioactif', 'Isopodes', 'Phasmes'],
    statValue: 'Bioactif',
    statLabel: 'spécialité',
  );

  static const all = [theo, clement, quentin];
}

/// Fiche de présentation d'un expert Terra.
class ExpertProfileScreen extends StatelessWidget {
  final TerraExpert expert;
  const ExpertProfileScreen({super.key, required this.expert});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    final fichesValidees =
        SpeciesService.all.where((s) => s.description.isNotEmpty).length;

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(children: [
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
          gradient: RadialGradient(center: const Alignment(0, -0.9), radius: 1.1,
              colors: [c.radialTop.withValues(alpha: 0.5), Colors.transparent]),
        ))),
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
          gradient: RadialGradient(center: const Alignment(0, 1.3), radius: 1.1,
              colors: [c.radialBottom.withValues(alpha: 0.4), Colors.transparent]),
        ))),

        SafeArea(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text('Retour', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ),
            const SizedBox(height: 24),

            Center(child: Column(children: [
              Container(
                width: 116, height: 116,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.primary.withValues(alpha: 0.5), width: 2),
                  boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.25),
                      blurRadius: 30, spreadRadius: 2)],
                ),
                child: ClipOval(child: Image.asset(
                  expert.imageAsset,
                  width: 112, height: 112, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: c.card,
                    child: Icon(Icons.person, color: c.textMuted, size: 48),
                  ),
                )),
              ),
              const SizedBox(height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(expert.name,
                    style: GoogleFonts.fraunces(fontSize: 26, fontWeight: FontWeight.w600,
                        color: c.textPrimary)),
                const SizedBox(width: 8),
                Icon(Icons.verified, size: 20, color: c.primary),
              ]),
              const SizedBox(height: 6),
              Text('EXPERT TERRA', style: AppTextStyles.eyebrow),
            ])),
            const SizedBox(height: 28),

            IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: _StatCard(value: expert.experience, label: 'd\'expérience')),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                value: expert.statValue ?? '$fichesValidees',
                label: expert.statLabel ?? 'fiches validées',
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(value: '${SpeciesService.all.length}', label: 'espèces suivies')),
            ])),
            const SizedBox(height: 28),

            Text('QUI EST ${expert.name.split(' ').first.toUpperCase()} ?', style: AppTextStyles.eyebrow),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: glassCard(radius: 20),
              padding: const EdgeInsets.all(18),
              child: Text(expert.bio,
                  style: TextStyle(fontSize: 14, color: c.textSecondary, height: 1.7)),
            ),
            const SizedBox(height: 24),

            Text('SES SPÉCIALITÉS', style: AppTextStyles.eyebrow),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8,
                children: [for (final s in expert.specialties) _SpecialtyChip(label: s)]),
          ]),
        )),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return Container(
      decoration: glassCard(radius: 18),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        // Taille FIXE (pas de FittedBox) → les 3 valeurs sont identiques.
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
            style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.w700,
                color: c.primary, height: 1)),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: c.textMuted)),
      ]),
    );
  }
}

class _SpecialtyChip extends StatelessWidget {
  final String label;
  const _SpecialtyChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: c.primary.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: c.textSecondary)),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Encyclopédie des espèces : fiches intégrées (rédigées avec Théo) +
/// fiches ajoutées via l'app (Firestore), fusionnées de façon transparente.
class ReptileSpecies {
  final String id;
  final String commonName;
  final String scientificName;
  final String category; // Lézard, Serpent, Tortue…
  final String emoji;
  final String difficulty; // Débutant / Intermédiaire / Avancé
  final String adultSize;
  final String lifespan;
  final String diet;
  final String tempRange;
  final String humidityRange;
  final String terrarium;
  final String origin;
  final String temperament;
  final String description;
  final List<String> maleTraits;
  final List<String> femaleTraits;
  final String sexingNote;
  final String? imageUrl;
  final bool professional; // nécessite un certificat de capacité
  final bool venomous; // espèce venimeuse

  const ReptileSpecies({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.category,
    required this.emoji,
    required this.difficulty,
    required this.adultSize,
    required this.lifespan,
    required this.diet,
    required this.tempRange,
    required this.humidityRange,
    required this.terrarium,
    required this.origin,
    required this.temperament,
    required this.description,
    required this.maleTraits,
    required this.femaleTraits,
    required this.sexingNote,
    this.professional = false,
    this.venomous = false,
    this.imageUrl,
  });

  factory ReptileSpecies.fromMap(String id, Map<String, dynamic> m) => ReptileSpecies(
        id: id,
        commonName: m['commonName'] ?? id,
        scientificName: m['scientificName'] ?? '',
        category: m['category'] ?? 'Autre',
        emoji: m['emoji'] ?? '🦎',
        difficulty: m['difficulty'] ?? 'Débutant',
        adultSize: m['adultSize'] ?? '—',
        lifespan: m['lifespan'] ?? '—',
        diet: m['diet'] ?? '—',
        tempRange: m['tempRange'] ?? '—',
        humidityRange: m['humidityRange'] ?? '—',
        terrarium: m['terrarium'] ?? '—',
        origin: m['origin'] ?? '—',
        temperament: m['temperament'] ?? '—',
        description: m['description'] ?? '',
        maleTraits: List<String>.from(m['maleTraits'] ?? []),
        femaleTraits: List<String>.from(m['femaleTraits'] ?? []),
        sexingNote: m['sexingNote'] ?? '',
        professional: m['professional'] ?? false,
        venomous: m['venomous'] ?? false,
        imageUrl: m['imageUrl'],
      );

  Map<String, dynamic> toMap() => {
        'commonName': commonName,
        'scientificName': scientificName,
        'category': category,
        'emoji': emoji,
        'difficulty': difficulty,
        'adultSize': adultSize,
        'lifespan': lifespan,
        'diet': diet,
        'tempRange': tempRange,
        'humidityRange': humidityRange,
        'terrarium': terrarium,
        'origin': origin,
        'temperament': temperament,
        'description': description,
        'maleTraits': maleTraits,
        'femaleTraits': femaleTraits,
        'sexingNote': sexingNote,
        'professional': professional,
        'venomous': venomous,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
}

class SpeciesService extends ChangeNotifier {
  SpeciesService._();
  static final SpeciesService instance = SpeciesService._();

  static List<ReptileSpecies> _remote = [];
  static bool _listening = false;

  /// Fiches locales : détaillées + squelettes à compléter.
  static List<ReptileSpecies> get _localAll => [..._builtin, ..._stubs];

  /// Fiches intégrées + fiches Firestore. Une fiche modifiée dans l'app
  /// (Firestore) REMPLACE la version intégrée du même nom scientifique.
  static List<ReptileSpecies> get all {
    final overrides = {
      for (final r in _remote) r.scientificName.toLowerCase(): r,
    };
    final seen = <String>{};
    final list = <ReptileSpecies>[];
    for (final l in _localAll) {
      final key = l.scientificName.toLowerCase();
      list.add(overrides[key] ?? l);
      seen.add(key);
    }
    for (final r in _remote) {
      if (!seen.contains(r.scientificName.toLowerCase())) list.add(r);
    }
    return list;
  }

  /// À appeler une fois : écoute en temps réel les fiches Firestore.
  void init() {
    if (_listening) return;
    _listening = true;
    try {
      FirebaseFirestore.instance
          .collection('species')
          .snapshots()
          .listen((snap) {
        _remote = [
          for (final d in snap.docs) ReptileSpecies.fromMap(d.id, d.data()),
        ];
        notifyListeners();
      }, onError: (_) {});
    } catch (_) {
      // Hors-ligne / règles Firestore : on reste sur les fiches intégrées.
    }
  }

  /// Ajoute une fiche dans Firestore (visible chez tous, sans rebuild).
  static Future<void> addSpecies(ReptileSpecies s) async {
    await FirebaseFirestore.instance.collection('species').doc(s.id).set({
      ...s.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Crée ou met à jour une fiche (édition manuelle dans l'app).
  static Future<void> saveSpecies(ReptileSpecies s) async {
    await FirebaseFirestore.instance.collection('species').doc(s.id).set({
      ...s.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static const List<ReptileSpecies> _builtin = [
    ReptileSpecies(
      id: 'gecko-leopard',
      commonName: 'Gecko léopard',
      scientificName: 'Eublepharis macularius',
      category: 'Lézard',
      emoji: '🦎',
      difficulty: 'Débutant',
      adultSize: '20–25 cm',
      lifespan: '15–20 ans',
      diet: 'Insectivore',
      tempRange: 'Point chaud 30–32 °C · froid 24–26 °C',
      humidityRange: '30–40 %',
      terrarium: 'Désertique · 60×40 cm min.',
      origin: 'Asie centrale, Pakistan, Inde',
      temperament: 'Docile, nocturne, facile à manipuler',
      description:
          "Le gecko léopard est LE reptile idéal pour débuter : robuste, docile et peu exigeant. "
          "Terrestre et nocturne, il ne grimpe pas et n'a pas besoin d'UVB puissants. "
          "Il stocke ses réserves dans sa queue épaisse — signe d'un animal en bonne santé.",
      maleTraits: [
        'Pores pré-anaux en V bien visibles',
        'Deux renflements (hémipénis) à la base de la queue',
        'Tête un peu plus large',
      ],
      femaleTraits: [
        'Pores pré-anaux absents ou très discrets',
        'Base de la queue lisse, sans renflement',
        'Silhouette générale plus fine',
      ],
      sexingNote: 'Sexage fiable à partir de ~6 mois / 35 g.',
    ),
    ReptileSpecies(
      id: 'pogona',
      commonName: 'Dragon barbu (Pogona)',
      scientificName: 'Pogona vitticeps',
      category: 'Lézard',
      emoji: '🐉',
      difficulty: 'Débutant',
      adultSize: '40–55 cm',
      lifespan: '8–12 ans',
      diet: 'Omnivore (insectes + végétaux)',
      tempRange: 'Point chaud 38–42 °C · froid 26–28 °C',
      humidityRange: '30–40 %',
      terrarium: 'Désertique · 120×60 cm min.',
      origin: 'Australie (zones arides)',
      temperament: 'Diurne, curieux, très sociable',
      description:
          "Le Pogona est un lézard diurne au caractère attachant, qui reconnaît son propriétaire. "
          "Il a besoin d'un fort gradient de chaleur et d'UVB puissants pour synthétiser la vitamine D3. "
          "Jeune il est surtout insectivore, adulte il mange davantage de végétaux.",
      maleTraits: [
        'Tête plus massive, « barbe » qui noircit',
        'Deux renflements hémipéniens à la base de la queue',
        'Pores fémoraux marqués',
      ],
      femaleTraits: [
        'Tête plus fine, barbe moins expressive',
        'Un seul renflement central à la base de la queue',
        'Pores fémoraux discrets',
      ],
      sexingNote: 'Fiable vers 4–6 mois (transillumination de la queue).',
    ),
    ReptileSpecies(
      id: 'python-royal',
      commonName: 'Python royal',
      scientificName: 'Python regius',
      category: 'Serpent',
      emoji: '🐍',
      difficulty: 'Intermédiaire',
      adultSize: '1,2–1,5 m',
      lifespan: '20–30 ans',
      diet: 'Carnivore (rongeurs)',
      tempRange: 'Point chaud 31–33 °C · froid 26–28 °C',
      humidityRange: '55–65 %',
      terrarium: 'Tropical sec · 100×50 cm min.',
      origin: "Afrique de l'Ouest et centrale",
      temperament: 'Calme, timide, se met en boule',
      description:
          "Le python royal est le serpent le plus populaire au monde : docile et de taille raisonnable. "
          "Il peut faire des grèves de la faim sans danger pendant des semaines. "
          "Il apprécie des cachettes bien fermées des deux côtés du terrarium pour se sentir en sécurité.",
      maleTraits: [
        'Ergots (griffes) plus longs près du cloaque',
        'Queue plus fine qui s\'affine vite après le cloaque',
        'Corps généralement plus petit',
      ],
      femaleTraits: [
        'Ergots plus courts, voire absents',
        'Queue plus épaisse et plus longue',
        'Corps souvent plus grand et massif',
      ],
      sexingNote: 'Sexage fiable par sondage, à faire par un éleveur/vétérinaire.',
    ),
    ReptileSpecies(
      id: 'serpent-des-bles',
      commonName: 'Serpent des blés',
      scientificName: 'Pantherophis guttatus',
      category: 'Serpent',
      emoji: '🐍',
      difficulty: 'Débutant',
      adultSize: '1,2–1,5 m',
      lifespan: '15–20 ans',
      diet: 'Carnivore (rongeurs)',
      tempRange: 'Point chaud 28–30 °C · froid 23–25 °C',
      humidityRange: '40–50 %',
      terrarium: 'Tempéré · 100×50 cm min.',
      origin: "Sud-est des États-Unis",
      temperament: 'Actif, curieux, très manipulable',
      description:
          "Le serpent des blés est un excellent premier serpent : robuste, actif et disponible dans une "
          "infinité de couleurs (morphs). Bon évadé, il faut un terrarium bien fermé. "
          "Il tolère une large plage de conditions, ce qui pardonne les petites erreurs de débutant.",
      maleTraits: [
        'Queue longue qui s\'affine progressivement',
        'Base de la queue plus épaisse (hémipénis)',
        'Sondage : poche profonde',
      ],
      femaleTraits: [
        'Queue plus courte, se rétrécit vite',
        'Base de la queue plus fine',
        'Sondage : poche peu profonde',
      ],
      sexingNote: 'Sondage ou éversion à réaliser par une personne expérimentée.',
    ),
    ReptileSpecies(
      id: 'gecko-crete',
      commonName: 'Gecko à crête',
      scientificName: 'Correlophus ciliatus',
      category: 'Lézard',
      emoji: '🦎',
      difficulty: 'Débutant',
      adultSize: '18–22 cm',
      lifespan: '15–20 ans',
      diet: 'Frugivore/omnivore (CGD + insectes)',
      tempRange: 'Ambiante 22–26 °C (pas de point chaud fort)',
      humidityRange: '60–80 %',
      terrarium: 'Tropical arboricole · 45×45×60 cm',
      origin: 'Nouvelle-Calédonie',
      temperament: 'Arboricole, nocturne, sauteur',
      description:
          "Le gecko à crête vit dans les arbres et se nourrit surtout de purée du commerce (CGD), "
          "ce qui simplifie énormément l'entretien. Il n'a pas besoin de chauffage fort et peut se passer "
          "d'UVB si l'alimentation est complémentée. Il peut perdre sa queue, qui ne repousse pas.",
      maleTraits: [
        'Renflement hémipénien net à la base de la queue',
        'Pores pré-cloacaux visibles',
        'Apparaît vers 15–20 g',
      ],
      femaleTraits: [
        'Base de la queue lisse',
        'Pas de pores marqués',
        'Silhouette identique au mâle par ailleurs',
      ],
      sexingNote: 'Observable à la loupe dès ~15 g.',
    ),
    ReptileSpecies(
      id: 'tortue-horsfield',
      commonName: 'Tortue de Horsfield',
      scientificName: 'Testudo horsfieldii',
      category: 'Tortue',
      emoji: '🐢',
      difficulty: 'Intermédiaire',
      adultSize: '15–20 cm',
      lifespan: '40–60 ans',
      diet: 'Herbivore (plantes sauvages)',
      tempRange: 'Point chaud 32–35 °C · froid 22–25 °C',
      humidityRange: '40–50 %',
      terrarium: 'Table à tortue / enclos · le plus grand possible',
      origin: 'Asie centrale (steppes)',
      temperament: 'Diurne, fouisseuse, robuste',
      description:
          "La tortue de Horsfield (ou tortue russe) est une tortue terrestre qui hiberne. "
          "Elle a besoin de beaucoup d'espace, d'UVB et d'une alimentation riche en fibres et pauvre en fruits. "
          "C'est un engagement de plusieurs décennies — souvent plus long qu'on ne l'imagine.",
      maleTraits: [
        'Queue longue et épaisse',
        'Plastron (dessous) légèrement concave',
        'Cloaque situé plus loin du corps',
      ],
      femaleTraits: [
        'Queue courte et fine',
        'Plastron plat',
        'Cloaque proche de la carapace',
      ],
      sexingNote: 'Fiable une fois adulte (10–12 cm).',
    ),

    // ── Espèces professionnelles (certificat de capacité requis) ────────────
    ReptileSpecies(
      id: 'python-reticule',
      commonName: 'Python réticulé',
      scientificName: 'Malayopython reticulatus',
      category: 'Serpent',
      emoji: '🐍',
      difficulty: 'Avancé',
      adultSize: '4–7 m (jusqu\'à 9 m)',
      lifespan: '20–25 ans',
      diet: 'Carnivore (grosses proies)',
      tempRange: 'Point chaud 30–32 °C · froid 26–28 °C',
      humidityRange: '60–70 %',
      terrarium: 'Sur mesure · plusieurs m²',
      origin: 'Asie du Sud-Est',
      temperament: "Puissant, force considérable, imprévisible",
      description:
          "L'un des plus grands serpents du monde. Sa force de constriction le rend dangereux et il est "
          "réservé aux détenteurs expérimentés. En France, sa détention exige un CERTIFICAT DE CAPACITÉ "
          "au-delà d'une certaine taille, ainsi qu'une autorisation d'ouverture d'établissement. "
          "Manipulation à deux personnes minimum.",
      maleTraits: [
        'Ergots plus longs près du cloaque',
        'Queue plus fine, s\'affine vite',
        'Taille souvent inférieure à la femelle',
      ],
      femaleTraits: [
        'Ergots plus courts',
        'Queue plus épaisse',
        'Corps nettement plus grand et massif',
      ],
      sexingNote: 'Sexage par sondage, réservé à un professionnel.',
      professional: true,
    ),
    ReptileSpecies(
      id: 'vipere-gabon',
      commonName: 'Vipère du Gabon',
      scientificName: 'Bitis gabonica',
      category: 'Serpent',
      emoji: '🐍',
      difficulty: 'Avancé',
      adultSize: '1,2–1,8 m',
      lifespan: '15–20 ans',
      diet: 'Carnivore (rongeurs)',
      tempRange: 'Point chaud 28–30 °C · froid 22–24 °C',
      humidityRange: '60–75 %',
      terrarium: 'Sécurisé et verrouillé',
      origin: 'Afrique subsaharienne',
      temperament: 'Placide mais VENIMEUX (crochets les plus longs)',
      description:
          "Serpent VENIMEUX — espèce strictement réservée aux professionnels. En France, sa détention "
          "impose un CERTIFICAT DE CAPACITÉ, une autorisation d'établissement, un terrarium verrouillé et "
          "un protocole d'urgence (accès au sérum antivenimeux, vétérinaire référent). "
          "Ne jamais manipuler à mains nues.",
      maleTraits: [
        'Queue relativement plus longue',
        'Base de la queue plus épaisse',
        'Détermination par un vétérinaire',
      ],
      femaleTraits: [
        'Queue plus courte',
        'Corps plus large (surtout gravide)',
        'Détermination par un vétérinaire',
      ],
      sexingNote: 'Sexage réservé à un vétérinaire / structure agréée.',
      professional: true,
      venomous: true,
    ),
    ReptileSpecies(
      id: 'varan-malais',
      commonName: 'Varan malais',
      scientificName: 'Varanus salvator',
      category: 'Lézard',
      emoji: '🦎',
      difficulty: 'Avancé',
      adultSize: '1,5–2,5 m',
      lifespan: '15–20 ans',
      diet: 'Carnivore (proies + poissons)',
      tempRange: 'Point chaud 40–45 °C · froid 28–30 °C',
      humidityRange: '70–80 %',
      terrarium: 'Enclos sur mesure avec grand bassin',
      origin: 'Asie du Sud-Est',
      temperament: 'Semi-aquatique, puissant, griffes et morsure',
      description:
          "Grand varan semi-aquatique, intelligent mais puissant. Il a besoin d'un immense espace et d'un "
          "bassin. En France, sa détention exige un CERTIFICAT DE CAPACITÉ au-delà d'une certaine taille "
          "et une autorisation d'établissement. Réservé aux détenteurs expérimentés.",
      maleTraits: [
        'Tête plus large et massive',
        'Base de la queue renflée',
        'Taille généralement supérieure',
      ],
      femaleTraits: [
        'Tête plus fine',
        'Base de la queue lisse',
        'Silhouette plus élancée',
      ],
      sexingNote: 'Sexage fiable par un vétérinaire (radio / endoscopie).',
      professional: true,
    ),
  ];

  // ── Fiches "squelette" : nom + catégorie + niveau, à compléter avec Théo ──
  // Les photos arrivent automatiquement d'iNaturalist (nom scientifique).
  // (id, nom commun, nom scientifique, catégorie, niveau, certificat requis)
  // (id, nom commun, nom scientifique, catégorie, niveau, certificat requis, venimeux)
  static const _stubData = <(String, String, String, String, String, bool, bool)>[
    // Lézards
    ('gecko-tokay', 'Gecko tokay', 'Gekko gecko', 'Lézard', 'Intermédiaire', false, false),
    ('gecko-gargouille', 'Gecko gargouille', 'Rhacodactylus auriculatus', 'Lézard', 'Débutant', false, false),
    ('gecko-leachianus', 'Gecko géant de Nouvelle-Calédonie', 'Rhacodactylus leachianus', 'Lézard', 'Intermédiaire', false, false),
    ('gecko-chahoua', 'Gecko chahoua', 'Mniarogekko chahoua', 'Lézard', 'Intermédiaire', false, false),
    ('phelsuma-grandis', 'Gecko diurne géant de Madagascar', 'Phelsuma grandis', 'Lézard', 'Intermédiaire', false, false),
    ('phelsuma-laticauda', 'Gecko poussière d\'or', 'Phelsuma laticauda', 'Lézard', 'Intermédiaire', false, false),
    ('gecko-queue-grasse', 'Gecko à queue grasse', 'Hemitheconyx caudicinctus', 'Lézard', 'Débutant', false, false),
    ('gecko-ligne-blanche', 'Gecko à ligne blanche', 'Gekko vittatus', 'Lézard', 'Intermédiaire', false, false),
    ('uroplatus-phantasticus', 'Gecko satanique à queue de feuille', 'Uroplatus phantasticus', 'Lézard', 'Avancé', false, false),
    ('pogona-nain', 'Pogona nain', 'Pogona henrylawsoni', 'Lézard', 'Débutant', false, false),
    ('dragon-eau-chinois', 'Dragon d\'eau chinois', 'Physignathus cocincinus', 'Lézard', 'Intermédiaire', false, false),
    ('fouette-queue-geyri', 'Fouette-queue du Sahara', 'Uromastyx geyri', 'Lézard', 'Intermédiaire', false, false),
    ('scinque-langue-bleue', 'Scinque à langue bleue', 'Tiliqua scincoides', 'Lézard', 'Débutant', false, false),
    ('scinque-feu', 'Scinque de feu', 'Lepidothyris fernandi', 'Lézard', 'Intermédiaire', false, false),
    ('anolis-vert', 'Anolis vert', 'Anolis carolinensis', 'Lézard', 'Débutant', false, false),
    ('basilic-vert', 'Basilic vert', 'Basiliscus plumifrons', 'Lézard', 'Avancé', false, false),
    ('cameleon-casque', 'Caméléon casqué du Yémen', 'Chamaeleo calyptratus', 'Lézard', 'Intermédiaire', false, false),
    ('cameleon-panthere', 'Caméléon panthère', 'Furcifer pardalis', 'Lézard', 'Avancé', false, false),
    ('iguane-vert', 'Iguane vert', 'Iguana iguana', 'Lézard', 'Avancé', true, false),
    ('varan-savanes', 'Varan des savanes', 'Varanus exanthematicus', 'Lézard', 'Avancé', false, false),
    ('lezard-collerette', 'Lézard à collerette', 'Chlamydosaurus kingii', 'Lézard', 'Avancé', false, false),
    ('teju-argentin', 'Téju noir et blanc d\'Argentine', 'Salvator merianae', 'Lézard', 'Avancé', false, false),

    // Serpents
    ('serpent-roi-californie', 'Serpent roi de Californie', 'Lampropeltis californiae', 'Serpent', 'Débutant', false, false),
    ('serpent-lait', 'Serpent lait', 'Lampropeltis triangulum', 'Serpent', 'Débutant', false, false),
    ('serpent-groin', 'Serpent à groin de l\'Ouest', 'Heterodon nasicus', 'Serpent', 'Débutant', false, false),
    ('python-tachete', 'Python tacheté', 'Antaresia maculosa', 'Serpent', 'Débutant', false, false),
    ('python-children', 'Python de Children', 'Antaresia childreni', 'Serpent', 'Débutant', false, false),
    ('serpent-maisons', 'Serpent des maisons africain', 'Boaedon fuliginosus', 'Serpent', 'Débutant', false, false),
    ('boa-sables', 'Boa des sables du Kenya', 'Eryx colubrinus', 'Serpent', 'Débutant', false, false),
    ('serpent-ratier-noir', 'Serpent ratier noir', 'Pantherophis obsoletus', 'Serpent', 'Débutant', false, false),
    ('python-tapis', 'Python tapis', 'Morelia spilota', 'Serpent', 'Intermédiaire', false, false),
    ('boa-arc-en-ciel', 'Boa arc-en-ciel du Brésil', 'Epicrates cenchria', 'Serpent', 'Intermédiaire', false, false),
    ('serpent-pins', 'Serpent des pins', 'Pituophis catenifer', 'Serpent', 'Intermédiaire', false, false),
    ('python-vert', 'Python vert arboricole', 'Morelia viridis', 'Serpent', 'Avancé', false, false),
    ('boa-constricteur', 'Boa constricteur', 'Boa constrictor', 'Serpent', 'Avancé', false, false),
    ('python-birman', 'Python birman', 'Python bivittatus', 'Serpent', 'Avancé', true, false),
    ('python-seba', 'Python de Seba', 'Python sebae', 'Serpent', 'Avancé', true, false),
    ('anaconda-vert', 'Anaconda vert', 'Eunectes murinus', 'Serpent', 'Avancé', true, false),
    ('crotale-diamantin', 'Crotale diamantin de l\'Ouest', 'Crotalus atrox', 'Serpent', 'Avancé', true, true),
    ('cobra-royal', 'Cobra royal', 'Ophiophagus hannah', 'Serpent', 'Avancé', true, true),

    // Tortues
    ('tortue-hermann', 'Tortue d\'Hermann', 'Testudo hermanni', 'Tortue', 'Intermédiaire', false, false),
    ('tortue-grecque', 'Tortue grecque', 'Testudo graeca', 'Tortue', 'Intermédiaire', false, false),
    ('tortue-leopard', 'Tortue léopard', 'Stigmochelys pardalis', 'Tortue', 'Avancé', false, false),
    ('tortue-sillonnee', 'Tortue sillonnée', 'Centrochelys sulcata', 'Tortue', 'Avancé', false, false),
    ('tortue-charbonniere', 'Tortue charbonnière à pattes rouges', 'Chelonoidis carbonarius', 'Tortue', 'Intermédiaire', false, false),
    ('tortue-etoilee-inde', 'Tortue étoilée d\'Inde', 'Geochelone elegans', 'Tortue', 'Avancé', false, false),
    ('tortue-musquee', 'Tortue musquée commune', 'Sternotherus odoratus', 'Tortue', 'Débutant', false, false),
    ('pelomeduse', 'Pélomeduse roussâtre', 'Pelomedusa subrufa', 'Tortue', 'Intermédiaire', false, false),

    // Araignées (mygales)
    ('mygale-rose-chili', 'Mygale rose du Chili', 'Grammostola rosea', 'Araignée', 'Débutant', false, false),
    ('mygale-frisee', 'Mygale frisée', 'Tliltocatl albopilosus', 'Araignée', 'Débutant', false, false),
    ('mygale-genoux-rouges', 'Mygale à genoux rouges du Mexique', 'Brachypelma hamorii', 'Araignée', 'Débutant', false, false),
    ('mygale-bleue', 'Mygale bleue-verte', 'Chromatopelma cyaneopubescens', 'Araignée', 'Intermédiaire', false, false),
    ('mygale-goliath', 'Mygale Goliath', 'Theraphosa blondi', 'Araignée', 'Avancé', false, false),
    ('mygale-ornementale', 'Mygale ornementale indienne', 'Poecilotheria regalis', 'Araignée', 'Avancé', false, false),

    // Amphibiens
    ('grenouille-pacman', 'Grenouille Pacman', 'Ceratophrys ornata', 'Amphibien', 'Débutant', false, false),
    ('rainette-white', 'Rainette de White', 'Ranoidea caerulea', 'Amphibien', 'Débutant', false, false),
    ('dendrobate-bleue', 'Dendrobate bleue', 'Dendrobates tinctorius', 'Amphibien', 'Avancé', false, false),
    ('axolotl', 'Axolotl', 'Ambystoma mexicanum', 'Amphibien', 'Débutant', false, false),

    // Autres pensionnaires de terrarium
    ('scorpion-empereur', 'Scorpion empereur', 'Pandinus imperator', 'Autre', 'Intermédiaire', false, false),
  ];

  static final List<ReptileSpecies> _stubs = [
    for (final s in _stubData)
      ReptileSpecies(
        id: s.$1,
        commonName: s.$2,
        scientificName: s.$3,
        category: s.$4,
        emoji: switch (s.$4) {
          'Serpent'   => '🐍',
          'Tortue'    => '🐢',
          'Araignée'  => '🕷️',
          'Amphibien' => '🐸',
          'Autre'     => '🐾',
          _           => '🦎',
        },
        difficulty: s.$5,
        professional: s.$6,
        venomous: s.$7,
        adultSize: '—', lifespan: '—', diet: '—', tempRange: '—',
        humidityRange: '—', terrarium: '—', origin: '—', temperament: '—',
        description: '', maleTraits: [], femaleTraits: [], sexingNote: '',
      ),
  ];

  static List<ReptileSpecies> search(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return all;
    return all.where((s) =>
        s.commonName.toLowerCase().contains(query) ||
        s.scientificName.toLowerCase().contains(query) ||
        s.category.toLowerCase().contains(query)).toList();
  }

  /// Suggestions selon le profil du questionnaire (niveau + reptiles choisis).
  /// Le niveau prime : les espèces DU niveau de l'utilisateur d'abord, puis
  /// les plus accessibles. Les catégories favorites servent au tri, pas au
  /// filtre (sinon on masquerait les espèces du bon niveau).
  static List<ReptileSpecies> suggestFor({String? niveau, List<String> animaux = const []}) {
    const order = ['Débutant', 'Intermédiaire', 'Avancé'];
    final target = switch (niveau) {
      'Débutant'      => 0,
      'Intermédiaire' => 1,
      'Avancé'        => 2,
      'Professionnel' => 2, // ancien libellé (comptes existants)
      'Expert'        => 2, // ancien libellé (comptes existants)
      _               => -1,
    };
    if (target < 0) return [];

    final cats = animaux.where((a) => a != 'Autre').toSet();

    // Jamais au-dessus du niveau de l'utilisateur, et jamais d'espèce à
    // certificat de capacité : c'est un statut légal, pas un niveau.
    final list = all.where((s) =>
        !s.professional && order.indexOf(s.difficulty) <= target).toList();

    int rank(ReptileSpecies s) {
      final gap = target - order.indexOf(s.difficulty); // 0 = pile le bon niveau
      final catBoost = (cats.isNotEmpty && cats.contains(s.category)) ? 0 : 1;
      return gap * 2 + catBoost;
    }

    list.sort((a, b) => rank(a).compareTo(rank(b)));
    return list.take(6).toList();
  }
}

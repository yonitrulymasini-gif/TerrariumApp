import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Photo iNaturalist (licence Creative Commons) avec son attribution.
class INatPhoto {
  final String url;
  final String attribution;
  const INatPhoto({required this.url, required this.attribution});

  /// Vignette légère (~4× plus petite) pour les cartes de grille.
  String get smallUrl => url.replaceFirst('/medium.', '/small.');

  Map<String, dynamic> toJson() => {'url': url, 'attribution': attribution};
  factory INatPhoto.fromJson(Map<String, dynamic> j) =>
      INatPhoto(url: j['url'] ?? '', attribution: j['attribution'] ?? '');
}

/// Résultat de recherche d'espèce (pour ajouter de futures fiches :
/// nom commun + nom scientifique + photo — le niveau reste à renseigner).
class INatTaxon {
  final String scientificName;
  final String? commonName; // en français si dispo
  final String? photoUrl;
  final String? attribution;
  const INatTaxon({required this.scientificName, this.commonName, this.photoUrl, this.attribution});
}

/// Client minimal de l'API publique iNaturalist (gratuite, sans clé).
/// On ne garde que les photos sous licence CC → attribution conservée.
class INaturalistService {
  static const _host = 'api.inaturalist.org';

  /// Futures mémoïsées : si la grille et les suggestions demandent la même
  /// espèce en même temps, une seule requête part (fini les rafales doublons).
  static final _inflight = <String, Future<List<INatPhoto>>>{};

  /// Première photo de la galerie (pour les cartes).
  static Future<INatPhoto?> photoFor(String scientificName) async {
    final photos = await photosFor(scientificName);
    return photos.isEmpty ? null : photos.first;
  }

  /// Galerie de photos CC d'une espèce, par nom scientifique.
  /// Cache disque : une seule récupération par espèce, à vie.
  static Future<List<INatPhoto>> photosFor(String scientificName, {int max = 6}) {
    final key = scientificName.trim().toLowerCase();
    return _inflight.putIfAbsent(key, () => _fetchPhotos(key, scientificName, max));
  }

  static Future<List<INatPhoto>> _fetchPhotos(String key, String scientificName, int max) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('inat_gallery_$key');
    if (cached != null) {
      return [
        for (final e in jsonDecode(cached) as List)
          INatPhoto.fromJson(e as Map<String, dynamic>),
      ];
    }

    try {
      // 1) Trouver le taxon — on privilégie la correspondance exacte du nom.
      final sRes = await http
          .get(Uri.https(_host, '/v1/taxa', {'q': scientificName, 'per_page': '5'}))
          .timeout(const Duration(seconds: 10));
      if (sRes.statusCode != 200) {
        _inflight.remove(key); // limite de débit… on retentera plus tard
        return [];
      }
      final results =
          ((jsonDecode(sRes.body)['results'] as List?) ?? []).cast<Map<String, dynamic>>();
      if (results.isEmpty) {
        await prefs.setString('inat_gallery_$key', '[]');
        return [];
      }
      final best = results.firstWhere(
        (r) => (r['name'] as String?)?.toLowerCase() == key,
        orElse: () => results.first,
      );

      // 2) Galerie complète du taxon (jusqu'à ~20 photos).
      final photos = <INatPhoto>[];
      final dRes = await http
          .get(Uri.https(_host, '/v1/taxa/${best['id']}'))
          .timeout(const Duration(seconds: 10));
      if (dRes.statusCode == 200) {
        final dResults = (jsonDecode(dRes.body)['results'] as List?) ?? [];
        final tps = dResults.isNotEmpty
            ? ((dResults.first as Map<String, dynamic>)['taxon_photos'] as List? ?? [])
            : [];
        for (final tp in tps) {
          final p = (tp as Map<String, dynamic>)['photo'] as Map<String, dynamic>?;
          final url = p?['medium_url'] as String?;
          if (url == null || url.isEmpty) continue;
          if (p?['license_code'] == null) continue; // pas CC → on écarte
          photos.add(INatPhoto(url: url, attribution: (p?['attribution'] as String?) ?? 'iNaturalist'));
          if (photos.length >= max) break;
        }
      }

      // Repli : la photo par défaut si la galerie CC est vide.
      if (photos.isEmpty) {
        final dp = best['default_photo'] as Map<String, dynamic>?;
        final url = dp?['medium_url'] as String?;
        if (url != null && url.isNotEmpty) {
          photos.add(INatPhoto(url: url, attribution: (dp?['attribution'] as String?) ?? 'iNaturalist'));
        }
      }

      await prefs.setString(
          'inat_gallery_$key', jsonEncode([for (final p in photos) p.toJson()]));
      return photos;
    } catch (_) {
      _inflight.remove(key); // erreur réseau : on retentera à la prochaine occasion
      return [];
    }
  }

  /// Recherche d'espèces (reptiles & co) : nom, nom scientifique, photo.
  /// Servira au flux « ajouter une espèce » (niveau à renseigner à la main).
  static Future<List<INatTaxon>> search(String query, {int perPage = 10}) async {
    if (query.trim().isEmpty) return [];
    try {
      final uri = Uri.https(_host, '/v1/taxa', {
        'q': query.trim(),
        'per_page': '$perPage',
        'locale': 'fr', // noms communs en français quand ils existent
        'rank': 'species',
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];

      final results = (jsonDecode(res.body)['results'] as List?) ?? [];
      return results.map((r) {
        final dp = r['default_photo'] as Map<String, dynamic>?;
        return INatTaxon(
          scientificName: r['name'] ?? '',
          commonName: r['preferred_common_name'] as String?,
          photoUrl: dp?['medium_url'] as String?,
          attribution: dp?['attribution'] as String?,
        );
      }).where((t) => t.scientificName.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }
}

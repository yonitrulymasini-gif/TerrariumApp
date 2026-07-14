import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Favoris d'espèces, persistés localement (par identifiant de fiche).
class FavoritesService extends ChangeNotifier {
  static final FavoritesService instance = FavoritesService._();
  FavoritesService._();

  static const _key = 'favorite_species';

  Set<String> _ids = {};
  Set<String> get ids => Set.unmodifiable(_ids);
  int get count => _ids.length;
  bool isFavorite(String id) => _ids.contains(id);

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _ids = (p.getStringList(_key) ?? <String>[]).toSet();
    notifyListeners();
  }

  Future<void> toggle(String id) async {
    if (!_ids.remove(id)) _ids.add(id);
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key, _ids.toList());
  }
}

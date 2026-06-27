import 'package:easy_onvif/onvif.dart';
import 'package:easy_onvif/shared.dart';

/// Pilotage de l'orientation (PTZ) d'une caméra ONVIF.
///
/// Les identifiants et l'IP sont extraits de l'URL RTSP déjà configurée.
/// Le port ONVIF est distinct du port RTSP (8000 par défaut sur Arenti).
class PtzService {
  static final PtzService instance = PtzService._();
  PtzService._();

  Onvif? _onvif;
  String? _profileToken;
  String? _connectedKey;

  /// Dernière erreur lisible (pour diagnostic UI).
  String? lastError;

  bool get isReady => _onvif != null && _profileToken != null;

  /// Se connecte en réutilisant les infos de l'URL RTSP. Renvoie true si OK.
  /// Essaie plusieurs ports ONVIF courants si le port par défaut échoue.
  Future<bool> connectFromRtsp(String rtspUrl,
      {List<int> onvifPorts = const [8000, 80, 2020, 8899, 8080]}) async {
    final uri = Uri.parse(rtspUrl);
    // ⚠️ Uri.userInfo n'est PAS décodé : il faut décoder soi-même les
    // caractères encodés du mot de passe (ex. %23 → #, %24 → $), sinon
    // l'authentification ONVIF échoue.
    final userInfo = uri.userInfo;
    final sep = userInfo.indexOf(':');
    final username = Uri.decodeComponent(sep >= 0 ? userInfo.substring(0, sep) : 'admin');
    final password = Uri.decodeComponent(sep >= 0 ? userInfo.substring(sep + 1) : '');
    final ip = uri.host;

    for (final port in onvifPorts) {
      final host = '$ip:$port';
      final key = '$host|$username';
      if (_connectedKey == key && isReady) return true;
      try {
        final onvif = await Onvif.connect(
          host: host,
          username: username,
          password: password,
        );
        final profiles = await onvif.media.getProfiles();
        if (profiles.isEmpty) {
          lastError = 'port $port : aucun profil ONVIF';
          continue;
        }
        _onvif = onvif;
        _profileToken = profiles.first.token;
        _connectedKey = key;
        lastError = null;
        return true;
      } catch (e) {
        lastError = 'port $port : ${_short(e)}';
      }
    }
    return false;
  }

  Future<bool> _do(Future<void> Function() action) async {
    try {
      await action();
      lastError = null;
      return true;
    } catch (e) {
      lastError = _short(e);
      return false;
    }
  }

  /// Démarre un mouvement continu (x = pan : - gauche / + droite,
  /// y = tilt : - bas / + haut). Vitesses dans [-1, 1].
  Future<bool> startMove(double x, double y) => _do(() => _onvif!.ptz.continuousMove(
        _profileToken!,
        velocity: PtzSpeed(panTilt: Vector2D(x: x, y: y), zoom: Vector1D(x: 0)),
      ));

  /// Arrête le mouvement en cours.
  Future<bool> stopMove() => _do(() => _onvif!.ptz.stop(_profileToken!));

  String _short(Object e) {
    final s = e.toString();
    return s.length > 120 ? '${s.substring(0, 120)}…' : s;
  }

  void reset() {
    _onvif = null;
    _profileToken = null;
    _connectedKey = null;
  }
}

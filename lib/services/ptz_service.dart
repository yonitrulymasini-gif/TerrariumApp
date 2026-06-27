import 'package:easy_onvif/onvif.dart';

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
    final userInfo = uri.userInfo; // déjà décodé par Uri (admin:motdepasse)
    final sep = userInfo.indexOf(':');
    final username = sep >= 0 ? userInfo.substring(0, sep) : 'admin';
    final password = sep >= 0 ? userInfo.substring(sep + 1) : '';
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

  Future<bool> up([double s = 0.08])    => _do(() => _onvif!.ptz.moveUp(_profileToken!, s));
  Future<bool> down([double s = 0.08])  => _do(() => _onvif!.ptz.moveDown(_profileToken!, -s));
  Future<bool> left([double s = 0.08])  => _do(() => _onvif!.ptz.moveLeft(_profileToken!, -s));
  Future<bool> right([double s = 0.08]) => _do(() => _onvif!.ptz.moveRight(_profileToken!, s));

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

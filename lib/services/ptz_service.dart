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

  bool get isReady => _onvif != null && _profileToken != null;

  /// Se connecte en réutilisant les infos de l'URL RTSP. Renvoie true si OK.
  Future<bool> connectFromRtsp(String rtspUrl, {int onvifPort = 8000}) async {
    try {
      final uri = Uri.parse(rtspUrl);
      final userInfo = uri.userInfo; // déjà décodé par Uri (admin:motdepasse)
      final sep = userInfo.indexOf(':');
      final username = sep >= 0 ? userInfo.substring(0, sep) : 'admin';
      final password = sep >= 0 ? userInfo.substring(sep + 1) : '';
      final host = '${uri.host}:$onvifPort';
      final key = '$host|$username';

      if (_connectedKey == key && isReady) return true;

      final onvif = await Onvif.connect(
        host: host,
        username: username,
        password: password,
      );
      final profiles = await onvif.media.getProfiles();
      if (profiles.isEmpty) return false;

      _onvif = onvif;
      _profileToken = profiles.first.token;
      _connectedKey = key;
      return true;
    } catch (_) {
      _onvif = null;
      _profileToken = null;
      _connectedKey = null;
      return false;
    }
  }

  Future<void> up([double step = 0.08])    async { if (isReady) await _onvif!.ptz.moveUp(_profileToken!, step); }
  Future<void> down([double step = 0.08])  async { if (isReady) await _onvif!.ptz.moveDown(_profileToken!, -step); }
  Future<void> left([double step = 0.08])  async { if (isReady) await _onvif!.ptz.moveLeft(_profileToken!, -step); }
  Future<void> right([double step = 0.08]) async { if (isReady) await _onvif!.ptz.moveRight(_profileToken!, step); }

  void reset() {
    _onvif = null;
    _profileToken = null;
    _connectedKey = null;
  }
}

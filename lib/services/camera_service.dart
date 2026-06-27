import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gère l'URL RTSP de la caméra, persistée en local.
class CameraService extends ChangeNotifier {
  static final CameraService instance = CameraService._();
  CameraService._();

  static const _key = 'camera_rtsp_url';

  String? _rtspUrl;
  String? get rtspUrl => _rtspUrl;
  bool get hasCamera => _rtspUrl != null && _rtspUrl!.isNotEmpty;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _rtspUrl = p.getString(_key);
    notifyListeners();
  }

  Future<void> setUrl(String url) async {
    _rtspUrl = url.trim().isEmpty ? null : url.trim();
    final p = await SharedPreferences.getInstance();
    if (_rtspUrl == null) {
      await p.remove(_key);
    } else {
      await p.setString(_key, _rtspUrl!);
    }
    notifyListeners();
  }

  Future<void> clear() => setUrl('');
}

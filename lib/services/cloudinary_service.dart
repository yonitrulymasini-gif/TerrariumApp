import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Upload d'images vers Cloudinary (preset non-signé).
class CloudinaryService {
  static const _cloudName = 'dp9fdg7vw';
  static const _uploadPreset = 'Terra_Flutter';
  static const _maxBytes = 10 * 1024 * 1024; // 10 Mo

  /// Upload [bytes] et retourne l'URL sécurisée optimisée, ou null si échec.
  /// [transform] : transformation Cloudinary insérée dans l'URL (ex: 'w_900').
  static Future<String?> upload(
    Uint8List bytes,
    String mime, {
    String transform = 'f_auto,q_auto,w_900',
  }) async {
    // Garde-fous : uniquement des images, taille raisonnable.
    if (!mime.startsWith('image/')) return null;
    if (bytes.lengthInBytes > _maxBytes) return null;
    try {
      final b64 = base64Encode(bytes);
      final ext = mime.split('/').last;
      final response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
        body: {
          'file': 'data:$mime;base64,$b64',
          'upload_preset': _uploadPreset,
          'filename_override': 'img_${DateTime.now().millisecondsSinceEpoch}.$ext',
        },
      ).timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        final url = jsonDecode(response.body)['secure_url'] as String;
        return url.replaceFirst('/upload/', '/upload/$transform/');
      }
    } catch (_) {}
    return null;
  }
}

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';

class QrScannerScreen extends StatefulWidget {
  final String promptText;
  final String? Function(String raw)? extractor;
  final String invalidMessage;

  const QrScannerScreen({
    super.key,
    this.promptText = 'Scanne le QR code\nà l\'intérieur de ta boîte Terra',
    this.extractor,
    this.invalidMessage = 'QR code invalide',
  });

  /// Extrait une URL RTSP d'un QR code (URL brute ou lien avec paramètre rtsp/url).
  static String? extractCameraUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('rtsp://') || trimmed.startsWith('rtsps://')) return trimmed;
    try {
      final uri = Uri.parse(trimmed);
      final url = uri.queryParameters['rtsp'] ?? uri.queryParameters['url'];
      if (url != null && (url.startsWith('rtsp://') || url.startsWith('rtsps://'))) return url;
    } catch (_) {}
    return null;
  }

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _ctrl = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  bool _scanned = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    final value = (widget.extractor ?? _extractDeviceId)(raw);
    if (value == null) {
      _showError(widget.invalidMessage);
      return;
    }

    _scanned = true;
    _ctrl.stop();
    Navigator.of(context).pop(value);
  }

  String? _extractDeviceId(String raw) {
    // Format attendu : https://terraapp.fr/setup?device=ESP32_XXXX
    // ou juste l'ID brut : ESP32_XXXX
    try {
      final uri = Uri.parse(raw);
      final id = uri.queryParameters['device'];
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {}

    // ID brut (commence par ESP32_)
    if (raw.startsWith('ESP32_')) return raw.trim();
    return null;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _scanned = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // Caméra
        MobileScanner(controller: _ctrl, onDetect: _onDetect),

        // Overlay sombre autour du cadre
        _ScanOverlay(),

        // UI
        SafeArea(
          child: Column(children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _ctrl.toggleTorch(),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flashlight_on_outlined, color: Colors.white, size: 20),
                  ),
                ),
              ]),
            ),

            const Spacer(),

            // Texte sous le cadre
            const SizedBox(height: 260), // hauteur approx du cadre
            const SizedBox(height: 24),
            Text(widget.promptText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6)),
            const Spacer(),
          ]),
        ),
      ]),
    );
  }
}

// ── Overlay avec fenêtre de scan ────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const frameSize = 240.0;
    const cornerRadius = 20.0;
    const cornerLength = 28.0;
    const cornerWidth = 4.0;
    final frameLeft = (size.width - frameSize) / 2;
    final frameTop = (size.height - frameSize) / 2 - 40;

    return Stack(children: [
      // Fond sombre
      ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
        child: Stack(children: [
          Container(color: Colors.transparent),
          Center(
            child: Transform.translate(
              offset: const Offset(0, -40),
              child: Container(
                width: frameSize, height: frameSize,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(cornerRadius),
                ),
              ),
            ),
          ),
        ]),
      ),

      // Coins verts
      ..._corners(frameLeft, frameTop, frameSize, cornerRadius, cornerLength, cornerWidth),
    ]);
  }

  List<Widget> _corners(double l, double t, double s, double r, double cl, double cw) {
    final c = AppColors.primary;
    return [
      // Top-left
      Positioned(left: l, top: t,
          child: _Corner(r, cl, cw, c, top: true, left: true)),
      // Top-right
      Positioned(left: l + s - cl, top: t,
          child: _Corner(r, cl, cw, c, top: true, left: false)),
      // Bottom-left
      Positioned(left: l, top: t + s - cl,
          child: _Corner(r, cl, cw, c, top: false, left: true)),
      // Bottom-right
      Positioned(left: l + s - cl, top: t + s - cl,
          child: _Corner(r, cl, cw, c, top: false, left: false)),
    ];
  }
}

class _Corner extends StatelessWidget {
  final double radius, length, width;
  final Color color;
  final bool top, left;
  const _Corner(this.radius, this.length, this.width, this.color,
      {required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(length, length),
      painter: _CornerPainter(radius, width, color, top: top, left: left),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final double radius, strokeWidth;
  final Color color;
  final bool top, left;
  const _CornerPainter(this.radius, this.strokeWidth, this.color,
      {required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final w = size.width;
    final h = size.height;

    if (top && left) {
      path.moveTo(0, h);
      path.lineTo(0, radius);
      path.arcToPoint(Offset(radius, 0), radius: Radius.circular(radius));
      path.lineTo(w, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(w - radius, 0);
      path.arcToPoint(Offset(w, radius), radius: Radius.circular(radius));
      path.lineTo(w, h);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, h - radius);
      path.arcToPoint(Offset(radius, h), radius: Radius.circular(radius));
      path.lineTo(w, h);
    } else {
      path.moveTo(0, h);
      path.lineTo(w - radius, h);
      path.arcToPoint(Offset(w, h - radius), radius: Radius.circular(radius));
      path.lineTo(w, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

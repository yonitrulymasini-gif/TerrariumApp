import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import '../services/theme_service.dart';

/// Écran de recadrage réutilisable. Renvoie les octets de l'image recadrée
/// (PNG) via Navigator.pop, ou null si annulé.
class ImageCropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final double? aspectRatio; // null = ratio libre
  final bool circle;
  final String title;

  const ImageCropScreen({
    super.key,
    required this.imageBytes,
    this.aspectRatio = 1,
    this.circle = true,
    this.title = 'Cadrer la photo',
  });

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  final _controller = CropController();
  bool _cropping = false;

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Text('Annuler', style: TextStyle(color: Colors.white70, fontSize: 15)),
            ),
            const Spacer(),
            Text(widget.title,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            const Spacer(),
            const SizedBox(width: 52), // équilibre visuel
          ]),
        ),

        Expanded(child: Crop(
          controller: _controller,
          image: widget.imageBytes,
          aspectRatio: widget.aspectRatio,
          withCircleUi: widget.circle,
          baseColor: Colors.black,
          maskColor: Colors.black.withValues(alpha: 0.55),
          radius: 12,
          onCropped: (result) {
            if (!mounted) return;
            setState(() => _cropping = false);
            if (result is CropSuccess) {
              Navigator.of(context).pop(result.croppedImage);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Recadrage impossible'),
                behavior: SnackBarBehavior.floating,
              ));
            }
          },
          cornerDotBuilder: (size, index) =>
              const DotControl(color: Colors.white),
        )),

        // Bouton valider
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: GestureDetector(
            onTap: _cropping ? null : () {
              setState(() => _cropping = true);
              _controller.crop();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.3),
                    blurRadius: 16, offset: const Offset(0, 5))],
              ),
              child: _cropping
                  ? Center(child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: c.bg)))
                  : Text('Valider', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.bg)),
            ),
          ),
        ),
      ])),
    );
  }
}

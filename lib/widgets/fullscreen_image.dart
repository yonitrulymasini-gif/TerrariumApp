import 'package:flutter/material.dart';

/// Ouvre une image en plein écran (fond noir, tap pour fermer).
void openFullscreenImage(BuildContext context, String url) {
  Navigator.of(context).push(PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, __, ___) => _FullscreenImage(url: url),
    transitionsBuilder: (_, anim, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: child,
    ),
  ));
}

class _FullscreenImage extends StatelessWidget {
  final String url;
  const _FullscreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.black,
      // SizedBox.expand + StackFit.expand : force le contenu à remplir tout
      // l'écran (sinon le Stack se réduit à la taille de l'image → minuscule).
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator(
                          color: Colors.white70, strokeWidth: 2)),
                  errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_outlined, color: Colors.white38, size: 48)),
                ),
              ),
            ),
            // Bouton fermer
            Positioned(
              top: topInset + 12,
              left: 12,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

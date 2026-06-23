import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CommunauteScreen extends StatelessWidget {
  const CommunauteScreen({super.key});

  static const _posts = [
    {'user': 'lila_terraria', 'time': 'il y a 2 h', 'caption': 'Mon dendrobate adore sa nouvelle plante 🌿', 'likes': 42, 'comments': 8},
    {'user': 'tropical_dan', 'time': 'hier', 'caption': 'Setup paludarium terminé après 3 mois de patience !', 'likes': 127, 'comments': 24},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 120),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('COMMUNAUTÉ', style: AppTextStyles.eyebrow),
                const SizedBox(height: 6),
                Text('Feed', style: AppTextStyles.serif28),
              ]),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.primary,
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: Offset(0, 4))],
                ),
                child: const Icon(Icons.add, color: AppColors.bg, size: 22),
              ),
            ]),
            const SizedBox(height: 20),

            for (final post in _posts) ...[
              Container(
                decoration: glassCard(radius: 24),
                margin: const EdgeInsets.only(bottom: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF3D6B40)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(child: Text(
                          (post['user'] as String)[0].toUpperCase(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.bg),
                        )),
                      ),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(post['user'] as String,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                        Text(post['time'] as String,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ]),
                    ]),
                  ),
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [const Color(0xFF1F3D2B), AppColors.bg, const Color(0xFF1A2E1A)],
                        ),
                      ),
                      child: const Center(child: Icon(Icons.camera_alt_outlined,
                          size: 48, color: Color(0x40FFFFFF))),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.favorite_border, size: 22, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('${post['likes']}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                        const SizedBox(width: 16),
                        const Icon(Icons.chat_bubble_outline, size: 22, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('${post['comments']}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      ]),
                      const SizedBox(height: 10),
                      Text(post['caption'] as String,
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5)),
                    ]),
                  ),
                ]),
              ),
            ],

            const Center(child: Text(
              'Ces posts sont des exemples — partage ta première photo pour démarrer',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.6),
            )),
          ]),
        ),
      ),
    );
  }
}

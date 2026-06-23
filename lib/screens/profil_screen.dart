import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'onboarding_screen.dart';
import '../utils/fade_route.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'Moi';
    final email = user?.email ?? '';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 120),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('PROFIL', style: AppTextStyles.eyebrow),
            const SizedBox(height: 6),
            Text('Mon compte', style: AppTextStyles.serif28),
            const SizedBox(height: 24),

            // Carte profil
            Container(
              decoration: glassCard(radius: 24),
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                user?.photoURL != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(user!.photoURL!, width: 64, height: 64, fit: BoxFit.cover),
                      )
                    : Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF3D6B40)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(child: Text(initial,
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.bg))),
                      ),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                ]),
              ]),
            ),
            const SizedBox(height: 12),

            // Menu
            _MenuRow(icon: Icons.memory_outlined, title: 'Mes appareils', subtitle: '0 ESP32 connecté'),
            const SizedBox(height: 10),
            _MenuRow(icon: Icons.settings_outlined, title: 'Paramètres', subtitle: 'Notifications, unités'),
            const SizedBox(height: 10),
            _MenuRow(icon: Icons.help_outline, title: 'Aide', subtitle: 'Guide ESP32, MQTT, FAQ'),
            const SizedBox(height: 24),

            // Déconnexion
            GestureDetector(
              onTap: () async {
                await AuthService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    fadeRoute(const OnboardingScreen()), (_) => false);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.red.withValues(alpha: 0.30)),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.logout, color: AppColors.red, size: 18),
                  SizedBox(width: 10),
                  Text('Se déconnecter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.red)),
                ]),
              ),
            ),
            const SizedBox(height: 24),

            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.eco_outlined, size: 12, color: AppColors.primary),
              SizedBox(width: 6),
              Text('Terra · v0.1', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _MenuRow({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: glassCard(radius: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: AppColors.textMuted),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ])),
        const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
      ]),
    );
  }
}

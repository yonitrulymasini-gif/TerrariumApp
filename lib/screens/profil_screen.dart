import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/device_service.dart';
import '../utils/fade_route.dart';
import 'onboarding_screen.dart';
import 'mes_appareils_screen.dart';
import 'notifications_settings_screen.dart';
import 'preferences_screen.dart';
import 'aide_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});
  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  int _scenarioCount = 0;
  int _postCount = 0;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    DeviceService.instance.addListener(_onChange);
    _loadStats();
  }

  @override
  void dispose() {
    DeviceService.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  Future<void> _changeAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked == null) return;
    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await picked.readAsBytes();
      await ProfileService.updateAvatar(bytes, picked.mimeType ?? 'image/jpeg');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Échec de la mise à jour de la photo'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _loadStats() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final db = FirebaseFirestore.instance;
    final scenarios = await db.collection('users').doc(uid).collection('scenarios').count().get();
    final posts = await db.collection('posts').where('uid', isEqualTo: uid).count().get();
    if (mounted) setState(() {
      _scenarioCount = scenarios.count ?? 0;
      _postCount = posts.count ?? 0;
    });
  }

  Future<void> _signOut() async {
    await AuthService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        fadeRoute(const OnboardingScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceCount = DeviceService.instance.devices.length;

    final user = FirebaseAuth.instance.currentUser;
        final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'Moi';
        final email = user?.email ?? '';
        final isAnon = user?.isAnonymous ?? true;
        final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 120),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PROFIL', style: AppTextStyles.eyebrow),
            const SizedBox(height: 6),
            Text('Mon compte', style: AppTextStyles.serif28),
            const SizedBox(height: 28),

            // ── Carte hero ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: glassCard(radius: 28),
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                StreamBuilder<String?>(
                  stream: ProfileService.avatarStream(),
                  builder: (ctx, snap) => _EditableAvatar(
                    photoURL: snap.data,
                    initial: initial,
                    size: 88,
                    uploading: _uploadingAvatar,
                    onEdit: _changeAvatar,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isAnon ? 'Invité' : displayName,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  isAnon ? 'Compte non sauvegardé' : email,
                  style: TextStyle(fontSize: 13, color: isAnon ? AppColors.accent : ThemeService.instance.colors.textMuted),
                ),
                const SizedBox(height: 20),

                Container(
                  decoration: BoxDecoration(
                    color: ThemeService.instance.colors.bg.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(children: [
                    _StatCell(value: '$deviceCount', label: 'Appareils'),
                    _Divider(),
                    _StatCell(value: '$_scenarioCount', label: 'Scénarios'),
                    _Divider(),
                    _StatCell(value: '$_postCount', label: 'Posts'),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Compte ──────────────────────────────────────────────────────
            Text('COMPTE', style: AppTextStyles.eyebrow),
            const SizedBox(height: 12),
            _MenuSection(items: [
              _MenuItem(
                icon: Icons.eco_outlined,
                iconColor: ThemeService.instance.colors.primary,
                title: 'Mes appareils',
                subtitle: deviceCount == 0
                    ? 'Aucun appareil connecté'
                    : '$deviceCount appareil${deviceCount > 1 ? 's' : ''} connecté${deviceCount > 1 ? 's' : ''}',
                onTap: () => Navigator.of(context).push(fadeRoute(const MesAppareilsScreen())),
              ),
              _MenuItem(
                icon: Icons.notifications_outlined,
                iconColor: ThemeService.instance.colors.primary,
                title: 'Notifications',
                subtitle: 'Alertes',
                onTap: () => Navigator.of(context).push(fadeRoute(const NotificationsSettingsScreen())),
              ),
              _MenuItem(
                icon: Icons.tune_outlined,
                iconColor: ThemeService.instance.colors.primary,
                title: 'Préférences',
                subtitle: 'Affichage',
                onTap: () => Navigator.of(context).push(fadeRoute(const PreferencesScreen())),
              ),
            ]),

            const SizedBox(height: 24),
            Text('SUPPORT', style: AppTextStyles.eyebrow),
            const SizedBox(height: 12),
            _MenuSection(items: [
              _MenuItem(
                icon: Icons.help_outline,
                iconColor: ThemeService.instance.colors.textMuted,
                title: 'Aide & FAQ',
                subtitle: 'Guide ESP32, MQTT',
                onTap: () => Navigator.of(context).push(fadeRoute(const AideScreen())),
              ),
              _MenuItem(
                icon: Icons.bug_report_outlined,
                iconColor: ThemeService.instance.colors.textMuted,
                title: 'Signaler un problème',
                subtitle: 'Envoyer un rapport',
                onTap: () => launchUrl(Uri.parse(
                  'mailto:support@terraapp.fr?subject=Rapport%20de%20bug%20Terra')),
              ),
            ]),

            const SizedBox(height: 28),

            GestureDetector(
              onTap: _signOut,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.red.withValues(alpha: 0.25)),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.logout_outlined, color: AppColors.red, size: 18),
                  SizedBox(width: 10),
                  Text('Se déconnecter',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.red)),
                ]),
              ),
            ),

            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.eco_outlined, size: 12, color: ThemeService.instance.colors.primary),
              SizedBox(width: 6),
              Text('Terra · v0.1', style: TextStyle(fontSize: 12, color: ThemeService.instance.colors.textMuted)),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ── Avatar éditable ───────────────────────────────────────────────────────────

class _EditableAvatar extends StatelessWidget {
  final String? photoURL;
  final String initial;
  final double size;
  final bool uploading;
  final VoidCallback onEdit;
  const _EditableAvatar({
    required this.photoURL, required this.initial, required this.size,
    required this.uploading, required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final radius = size / 4;
    final fallback = Container(
      width: size, height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: [ThemeService.instance.colors.primary, ThemeService.instance.colors.radialTop],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Text(initial,
          style: TextStyle(fontSize: size * 0.38, fontWeight: FontWeight.w700,
              color: ThemeService.instance.colors.bg))),
    );

    Widget avatar = photoURL == null
        ? fallback
        : ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.network(
              photoURL!, width: size, height: size, fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => fallback,
            ),
          );

    return SizedBox(
      width: size + 8, height: size + 8,
      child: Stack(clipBehavior: Clip.none, children: [
        avatar,
        // Overlay de chargement
        if (uploading) Container(
          width: size, height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: Colors.black54,
          ),
          child: Center(child: SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5, color: ThemeService.instance.colors.accent),
          )),
        ),
        // Bouton +
        Positioned(
          bottom: -2, right: -2,
          child: GestureDetector(
            onTap: uploading ? null : onEdit,
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: ThemeService.instance.colors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: ThemeService.instance.colors.card, width: 3),
              ),
              child: Icon(Icons.add, size: 16, color: ThemeService.instance.colors.bg),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Stats ─────────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.textPrimary)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 11, color: ThemeService.instance.colors.textMuted)),
    ]),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: ThemeService.instance.colors.border);
}

// ── Menu ──────────────────────────────────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) => Container(
    decoration: glassCard(radius: 20),
    child: Column(children: [
      for (int i = 0; i < items.length; i++) ...[
        items[i],
        if (i < items.length - 1)
          const Divider(height: 1, thickness: 1, color: Color(0x10507850), indent: 68),
      ],
    ]),
  );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.iconColor, required this.title,
      required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 15, color: ThemeService.instance.colors.textPrimary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 12, color: ThemeService.instance.colors.textMuted)),
        ])),
        Icon(Icons.chevron_right, color: ThemeService.instance.colors.textMuted, size: 20),
      ]),
    ),
  );
}

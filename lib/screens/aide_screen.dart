import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';

class AideScreen extends StatefulWidget {
  const AideScreen({super.key});
  @override
  State<AideScreen> createState() => _AideScreenState();
}

const _faqs = [
    _Faq(
      q: 'Comment connecter mon boîtier Terra ?',
      a: 'Scanne le QR code dans ta boîte, ou entre l\'ID manuellement dans l\'écran de connexion. Assure-toi que le boîtier est alimenté et que ton téléphone est connecté au WiFi.',
    ),
    _Faq(
      q: 'Pourquoi mon appareil apparaît "hors ligne" ?',
      a: 'Vérifie que le boîtier est alimenté et connecté au WiFi. Il peut mettre jusqu\'à 30 secondes à réapparaître en ligne après une reconnexion.',
    ),
    _Faq(
      q: 'Comment fonctionnent les scénarios ?',
      a: 'Les scénarios automatisent tes prises électriques selon des conditions (température, humidité, horaire). Exemple : allumer le chauffage si la température descend sous 20°C.',
    ),
    _Faq(
      q: 'Quels sont les protocoles supportés ?',
      a: 'Le boîtier Terra communique via MQTT over TLS sur le port 8883. Le firmware est basé sur ESP32 avec PlatformIO.',
    ),
    _Faq(
      q: 'Mes données sont-elles sécurisées ?',
      a: 'Oui, toutes les données transitent via Firebase avec authentification. Les communications entre le boîtier et le cloud sont chiffrées via TLS.',
    ),
    _Faq(
      q: 'Comment réinitialiser le boîtier ?',
      a: 'Maintiens le bouton BOOT appuyé pendant 5 secondes. Le LED rouge clignotera 3 fois pour confirmer la réinitialisation. Tu devras le reconnecter à l\'app.',
    ),
  ];

class _AideScreenState extends State<AideScreen> {
  @override
  void initState() {
    super.initState();
    ThemeService.instance.addListener(_onTheme);
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onTheme);
    super.dispose();
  }

  void _onTheme() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeService.instance.colors.bg,
      body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(Icons.arrow_back, color: AppColors.textSecondary, size: 22),
            ),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SUPPORT', style: AppTextStyles.eyebrow),
              Text('Aide & FAQ', style: AppTextStyles.serif28),
            ]),
          ]),
        ),
        const SizedBox(height: 24),

        Expanded(child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          children: [
            // Liens rapides
            Container(
              decoration: glassCard(radius: 20),
              child: Column(children: [
                _LinkRow(
                  icon: Icons.book_outlined,
                  iconColor: AppColors.primary,
                  title: 'Documentation ESP32',
                  subtitle: 'Guide de configuration firmware',
                  onTap: () => launchUrl(Uri.parse('https://docs.espressif.com/projects/esp-idf/fr/')),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0x10507850), indent: 68),
                _LinkRow(
                  icon: Icons.code_outlined,
                  iconColor: const Color(0xFF818CF8),
                  title: 'GitHub Terra',
                  subtitle: 'Code source et releases',
                  onTap: () => launchUrl(Uri.parse('https://github.com')),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0x10507850), indent: 68),
                _LinkRow(
                  icon: Icons.chat_bubble_outline,
                  iconColor: const Color(0xFF38BDF8),
                  title: 'Communauté Discord',
                  subtitle: 'Rejoins la communauté Terra',
                  onTap: () => launchUrl(Uri.parse('https://discord.com')),
                ),
              ]),
            ),

            const SizedBox(height: 28),
            Text('QUESTIONS FRÉQUENTES', style: AppTextStyles.eyebrow),
            const SizedBox(height: 12),

            ..._faqs.map((faq) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FaqTile(faq: faq),
            )),
          ],
        )),
      ])),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _LinkRow({required this.icon, required this.iconColor, required this.title,
      required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ])),
        Icon(Icons.open_in_new, size: 16, color: AppColors.textMuted),
      ]),
    ),
  );
}

class _Faq {
  final String q;
  final String a;
  const _Faq({required this.q, required this.a});
}

class _FaqTile extends StatefulWidget {
  final _Faq faq;
  const _FaqTile({required this.faq});
  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => _open = !_open),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: glassCard(radius: 16),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(widget.faq.q,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
          Icon(_open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppColors.textMuted, size: 20),
        ]),
        if (_open) ...[
          const SizedBox(height: 10),
          Text(widget.faq.a,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.6)),
        ],
      ]),
    ),
  );
}

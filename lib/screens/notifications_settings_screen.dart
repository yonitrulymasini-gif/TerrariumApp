import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});
  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    ThemeService.instance.addListener(_onThemeChange);
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _enabled = p.getBool('notifications_enabled') ?? true);
  }

  Future<void> _toggle(bool v) async {
    setState(() => _enabled = v);
    (await SharedPreferences.getInstance()).setBool('notifications_enabled', v);
  }

  void _onThemeChange() => setState(() {});

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
              Text('PARAMÈTRES', style: AppTextStyles.eyebrow),
              Text('Notifications', style: AppTextStyles.serif28),
            ]),
          ]),
        ),
        const SizedBox(height: 28),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: glassCard(radius: 20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: (_enabled ? AppColors.primary : AppColors.textMuted).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    _enabled ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                    size: 20,
                    color: _enabled ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Activer les notifications',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(
                    _enabled ? 'Tu recevras les alertes Terra' : 'Aucune alerte ne sera envoyée',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ])),
                Switch.adaptive(
                  value: _enabled,
                  onChanged: _toggle,
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: ThemeService.instance.colors.border,
                ),
              ]),
            ),
          ),
        ),

        if (!_enabled) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
              ),
              child: Row(children: [
                Icon(Icons.info_outline, color: AppColors.accent, size: 18),
                const SizedBox(width: 12),
                Expanded(child: Text(
                  'Tu ne seras pas alerté en cas de température ou d\'humidité hors plage.',
                  style: TextStyle(fontSize: 13, color: AppColors.accent, height: 1.5),
                )),
              ]),
            ),
          ),
        ],
      ])),
    );
  }
}

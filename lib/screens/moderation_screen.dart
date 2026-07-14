import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/community_service.dart';
import '../widgets/terra_confirm_dialog.dart';

/// Écran de modération réservé aux admins : liste les posts signalés,
/// affiche les motifs, et permet de supprimer un post ou d'ignorer les
/// signalements.
class ModerationScreen extends StatelessWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(Icons.arrow_back, color: c.textSecondary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('MODÉRATION', style: AppTextStyles.eyebrow),
              Text('Posts signalés', style: AppTextStyles.serif28),
            ])),
          ]),
        ),
        const SizedBox(height: 20),

        Expanded(child: StreamBuilder<List<CommunityPost>>(
          stream: CommunityService.reportedPostsStream(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: c.primary));
            }
            if (snap.hasError) {
              return _Empty(icon: Icons.lock_outline,
                  title: 'Accès refusé',
                  subtitle: 'Vérifie que ton compte est bien admin\n(règles Firestore).');
            }
            final posts = snap.data ?? [];
            if (posts.isEmpty) {
              return const _Empty(icon: Icons.verified_outlined,
                  title: 'Aucun signalement',
                  subtitle: 'Tout est propre pour le moment 🌿');
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _ReportedPostCard(post: posts[i]),
            );
          },
        )),
      ])),
    );
  }
}

class _ReportedPostCard extends StatelessWidget {
  final CommunityPost post;
  const _ReportedPostCard({required this.post});

  Future<void> _delete(BuildContext context) async {
    final ok = await showTerraConfirmDialog(
      context,
      icon: Icons.delete_outline,
      title: 'Supprimer le post',
      message: 'Le post de ${post.username} sera définitivement retiré.',
      confirmLabel: 'Supprimer',
      destructive: true,
    );
    if (ok == true) await CommunityService.deletePost(post.id);
  }

  Future<void> _clear(BuildContext context) async {
    final ok = await showTerraConfirmDialog(
      context,
      icon: Icons.check_circle_outline,
      title: 'Ignorer les signalements',
      message: 'Le post sera conservé et retiré de cette liste.',
      confirmLabel: 'Ignorer',
    );
    if (ok == true) await CommunityService.clearReports(post.id);
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return Container(
      decoration: glassCard(radius: 20),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(post.username,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.flag, size: 11, color: AppColors.red),
              const SizedBox(width: 4),
              Text('${post.reportCount}', style: TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w700, color: AppColors.red)),
            ]),
          ),
        ]),
        if (post.caption.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(post.caption, maxLines: 3, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: c.textSecondary, height: 1.4)),
        ],
        if (post.imageUrl != null) ...[
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.image_outlined, size: 13, color: c.textMuted),
            const SizedBox(width: 4),
            Text('Contient une photo', style: TextStyle(fontSize: 11, color: c.textMuted)),
          ]),
        ],

        const SizedBox(height: 12),
        Text('MOTIFS', style: AppTextStyles.eyebrow),
        const SizedBox(height: 6),
        StreamBuilder<List<PostReport>>(
          stream: CommunityService.reportsStream(post.id),
          builder: (ctx, snap) {
            if (snap.hasError) {
              return Text(
                'Motifs illisibles — publie les règles Firestore (lecture admin des « reports »).',
                style: TextStyle(fontSize: 12, color: AppColors.red, height: 1.4));
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return Text('Chargement…', style: TextStyle(fontSize: 12, color: c.textMuted));
            }
            final reports = snap.data ?? [];
            if (reports.isEmpty) {
              return Text('Aucun motif détaillé (${post.reportCount} signalement${post.reportCount > 1 ? 's' : ''}).',
                  style: TextStyle(fontSize: 12, color: c.textMuted));
            }
            return Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final r in reports) _ReasonLine(report: r)]);
          },
        ),

        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _ActionBtn(
            label: 'Ignorer', icon: Icons.check, filled: false,
            onTap: () => _clear(context),
          )),
          const SizedBox(width: 10),
          Expanded(child: _ActionBtn(
            label: 'Supprimer', icon: Icons.delete_outline, filled: true,
            onTap: () => _delete(context),
          )),
        ]),
      ]),
    );
  }
}

class _ReasonLine extends StatelessWidget {
  final PostReport report;
  const _ReasonLine({required this.report});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(width: 5, height: 5, decoration: BoxDecoration(
              shape: BoxShape.circle, color: AppColors.red.withValues(alpha: 0.7))),
        ),
        const SizedBox(width: 8),
        Expanded(child: RichText(text: TextSpan(
          style: TextStyle(fontSize: 12.5, color: c.textSecondary, height: 1.4),
          children: [
            TextSpan(text: report.reason,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (report.details != null && report.details!.trim().isNotEmpty)
              TextSpan(text: ' — ${report.details}',
                  style: TextStyle(color: c.textMuted)),
          ],
        ))),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    final color = filled ? AppColors.red : c.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: filled ? AppColors.red.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: filled ? AppColors.red.withValues(alpha: 0.35) : c.border),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _Empty({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return Center(child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 48, color: c.textMuted.withValues(alpha: 0.4)),
        const SizedBox(height: 16),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.textPrimary)),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: c.textMuted, height: 1.5)),
      ]),
    ));
  }
}

import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/community_service.dart';
import '../services/profile_service.dart';
import '../services/scenario_service.dart';
import '../services/app_nav.dart';

class CommunauteScreen extends StatefulWidget {
  const CommunauteScreen({super.key});
  @override
  State<CommunauteScreen> createState() => _CommunauteScreenState();
}

class _CommunauteScreenState extends State<CommunauteScreen> {
  // null = "Tous"
  String? _filter;

  @override
  void initState() {
    super.initState();
    AppNav.instance.addListener(_onNav);
    // Au cas où un scénario serait déjà en attente à la création
    WidgetsBinding.instance.addPostFrameCallback((_) => _onNav());
  }

  @override
  void dispose() {
    AppNav.instance.removeListener(_onNav);
    super.dispose();
  }

  void _onNav() {
    if (AppNav.instance.tab != AppNav.communityTab) return;
    final scenario = AppNav.instance.consumePendingScenario();
    if (scenario != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showNewPost(context, scenario: scenario);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('COMMUNAUTÉ', style: AppTextStyles.eyebrow),
                  const SizedBox(height: 6),
                  Text('Explore', style: AppTextStyles.serif28),
                ]),
                GestureDetector(
                  onTap: () => _showNewPost(context),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, color: ThemeService.instance.colors.primary,
                      boxShadow: [BoxShadow(color: ThemeService.instance.colors.primary.withValues(alpha: 0.3),
                          blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: Icon(Icons.add, color: ThemeService.instance.colors.bg, size: 22),
                  ),
                ),
              ]),
            )),

            // ── Filtres catégories ────────────────────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _FilterChip(label: 'Tous', icon: Icons.grid_view_rounded,
                        selected: _filter == null, onTap: () => setState(() => _filter = null)),
                    ...PostCategory.all.map((c) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _FilterChip(label: c.label, icon: c.icon,
                          selected: _filter == c.key, onTap: () => setState(() => _filter = c.key)),
                    )),
                  ],
                ),
              ),
            )),

            StreamBuilder<List<CommunityPost>>(
              stream: CommunityService.postsStream(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return SliverToBoxAdapter(
                    child: Center(child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: ThemeService.instance.colors.primary),
                    )),
                  );
                }
                final all = snap.data ?? [];
                final posts = _filter == null
                    ? all
                    : all.where((p) => p.category == _filter).toList();

                if (posts.isEmpty) {
                  final emptyMsg = _filter == null
                      ? 'Sois le premier à poster !'
                      : 'Aucun post dans "${PostCategory.byKey(_filter!).label}"';
                  return SliverToBoxAdapter(child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    child: Column(children: [
                      const SizedBox(height: 40),
                      Icon(Icons.people_outline, size: 48, color: ThemeService.instance.colors.textMuted.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text(emptyMsg, textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: ThemeService.instance.colors.textMuted)),
                      const SizedBox(height: 8),
                      Text('Partage ton setup, tes conseils ou tes scénarios.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: ThemeService.instance.colors.textHint)),
                    ]),
                  ));
                }
                return SliverList(delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: EdgeInsets.fromLTRB(20, i == 0 ? 16 : 0, 20, 16),
                    child: _PostCard(post: posts[i]),
                  ),
                  childCount: posts.length,
                ));
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  void _showNewPost(BuildContext context, {TerraScenario? scenario}) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeService.instance.colors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _NewPostSheet(messenger: messenger, scenario: scenario),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final PostCategory category;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.category, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? c.primary.withValues(alpha: 0.15) : c.bg,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: selected ? c.primary.withValues(alpha: 0.5) : c.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(category.icon, size: 15, color: selected ? c.primary : c.textMuted),
          const SizedBox(width: 6),
          Text(category.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
              color: selected ? c.primary : c.textMuted)),
        ]),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final PostCategory category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(category.icon, size: 11, color: c.primary),
        const SizedBox(width: 4),
        Text(category.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c.primary)),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? c.primary : c.card,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: selected ? c.primary : c.border),
        ),
        child: Row(children: [
          Icon(icon, size: 15, color: selected ? c.bg : c.textMuted),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: selected ? c.bg : c.textSecondary)),
        ]),
      ),
    );
  }
}

// ── Nouveau post ─────────────────────────────────────────────────────────────

class _NewPostSheet extends StatefulWidget {
  final ScaffoldMessengerState messenger;
  final TerraScenario? scenario;
  const _NewPostSheet({required this.messenger, this.scenario});
  @override
  State<_NewPostSheet> createState() => _NewPostSheetState();
}

class _NewPostSheetState extends State<_NewPostSheet> {
  final _ctrl = TextEditingController();
  XFile? _pickedFile;
  Uint8List? _imageBytes;
  bool _publishing = false;
  String? _error;
  String _category = 'setup';

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() { _pickedFile = picked; _imageBytes = bytes; });
    }
  }

  Future<void> _publish() async {
    if (_ctrl.text.trim().isEmpty && _pickedFile == null && widget.scenario == null) return;
    setState(() { _publishing = true; _error = null; });
    try {
      await CommunityService.createPost(_ctrl.text.trim(),
          pickedFile: _pickedFile, scenario: widget.scenario, category: _category);
      final messenger = widget.messenger;
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Text('Post publié !'),
        ]),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      if (mounted) setState(() { _publishing = false; _error = 'Erreur : $e'; });
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [

        // Handle + header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x14507850))),
          ),
          child: Row(children: [
            Expanded(
              child: Text('Nouveau post',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.textPrimary)),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: ThemeService.instance.colors.bg, shape: BoxShape.circle,
                  border: Border.all(color: ThemeService.instance.colors.border),
                ),
                child: Icon(Icons.close, size: 16, color: ThemeService.instance.colors.textMuted),
              ),
            ),
            const SizedBox(width: 12),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Avatar + champ texte
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _UserAvatar(size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _ctrl, maxLines: 7, minLines: 5, autofocus: true,
                  style: TextStyle(color: ThemeService.instance.colors.textPrimary, fontSize: 15, height: 1.6),
                  decoration: InputDecoration(
                    hintText: widget.scenario != null
                        ? 'Décris ton scénario, donne des conseils…'
                        : 'Partage ton setup, une astuce, une photo…',
                    hintStyle: TextStyle(color: ThemeService.instance.colors.textMuted, fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ]),

            // Carte scénario joint
            if (widget.scenario != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ThemeService.instance.colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ThemeService.instance.colors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: ThemeService.instance.colors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.scenario!.icon, size: 20, color: ThemeService.instance.colors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.auto_awesome, size: 12, color: ThemeService.instance.colors.primary),
                      const SizedBox(width: 4),
                      Text('SCÉNARIO PARTAGÉ',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                              letterSpacing: 0.5, color: ThemeService.instance.colors.primary)),
                    ]),
                    const SizedBox(height: 4),
                    Text(widget.scenario!.name,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.textPrimary)),
                    Text(widget.scenario!.description,
                        style: TextStyle(fontSize: 12, color: ThemeService.instance.colors.textMuted)),
                  ])),
                ]),
              ),
            ],

            // Aperçu image
            if (_imageBytes != null) ...[
              const SizedBox(height: 14),
              Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.memory(_imageBytes!, width: double.infinity, height: 200, fit: BoxFit.cover),
                ),
                Positioned(top: 10, right: 10, child: GestureDetector(
                  onTap: () => setState(() { _imageBytes = null; _pickedFile = null; }),
                  child: Container(
                    width: 30, height: 30,
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                )),
              ]),
            ],

            // Sélecteur de catégorie (masqué si scénario joint = forcé)
            if (widget.scenario == null) ...[
              const SizedBox(height: 16),
              Text('CATÉGORIE', style: AppTextStyles.eyebrow),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: PostCategory.all
                  .where((c) => c.key != 'scenario')
                  .map((c) => _CategoryChip(
                        category: c,
                        selected: _category == c.key,
                        onTap: () => setState(() => _category = c.key),
                      )).toList()),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppColors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.red))),
                ]),
              ),
            ],

            const SizedBox(height: 20),

            // Barre bas : icônes + publier
            Row(children: [
              _IconAction(icon: Icons.photo_library_outlined,
                  onTap: () => _pickImage(ImageSource.gallery)),
              const SizedBox(width: 8),
              _IconAction(icon: Icons.camera_alt_outlined,
                  onTap: () => _pickImage(ImageSource.camera)),
              const Spacer(),
              GestureDetector(
                onTap: _publishing ? null : _publish,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: ThemeService.instance.colors.primary,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [BoxShadow(color: ThemeService.instance.colors.primary.withValues(alpha: 0.35),
                        blurRadius: 14, offset: const Offset(0, 4))],
                  ),
                  child: _publishing
                      ? SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: ThemeService.instance.colors.bg))
                      : Text('Publier',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.bg)),
                ),
              ),
            ]),
          ]),
        ),
      ])),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final double size;
  const _UserAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email ?? '?';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final fallback = Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [ThemeService.instance.colors.primary, ThemeService.instance.colors.radialTop],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Text(initial,
          style: TextStyle(fontSize: size * 0.38, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.bg))),
    );
    return StreamBuilder<String?>(
      stream: ProfileService.avatarStream(),
      builder: (ctx, snap) {
        final photoURL = snap.data;
        if (photoURL == null) return fallback;
        return ClipOval(
          child: Image.network(photoURL, width: size, height: size, fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => fallback),
        );
      },
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: ThemeService.instance.colors.bg,
        shape: BoxShape.circle,
        border: Border.all(color: ThemeService.instance.colors.border),
      ),
      child: Icon(icon, size: 18, color: ThemeService.instance.colors.textSecondary),
    ),
  );
}

// ── Post ─────────────────────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  final CommunityPost post;
  const _PostCard({required this.post});
  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _showComments = false;

  void _showOptions(BuildContext context) {
    final isOwn = widget.post.uid == FirebaseAuth.instance.currentUser?.uid;
    final c = ThemeService.instance.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Carte d'options
            Container(
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.border),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(height: 10),
                Container(width: 36, height: 4, decoration: BoxDecoration(
                    color: ThemeService.instance.colors.textHint, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 6),
                if (isOwn) ...[
                  _OptionTile(
                    icon: Icons.edit_outlined, label: 'Modifier le post',
                    subtitle: 'Changer le texte ou la photo',
                    onTap: () { Navigator.pop(context); _showEdit(context); },
                  ),
                  Divider(height: 1, color: c.border, indent: 64, endIndent: 16),
                  _OptionTile(
                    icon: Icons.delete_outline, label: 'Supprimer',
                    subtitle: 'Retirer définitivement ce post',
                    color: AppColors.red,
                    onTap: () { Navigator.pop(context); _confirmDelete(context); },
                  ),
                ] else
                  _OptionTile(
                    icon: Icons.flag_outlined, label: 'Signaler',
                    subtitle: 'Signaler un contenu inapproprié',
                    onTap: () => Navigator.pop(context),
                  ),
                const SizedBox(height: 6),
              ]),
            ),
            const SizedBox(height: 8),
            // Bouton Annuler
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.border),
                ),
                child: Text('Annuler', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.textPrimary)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeService.instance.colors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _EditPostSheet(post: widget.post),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeService.instance.colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Supprimer le post', style: TextStyle(color: ThemeService.instance.colors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
        content: Text('Cette action est irréversible.', style: TextStyle(color: ThemeService.instance.colors.textMuted, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Annuler', style: TextStyle(color: ThemeService.instance.colors.textMuted))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await CommunityService.deletePost(widget.post.id);
            },
            child: const Text('Supprimer', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final post = widget.post;
    final liked = post.likedBy.contains(currentUid);

    return Container(
      decoration: glassCard(radius: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
          child: Row(children: [
            currentUid == post.uid
                ? _UserAvatar(size: 40)
                : Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [ThemeService.instance.colors.primary, ThemeService.instance.colors.radialTop],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(child: Text(
                      post.username.isNotEmpty ? post.username[0].toUpperCase() : '?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.bg),
                    )),
                  ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(post.username, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ThemeService.instance.colors.textPrimary))),
                const SizedBox(width: 8),
                _CategoryBadge(category: PostCategory.byKey(post.category)),
              ]),
              Text(post.timeAgo, style: TextStyle(fontSize: 12, color: ThemeService.instance.colors.textMuted)),
            ])),
            GestureDetector(
              onTap: () => _showOptions(context),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.more_horiz, color: ThemeService.instance.colors.textMuted, size: 20),
              ),
            ),
          ]),
        ),

        // Caption
        if (post.caption.isNotEmpty) Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, post.imageUrl != null ? 10 : 14),
          child: Text(post.caption, style: TextStyle(fontSize: 14, color: ThemeService.instance.colors.textPrimary, height: 1.6)),
        ),

        // Image
        if (post.imageUrl != null) ClipRRect(
          borderRadius: post.caption.isEmpty
              ? const BorderRadius.vertical(top: Radius.circular(24))
              : BorderRadius.zero,
          child: Image.network(
            post.imageUrl!,
            width: double.infinity, height: 220, fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) => progress == null ? child
                : Container(height: 220, color: ThemeService.instance.colors.card,
                    child: Center(child: CircularProgressIndicator(color: ThemeService.instance.colors.primary, strokeWidth: 2))),
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),

        // Scénario joint
        if (post.scenario != null) Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: _SharedScenarioCard(scenario: post.scenario!),
        ),

        // Actions
        Container(
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x18507850)))),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(children: [
            GestureDetector(
              onTap: () => CommunityService.toggleLike(post.id, post.likedBy),
              child: Row(children: [
                Icon(liked ? Icons.favorite : Icons.favorite_border,
                    size: 20, color: liked ? AppColors.red : ThemeService.instance.colors.textSecondary),
                const SizedBox(width: 5),
                Text('${post.likes}', style: TextStyle(fontSize: 13, color: ThemeService.instance.colors.textSecondary)),
              ]),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () => setState(() => _showComments = !_showComments),
              child: Row(children: [
                Icon(Icons.chat_bubble_outline, size: 18,
                    color: _showComments ? ThemeService.instance.colors.primary : ThemeService.instance.colors.textSecondary),
                const SizedBox(width: 5),
                Text('${post.commentCount}', style: TextStyle(fontSize: 13,
                    color: _showComments ? ThemeService.instance.colors.primary : ThemeService.instance.colors.textSecondary)),
              ]),
            ),
          ]),
        ),

        // Comments section
        if (_showComments) _CommentsSection(postId: post.id),
      ]),
    );
  }
}

// ── Carte scénario joint à un post (avec import) ──────────────────────────────

class _SharedScenarioCard extends StatefulWidget {
  final SharedScenario scenario;
  const _SharedScenarioCard({required this.scenario});
  @override
  State<_SharedScenarioCard> createState() => _SharedScenarioCardState();
}

class _SharedScenarioCardState extends State<_SharedScenarioCard> {
  bool _importing = false;
  bool _imported = false;

  Future<void> _import() async {
    setState(() => _importing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await CommunityService.importSharedScenario(widget.scenario);
      if (mounted) setState(() { _importing = false; _imported = true; });
      messenger.showSnackBar(SnackBar(
        content: Text('Scénario "${widget.scenario.name}" importé !'),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (_) {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    final s = widget.scenario;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.primary.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(s.icon, size: 20, color: c.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.auto_awesome, size: 11, color: c.primary),
              const SizedBox(width: 4),
              Text('SCÉNARIO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 0.5, color: c.primary)),
            ]),
            const SizedBox(height: 2),
            Text(s.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.textPrimary)),
            Text(s.description, style: TextStyle(fontSize: 12, color: ThemeService.instance.colors.textMuted)),
          ])),
        ]),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: (_importing || _imported) ? null : _import,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _imported ? Colors.transparent : c.primary,
              borderRadius: BorderRadius.circular(50),
              border: _imported ? Border.all(color: c.primary.withValues(alpha: 0.4)) : null,
            ),
            child: _importing
                ? Center(child: SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: c.bg)))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(_imported ? Icons.check : Icons.download_outlined,
                        size: 16, color: _imported ? c.primary : c.bg),
                    const SizedBox(width: 6),
                    Text(_imported ? 'Importé' : 'Importer ce scénario',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: _imported ? c.primary : c.bg)),
                  ]),
          ),
        ),
      ]),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? color;
  final VoidCallback onTap;
  const _OptionTile({required this.icon, required this.label, required this.onTap,
      this.subtitle, this.color});

  @override
  Widget build(BuildContext context) {
    final tint = color ?? ThemeService.instance.colors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: tint),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: tint)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: TextStyle(fontSize: 12, color: ThemeService.instance.colors.textMuted)),
            ],
          ])),
        ]),
      ),
    );
  }
}

// ── Éditeur de post (texte + photo) ───────────────────────────────────────────

class _EditPostSheet extends StatefulWidget {
  final CommunityPost post;
  const _EditPostSheet({required this.post});
  @override
  State<_EditPostSheet> createState() => _EditPostSheetState();
}

class _EditPostSheetState extends State<_EditPostSheet> {
  late final TextEditingController _ctrl;
  XFile? _newImage;
  Uint8List? _newImageBytes;
  bool _removeImage = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.post.caption);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery, imageQuality: 75, maxWidth: 1280, maxHeight: 1280);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() { _newImage = picked; _newImageBytes = bytes; _removeImage = false; });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final nav = Navigator.of(context);
    try {
      await CommunityService.updatePost(
        widget.post.id,
        caption: _ctrl.text.trim(),
        newImage: _newImage,
        removeImage: _removeImage,
      );
      nav.pop();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    // Détermine l'image à afficher : nouvelle > existante (sauf si supprimée)
    final hasImage = !_removeImage && (_newImageBytes != null || widget.post.imageUrl != null);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(top: false, child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Modifier le post',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.textPrimary)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: c.bg, shape: BoxShape.circle, border: Border.all(color: c.border)),
                  child: Icon(Icons.close, size: 16, color: c.textMuted),
                ),
              ),
            ]),
            const SizedBox(height: 18),

            // Champ texte
            TextField(
              controller: _ctrl, maxLines: 5, minLines: 3, autofocus: true,
              style: TextStyle(color: ThemeService.instance.colors.textPrimary, fontSize: 15, height: 1.6),
              decoration: InputDecoration(
                hintText: 'Modifie ton texte…',
                hintStyle: TextStyle(color: ThemeService.instance.colors.textMuted),
                filled: true, fillColor: c.bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.primary)),
              ),
            ),
            const SizedBox(height: 16),

            // Photo
            if (hasImage) ...[
              Text('PHOTO', style: AppTextStyles.eyebrow),
              const SizedBox(height: 8),
              Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _newImageBytes != null
                      ? Image.memory(_newImageBytes!, width: double.infinity, height: 180, fit: BoxFit.cover)
                      : Image.network(widget.post.imageUrl!, width: double.infinity, height: 180, fit: BoxFit.cover),
                ),
                // Boutons changer / supprimer la photo
                Positioned(top: 8, right: 8, child: Row(children: [
                  _CircleBtn(icon: Icons.swap_horiz, onTap: _pickImage),
                  const SizedBox(width: 8),
                  _CircleBtn(icon: Icons.delete_outline, color: AppColors.red,
                      onTap: () => setState(() { _removeImage = true; _newImage = null; _newImageBytes = null; })),
                ])),
              ]),
            ] else
              // Pas de photo → bouton ajouter
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 18, color: c.primary),
                    const SizedBox(width: 8),
                    Text('Ajouter une photo',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.primary)),
                  ]),
                ),
              ),

            const SizedBox(height: 20),

            // Enregistrer
            GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(50)),
                child: _saving
                    ? Center(child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: c.bg)))
                    : Text('Enregistrer', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.bg)),
              ),
            ),
          ]),
        ),
      )),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34, height: 34,
      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
      child: Icon(icon, size: 17, color: color ?? Colors.white),
    ),
  );
}

// ── Section commentaires ──────────────────────────────────────────────────────

class _CommentsSection extends StatefulWidget {
  final String postId;
  const _CommentsSection({required this.postId});
  @override
  State<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<_CommentsSection> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _deleteComment(BuildContext context, PostComment comment) async {
    try {
      await CommunityService.deleteComment(widget.postId, comment.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _send() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    await CommunityService.addComment(widget.postId, _ctrl.text);
    _ctrl.clear();
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x18507850)))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      StreamBuilder<List<PostComment>>(
        stream: CommunityService.commentsStream(widget.postId),
        builder: (ctx, snap) {
          final comments = snap.data ?? [];
          if (comments.isEmpty) return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('Aucun commentaire. Sois le premier !',
                style: TextStyle(fontSize: 12, color: ThemeService.instance.colors.textMuted)),
          );
          final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
          return Column(children: comments.map((c) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              c.uid == currentUid
                  ? _UserAvatar(size: 28)
                  : Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ThemeService.instance.colors.primary.withValues(alpha: 0.2),
                      ),
                      child: Center(child: Text(
                        c.username.isNotEmpty ? c.username[0].toUpperCase() : '?',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.primary),
                      )),
                    ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(c.username, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.textPrimary)),
                  const SizedBox(width: 6),
                  Text(c.timeAgo, style: TextStyle(fontSize: 11, color: ThemeService.instance.colors.textHint)),
                  const Spacer(),
                  if (c.uid == currentUid)
                    GestureDetector(
                      onTap: () => _deleteComment(context, c),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(Icons.delete_outline, size: 15, color: ThemeService.instance.colors.textHint),
                      ),
                    ),
                ]),
                const SizedBox(height: 2),
                Text(c.text, style: TextStyle(fontSize: 13, color: ThemeService.instance.colors.textPrimary, height: 1.5)),
              ])),
            ]),
          )).toList());
        },
      ),
      // Champ écriture
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Row(children: [
          _UserAvatar(size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: TextStyle(color: ThemeService.instance.colors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ajoute un commentaire…',
                hintStyle: TextStyle(color: ThemeService.instance.colors.textMuted, fontSize: 13),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: ThemeService.instance.colors.bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sending ? null : _send,
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(shape: BoxShape.circle, color: ThemeService.instance.colors.primary),
              child: _sending
                  ? Padding(padding: const EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2, color: ThemeService.instance.colors.bg))
                  : Icon(Icons.send_rounded, size: 16, color: ThemeService.instance.colors.bg),
            ),
          ),
        ]),
      ),
    ]),
  );
}

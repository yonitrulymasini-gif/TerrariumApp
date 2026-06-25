import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  static Stream<int> unreadCount() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('alerts')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Future<void> _markAllRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final batch = FirebaseFirestore.instance.batch();
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('alerts')
        .where('read', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: ThemeService.instance.colors.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(Icons.arrow_back, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 16),
              Text('Alertes', style: AppTextStyles.serif28),
              const Spacer(),
              GestureDetector(
                onTap: _markAllRead,
                child: Text('Tout lire', style: TextStyle(fontSize: 13, color: AppColors.accentGreen)),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: uid == null
                ? Center(child: Text('Non connecté', style: TextStyle(color: AppColors.textMuted)))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('alerts')
                        .orderBy('createdAt', descending: true)
                        .limit(50)
                        .snapshots(),
                    builder: (ctx, snap) {
                      if (!snap.hasData) return Center(child: CircularProgressIndicator(color: ThemeService.instance.colors.primary));
                      final docs = snap.data!.docs;
                      if (docs.isEmpty) return _empty();
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final data = docs[i].data() as Map<String, dynamic>;
                          return _AlertRow(data: data, docId: docs[i].id, uid: uid);
                        },
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.notifications_none_rounded, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('Aucune alerte', style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
        ]),
      );
}

class _AlertRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String uid;
  const _AlertRow({required this.data, required this.docId, required this.uid});

  @override
  Widget build(BuildContext context) {
    final type = data['type'] as String? ?? '';
    final value = data['value'];
    final read = data['read'] as bool? ?? false;

    final (icon, color, label) = switch (type) {
      'temp_high' => (Icons.thermostat, const Color(0xFFFB923C), 'Température trop élevée'),
      'temp_low'  => (Icons.thermostat, const Color(0xFF38BDF8), 'Température trop basse'),
      'humid_high' => (Icons.water_drop, const Color(0xFF38BDF8), 'Humidité trop élevée'),
      'humid_low'  => (Icons.water_drop, const Color(0xFFFB923C), 'Humidité trop basse'),
      _            => (Icons.warning_amber_rounded, AppColors.yellow, 'Alerte'),
    };

    return GestureDetector(
      onTap: () {
        if (!read) {
          FirebaseFirestore.instance
              .collection('users').doc(uid).collection('alerts').doc(docId)
              .update({'read': true});
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: glassCard(radius: 16).copyWith(
          border: read ? null : Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(
                fontSize: 14, color: AppColors.textPrimary, fontWeight: read ? FontWeight.w400 : FontWeight.w600)),
            if (value != null)
              Text('Valeur : $value', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ])),
          if (!read)
            Container(width: 8, height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        ]),
      ),
    );
  }
}

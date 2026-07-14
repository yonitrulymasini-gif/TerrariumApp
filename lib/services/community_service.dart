import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'cloudinary_service.dart';
import 'scenario_service.dart';

/// Salons de la communauté (le champ `category` d'un post = clé du salon).
class PostCategory {
  final String key;
  final String label;
  final String description;
  final IconData icon;
  const PostCategory(this.key, this.label, this.icon, [this.description = '']);

  static const question = PostCategory('question', 'Discussions', Icons.forum_outlined, 'Questions & sujets divers');
  static const setup = PostCategory('setup', 'Setups', Icons.grass_outlined, 'Montages & aménagements');
  static const health = PostCategory('sante', 'Santé', Icons.healing_outlined, 'Soins, mues, alimentation');
  static const tip = PostCategory('tip', 'Astuces', Icons.lightbulb_outline, 'Trucs & bonnes pratiques');
  static const photo = PostCategory('photo', 'Photos', Icons.photo_camera_outlined, 'Vos reptiles en photo');
  static const scenario = PostCategory('scenario', 'Scénario', Icons.auto_awesome_outlined);

  /// Les salons du fil « Général » (dans l'ordre d'affichage).
  static const salons = [question, setup, health, tip, photo];
  static const all = [question, setup, health, tip, photo, scenario];

  static PostCategory byKey(String key) =>
      all.firstWhere((c) => c.key == key, orElse: () => question);
}

class CommunityService {
  static final _db = FirebaseFirestore.instance;
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  static String? get _username => FirebaseAuth.instance.currentUser?.displayName
      ?? FirebaseAuth.instance.currentUser?.email?.split('@').first
      ?? 'Anonyme';
  static String? get _photoUrl => FirebaseAuth.instance.currentUser?.photoURL;

  // ── Posts ──────────────────────────────────────────────────────────────────

  static Stream<List<CommunityPost>> postsStream() {
    return _db.collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((s) => s.docs.map((d) => CommunityPost.fromMap(d.id, d.data())).toList());
  }

  static Future<void> createPost(String caption,
      {XFile? pickedFile, TerraScenario? scenario, String category = 'setup'}) async {
    if (_uid == null) return;

    // Lit les bytes de l'image (local, rapide) AVANT de créer le post
    Uint8List? bytes;
    String mime = 'image/jpeg';
    if (pickedFile != null) {
      bytes = await pickedFile.readAsBytes();
      mime = pickedFile.mimeType ?? 'image/jpeg';
    }

    // Un post avec scénario joint est toujours catégorie "scenario"
    final cat = scenario != null ? 'scenario' : category;

    // 1. Crée le post immédiatement → l'UI peut se fermer tout de suite
    final docRef = await _db.collection('posts').add({
      'uid': _uid,
      'username': _username,
      if (_photoUrl != null) 'authorPhotoUrl': _photoUrl,
      'caption': caption,
      'category': cat,
      'likes': 0,
      'likedBy': [],
      'commentCount': 0,
      if (scenario != null) 'scenario': {
        'name': scenario.name,
        'description': scenario.description,
        'triggerType': scenario.triggerType,
        if (scenario.triggerValue != null) 'triggerValue': scenario.triggerValue,
        if (scenario.scheduleTime != null) 'scheduleTime': scenario.scheduleTime,
        if (scenario.scheduleEnd != null) 'scheduleEnd': scenario.scheduleEnd,
        'actionType': scenario.actionType,
        'relay': scenario.relay,
      },
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Upload l'image en arrière-plan, puis met à jour le post (sans bloquer)
    if (bytes != null) {
      CloudinaryService.upload(bytes, mime).then((url) {
        if (url != null) docRef.update({'imageUrl': url});
      });
    }
  }

  static Future<void> toggleLike(String postId, List<String> likedBy) async {
    if (_uid == null) return;
    final ref = _db.collection('posts').doc(postId);
    if (likedBy.contains(_uid)) {
      await ref.update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([_uid]),
      });
    } else {
      await ref.update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([_uid]),
      });
    }
  }

  static Future<void> deletePost(String postId) async {
    if (_uid == null) return;
    await _db.collection('posts').doc(postId).delete();
  }

  static Future<void> editPost(String postId, String caption) async {
    if (_uid == null) return;
    await _db.collection('posts').doc(postId).update({'caption': caption});
  }

  /// Signale un post avec un motif. Un même utilisateur ne peut signaler
  /// qu'une fois un post donné (doc id = uid). L'incrément du compteur est
  /// « best-effort » : s'il est refusé par les règles, le signalement reste
  /// enregistré et l'utilisateur voit quand même une confirmation.
  static Future<void> reportPost(String postId, String reason, {String? details}) async {
    if (_uid == null) return;
    await _db.collection('posts').doc(postId).collection('reports').doc(_uid).set({
      'uid': _uid,
      'username': _username,
      'reason': reason,
      if (details != null && details.trim().isNotEmpty) 'details': details.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    try {
      await _db.collection('posts').doc(postId).update({
        'reportCount': FieldValue.increment(1),
      });
    } catch (_) {
      // Compteur non incrémenté (règles) — le signalement est tout de même enregistré.
    }
  }

  // ── Modération (admins) ─────────────────────────────────────────────────────

  /// Flux des posts signalés (reportCount > 0), les plus signalés en premier.
  static Stream<List<CommunityPost>> reportedPostsStream() {
    return _db.collection('posts')
        .where('reportCount', isGreaterThan: 0)
        .orderBy('reportCount', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => CommunityPost.fromMap(d.id, d.data())).toList());
  }

  /// Signalements détaillés d'un post donné.
  static Stream<List<PostReport>> reportsStream(String postId) {
    return _db.collection('posts').doc(postId).collection('reports')
        .snapshots()
        .map((s) => s.docs.map((d) => PostReport.fromMap(d.id, d.data())).toList());
  }

  /// Ignore les signalements d'un post : supprime les docs et remet le compteur à 0.
  static Future<void> clearReports(String postId) async {
    final reports = await _db.collection('posts').doc(postId).collection('reports').get();
    for (final d in reports.docs) {
      await d.reference.delete();
    }
    await _db.collection('posts').doc(postId).update({'reportCount': 0});
  }

  /// Met à jour le texte et/ou la photo d'un post.
  /// - [newImage] : nouvelle image à uploader (remplace l'existante)
  /// - [removeImage] : supprime la photo du post
  static Future<void> updatePost(
    String postId, {
    required String caption,
    XFile? newImage,
    bool removeImage = false,
  }) async {
    if (_uid == null) return;
    final ref = _db.collection('posts').doc(postId);

    // 1. Met à jour le texte tout de suite
    await ref.update({'caption': caption});

    // 2. Suppression de la photo
    if (removeImage) {
      await ref.update({'imageUrl': FieldValue.delete()});
      return;
    }

    // 3. Nouvelle photo → upload puis attache
    if (newImage != null) {
      final bytes = await newImage.readAsBytes();
      final mime = newImage.mimeType ?? 'image/jpeg';
      final url = await CloudinaryService.upload(bytes, mime);
      if (url != null) await ref.update({'imageUrl': url});
    }
  }

  // ── Commentaires ──────────────────────────────────────────────────────────

  static Stream<List<PostComment>> commentsStream(String postId) {
    return _db.collection('posts').doc(postId).collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map((d) => PostComment.fromMap(d.id, d.data())).toList());
  }

  static Future<void> deleteComment(String postId, String commentId) async {
    if (_uid == null) return;
    await _db.collection('posts').doc(postId).collection('comments').doc(commentId).delete();
    await _db.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(-1),
    });
  }

  static Future<void> addComment(String postId, String text) async {
    if (_uid == null || text.trim().isEmpty) return;
    await _db.collection('posts').doc(postId).collection('comments').add({
      'uid': _uid,
      'username': _username,
      if (_photoUrl != null) 'authorPhotoUrl': _photoUrl,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });
  }

  /// Importe un scénario joint à un post dans les scénarios de l'utilisateur.
  static Future<void> importSharedScenario(SharedScenario s) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).collection('scenarios')
        .add(s.toScenarioMap());
  }
}

// ── Modèles ──────────────────────────────────────────────────────────────────

class CommunityPost {
  final String id;
  final String uid;
  final String username;
  final String? authorPhotoUrl;
  final String caption;
  final String? imageUrl;
  final int likes;
  final int commentCount;
  final int reportCount;
  final List<String> likedBy;
  final DateTime? createdAt;
  final SharedScenario? scenario;
  final String category;

  const CommunityPost({
    required this.id, required this.uid, required this.username,
    required this.caption, this.imageUrl, required this.likes,
    required this.commentCount, required this.likedBy, this.createdAt,
    this.scenario, this.category = 'setup', this.reportCount = 0,
    this.authorPhotoUrl,
  });

  factory CommunityPost.fromMap(String id, Map<String, dynamic> m) => CommunityPost(
    id: id, uid: m['uid'] ?? '', username: m['username'] ?? 'Anonyme',
    authorPhotoUrl: m['authorPhotoUrl'],
    caption: m['caption'] ?? '',
    imageUrl: m['imageUrl'],
    likes: (m['likes'] as num?)?.toInt() ?? 0,
    commentCount: (m['commentCount'] as num?)?.toInt() ?? 0,
    reportCount: (m['reportCount'] as num?)?.toInt() ?? 0,
    likedBy: List<String>.from(m['likedBy'] ?? []),
    createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    scenario: m['scenario'] != null
        ? SharedScenario.fromMap(Map<String, dynamic>.from(m['scenario']))
        : null,
    category: m['category'] ?? (m['scenario'] != null ? 'scenario' : 'setup'),
  );

  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
    return '${createdAt!.day}/${createdAt!.month}';
  }
}

/// Scénario joint à un post communautaire (snapshot affichable + importable).
class SharedScenario {
  final String name, description, triggerType, actionType;
  final double? triggerValue;
  final String? scheduleTime, scheduleEnd;
  final int relay;

  const SharedScenario({
    required this.name, required this.description, required this.triggerType,
    required this.actionType, this.triggerValue, this.scheduleTime,
    this.scheduleEnd, required this.relay,
  });

  factory SharedScenario.fromMap(Map<String, dynamic> m) => SharedScenario(
    name: m['name'] ?? '',
    description: m['description'] ?? '',
    triggerType: m['triggerType'] ?? 'schedule',
    actionType: m['actionType'] ?? 'relay_on',
    triggerValue: (m['triggerValue'] as num?)?.toDouble(),
    scheduleTime: m['scheduleTime'],
    scheduleEnd: m['scheduleEnd'],
    relay: (m['relay'] as num?)?.toInt() ?? 1,
  );

  IconData get icon {
    if (triggerType.contains('temp')) return Icons.thermostat_outlined;
    if (triggerType.contains('humid')) return Icons.water_drop_outlined;
    return Icons.schedule_outlined;
  }

  Map<String, dynamic> toScenarioMap() => {
    'name': name,
    'triggerType': triggerType,
    if (triggerValue != null) 'triggerValue': triggerValue,
    if (scheduleTime != null) 'scheduleTime': scheduleTime,
    if (scheduleEnd != null) 'scheduleEnd': scheduleEnd,
    'actionType': actionType,
    'relay': relay,
    'enabled': true,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

class PostComment {
  final String id, uid, username, text;
  final String? authorPhotoUrl;
  final DateTime? createdAt;

  const PostComment({required this.id, required this.uid, required this.username,
      required this.text, this.authorPhotoUrl, this.createdAt});

  factory PostComment.fromMap(String id, Map<String, dynamic> m) => PostComment(
    id: id, uid: m['uid'] ?? '', username: m['username'] ?? 'Anonyme',
    authorPhotoUrl: m['authorPhotoUrl'],
    text: m['text'] ?? '',
    createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
  );

  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }
}

class PostReport {
  final String id, uid, username, reason;
  final String? details;
  final DateTime? createdAt;

  const PostReport({required this.id, required this.uid, required this.username,
      required this.reason, this.details, this.createdAt});

  factory PostReport.fromMap(String id, Map<String, dynamic> m) => PostReport(
    id: id, uid: m['uid'] ?? '', username: m['username'] ?? 'Anonyme',
    reason: m['reason'] ?? '—',
    details: m['details'],
    createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
  );
}

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'cloudinary_service.dart';
import 'scenario_service.dart';

/// Catégories de posts de la communauté.
class PostCategory {
  final String key;
  final String label;
  final IconData icon;
  const PostCategory(this.key, this.label, this.icon);

  /// Catégories sélectionnables à la création (hors "Tous").
  static const setup = PostCategory('setup', 'Setup', Icons.eco_outlined);
  static const scenario = PostCategory('scenario', 'Scénario', Icons.auto_awesome_outlined);
  static const question = PostCategory('question', 'Question', Icons.help_outline);
  static const tip = PostCategory('tip', 'Astuce', Icons.lightbulb_outline);

  static const all = [setup, scenario, question, tip];

  static PostCategory byKey(String key) =>
      all.firstWhere((c) => c.key == key, orElse: () => setup);
}

class CommunityService {
  static final _db = FirebaseFirestore.instance;
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  static String? get _username => FirebaseAuth.instance.currentUser?.displayName
      ?? FirebaseAuth.instance.currentUser?.email?.split('@').first
      ?? 'Anonyme';

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
  final String caption;
  final String? imageUrl;
  final int likes;
  final int commentCount;
  final List<String> likedBy;
  final DateTime? createdAt;
  final SharedScenario? scenario;
  final String category;

  const CommunityPost({
    required this.id, required this.uid, required this.username,
    required this.caption, this.imageUrl, required this.likes,
    required this.commentCount, required this.likedBy, this.createdAt,
    this.scenario, this.category = 'setup',
  });

  factory CommunityPost.fromMap(String id, Map<String, dynamic> m) => CommunityPost(
    id: id, uid: m['uid'] ?? '', username: m['username'] ?? 'Anonyme',
    caption: m['caption'] ?? '',
    imageUrl: m['imageUrl'],
    likes: (m['likes'] as num?)?.toInt() ?? 0,
    commentCount: (m['commentCount'] as num?)?.toInt() ?? 0,
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
  final DateTime? createdAt;

  const PostComment({required this.id, required this.uid, required this.username,
      required this.text, this.createdAt});

  factory PostComment.fromMap(String id, Map<String, dynamic> m) => PostComment(
    id: id, uid: m['uid'] ?? '', username: m['username'] ?? 'Anonyme',
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

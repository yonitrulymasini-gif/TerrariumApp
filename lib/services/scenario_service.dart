import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ScenarioService {
  static final _db = FirebaseFirestore.instance;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static CollectionReference get _col =>
      _db.collection('users').doc(_uid).collection('scenarios');

  static Stream<List<TerraScenario>> stream() {
    if (_uid == null) return const Stream.empty();
    return _col.orderBy('createdAt', descending: false).snapshots().map(
          (s) => s.docs.map((d) => TerraScenario.fromMap(d.id, d.data() as Map<String, dynamic>)).toList(),
        );
  }

  static Future<void> create(TerraScenario s) async {
    if (_uid == null) throw Exception('Utilisateur non connecté');
    await _col.doc(s.id).set(s.toMap())
        .timeout(const Duration(seconds: 10), onTimeout: () {
      throw Exception('Délai dépassé — vérifie ta connexion ou les règles Firestore');
    });
  }

  static Future<void> toggle(String id, bool enabled) async {
    await _col.doc(id).update({'enabled': enabled});
  }

  static Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}

class TerraScenario {
  final String id;
  final String name;
  final String triggerType; // 'temp_above' | 'temp_below' | 'humid_above' | 'humid_below' | 'schedule'
  final double? triggerValue;
  final String? scheduleTime; // 'HH:mm'
  final String? scheduleEnd;
  final String actionType; // 'relay_on' | 'relay_off'
  final int relay; // 1-4
  final bool enabled;

  const TerraScenario({
    required this.id,
    required this.name,
    required this.triggerType,
    this.triggerValue,
    this.scheduleTime,
    this.scheduleEnd,
    required this.actionType,
    required this.relay,
    this.enabled = true,
  });

  factory TerraScenario.fromMap(String id, Map<String, dynamic> m) => TerraScenario(
        id: id,
        name: m['name'] ?? '',
        triggerType: m['triggerType'] ?? 'schedule',
        triggerValue: (m['triggerValue'] as num?)?.toDouble(),
        scheduleTime: m['scheduleTime'],
        scheduleEnd: m['scheduleEnd'],
        actionType: m['actionType'] ?? 'relay_on',
        relay: (m['relay'] as num?)?.toInt() ?? 1,
        enabled: m['enabled'] ?? true,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'triggerType': triggerType,
        if (triggerValue != null) 'triggerValue': triggerValue,
        if (scheduleTime != null) 'scheduleTime': scheduleTime,
        if (scheduleEnd != null) 'scheduleEnd': scheduleEnd,
        'actionType': actionType,
        'relay': relay,
        'enabled': enabled,
        'createdAt': FieldValue.serverTimestamp(),
      };

  IconData get icon {
    switch (triggerType) {
      case 'temp_above':
      case 'temp_below': return Icons.thermostat_outlined;
      case 'humid_above':
      case 'humid_below': return Icons.water_drop_outlined;
      default: return Icons.schedule_outlined;
    }
  }

  String get description {
    switch (triggerType) {
      case 'temp_above': return 'Si T° > ${triggerValue?.toStringAsFixed(0)}°C → Prise $relay ${actionType == 'relay_on' ? 'ON' : 'OFF'}';
      case 'temp_below': return 'Si T° < ${triggerValue?.toStringAsFixed(0)}°C → Prise $relay ${actionType == 'relay_on' ? 'ON' : 'OFF'}';
      case 'humid_above': return 'Si humidité > ${triggerValue?.toStringAsFixed(0)}% → Prise $relay ${actionType == 'relay_on' ? 'ON' : 'OFF'}';
      case 'humid_below': return 'Si humidité < ${triggerValue?.toStringAsFixed(0)}% → Prise $relay ${actionType == 'relay_on' ? 'ON' : 'OFF'}';
      case 'schedule': return 'De $scheduleTime à $scheduleEnd → Prise $relay ${actionType == 'relay_on' ? 'ON' : 'OFF'}';
      default: return '';
    }
  }
}

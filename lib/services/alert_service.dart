import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'telemetry_service.dart';

/// Surveille la télémétrie et écrit des alertes dans Firestore quand hors plage.
/// Le backend (Cloud Function) lit ces alertes et envoie la notif FCM.
class AlertService {
  static final _db = FirebaseFirestore.instance;
  static final Map<String, StreamSubscription> _subs = {};

  static void watchDevice(String serialId, AlertThresholds thresholds) {
    _subs[serialId]?.cancel();
    _subs[serialId] = TelemetryService.stream(serialId).listen((data) {
      _check(serialId, data, thresholds);
    });
  }

  static void stopWatching(String serialId) {
    _subs[serialId]?.cancel();
    _subs.remove(serialId);
  }

  static Future<void> _check(
      String serialId, TelemetryData data, AlertThresholds t) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final alerts = <Map<String, dynamic>>[];

    if (data.temperature != null) {
      if (data.temperature! < t.tempMin) {
        alerts.add({'type': 'temp_low', 'value': data.temperature, 'threshold': t.tempMin});
      } else if (data.temperature! > t.tempMax) {
        alerts.add({'type': 'temp_high', 'value': data.temperature, 'threshold': t.tempMax});
      }
    }

    if (data.humidity != null) {
      if (data.humidity! < t.humidMin) {
        alerts.add({'type': 'humid_low', 'value': data.humidity, 'threshold': t.humidMin});
      } else if (data.humidity! > t.humidMax) {
        alerts.add({'type': 'humid_high', 'value': data.humidity, 'threshold': t.humidMax});
      }
    }

    for (final alert in alerts) {
      // Evite les doublons : vérifie si une alerte similaire existe dans les 10 dernières minutes
      final recent = await _db
          .collection('users')
          .doc(uid)
          .collection('alerts')
          .where('deviceId', isEqualTo: serialId)
          .where('type', isEqualTo: alert['type'])
          .where('createdAt', isGreaterThan: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(minutes: 10))))
          .limit(1)
          .get();

      if (recent.docs.isEmpty) {
        await _db.collection('users').doc(uid).collection('alerts').add({
          ...alert,
          'deviceId': serialId,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
    }
  }
}

class AlertThresholds {
  final double tempMin;
  final double tempMax;
  final double humidMin;
  final double humidMax;

  const AlertThresholds({
    this.tempMin = 18.0,
    this.tempMax = 35.0,
    this.humidMin = 40.0,
    this.humidMax = 90.0,
  });

  factory AlertThresholds.fromMap(Map<String, dynamic> map) => AlertThresholds(
        tempMin: (map['tempMin'] as num?)?.toDouble() ?? 18.0,
        tempMax: (map['tempMax'] as num?)?.toDouble() ?? 35.0,
        humidMin: (map['humidMin'] as num?)?.toDouble() ?? 40.0,
        humidMax: (map['humidMax'] as num?)?.toDouble() ?? 90.0,
      );

  Map<String, dynamic> toMap() => {
        'tempMin': tempMin, 'tempMax': tempMax,
        'humidMin': humidMin, 'humidMax': humidMax,
      };
}

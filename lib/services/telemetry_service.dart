import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_config.dart';

/// Stream les dernières mesures d'un device depuis Firestore.
/// L'ESP32 écrit dans : devices/{serialId}/telemetry (doc "latest")
/// En démo ([kDemoMode]), les mesures sont simulées localement.
class TelemetryService {
  static final _db = FirebaseFirestore.instance;

  static Stream<TelemetryData> stream(String serialId) {
    if (kDemoMode) return _demoStream();
    return _db
        .collection('devices')
        .doc(serialId)
        .collection('telemetry')
        .doc('latest')
        .snapshots()
        .map((snap) {
      if (!snap.exists) return TelemetryData.empty();
      return TelemetryData.fromMap(snap.data()!);
    });
  }

  /// Mesures simulées : marche aléatoire douce autour de valeurs réalistes.
  static Stream<TelemetryData> _demoStream() async* {
    final rnd = Random();
    double temp = 26.5;
    double humid = 65;
    final relays = <String, bool>{
      'relay1': true, 'relay2': false, 'relay3': true, 'relay4': false,
    };

    TelemetryData snapshot() => TelemetryData(
          temperature: temp,
          humidity: humid,
          updatedAt: DateTime.now(),
          relays: Map.of(relays),
        );

    yield snapshot(); // valeur immédiate
    while (true) {
      await Future.delayed(const Duration(seconds: 3));
      temp = (temp + (rnd.nextDouble() - 0.5) * 0.6).clamp(24.0, 30.0);
      humid = (humid + (rnd.nextDouble() - 0.5) * 3).clamp(55.0, 80.0);
      // De temps en temps, une prise change d'état
      if (rnd.nextInt(6) == 0) {
        final k = 'relay${rnd.nextInt(4) + 1}';
        relays[k] = !(relays[k] ?? false);
      }
      yield snapshot();
    }
  }
}

class TelemetryData {
  final double? temperature;
  final double? humidity;
  final DateTime? updatedAt;
  final Map<String, bool> relays; // ex: {'relay1': true, 'relay2': false}

  const TelemetryData({
    this.temperature,
    this.humidity,
    this.updatedAt,
    this.relays = const {},
  });

  factory TelemetryData.empty() => const TelemetryData();

  factory TelemetryData.fromMap(Map<String, dynamic> map) => TelemetryData(
        temperature: (map['temperature'] as num?)?.toDouble(),
        humidity: (map['humidity'] as num?)?.toDouble(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
        relays: Map<String, bool>.from(map['relays'] ?? {}),
      );

  String get tempDisplay => temperature != null ? temperature!.toStringAsFixed(1) : '—';
  String get humidDisplay => humidity != null ? humidity!.toStringAsFixed(0) : '—';

  /// Affichage d'une température dérivée (sondes), avec décalage.
  String tempWithOffset(double offset) =>
      temperature != null ? (temperature! + offset).toStringAsFixed(1) : '—';
}

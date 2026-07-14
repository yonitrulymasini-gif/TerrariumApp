import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_config.dart';

/// Stream les dernières mesures d'un device depuis Firestore.
/// L'ESP32 écrit dans : devices/{serialId}/telemetry (doc "latest")
/// En démo ([kDemoMode]), les mesures sont simulées localement.
class TelemetryService {
  static final _db = FirebaseFirestore.instance;

  /// Flux démo partagé : une seule simulation pour toute l'app (mêmes valeurs
  /// sur l'Accueil, les Mesures et les graphiques).
  static Stream<TelemetryData>? _demoShared;

  /// Dernière mesure émise (affichage instantané pour les nouveaux abonnés).
  static TelemetryData? latest;

  /// Historique des mesures, pour les graphiques (pré-simulé en démo, puis
  /// un point toutes les 3 s, plafonné).
  static final List<TelemetryData> history = [];
  static const _historyMax = 4000;

  static Stream<TelemetryData> stream(String serialId) async* {
    if (kDemoMode) {
      _demoShared ??= _demoStream().asBroadcastStream();
      if (latest != null) yield latest!;
      yield* _demoShared!;
      return;
    }
    yield* _db
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

    TelemetryData snapshot(DateTime at) => TelemetryData(
          temperature: temp,
          humidity: humid,
          updatedAt: at,
          relays: Map.of(relays),
        );

    // Modèle jour/nuit : plus chaud et plus sec en journée (pic ~14 h).
    double sunAt(DateTime t) {
      final h = t.hour + t.minute / 60.0;
      return max(0.0, sin(pi * (h - 7) / 14)); // lever 7 h, coucher 21 h
    }

    final now = DateTime.now();

    // En démo : 7 jours d'historique (1 point / 10 min) pour tester les
    // graphiques par date avant l'arrivée du vrai boîtier.
    for (var t = now.subtract(const Duration(days: 7));
        t.isBefore(now.subtract(const Duration(minutes: 30)));
        t = t.add(const Duration(minutes: 10))) {
      final sun = sunAt(t);
      temp = (25.0 + 2.6 * sun + (rnd.nextDouble() - 0.5) * 0.5).clamp(23.5, 30.0);
      humid = (71 - 9 * sun + (rnd.nextDouble() - 0.5) * 3).clamp(50.0, 85.0);
      history.add(snapshot(t));
    }

    // ~30 dernières minutes en points fins, dans la continuité du modèle.
    temp = (25.0 + 2.6 * sunAt(now)).clamp(23.5, 30.0);
    humid = (71 - 9 * sunAt(now)).clamp(50.0, 85.0);
    for (int i = 120; i > 0; i--) {
      temp = (temp + (rnd.nextDouble() - 0.5) * 0.4).clamp(24.0, 30.0);
      humid = (humid + (rnd.nextDouble() - 0.5) * 2).clamp(55.0, 80.0);
      history.add(snapshot(now.subtract(Duration(seconds: 15 * i))));
    }

    void push(TelemetryData d) {
      latest = d;
      history.add(d);
      if (history.length > _historyMax) {
        history.removeRange(0, history.length - _historyMax);
      }
    }

    final first = snapshot(DateTime.now());
    push(first);
    yield first; // valeur immédiate
    while (true) {
      await Future.delayed(const Duration(seconds: 3));
      temp = (temp + (rnd.nextDouble() - 0.5) * 0.6).clamp(24.0, 30.0);
      humid = (humid + (rnd.nextDouble() - 0.5) * 3).clamp(55.0, 80.0);
      // De temps en temps, une prise change d'état
      if (rnd.nextInt(6) == 0) {
        final k = 'relay${rnd.nextInt(4) + 1}';
        relays[k] = !(relays[k] ?? false);
      }
      final d = snapshot(DateTime.now());
      push(d);
      yield d;
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

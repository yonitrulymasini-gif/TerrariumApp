import 'package:cloud_firestore/cloud_firestore.dart';

/// Stream les dernières mesures d'un device depuis Firestore.
/// L'ESP32 écrit dans : devices/{serialId}/telemetry (doc "latest")
class TelemetryService {
  static final _db = FirebaseFirestore.instance;

  static Stream<TelemetryData> stream(String serialId) {
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
}

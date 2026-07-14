import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../app_config.dart';

class DeviceService extends ChangeNotifier {
  static final DeviceService _instance = DeviceService._();
  static DeviceService get instance => _instance;
  DeviceService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<TerraDevice> _devices = [];
  List<TerraDevice> get devices => List.unmodifiable(_devices);
  bool get hasDevice => _devices.isNotEmpty;

  // Prises partagées entre Accueil et Mesures
  final _outlets = [
    const OutletConfig(name: 'Prise 1'),
    const OutletConfig(name: 'Prise 2'),
    const OutletConfig(name: 'Prise 3'),
    const OutletConfig(name: 'Prise 4'),
  ];
  List<OutletConfig> get outlets => List.unmodifiable(_outlets);

  void setOutletState(int i, bool on) {
    _outlets[i] = _outlets[i].copyWith(on: on);
    notifyListeners();
  }

  void setOutletName(int i, String name) {
    if (name.trim().isEmpty) return;
    _outlets[i] = _outlets[i].copyWith(name: name.trim());
    notifyListeners();
  }

  /// Appeler au démarrage (après login) pour streamer les devices du user
  void startListening() {
    // En démo, on ne dépend pas de Firestore : la liste locale est gardée
    // telle quelle (sinon le snapshot l'écraserait).
    if (kDemoMode) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _db
        .collection('users')
        .doc(uid)
        .collection('devices')
        .snapshots()
        .listen((snap) {
      _devices = snap.docs.map((d) => TerraDevice.fromMap(d.id, d.data())).toList();
      notifyListeners();
    });
  }

  /// Appelé après appairage réussi
  Future<void> addDevice(TerraDevice device) async {
    // Ajout local immédiat : l'accueil voit l'appareil tout de suite, même si
    // l'utilisateur est anonyme ou si l'écriture Firestore échoue.
    if (!_devices.any((d) => d.serialId == device.serialId)) {
      _devices = [..._devices, device];
      notifyListeners();
    }

    if (kDemoMode) return; // pas d'écriture Firestore en démo

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(device.serialId)
        .set(device.toMap());
  }

  /// Renomme un terrarium (titre affiché).
  Future<void> setDeviceName(String serialId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    _devices = [
      for (final d in _devices)
        d.serialId == serialId ? d.copyWith(name: trimmed) : d,
    ];
    notifyListeners();

    if (kDemoMode) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(serialId)
        .update({'name': trimmed});
  }

  Future<void> removeDevice(String serialId) async {
    _devices = _devices.where((d) => d.serialId != serialId).toList();
    notifyListeners();

    if (kDemoMode) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(serialId)
        .delete();
  }
}

// ── Outlet (prise) ──────────────────────────────────────────────────────────

class OutletConfig {
  final String name;
  final bool on;
  const OutletConfig({required this.name, this.on = false});
  OutletConfig copyWith({String? name, bool? on}) =>
      OutletConfig(name: name ?? this.name, on: on ?? this.on);
}

// ── Device ──────────────────────────────────────────────────────────────────

class TerraDevice {
  final String serialId;
  final String name;
  final bool online;

  const TerraDevice({
    required this.serialId,
    required this.name,
    this.online = false,
  });

  TerraDevice copyWith({String? name, bool? online}) => TerraDevice(
        serialId: serialId,
        name: name ?? this.name,
        online: online ?? this.online,
      );

  factory TerraDevice.fromMap(String id, Map<String, dynamic> map) => TerraDevice(
        serialId: id,
        name: map['name'] ?? id,
        online: map['online'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'online': online,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

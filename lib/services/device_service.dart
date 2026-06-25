import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DeviceService extends ChangeNotifier {
  static final DeviceService _instance = DeviceService._();
  static DeviceService get instance => _instance;
  DeviceService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<TerraDevice> _devices = [];
  List<TerraDevice> get devices => List.unmodifiable(_devices);
  bool get hasDevice => _devices.isNotEmpty;

  /// Appeler au démarrage (après login) pour streamer les devices du user
  void startListening() {
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
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(device.serialId)
        .set(device.toMap());
  }

  Future<void> removeDevice(String serialId) async {
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

class TerraDevice {
  final String serialId;
  final String name;
  final bool online;

  const TerraDevice({
    required this.serialId,
    required this.name,
    this.online = false,
  });

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

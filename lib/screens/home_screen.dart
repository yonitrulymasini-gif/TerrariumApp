import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/device_service.dart';
import '../services/telemetry_service.dart';
import '../utils/fade_route.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../services/app_nav.dart';
import '../services/camera_service.dart';
import '../services/ptz_service.dart';
import 'alerts_screen.dart';
import 'pairing_screen.dart';
import 'qr_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    DeviceService.instance.addListener(_onDeviceChange);
  }

  @override
  void dispose() {
    DeviceService.instance.removeListener(_onDeviceChange);
    super.dispose();
  }

  void _onDeviceChange() => setState(() {});


  @override
  Widget build(BuildContext context) {
    if (!DeviceService.instance.hasDevice) {
      return _EmptyState();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 32, 0, 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bonjour', style: AppTextStyles.eyebrow),
                            const SizedBox(height: 4),
                            Text('Yoni', style: AppTextStyles.serif28),
                          ],
                        ),
                        StreamBuilder<int>(
                          stream: AlertsScreen.unreadCount(),
                          builder: (ctx, snap) {
                            final count = snap.data ?? 0;
                            return GestureDetector(
                              onTap: () => Navigator.of(context).push(fadeRoute(const AlertsScreen())),
                              child: Stack(children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: glassCard(radius: 22),
                                  child: Icon(Icons.notifications_outlined,
                                      color: ThemeService.instance.colors.textPrimary, size: 20),
                                ),
                                if (count > 0) Positioned(
                                  top: 8, right: 8,
                                  child: Container(
                                    width: count > 9 ? 18 : 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(7),
                                      border: Border.all(color: ThemeService.instance.colors.bg, width: 1.5),
                                    ),
                                    child: Center(child: Text(
                                      count > 9 ? '9+' : '$count',
                                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: ThemeService.instance.colors.bg),
                                    )),
                                  ),
                                ),
                              ]),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Carte terrarium
                  _TerrariumCard(device: DeviceService.instance.devices.first),
                  const SizedBox(height: 20),

                  // Caméra
                  _CameraCard(),
                  const SizedBox(height: 20),

                  // Prises rapides
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PRISES RAPIDES', style: AppTextStyles.eyebrow),
                      GestureDetector(
                        onTap: () => AppNav.instance.goToTab(1),
                        child: Text('Tout voir',
                            style: TextStyle(fontSize: 13, color: ThemeService.instance.colors.primary, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.1,
                    ),
                    itemCount: DeviceService.instance.outlets.length,
                    itemBuilder: (_, i) {
                      final o = DeviceService.instance.outlets[i];
                      final isOn = o.on;
                      return GestureDetector(
                        onTap: () => DeviceService.instance.setOutletState(i, !isOn),
                        child: Container(
                          decoration: glassCard(radius: 20).copyWith(
                            border: isOn
                                ? Border.all(color: ThemeService.instance.colors.primary.withValues(alpha: 0.4))
                                : Border.all(color: AppColors.border, width: 1),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: isOn
                                      ? ThemeService.instance.colors.primary.withValues(alpha: 0.20)
                                      : Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.power_outlined, size: 18,
                                    color: isOn ? ThemeService.instance.colors.primary : ThemeService.instance.colors.textMuted),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(o.name,
                                        style: TextStyle(fontSize: 13, color: ThemeService.instance.colors.textPrimary, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 2),
                                    Text(isOn ? 'Allumé' : 'Éteint',
                                        style: TextStyle(fontSize: 11, color: ThemeService.instance.colors.textMuted)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // CTA ajouter terrarium
                  Container(
                    width: double.infinity,
                    decoration: glassCard(radius: 24),
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 0),
                    child: Column(
                      children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: ThemeService.instance.colors.primary.withValues(alpha: 0.15),
                          ),
                          child: Icon(Icons.add, color: ThemeService.instance.colors.primary, size: 24),
                        ),
                        const SizedBox(height: 12),
                        Text('Ajoute un autre terrarium',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: ThemeService.instance.colors.textPrimary, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text('Connecte ton ESP32 pour démarrer la surveillance',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: ThemeService.instance.colors.textMuted, height: 1.6)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: ThemeService.instance.colors.primary,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: ThemeService.instance.colors.primary.withValues(alpha: 0.25),
                                blurRadius: 16, offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Text('Configurer',
                              style: GoogleFonts.inter(
                                fontSize: 14, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.bg)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TerrariumCard extends StatelessWidget {
  final TerraDevice device;
  const _TerrariumCard({required this.device});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TelemetryData>(
      stream: TelemetryService.stream(device.serialId),
      builder: (context, snap) {
        final data = snap.data ?? TelemetryData.empty();
        final online = device.online;

        return Container(
          decoration: glassCard(radius: 24),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: online ? ThemeService.instance.colors.primary : ThemeService.instance.colors.textMuted,
                      boxShadow: online ? [BoxShadow(color: ThemeService.instance.colors.primary.withValues(alpha: 0.6), blurRadius: 8)] : [],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(online ? 'En ligne' : 'Hors ligne',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                          color: online ? ThemeService.instance.colors.primary : ThemeService.instance.colors.textMuted)),
                ]),
                Text(device.name, style: TextStyle(fontSize: 12, color: ThemeService.instance.colors.textMuted)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Row(children: [
                Icon(Icons.eco_outlined, color: ThemeService.instance.colors.primary, size: 22),
                const SizedBox(width: 10),
                Text('Jungle tropicale',
                    style: GoogleFonts.fraunces(fontSize: 22, color: ThemeService.instance.colors.textPrimary, fontWeight: FontWeight.w600)),
              ]),
            ),
            Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x18507850)))),
              child: Row(children: [
                Expanded(child: _MetricCell(
                  icon: Icons.thermostat_outlined,
                  iconColor: const Color(0xFFFB923C),
                  label: 'TEMPÉRATURE',
                  value: data.tempDisplay, unit: '°C',
                )),
                Container(width: 1, color: AppColors.borderLight),
                Expanded(child: _MetricCell(
                  icon: Icons.water_drop_outlined,
                  iconColor: const Color(0xFF38BDF8),
                  label: 'HUMIDITÉ',
                  value: data.humidDisplay, unit: '%',
                )),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

class _MetricCell extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;

  const _MetricCell({required this.icon, required this.iconColor, required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 10, color: ThemeService.instance.colors.textMuted, fontWeight: FontWeight.w500, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: GoogleFonts.fraunces(fontSize: 32, color: ThemeService.instance.colors.textPrimary, fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              Text(unit, style: TextStyle(fontSize: 13, color: ThemeService.instance.colors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Carte caméra ────────────────────────────────────────────────────────────

class _CameraCard extends StatefulWidget {
  _CameraCard();

  @override
  State<_CameraCard> createState() => _CameraCardState();
}

class _CameraCardState extends State<_CameraCard> with WidgetsBindingObserver {
  Player? _player;
  VideoController? _controller;
  String? _activeUrl;
  String? _error;
  bool _buffering = false;
  StreamSubscription? _errorSub;
  StreamSubscription? _bufferingSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    CameraService.instance.addListener(_onCameraChange);
    _initPlayer(CameraService.instance.rtspUrl);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    CameraService.instance.removeListener(_onCameraChange);
    _errorSub?.cancel();
    _bufferingSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Au retour dans l'app, le flux RTSP est tombé → on recharge.
    if (state == AppLifecycleState.resumed) _reload();
  }

  void _onCameraChange() {
    final url = CameraService.instance.rtspUrl;
    if (url != _activeUrl) _initPlayer(url);
  }

  /// Recharge le flux sur le MÊME lecteur (garde le controller valide pour le
  /// plein écran). Recrée le lecteur seulement s'il n'existe pas encore.
  Future<void> _reload() async {
    final player = _player;
    final url = _activeUrl;
    if (url == null || url.isEmpty) return;
    if (player == null) { await _initPlayer(url); return; }
    if (mounted) setState(() => _error = null);
    try {
      await player.open(Media(url));
    } catch (_) {
      await _initPlayer(url);
    }
  }

  Future<void> _initPlayer(String? url) async {
    await _errorSub?.cancel();
    await _bufferingSub?.cancel();
    await _player?.dispose();
    _player = null;
    _controller = null;
    _error = null;
    _buffering = false;
    _activeUrl = url;

    if (url == null || url.isEmpty) {
      if (mounted) setState(() {});
      return;
    }

    final player = Player();
    final controller = VideoController(player);

    // Force le RTSP en TCP (natif uniquement) : l'UDP passe mal sur le WiFi
    // → écran noir. Sur le web, media_kit n'expose pas setProperty et le RTSP
    // n'est pas supporté par le navigateur de toute façon — on saute.
    if (!kIsWeb) {
      try {
        final platform = player.platform as dynamic;
        await platform.setProperty('rtsp-transport', 'tcp');
        await platform.setProperty('network-timeout', '15');
      } catch (_) {}
    }

    _errorSub = player.stream.error.listen((e) {
      if (mounted) setState(() => _error = e);
    });
    _bufferingSub = player.stream.buffering.listen((b) {
      if (mounted) setState(() => _buffering = b);
    });

    if (mounted) setState(() { _player = player; _controller = controller; });
    await player.open(Media(url));
  }

  void _retry() => _reload();

  Future<void> _showUrlDialog() async {
    final ctrl = TextEditingController(text: CameraService.instance.rtspUrl ?? '');
    final c = ThemeService.instance.colors;
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.card,
        title: Text('URL RTSP de la caméra', style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Exemple :', style: TextStyle(fontSize: 12, color: c.textMuted)),
          const SizedBox(height: 2),
          Text('rtsp://192.168.1.100:554/stream', style: TextStyle(fontSize: 11, color: c.textMuted, fontFamily: 'monospace')),
          const SizedBox(height: 14),
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.url,
            style: TextStyle(color: c.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'rtsp://...',
              hintStyle: TextStyle(color: c.textMuted),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: c.border)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: c.primary)),
            ),
          ),
        ]),
        actions: [
          if (CameraService.instance.hasCamera)
            TextButton(
              onPressed: () { CameraService.instance.clear(); Navigator.pop(context); },
              child: Text('Supprimer', style: TextStyle(color: AppColors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: c.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: Text('OK', style: TextStyle(color: c.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null) await CameraService.instance.setUrl(result);
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeService.instance.colors;
    final hasStream = _controller != null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('CAMÉRA', style: AppTextStyles.eyebrow),
        GestureDetector(
          onTap: _showUrlDialog,
          child: Text(
            hasStream ? 'Changer' : 'Configurer',
            style: TextStyle(fontSize: 13, color: c.primary, fontWeight: FontWeight.w500),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          height: 210,
          decoration: glassCard(radius: 20),
          child: hasStream ? _buildStream(c) : _buildPlaceholder(c),
        ),
      ),
      // Barre de contrôle SOUS la vidéo (vue dégagée).
      if (hasStream && _error == null) ...[
        const SizedBox(height: 12),
        _controlBar(c),
      ],
    ]);
  }

  Widget _controlBar(dynamic c) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      _PtzPad(onMove: _ptzMove, size: 78, iconColor: c.textPrimary, bgColor: c.card),
      Row(children: [
        _ctrlBtn(Icons.refresh, _reload, c),
        const SizedBox(width: 10),
        _ctrlBtn(Icons.camera_alt_outlined, _capture, c),
        const SizedBox(width: 10),
        _ctrlBtn(Icons.fullscreen, _openFullscreen, c),
      ]),
    ]);
  }

  Widget _ctrlBtn(IconData icon, VoidCallback onTap, dynamic c) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 46, height: 46,
      decoration: BoxDecoration(color: c.card, shape: BoxShape.circle, border: Border.all(color: c.border)),
      child: Icon(icon, color: c.textPrimary, size: 21),
    ),
  );

  void _openFullscreen() {
    if (_controller == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _CameraFullscreenPage(controller: _controller!, onCapture: _capture, onPtz: _ptzMove, onRefresh: _reload),
      fullscreenDialog: true,
    ));
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ThemeService.instance.colors.card,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _capture() async {
    final player = _player;
    if (player == null) return;
    try {
      final bytes = await player.screenshot();
      if (bytes == null) { _toast('Capture impossible'); return; }
      await Gal.putImageBytes(bytes, name: 'terra_${DateTime.now().millisecondsSinceEpoch}');
      _toast('Capture enregistrée dans Photos 📷');
    } on GalException {
      _toast('Autorise l\'accès aux Photos dans Réglages');
    } catch (_) {
      _toast('Capture impossible');
    }
  }

  bool _ptzBusy = false;
  Future<void> _ptzMove(String dir) async {
    if (_ptzBusy) return;
    _ptzBusy = true;
    try {
      final url = CameraService.instance.rtspUrl;
      if (url == null) return;
      if (!PtzService.instance.isReady) {
        final ok = await PtzService.instance.connectFromRtsp(url);
        if (!ok) { _toast('PTZ : ${PtzService.instance.lastError ?? "connexion impossible"}'); return; }
      }
      bool moved;
      switch (dir) {
        case 'up': moved = await PtzService.instance.up(); break;
        case 'down': moved = await PtzService.instance.down(); break;
        case 'left': moved = await PtzService.instance.left(); break;
        default: moved = await PtzService.instance.right(); break;
      }
      if (!moved) _toast('PTZ : ${PtzService.instance.lastError ?? "mouvement refusé"}');
    } finally {
      _ptzBusy = false;
    }
  }

  Widget _buildStream(dynamic c) {
    return Stack(children: [
      // BoxFit.cover : remplit toute la carte sans bandes noires (recadre un peu).
      Positioned.fill(
        child: ColoredBox(
          color: Colors.black,
          child: Video(controller: _controller!, controls: NoVideoControls, fit: BoxFit.cover),
        ),
      ),

      // Spinner de connexion
      if (_buffering && _error == null)
        Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: c.primary, strokeWidth: 2.5),
          const SizedBox(height: 12),
          const Text('Connexion à la caméra…', style: TextStyle(fontSize: 12, color: Colors.white60)),
        ])),

      // Overlay d'erreur
      if (_error != null)
        Positioned.fill(child: Container(
          color: Colors.black.withValues(alpha: 0.9),
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.videocam_off_outlined, color: AppColors.red, size: 32),
            const SizedBox(height: 10),
            const Text('Flux indisponible', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(_error!, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.white54)),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _retry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(20)),
                child: Text('Réessayer', style: TextStyle(fontSize: 13, color: c.bg, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        )),

      // Badge LIVE (seul élément sur la vidéo)
      if (_error == null) Positioned(
        top: 10, left: 10,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: c.primary)),
            const SizedBox(width: 5),
            const Text('LIVE', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildPlaceholder(dynamic c) {
    return Stack(children: [
      Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.85))),
      Positioned.fill(child: CustomPaint(painter: _GridPainter(color: Colors.white.withValues(alpha: 0.05)))),
      Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.primary.withValues(alpha: 0.15),
            border: Border.all(color: c.primary.withValues(alpha: 0.35), width: 1.5),
          ),
          child: Icon(Icons.videocam_outlined, color: c.primary, size: 26),
        ),
        const SizedBox(height: 10),
        const Text('Aucune caméra configurée', style: TextStyle(fontSize: 13, color: Colors.white60, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        const Text('Appuie sur "Configurer" pour ajouter l\'URL RTSP', style: TextStyle(fontSize: 11, color: Colors.white38)),
      ])),
    ]);
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 0.5;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(Offset(0, size.height * i / 3), Offset(size.width, size.height * i / 3), p);
      canvas.drawLine(Offset(size.width * i / 3, 0), Offset(size.width * i / 3, size.height), p);
    }
  }
  @override
  bool shouldRepaint(_GridPainter old) => old.color != color;
}

// ── D-pad d'orientation PTZ ──────────────────────────────────────────────────

class _PtzPad extends StatelessWidget {
  final Future<void> Function(String dir) onMove;
  final double size;
  final Color iconColor;
  final Color bgColor;
  const _PtzPad({required this.onMove, this.size = 96,
      this.iconColor = Colors.white, this.bgColor = const Color(0x73000000)});

  @override
  Widget build(BuildContext context) {
    final btn = size / 3;
    Widget arrow(String dir, IconData icon, Alignment align) => Align(
      alignment: align,
      child: GestureDetector(
        onTap: () => onMove(dir),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(width: btn, height: btn, child: Icon(icon, color: iconColor, size: 20)),
      ),
    );
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: bgColor, shape: BoxShape.circle,
        border: Border.all(color: iconColor.withValues(alpha: 0.18)),
      ),
      child: Stack(children: [
        arrow('up', Icons.keyboard_arrow_up, Alignment.topCenter),
        arrow('down', Icons.keyboard_arrow_down, Alignment.bottomCenter),
        arrow('left', Icons.keyboard_arrow_left, Alignment.centerLeft),
        arrow('right', Icons.keyboard_arrow_right, Alignment.centerRight),
        Align(alignment: Alignment.center, child: Container(
          width: btn * 0.5, height: btn * 0.5,
          decoration: BoxDecoration(shape: BoxShape.circle, color: iconColor.withValues(alpha: 0.25)),
        )),
      ]),
    );
  }
}

// ── Caméra plein écran ──────────────────────────────────────────────────────

class _CameraFullscreenPage extends StatefulWidget {
  final VideoController controller;
  final Future<void> Function() onCapture;
  final Future<void> Function(String dir) onPtz;
  final Future<void> Function() onRefresh;
  const _CameraFullscreenPage({required this.controller, required this.onCapture, required this.onPtz, required this.onRefresh});

  @override
  State<_CameraFullscreenPage> createState() => _CameraFullscreenPageState();
}

class _CameraFullscreenPageState extends State<_CameraFullscreenPage> {
  @override
  void initState() {
    super.initState();
    // Autorise le paysage + masque les barres système pour un vrai plein écran.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restaure le verrouillage portrait de l'app.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Positioned.fill(
          child: Video(controller: widget.controller, controls: NoVideoControls, fit: BoxFit.contain),
        ),
        // Fermer
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),
        ),
        // D-pad orientation (bas gauche)
        Positioned(bottom: 24, left: 24, child: SafeArea(child: _PtzPad(onMove: widget.onPtz, size: 120))),
        // Refresh (haut droite)
        SafeArea(child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: GestureDetector(
              onTap: widget.onRefresh,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.refresh, color: Colors.white, size: 24),
              ),
            ),
          ),
        )),
        // Capture (bas droite)
        Positioned(bottom: 24, right: 24, child: SafeArea(child: GestureDetector(
          onTap: widget.onCapture,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 26),
          ),
        ))),
      ]),
    );
  }
}

// ── Empty state (aucun device associé) ──────────────────────────────────────

class _EmptyState extends StatelessWidget {
  // Pas de const : ce widget lit le thème et doit pouvoir se reconstruire.
  // ignore: prefer_const_constructors_in_immutables
  _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 120),
          child: Column(children: [
            // Header
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ACCUEIL', style: AppTextStyles.eyebrow),
                const SizedBox(height: 4),
                Text('Tableau de bord', style: AppTextStyles.serif28),
              ]),
            ]),

            const Spacer(),

            // Illustration centrale
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ThemeService.instance.colors.primary.withValues(alpha: 0.10),
                border: Border.all(color: ThemeService.instance.colors.primary.withValues(alpha: 0.25), width: 2),
              ),
              child: Icon(Icons.eco_outlined, size: 48, color: ThemeService.instance.colors.primary.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 28),
            Text('Connecte ton Terra', style: AppTextStyles.serif28),
            const SizedBox(height: 12),
            Text(
              'Scan le QR code dans ta boîte\npour appairer ton boîtier.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: ThemeService.instance.colors.textMuted, height: 1.7),
            ),

            const Spacer(),

            // CTA principal
            GestureDetector(
              onTap: () => Navigator.of(context).push(fadeRoute(const PairingScreen())),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: ThemeService.instance.colors.primary,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [BoxShadow(
                    color: ThemeService.instance.colors.primary.withValues(alpha: 0.3),
                    blurRadius: 20, offset: const Offset(0, 6),
                  )],
                ),
                child: Text('Connecter un appareil',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.bg)),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () async {
                final deviceId = await Navigator.of(context).push<String>(
                  MaterialPageRoute(builder: (_) => const QrScannerScreen(), fullscreenDialog: true),
                );
                if (deviceId != null && context.mounted) {
                  Navigator.of(context).push(fadeRoute(PairingScreen(prefillDeviceId: deviceId)));
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 17),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: ThemeService.instance.colors.border),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.qr_code_scanner, color: ThemeService.instance.colors.textSecondary, size: 18),
                  const SizedBox(width: 10),
                  Text('Scanner le QR code', style: TextStyle(fontSize: 15, color: ThemeService.instance.colors.textSecondary)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

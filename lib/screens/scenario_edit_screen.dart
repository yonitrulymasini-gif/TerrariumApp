import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/scenario_service.dart';
import '../widgets/time_wheel_picker.dart';
import '../widgets/terra_confirm_dialog.dart';

class ScenarioEditScreen extends StatefulWidget {
  final TerraScenario? existing;
  const ScenarioEditScreen({super.key, this.existing});

  @override
  State<ScenarioEditScreen> createState() => _ScenarioEditScreenState();
}

class _ScenarioEditScreenState extends State<ScenarioEditScreen> {
  final _nameCtrl = TextEditingController();
  bool _nameError = false;
  String _triggerType = 'temp_above';
  double _triggerValue = 28;
  TimeOfDay _scheduleStart = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _scheduleEnd = const TimeOfDay(hour: 20, minute: 0);
  String _actionType = 'relay_on';
  int _relay = 1;
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    if (s != null) {
      _nameCtrl.text = s.name;
      _triggerType = s.triggerType;
      _triggerValue = s.triggerValue ?? 28;
      _actionType = s.actionType;
      _relay = s.relay;
      if (s.scheduleTime != null) _scheduleStart = _parseTime(s.scheduleTime!);
      if (s.scheduleEnd != null) _scheduleEnd = _parseTime(s.scheduleEnd!);
    }
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _nameError = true);
      return;
    }
    setState(() => _saving = true);
    try {
      final scenario = TerraScenario(
        id: widget.existing?.id ?? const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        triggerType: _triggerType,
        triggerValue: _triggerType != 'schedule' ? _triggerValue : null,
        scheduleTime: _triggerType == 'schedule' ? _formatTime(_scheduleStart) : null,
        scheduleEnd: _triggerType == 'schedule' ? _formatTime(_scheduleEnd) : null,
        actionType: _actionType,
        relay: _relay,
      );
      await ScenarioService.create(scenario);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showTerraConfirmDialog(
      context,
      icon: Icons.delete_outline,
      title: 'Supprimer\nle scénario ?',
      message: '« ${widget.existing!.name} » sera définitivement supprimé.',
      confirmLabel: 'Supprimer',
      cancelLabel: 'Le garder',
      destructive: true,
    );
    if (confirm != true) return;

    setState(() => _deleting = true);
    try {
      await ScenarioService.delete(widget.existing!.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeService.instance.colors.bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Text('Annuler', style: TextStyle(color: ThemeService.instance.colors.textSecondary, fontSize: 14)),
              ),
              const Spacer(),
              Text(widget.existing == null ? 'Nouveau scénario' : 'Modifier',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.textPrimary)),
              const Spacer(),
              GestureDetector(
                onTap: _saving ? null : _save,
                child: _saving
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    : Text('Sauver', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Nom
                Text('NOM', style: AppTextStyles.eyebrow),
                const SizedBox(height: 10),
                _Input(
                  ctrl: _nameCtrl,
                  hint: 'Cycle jour, Brumisation…',
                  error: _nameError,
                  onChanged: (_) { if (_nameError) setState(() => _nameError = false); },
                ),
                if (_nameError) ...[
                  const SizedBox(height: 6),
                  const Text('Le nom est obligatoire',
                      style: TextStyle(fontSize: 12, color: AppColors.red)),
                ],
                const SizedBox(height: 28),

                // Déclencheur
                Text('DÉCLENCHEUR', style: AppTextStyles.eyebrow),
                const SizedBox(height: 10),
                _SegmentRow(
                  options: const [
                    ('Temp °C', 'temp_above'),
                    ('Humidité', 'humid_above'),
                    ('Heure', 'schedule'),
                  ],
                  selected: _triggerType.contains('temp') ? 'temp_above'
                      : _triggerType.contains('humid') ? 'humid_above' : 'schedule',
                  onSelect: (v) => setState(() {
                    _triggerType = v;
                    if (v == 'temp_above') _triggerValue = 28;
                    if (v == 'humid_above') _triggerValue = 70;
                  }),
                ),
                const SizedBox(height: 16),

                if (_triggerType != 'schedule') ...[
                  // Condition : au-dessus / en-dessous
                  Row(children: [
                    _Chip(label: 'Au-dessus de', selected: _triggerType.endsWith('above'),
                        onTap: () => setState(() => _triggerType = _triggerType.contains('temp') ? 'temp_above' : 'humid_above')),
                    const SizedBox(width: 10),
                    _Chip(label: 'En-dessous de', selected: _triggerType.endsWith('below'),
                        onTap: () => setState(() => _triggerType = _triggerType.contains('temp') ? 'temp_below' : 'humid_below')),
                  ]),
                  const SizedBox(height: 16),
                  // Valeur slider
                  _SliderRow(
                    value: _triggerValue,
                    min: _triggerType.contains('temp') ? 15 : 20,
                    max: _triggerType.contains('temp') ? 40 : 95,
                    unit: _triggerType.contains('temp') ? '°C' : '%',
                    onChanged: (v) => setState(() => _triggerValue = v),
                  ),
                ] else ...[
                  // Plage horaire
                  Row(children: [
                    Expanded(child: _TimeButton(
                      label: 'Début', time: _scheduleStart,
                      onTap: () async {
                        final t = await showTimeWheelPicker(context, _scheduleStart);
                        if (t != null) setState(() => _scheduleStart = t);
                      },
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _TimeButton(
                      label: 'Fin', time: _scheduleEnd,
                      onTap: () async {
                        final t = await showTimeWheelPicker(context, _scheduleEnd);
                        if (t != null) setState(() => _scheduleEnd = t);
                      },
                    )),
                  ]),
                ],
                const SizedBox(height: 28),

                // Action
                Text('ACTION', style: AppTextStyles.eyebrow),
                const SizedBox(height: 10),
                Row(children: [
                  _Chip(label: 'Allumer', selected: _actionType == 'relay_on',
                      onTap: () => setState(() => _actionType = 'relay_on')),
                  const SizedBox(width: 10),
                  _Chip(label: 'Éteindre', selected: _actionType == 'relay_off',
                      onTap: () => setState(() => _actionType = 'relay_off')),
                ]),
                const SizedBox(height: 16),
                Text('PRISE', style: AppTextStyles.eyebrow),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: List.generate(4, (i) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _Chip(label: 'Prise ${i + 1}', selected: _relay == i + 1,
                        onTap: () => setState(() => _relay = i + 1)),
                  ))),
                ),
                const SizedBox(height: 36),

                // Résumé
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: glassCard(radius: 18),
                  child: Row(children: [
                    Icon(Icons.auto_awesome_outlined, color: AppColors.accent, size: 18),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_buildSummary(),
                        style: TextStyle(fontSize: 13, color: ThemeService.instance.colors.textSecondary, height: 1.5))),
                  ]),
                ),

                // Supprimer (édition uniquement)
                if (widget.existing != null) ...[
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _deleting ? null : _confirmDelete,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                      ),
                      child: _deleting
                          ? const Center(child: SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.red)))
                          : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.delete_outline, color: AppColors.red, size: 18),
                              SizedBox(width: 8),
                              Text('Supprimer le scénario',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.red)),
                            ]),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  String _buildSummary() {
    final name = _nameCtrl.text.isEmpty ? 'Ce scénario' : '"${_nameCtrl.text}"';
    final action = _actionType == 'relay_on' ? 'allume' : 'éteint';
    if (_triggerType == 'schedule') {
      return '$name $action la Prise $_relay de ${_formatTime(_scheduleStart)} à ${_formatTime(_scheduleEnd)}.';
    }
    final cond = _triggerType.endsWith('above') ? 'dépasse' : 'descend sous';
    final sensor = _triggerType.contains('temp') ? 'la température' : 'l\'humidité';
    final unit = _triggerType.contains('temp') ? '°C' : '%';
    return '$name $action la Prise $_relay quand $sensor $cond ${_triggerValue.toStringAsFixed(0)}$unit.';
  }
}

// ── Widgets ─────────────────────────────────────────────────────────────────

class _Input extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool error;
  final ValueChanged<String>? onChanged;
  const _Input({required this.ctrl, required this.hint, this.error = false, this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: ThemeService.instance.colors.card,
      borderRadius: BorderRadius.circular(50),
      border: Border.all(color: error ? AppColors.red : ThemeService.instance.colors.border),
    ),
    child: TextField(
      controller: ctrl,
      onChanged: onChanged,
      style: TextStyle(color: ThemeService.instance.colors.textPrimary, fontSize: 15),
      decoration: InputDecoration(hintText: hint,
          hintStyle: TextStyle(color: ThemeService.instance.colors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17)),
    ),
  );
}

class _SegmentRow extends StatelessWidget {
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onSelect;
  const _SegmentRow({required this.options, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: ThemeService.instance.colors.card, borderRadius: BorderRadius.circular(50),
        border: Border.all(color: ThemeService.instance.colors.border)),
    padding: const EdgeInsets.all(4),
    child: Row(children: options.map((o) {
      final active = selected == o.$2;
      return Expanded(child: GestureDetector(
        onTap: () => onSelect(o.$2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(o.$1, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                  color: active ? ThemeService.instance.colors.bg : ThemeService.instance.colors.textMuted)),
        ),
      ));
    }).toList()),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withValues(alpha: 0.15) : ThemeService.instance.colors.card,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: selected ? AppColors.primary.withValues(alpha: 0.5) : ThemeService.instance.colors.border),
      ),
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
          color: selected ? AppColors.primary : ThemeService.instance.colors.textMuted)),
    ),
  );
}

class _SliderRow extends StatelessWidget {
  final double value, min, max;
  final String unit;
  final ValueChanged<double> onChanged;
  const _SliderRow({required this.value, required this.min, required this.max, required this.unit, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Text('${value.toStringAsFixed(0)}$unit',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.textPrimary)),
    ]),
    SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: ThemeService.instance.colors.border,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: 0.15),
        trackHeight: 4,
      ),
      child: Slider(value: value, min: min, max: max, onChanged: onChanged),
    ),
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('${min.toStringAsFixed(0)}$unit', style: TextStyle(fontSize: 11, color: ThemeService.instance.colors.textMuted)),
      Text('${max.toStringAsFixed(0)}$unit', style: TextStyle(fontSize: 11, color: ThemeService.instance.colors.textMuted)),
    ]),
  ]);
}

class _TimeButton extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimeButton({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: ThemeService.instance.colors.card, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ThemeService.instance.colors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: ThemeService.instance.colors.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: ThemeService.instance.colors.textPrimary)),
      ]),
    ),
  );
}

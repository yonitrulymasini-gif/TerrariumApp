import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

Future<TimeOfDay?> showTimeWheelPicker(BuildContext context, TimeOfDay initial) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _TimeWheelSheet(initial: initial),
  );
}

class _TimeWheelSheet extends StatefulWidget {
  final TimeOfDay initial;
  const _TimeWheelSheet({required this.initial});

  @override
  State<_TimeWheelSheet> createState() => _TimeWheelSheetState();
}

class _TimeWheelSheetState extends State<_TimeWheelSheet> {
  late int _hour;
  late int _minute;
  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minCtrl;

  static const _loopCount = 10000;

  @override
  void initState() {
    super.initState();
    _hour = widget.initial.hour;
    _minute = widget.initial.minute;
    // On démarre au milieu du loop pour pouvoir scroller dans les deux sens
    _hourCtrl = FixedExtentScrollController(initialItem: (_loopCount ~/ 2 ~/ 24) * 24 + _hour);
    _minCtrl = FixedExtentScrollController(initialItem: (_loopCount ~/ 2 ~/ 60) * 60 + _minute);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF131F16),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),

          Text('Choisir l\'heure',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 28),

          // Labels h / min
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(width: 90, child: Center(child: Text('Heure',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted, letterSpacing: 1)))),
            const SizedBox(width: 32),
            SizedBox(width: 90, child: Center(child: Text('Minute',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted, letterSpacing: 1)))),
          ]),
          const SizedBox(height: 6),

          // Wheels
          SizedBox(
            height: 168,
            child: Stack(alignment: Alignment.center, children: [
              // Highlight du milieu
              Container(
                height: 52,
                width: 240,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
              ),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 90, child: _WheelPicker(
                  count: _loopCount, mod: 24, controller: _hourCtrl, selected: _hour,
                  onSelected: (v) => setState(() => _hour = v % 24),
                )),
                SizedBox(width: 32, child: Center(
                  child: Text(':', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700,
                      color: AppColors.primary.withValues(alpha: 0.8))),
                )),
                SizedBox(width: 90, child: _WheelPicker(
                  count: _loopCount, mod: 60, controller: _minCtrl, selected: _minute,
                  onSelected: (v) => setState(() => _minute = v % 60),
                )),
              ]),
            ]),
          ),
          const SizedBox(height: 28),

          // Boutons
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 17),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text('Annuler', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () => Navigator.of(context).pop(TimeOfDay(hour: _hour, minute: _minute)),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 17),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Text('Confirmer', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: AppColors.bg, fontWeight: FontWeight.w600)),
              ),
            )),
          ]),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

class _WheelPicker extends StatelessWidget {
  final int count;
  final int mod;
  final FixedExtentScrollController controller;
  final int selected;
  final ValueChanged<int> onSelected;
  const _WheelPicker({required this.count, required this.mod, required this.controller,
      required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 52,
      perspective: 0.003,
      diameterRatio: 2.5,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onSelected,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (ctx, i) {
          final val = i % mod;
          final active = val == selected;
          return Center(
            child: Text(
              val.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: active ? 28 : 20,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? AppColors.primary : AppColors.textMuted.withValues(alpha: 0.5),
              ),
            ),
          );
        },
      ),
    );
  }
}

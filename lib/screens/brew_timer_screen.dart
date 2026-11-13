import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Step-by-step guided brewing with a countdown for every step.
class BrewTimerScreen extends StatefulWidget {
  final Recipe recipe;
  final double factor;
  const BrewTimerScreen({super.key, required this.recipe, this.factor = 1});

  @override
  State<BrewTimerScreen> createState() => _BrewTimerScreenState();
}

class _BrewTimerScreenState extends State<BrewTimerScreen> {
  int _step = 0;
  late int _remaining = widget.recipe.steps.first.seconds;
  bool _running = false;
  bool _done = false;
  Timer? _timer;
  int _elapsedTotal = 0;

  List<BrewStep> get _steps => widget.recipe.steps;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      setState(() => _running = true);
    }
  }

  void _tick() {
    setState(() {
      _elapsedTotal++;
      if (_remaining > 1) {
        _remaining--;
      } else {
        _goTo(_step + 1);
      }
    });
  }

  void _goTo(int i) {
    HapticFeedback.mediumImpact();
    if (i >= _steps.length) {
      _timer?.cancel();
      _running = false;
      _done = true;
      _remaining = 0;
      return;
    }
    if (i < 0) i = 0;
    _step = i;
    _done = false;
    _remaining = _steps[i].seconds;
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    final progress = _done ? 1.0 : 1 - _remaining / step.seconds;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text(widget.recipe.title.of(context)),
        leading: IconButton(
          tooltip: context.tr('close'),
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: List.generate(
                  _steps.length,
                  (i) => Expanded(
                    child: Container(
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i < _step || _done
                            ? AppColors.brown
                            : i == _step
                            ? AppColors.muted
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _done ? context.tr('brew_done') : context.tr('step_x_of_y', {'x': _step + 1, 'y': _steps.length}),
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted),
              ),
              const Spacer(),
              SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      strokeCap: StrokeCap.round,
                      color: AppColors.brown,
                      backgroundColor: AppColors.border,
                    ),
                    Center(
                      child: _done
                          ? const Icon(Icons.local_cafe_rounded, size: 96)
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  secondsLabel(context, _remaining),
                                  style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w800),
                                ),
                                if (step.pourTo != null)
                                  Pill(
                                    text: context.tr('pour_to', {'n': (step.pourTo! * widget.factor).round()}),
                                    icon: Icons.water_drop_outlined,
                                    filled: true,
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _done ? context.tr('brew_done_msg') : step.text.of(context),
                  key: ValueKey('$_step$_done'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, height: 1.5),
                ),
              ),
              if (_done) ...[
                const SizedBox(height: 8),
                Text(
                  context.tr('total_time', {'t': secondsLabel(context, _elapsedTotal)}),
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
              const Spacer(),
              if (_done)
                FilledButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('finish')))
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.outlined(
                      tooltip: context.tr('previous_step'),
                      iconSize: 28,
                      onPressed: _step == 0 ? null : () => setState(() => _goTo(_step - 1)),
                      icon: const Icon(Icons.skip_previous_rounded),
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: IconButton.filled(
                        tooltip: context.tr(_running ? 'pause' : 'start'),
                        style: IconButton.styleFrom(backgroundColor: AppColors.brown),
                        iconSize: 44,
                        onPressed: _toggle,
                        icon: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded, color: AppColors.white),
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton.outlined(
                      tooltip: context.tr('next_step'),
                      iconSize: 28,
                      onPressed: () => setState(() => _goTo(_step + 1)),
                      icon: const Icon(Icons.skip_next_rounded),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

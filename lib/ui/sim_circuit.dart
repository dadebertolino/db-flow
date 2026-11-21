import 'package:flutter/material.dart';

import '../arduino/board.dart';
import '../i18n/tr.dart';
import '../render/board_painter.dart';
import '../render/theme.dart';
import 'run_controller.dart';

/// Circuito della simulazione Arduino: un elemento per ogni pin configurato.
/// LED e uscite mostrano il livello (o il PWM); pulsanti, potenziometri e
/// ingressi si comandano toccandoli.
class SimCircuit extends StatelessWidget {
  const SimCircuit({super.key, required this.run});

  final RunController run;

  @override
  Widget build(BuildContext context) {
    final pins = run.program.arduino?.pins ?? const <PinConfig>[];
    final theme = Theme.of(context);
    if (pins.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(tr.noSimPins(tr.pinsAndBoard), textAlign: TextAlign.center),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        for (final p in pins) _PinTile(run: run, pin: p),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          child: Text(tr.simNote, style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _PinTile extends StatelessWidget {
  const _PinTile({required this.run, required this.pin});

  final RunController run;
  final PinConfig pin;

  @override
  Widget build(BuildContext context) {
    final board = run.board!;
    final color = pinModeColor(pin.mode);
    final title = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: pin.name,
            style: monoStyle.copyWith(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: '  pin ${pin.pin}', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
    final Widget control;
    final Widget leading;
    switch (pin.mode) {
      case PinMode.output:
        final out = board.output(pin.pin);
        final level = out?.level ?? 0;
        final text = out == null
            ? 'LOW'
            : out.pwm
            ? 'PWM $level (${(level * 100 / 255).round()}%)'
            : (out.high ? 'HIGH' : 'LOW');
        leading = pin.component == Component.led
            ? _Led(level: level)
            : Icon(componentIcon(pin.component), color: color);
        control = Text(
          pin.component == Component.led ? '${level > 0 ? tr.ledOn : tr.ledOff} · $text' : text,
          style: monoStyle.copyWith(fontSize: 13),
        );
      case PinMode.input || PinMode.inputPullup:
        leading = Icon(componentIcon(pin.component), color: color);
        if (pin.component == Component.button) {
          final pressed = board.isPressed(pin.pin);
          control = Align(
            alignment: Alignment.centerLeft,
            child: Tooltip(
              message: tr.tapToPress,
              child: pressed
                  ? FilledButton(
                      onPressed: () => run.setPressed(pin.pin, false),
                      child: Text(tr.pressed),
                    )
                  : OutlinedButton(
                      onPressed: () => run.setPressed(pin.pin, true),
                      child: Text(tr.released),
                    ),
            ),
          );
        } else {
          final high = board.isHighInput(pin.pin);
          control = Row(
            children: [
              Switch(value: high, onChanged: (v) => run.setHighInput(pin.pin, v)),
              const SizedBox(width: 8),
              Text(high ? 'HIGH' : 'LOW', style: monoStyle.copyWith(fontSize: 13)),
            ],
          );
        }
      case PinMode.analogInput:
        leading = Icon(componentIcon(pin.component), color: color);
        final value = board.analogValue(pin.pin);
        control = Row(
          children: [
            Expanded(
              child: Slider(
                value: value.toDouble(),
                max: board.board.analogMax.toDouble(),
                label: '$value',
                onChanged: (v) => run.setAnalog(pin.pin, v.round()),
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                '$value',
                textAlign: TextAlign.end,
                style: monoStyle.copyWith(fontSize: 13),
              ),
            ),
          ],
        );
    }
    return Semantics(
      label: pin.name,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
        child: Row(
          children: [
            SizedBox(width: 36, child: Center(child: leading)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [title, const SizedBox(height: 2), control],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// LED disegnato: spento grigio scuro, acceso giallo con alone; con il PWM
/// la luminosità segue il valore.
class _Led extends StatelessWidget {
  const _Led({required this.level});

  /// 0–255.
  final int level;

  @override
  Widget build(BuildContext context) {
    final t = level / 255;
    const on = Color(0xFFFFC107);
    final off = Theme.of(context).colorScheme.outlineVariant;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.lerp(off, on, t),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
        boxShadow: [
          if (t > 0)
            BoxShadow(
              color: on.withValues(alpha: 0.6 * t),
              blurRadius: 14 * t,
              spreadRadius: 3 * t,
            ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_info.dart';
import '../i18n/tr.dart';

/// Colore dello splash nativo (pubspec.yaml → flutter_native_splash): la
/// schermata Flutter usa lo stesso, così il passaggio non si nota.
const splashBlue = Color(0xFF1F5FAD);

/// Schermata di avvio: logo, nome dell'app, versione e autore, visibile per
/// almeno [duration]; poi sfuma in [next].
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.next, this.duration = const Duration(seconds: 1)});

  final Widget next;
  final Duration duration;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  late bool _done = widget.duration == Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!_done) _timer = Timer(widget.duration, () => setState(() => _done = true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 350),
    // Le schermate occupano tutto lo spazio (lo Stack predefinito le centrerebbe
    // alla loro misura naturale, lasciando bande nere ai lati).
    layoutBuilder: (current, previous) =>
        Stack(fit: StackFit.expand, children: [...previous, ?current]),
    child: _done ? widget.next : const SplashView(),
  );
}

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: splashBlue,
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              Image.asset('assets/icon/splash.png', width: 180, height: 180),
              const SizedBox(height: 20),
              const Text(
                appName,
                style: TextStyle(
                  color: white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr.version(appVersion),
                style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 15),
              ),
              const Spacer(flex: 4),
              const Text(
                appAuthor,
                style: TextStyle(color: white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'i18n/tr.dart';
import 'io/incoming.dart';
import 'io/settings.dart';
import 'io/storage.dart';
import 'render/theme.dart';
import 'ui/home_page.dart';
import 'ui/splash_page.dart';

/// Lingue supportate, nell'ordine di [AppLanguage].
final supportedLocales = [for (final l in AppLanguage.values) Locale(l.name)];

/// Sceglie la lingua dell'app da quelle preferite dal dispositivo; se nessuna
/// è supportata usa l'inglese.
Locale resolveLocale(List<Locale>? preferred, Iterable<Locale> supported) {
  for (final p in preferred ?? const <Locale>[]) {
    for (final s in supported) {
      if (s.languageCode == p.languageCode) return s;
    }
  }
  return const Locale('en');
}

class DbFlowApp extends StatefulWidget {
  const DbFlowApp({
    super.key,
    this.storage,
    this.settings,
    this.incoming,
    this.locale,
    this.splashDuration = const Duration(seconds: 1),
  });

  /// Iniettabile nei test; di default la cartella documenti dell'app.
  final FlowStorage? storage;

  /// Preferenze (tema); iniettabili nei test.
  final AppSettings? settings;

  /// File `.flow` aperti dall'esterno; assente nei test.
  final IncomingFiles? incoming;

  /// Lingua forzata (test); di default quella del dispositivo.
  final Locale? locale;

  /// Durata minima della schermata di avvio (zero nei test che non la riguardano).
  final Duration splashDuration;

  @override
  State<DbFlowApp> createState() => _DbFlowAppState();
}

class _DbFlowAppState extends State<DbFlowApp> {
  late final AppSettings _settings = widget.settings ?? (AppSettings()..load());
  late final FlowStorage _storage = widget.storage ?? FlowStorage();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) => MaterialApp(
        title: 'DB Flow',
        debugShowCheckedModeBanner: false,
        theme: appTheme(Brightness.light),
        darkTheme: appTheme(Brightness.dark),
        themeMode: _settings.themeMode,
        locale: widget.locale,
        supportedLocales: supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        localeListResolutionCallback: (preferred, supported) => resolveLocale(preferred, supported),
        // La lingua dei testi segue quella scelta da Flutter per l'app.
        builder: (context, child) {
          final code = Localizations.localeOf(context).languageCode;
          setLanguage(AppLanguage.fromCode(code) ?? AppLanguage.en);
          return child!;
        },
        home: SplashGate(
          duration: widget.splashDuration,
          next: HomePage(storage: _storage, settings: _settings, incoming: widget.incoming),
        ),
      ),
    );
  }
}

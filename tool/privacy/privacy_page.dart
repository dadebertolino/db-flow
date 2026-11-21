// Pagina dell'informativa privacy per davidebertolino.it, generata dagli
// stessi testi dell'app (lib/i18n), in tutte le lingue: così sito e app dicono
// sempre la stessa cosa.
//
//   flutter test tool/privacy/render_privacy_page_test.dart
//
// produce tool/privacy/informativa-privacy.html: un unico blocco
// `<!-- wp:html -->` da incollare in Gutenberg. test/privacy_page_test.dart
// fallisce se il file non è aggiornato rispetto ai testi dell'app.
//
// Niente Google Fonts (standard privacy): Inter se il sito lo fornisce già,
// altrimenti i font di sistema.
import 'package:db_flow/app_info.dart';
import 'package:db_flow/i18n/tr.dart';

const privacyPagePath = 'tool/privacy/informativa-privacy.html';

/// Indirizzo del codice pubblico (attivo quando il repository diventa pubblico).
const repositoryUrl = 'https://github.com/dadebertolino/db-flow';

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String renderPrivacyPage() {
  final b = StringBuffer()
    ..writeln('<!-- wp:html -->')
    ..writeln('<style>')
    ..writeln(_css.trim())
    ..writeln('</style>')
    ..writeln('<div class="db-pro">')
    ..writeln('<section class="db-hero">')
    ..writeln('  <div class="db-wrap">')
    ..writeln('    <span class="db-label">INFORMATIVA PRIVACY</span>')
    ..writeln('    <h1>${_esc(appName)}</h1>')
    ..writeln('    <p class="db-meta">Davide Bertolino &middot; Novembre 2026</p>')
    ..writeln('    <nav class="db-langs" aria-label="Lingua / Language">');
  for (final l in AppLanguage.values) {
    b.writeln('      <a href="#${l.name}" hreflang="${l.name}">${_esc(l.nativeName)}</a>');
  }
  b
    ..writeln('    </nav>')
    ..writeln('  </div>')
    ..writeln('</section>')
    ..writeln('<div class="db-main">');

  final previous = tr.language;
  try {
    for (final l in AppLanguage.values) {
      setLanguage(l);
      b
        ..writeln('<section class="db-lang" id="${l.name}" lang="${l.name}">')
        ..writeln('  <h2>${_esc(tr.privacyPolicy)} &middot; ${_esc(appName)}</h2>')
        ..writeln('  <p class="db-updated">${_esc(tr.privacyUpdated)}</p>')
        ..writeln('  <div class="db-summary">')
        ..writeln('    <ul class="db-badges">');
      for (final t in [tr.noAccount, tr.noAds, tr.noDataCollection, tr.dataStaysOnDevice]) {
        b.writeln('      <li>${_esc(t)}</li>');
      }
      b
        ..writeln('    </ul>')
        ..writeln('    <p>${_esc(tr.privacySummary)}</p>')
        ..writeln('  </div>');
      for (final (title, paras) in tr.privacySections(appName, appAuthor, appLicense, appContact)) {
        b.writeln('  <h3>${_esc(title)}</h3>');
        for (final p in paras) {
          b.writeln('  <p>${_esc(p)}</p>');
        }
      }
      b.writeln('</section>');
    }
  } finally {
    setLanguage(previous);
  }

  b
    ..writeln('</div>')
    ..writeln('<footer class="db-footer">')
    ..writeln('  <div class="db-wrap">')
    ..writeln(
      '    <p><a href="mailto:$appContact">$appContact</a> &middot; '
      '<a href="$repositoryUrl">$repositoryUrl</a></p>',
    )
    ..writeln('    <p class="db-dim">${_esc(appName)} &middot; $appLicense</p>')
    ..writeln('  </div>')
    ..writeln('</footer>')
    ..writeln('</div>')
    ..writeln('<!-- /wp:html -->');
  return b.toString();
}

const _css = r'''
:root {
  --db-white: #FFFFFF; --db-off-white: #F7F8FA; --db-light-1: #F0F1F3;
  --db-light-2: #E5E7EB; --db-light-3: #D1D5DB;
  --db-black: #0A0A0A; --db-dark-1: #111111; --db-dark-2: #1A1A1A;
  --db-text: #1A1A1A; --db-text-secondary: #4B5563; --db-text-dim: #6B7280;
  --db-text-bright: #FFFFFF;
  --db-accent: #2563EB; --db-accent-dim: #1D4ED8; --db-accent-bright: #3B82F6;
  --db-green: #16A34A; --db-green-bg: #F0FDF4; --db-green-border: #BBF7D0;
  --db-radius: 4px; --db-radius-lg: 6px;
}
.db-pro {
  --db-font: 'Inter', system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;
  --db-mono: 'JetBrains Mono', ui-monospace, Menlo, Consolas, monospace;
  font-family: var(--db-font); color: var(--db-text); font-size: 16px; line-height: 1.65;
}
.db-pro .db-hero, .db-pro .db-footer {
  width: 100vw; position: relative; left: 50%; right: 50%;
  margin-left: -50vw; margin-right: -50vw;
}
.db-pro .db-wrap { max-width: 860px; margin: 0 auto; padding: 0 24px; }
.db-pro .db-hero { background: var(--db-dark-1); color: var(--db-text-bright); padding: 56px 0 40px; }
.db-pro .db-label {
  font-family: var(--db-mono); font-size: 11px; font-weight: 600; letter-spacing: 1.5px;
  text-transform: uppercase; color: var(--db-accent-bright);
}
.db-pro h1 {
  font-family: var(--db-font) !important; font-weight: 900; font-size: clamp(28px, 4vw, 44px);
  color: var(--db-text-bright) !important; background: none !important; margin: 10px 0 6px;
}
.db-pro .db-meta { font-size: 13px; font-weight: 500; color: #9CA3AF; margin: 0 0 20px; }
.db-pro .db-langs { display: flex; flex-wrap: wrap; gap: 8px; }
.db-pro .db-langs a {
  font-family: var(--db-mono); font-size: 12px; font-weight: 600; color: var(--db-text-bright);
  border: 1px solid #383838; border-radius: var(--db-radius); padding: 6px 12px; text-decoration: none;
}
.db-pro .db-langs a:hover { border-color: var(--db-accent-bright); }
.db-pro .db-main { max-width: 860px; margin: 0 auto; padding: 8px 24px 48px; background: var(--db-white); }
.db-pro .db-lang { padding-top: 32px; border-bottom: 1px solid var(--db-light-2); padding-bottom: 24px; }
.db-pro .db-lang:last-child { border-bottom: none; }
.db-pro h2 {
  font-family: var(--db-font) !important; font-weight: 700; font-size: 24px;
  color: var(--db-text) !important; background: none !important; margin: 0 0 4px;
}
.db-pro h3 {
  font-family: var(--db-font) !important; font-weight: 600; font-size: 18px;
  color: var(--db-accent-dim) !important; background: none !important; margin: 24px 0 8px;
}
.db-pro p { margin: 0 0 12px; }
.db-pro .db-updated { font-size: 13px; font-weight: 500; color: var(--db-text-dim); }
.db-pro .db-summary {
  background: var(--db-green-bg); border: 1px solid var(--db-green-border);
  border-radius: var(--db-radius-lg); padding: 16px 20px; margin: 16px 0 8px;
}
.db-pro .db-summary p { margin: 0; color: var(--db-text-secondary); }
.db-pro .db-badges { list-style: none; display: flex; flex-wrap: wrap; gap: 8px; padding: 0; margin: 0 0 12px; }
.db-pro .db-badges li {
  font-family: var(--db-mono); font-size: 11px; font-weight: 600; letter-spacing: 1px;
  text-transform: uppercase; color: var(--db-green); border: 1px solid var(--db-green-border);
  background: var(--db-white); border-radius: var(--db-radius); padding: 4px 10px;
}
.db-pro .db-footer { background: var(--db-black); color: var(--db-text-bright); padding: 32px 0; }
.db-pro .db-footer p { margin: 0 0 6px; font-size: 14px; }
.db-pro .db-footer a { color: var(--db-text-bright); }
.db-pro .db-footer .db-dim { color: #9CA3AF; font-size: 13px; }
@media (max-width: 640px) {
  .db-pro .db-hero { padding: 40px 0 28px; }
  .db-pro .db-main { padding: 0 16px 32px; }
  .db-pro .db-wrap { padding: 0 16px; }
  .db-pro h2 { font-size: 21px; }
}
''';

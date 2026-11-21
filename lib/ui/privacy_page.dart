import 'package:flutter/material.dart';

import '../app_info.dart';
import '../i18n/tr.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr.privacyPolicy)),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(tr.privacyUpdated, style: theme.textTheme.bodySmall),
            for (final (title, paras) in tr.privacySections(
              appName,
              appAuthor,
              appLicense,
              appContact,
            )) ...[
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 6),
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                ),
              ),
              for (final p in paras)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(p, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

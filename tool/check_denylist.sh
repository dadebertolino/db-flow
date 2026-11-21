#!/usr/bin/env bash
set -e
PATTERN='firebase_|google_mobile_ads|sentry|analytics|amplitude|mixpanel|appsflyer|adjust|facebook|onesignal'
if grep -Eiq "$PATTERN" pubspec.yaml pubspec.lock; then
  echo "ERRORE: dipendenza vietata trovata"; grep -Ein "$PATTERN" pubspec.yaml pubspec.lock; exit 1
fi
echo "Deny-list OK"

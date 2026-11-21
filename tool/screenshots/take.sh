#!/usr/bin/env bash
# Screenshot per App Store Connect: iPhone 6,3" (1206×2622, quello che App Store
# Connect chiede da novembre 2026), iPhone 6,9" (1320×2868), iPad 13" (2064×2752)
# e Mac (2880×1800), in chiaro, nelle lingue scelte. Per Google Play: telefono
# Android 1080×1920 e tablet 10" 1600×2560 (emulatore, AVD in $AVD).
#
#   bash tool/screenshots/take.sh                 # tutto, cinque lingue
#   bash tool/screenshots/take.sh iphone it,en    # un dispositivo, alcune lingue
#
# Dispositivi: iphone (6,3"), iphone69, ipad, mac (o all), android, tablet (o play). L'iPhone si cattura dal simulatore;
# iPad e Mac sono resi dal test sul Mac (il simulatore iPad senza finestra è
# troppo lento e instabile). Risultato in build/screenshots/<dispositivo>/<lingua>/.
# Il test (integration_test/screenshots_test.dart) usa una cartella temporanea:
# i diagrammi veri non vengono toccati. Sul Mac la finestra dell'app viene
# tenuta in primo piano: se resta coperta, macOS rallenta i frame e il test si blocca.
set -euo pipefail
cd "$(dirname "$0")/../.."

WHAT="${1:-all}"
LANGS="${2:-it,en,fr,de,es}"
OUT="build/screenshots"
TEST="integration_test/screenshots_test.dart"
IPHONE="iPhone 17"
IPHONE69="iPhone 17 Pro Max"
AVD="${AVD:-Pixel_10}"
ADB="${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb"
EMULATOR="${ANDROID_HOME:-$HOME/Library/Android/sdk}/emulator/emulator"

# Ordine delle schermate nella scheda.
order() {
  case "$1" in
    editor) echo 1 ;; run) echo 2 ;; code) echo 3 ;; arduino) echo 4 ;;
    pins) echo 5 ;; exercise) echo 6 ;; home) echo 7 ;; *) echo 9 ;;
  esac
}

udid() {
  xcrun simctl list devices available | grep -F "    $1 (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/'
}

simulator() { # <nome cartella> <nome simulatore>
  local dir="$1" id
  id="$(udid "$2")"
  [ -n "$id" ] || { echo "Simulatore «$2» non trovato"; exit 1; }
  xcrun simctl boot "$id" 2>/dev/null || true
  xcrun simctl bootstatus "$id" -b >/dev/null
  xcrun simctl status_bar "$id" override --time "9:41" --dataNetwork wifi --wifiMode active \
    --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState discharging --batteryLevel 100
  echo "== $2 ($id)"
  flutter test "$TEST" -d "$id" --dart-define=SHOT_LANGS="$LANGS" 2>&1 |
    while IFS= read -r line; do
      if [[ "$line" =~ DBFLOW_SHOT\ ([a-z]+)\ ([a-z]+)\ - ]]; then
        local lang="${BASH_REMATCH[1]}" name="${BASH_REMATCH[2]}"
        mkdir -p "$OUT/$dir/$lang"
        xcrun simctl io "$id" screenshot "$OUT/$dir/$lang/$(order "$name")_$name.png" >/dev/null 2>&1
        echo "   $dir/$lang/$(order "$name")_$name.png"
      elif [[ "$line" =~ (All\ tests\ passed|Some\ tests\ failed|EXCEPTION) ]]; then
        echo "   $line"
      fi
    done || echo "   ERRORE: test non riuscito"
  xcrun simctl status_bar "$id" clear
}

mac() { # <dispositivo: mac|ipad>
  local dev="$1"
  echo "== $dev (reso sul Mac)"
  (while sleep 3; do
    osascript -e 'tell application "System Events" to set frontmost of (first process whose name is "DB Flow") to true' 2>/dev/null || true
  done) &
  local keep=$!
  trap 'kill $keep 2>/dev/null || true' RETURN
  flutter test "$TEST" -d macos --dart-define=SHOT_LANGS="$LANGS" --dart-define=SHOT_DEVICE="$dev" 2>&1 |
    while IFS= read -r line; do
      if [[ "$line" =~ DBFLOW_SHOT\ ([a-z]+)\ ([a-z]+)\ (/.+\.png) ]]; then
        local lang="${BASH_REMATCH[1]}" name="${BASH_REMATCH[2]}" src="${BASH_REMATCH[3]}"
        mkdir -p "$OUT/$dev/$lang"
        cp "$src" "$OUT/$dev/$lang/$(order "$name")_$name.png"
        echo "   $dev/$lang/$(order "$name")_$name.png"
      elif [[ "$line" =~ (All\ tests\ passed|Some\ tests\ failed|EXCEPTION) ]]; then
        echo "   $line"
      fi
    done || echo "   ERRORE: test non riuscito"
}

# Emulatore Android con la risoluzione forzata: Google Play rifiuta le immagini
# con un lato più del doppio dell'altro (il Pixel 10 è 1080×2424). La barra di
# stato è in «modalità demo» (9:41, batteria piena, nessuna notifica).
android() { # <nome cartella> <larghezza×altezza> <densità>
  local dir="$1" serial
  serial="$("$ADB" devices | awk '/^emulator-/ && $2=="device" {print $1; exit}')"
  if [ -z "$serial" ]; then
    "$EMULATOR" -avd "$AVD" -no-snapshot-save -no-boot-anim >/dev/null 2>&1 &
    "$ADB" wait-for-device
    until [ "$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ]; do sleep 2; done
    serial="$("$ADB" devices | awk '/^emulator-/ && $2=="device" {print $1; exit}')"
  fi
  local a=("$ADB" -s "$serial")
  "${a[@]}" shell wm size "$2"
  "${a[@]}" shell wm density "$3"
  "${a[@]}" shell settings put global sysui_demo_allowed 1
  demo() { "${a[@]}" shell am broadcast -a com.android.systemui.demo -e command "$@" >/dev/null; }
  demo enter
  demo clock -e hhmm 0941
  demo battery -e level 100 -e plugged false
  demo network -e wifi show -e level 4 -e fully true -e mobile hide
  demo notifications -e visible false
  echo "== Android $2 ($serial)"
  flutter test "$TEST" -d "$serial" --dart-define=SHOT_LANGS="$LANGS" 2>&1 |
    while IFS= read -r line; do
      if [[ "$line" =~ DBFLOW_SHOT\ ([a-z]+)\ ([a-z]+)\ - ]]; then
        local lang="${BASH_REMATCH[1]}" name="${BASH_REMATCH[2]}"
        mkdir -p "$OUT/$dir/$lang"
        "${a[@]}" exec-out screencap -p >"$OUT/$dir/$lang/$(order "$name")_$name.png"
        echo "   $dir/$lang/$(order "$name")_$name.png"
      elif [[ "$line" =~ (All\ tests\ passed|Some\ tests\ failed|EXCEPTION) ]]; then
        echo "   $line"
      fi
    done || echo "   ERRORE: test non riuscito"
  demo exit
  "${a[@]}" shell wm size reset
  "${a[@]}" shell wm density reset
}

case "$WHAT" in
  iphone) simulator iphone "$IPHONE" ;;
  iphone69) simulator iphone69 "$IPHONE69" ;;
  ipad) mac ipad ;;
  mac) mac mac ;;
  all) simulator iphone "$IPHONE"; mac ipad; mac mac ;;
  android) android android 1080x1920 420 ;;
  tablet) android tablet 1600x2560 320 ;;
  play) android android 1080x1920 420; android tablet 1600x2560 320 ;;
  *) echo "Uso: $0 [iphone|iphone69|ipad|mac|all|android|tablet|play] [lingue]"; exit 1 ;;
esac

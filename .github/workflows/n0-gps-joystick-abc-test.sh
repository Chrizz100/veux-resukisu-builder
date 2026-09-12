#!/system/bin/sh
# N0 GPS Joystick A/B/C diagnostic collector
# Read-only/runtime diagnostic except force-stop/start of Ingress and logcat clear.

INGRESS='com.nianticproject.ingress'
JOY='com.theqtbsezydl.eeffevafzafjaxj'
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="/sdcard/Download/n0-gps-abc-$STAMP"
mkdir -p "$OUT" || exit 1

root() { su -c "$*"; }

snapshot() {
  phase="$1"
  dir="$OUT/$phase"
  mkdir -p "$dir"
  date '+%F %T %z' > "$dir/time.txt"
  root "pidof $INGRESS" > "$dir/ingress-pid.txt" 2>&1 || true
  root "pidof $JOY" > "$dir/joystick-pid.txt" 2>&1 || true
  root "pidof ${JOY}:overlay" > "$dir/joystick-overlay-pid.txt" 2>&1 || true
  root "cmd appops get $JOY android:mock_location" > "$dir/joystick-mock-appop.txt" 2>&1 || true
  root "cmd appops get $INGRESS android:mock_location" > "$dir/ingress-mock-appop.txt" 2>&1 || true
  root "dumpsys location" > "$dir/dumpsys-location.txt" 2>&1 || true
  root "dumpsys activity processes | grep -E '$INGRESS|$JOY'" > "$dir/processes.txt" 2>&1 || true
  root "logcat -b all -d -v threadtime" > "$dir/logcat-full.txt" 2>&1 || true
  root "logcat -b all -d -v threadtime | grep -Ei 'LSPLANT-N0|Failed to init lsplant|libpairipcore|SIGSEGV|SEGV_|Fatal signal|network!=gps|mock|LocationManager|Gnss|fused|FLP|$INGRESS|$JOY'" > "$dir/logcat-focus.txt" 2>&1 || true
}

start_ingress() {
  root "am force-stop $INGRESS" >/dev/null 2>&1 || true
  sleep 1
  root "monkey -p $INGRESS -c android.intent.category.LAUNCHER 1" >/dev/null 2>&1 || true
  sleep 10
}

printf '\nN0 GPS Joystick A/B/C Test\n'
printf 'Output: %s\n\n' "$OUT"

printf 'PHASE A: GPS Joystick komplett AUS/gestoppt lassen.\n'
printf 'Mock-Location-App-Auswahl NICHT aendern. Nur Joystick nicht starten.\n'
printf 'Druecke Enter, wenn bereit... '
read _
root "logcat -c" >/dev/null 2>&1 || true
start_ingress
printf 'Jetzt in Ingress ansehen: Scanner AKTIV oder DEAKTIVIERT?\n'
printf 'Schreibe Ergebnis (aktiv/deaktiviert): '
read ARES
echo "$ARES" > "$OUT/A-ui-result.txt"
snapshot A-joystick-off

printf '\nPHASE B: Ingress schliessen. GPS Joystick JETZT starten/aktivieren und laufen lassen.\n'
root "am force-stop $INGRESS" >/dev/null 2>&1 || true
printf 'Druecke Enter, sobald GPS Joystick aktiv ist... '
read _
root "logcat -c" >/dev/null 2>&1 || true
start_ingress
printf 'Scanner AKTIV oder DEAKTIVIERT? '
read BRES
echo "$BRES" > "$OUT/B-ui-result.txt"
snapshot B-joystick-before-ingress

printf '\nPHASE C: GPS Joystick AUS. Ingress wird neu gestartet.\n'
root "am force-stop $INGRESS" >/dev/null 2>&1 || true
printf 'GPS Joystick jetzt stoppen. Druecke Enter, wenn er AUS ist... '
read _
root "logcat -c" >/dev/null 2>&1 || true
start_ingress
printf 'Warte bis der Scanner sichtbar funktioniert. Ergebnis vor Joystick (aktiv/deaktiviert): '
read CBEFORE
echo "$CBEFORE" > "$OUT/C-before-ui-result.txt"
snapshot C1-before-joystick

printf '\nIngress OFFEN lassen. GPS Joystick JETZT einschalten, nichts anderes aendern.\n'
printf 'Druecke Enter unmittelbar nachdem der Joystick aktiv ist... '
read _
sleep 5
printf 'Scanner jetzt AKTIV oder DEAKTIVIERT? '
read CAFTER
echo "$CAFTER" > "$OUT/C-after-ui-result.txt"
snapshot C2-after-joystick

# concise summary
{
  echo "INGRESS=$INGRESS"
  echo "JOYSTICK=$JOY"
  echo "A_UI=$ARES"
  echo "B_UI=$BRES"
  echo "C_BEFORE_UI=$CBEFORE"
  echo "C_AFTER_UI=$CAFTER"
  echo "OUTPUT=$OUT"
} > "$OUT/SUMMARY.txt"

# Create one archive if toybox zip exists; otherwise leave directory.
if command -v zip >/dev/null 2>&1; then
  (cd /sdcard/Download && zip -qr "n0-gps-abc-$STAMP.zip" "n0-gps-abc-$STAMP")
  echo "ZIP=/sdcard/Download/n0-gps-abc-$STAMP.zip"
else
  echo "Kein zip-Befehl vorhanden. Lade den Ordner $OUT spaeter als ZIP hoch."
fi

echo "FERTIG. SUMMARY: $OUT/SUMMARY.txt"

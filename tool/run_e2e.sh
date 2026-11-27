#!/usr/bin/env bash
# End-to-end test of Tripora in Chrome against the LOCAL Firebase emulators.
# Never touches the live project: the app is started with
# USE_FIREBASE_EMULATORS=true and the emulators load firestore.rules.proposed.
#
# Needs: Node + firebase-tools, Java 11+ (JAVA_HOME), Chrome, and a matching
# chromedriver on PATH or in CHROMEDRIVER.
#   bash tool/run_e2e.sh
set -euo pipefail
cd "$(dirname "$0")/.."

PROJECT=tripora-7ded0           # must match firebase_options.dart
ADMIN_EMAIL=e2e-admin@example.com
ADMIN_PASSWORD=e2e-admin-pass   # exists only inside the local emulator
WORK=$(mktemp -d)
cp firestore.rules.proposed "$WORK/firestore.rules"
cat > "$WORK/firebase.json" <<JSON
{ "firestore": { "rules": "firestore.rules" },
  "emulators": { "auth": { "port": 9099 }, "firestore": { "port": 8080 },
                 "ui": { "enabled": false } } }
JSON

(cd "$WORK" && firebase emulators:start --only auth,firestore --project "$PROJECT") \
  > "$WORK/emulators.log" 2>&1 &
EMU_PID=$!
cleanup() {
  kill "$EMU_PID" 2>/dev/null || true
  [ -n "${CD_PID:-}" ] && kill "$CD_PID" 2>/dev/null || true
}
trap cleanup EXIT

echo "Waiting for emulators..."
for _ in $(seq 1 60); do
  curl -s http://localhost:8080 >/dev/null && curl -s http://localhost:9099 >/dev/null && break
  sleep 2
done

# Seed one admin account (emulator only).
ADMIN_UID=$(curl -s -X POST \
  "http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\",\"returnSecureToken\":true}" \
  | python -c "import json,sys; print(json.load(sys.stdin)['localId'])")
curl -s -X PATCH -H 'Authorization: Bearer owner' -H 'Content-Type: application/json' \
  "http://localhost:8080/v1/projects/$PROJECT/databases/(default)/documents/admins/$ADMIN_UID" \
  -d '{"fields":{"role":{"stringValue":"admin"}}}' >/dev/null
echo "Seeded emulator admin $ADMIN_UID"

"${CHROMEDRIVER:-chromedriver}" --port=4444 >/dev/null 2>&1 &
CD_PID=$!
sleep 2

flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_e2e_test.dart \
  -d chrome \
  --dart-define=USE_FIREBASE_EMULATORS=true \
  --dart-define=E2E_ADMIN_EMAIL=$ADMIN_EMAIL \
  --dart-define=E2E_ADMIN_PASSWORD=$ADMIN_PASSWORD

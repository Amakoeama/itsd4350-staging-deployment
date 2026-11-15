#!/usr/bin/env bash
#--- Mini Project 2.3: Blue/Green Production Promotion ---
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG="$ROOT/infrastructure/blue-green/nginx/nginx.conf"
BACKUP="$ROOT/infrastructure/blue-green/nginx/nginx.conf.backup"
NGINX="itsd4350-nginx"
URL="http://localhost:8080/health"

#--- Check the existing production configuration ---
[[ -f "$CONFIG" ]] || { echo "ERROR: Missing NGINX configuration."; exit 1; }

BLUE_COUNT="$(grep -Ec '^[[:space:]]*server[[:space:]]+blue:8000;' "$CONFIG" || true)"
GREEN_COUNT="$(grep -Ec '^[[:space:]]*server[[:space:]]+green:8000;' "$CONFIG" || true)"

[[ $((BLUE_COUNT + GREEN_COUNT)) -eq 1 ]] || {
    echo "ERROR: Expected exactly one active backend."
    exit 1
}

if [[ "$BLUE_COUNT" -eq 1 ]]; then
    ACTIVE="blue"
    TARGET="green"
else
    ACTIVE="green"
    TARGET="blue"
fi

#--- Verify the live production application ---
check_live() {
    local expected="$1"
    curl -fsS --max-time 5 "$URL" | python3 -c '
import json, sys
data = json.load(sys.stdin)
expected = sys.argv[1]
if data.get("status") != "healthy" or data.get("environment") != expected:
    sys.exit(1)
print("Live production verified:", data)
' "production-$expected"
}

#--- Verify the promotion candidate ---
check_candidate() {
    docker exec "itsd4350-$TARGET" python -c '
import json, sys, urllib.request
with urllib.request.urlopen("http://localhost:8000/health", timeout=5) as response:
    data = json.load(response)
if data.get("status") != "healthy" or data.get("environment") != sys.argv[1]:
    sys.exit(1)
print("Candidate verified:", data)
' "production-$TARGET"
}

#--- Restore previous routing after a failed switch ---
recover() {
    echo "ERROR: Promotion failed. Restoring $ACTIVE..."
    if [[ -f "$BACKUP" ]]; then
        cp -- "$BACKUP" "$CONFIG"
        if docker exec "$NGINX" nginx -t &&
           docker exec "$NGINX" nginx -s reload; then
            if check_live "$ACTIVE"; then
                echo "Recovery successful: $ACTIVE"
            else
                echo "CRITICAL: Recovery health check failed."
            fi
        else
            echo "CRITICAL: NGINX recovery failed."
        fi
    else
        echo "CRITICAL: No backup available."
    fi
}

echo "Active production: $ACTIVE"
echo "Promotion candidate: $TARGET"

#--- Confirm the container configuration matches ---
RUNNING="$(docker exec "$NGINX" nginx -T 2>/dev/null)"
if ! grep -Eq "^[[:space:]]*server[[:space:]]+$ACTIVE:8000;" <<< "$RUNNING"; then
    echo "ERROR: NGINX configuration mismatch."
    exit 1
fi

check_live "$ACTIVE"
check_candidate

echo
read -r -p "Type PROMOTE to switch production to $TARGET: " APPROVAL
if [[ "$APPROVAL" != "PROMOTE" ]]; then
    echo "Promotion cancelled."
    exit 1
fi

#--- Preserve the working configuration ---
cp -- "$CONFIG" "$BACKUP"
cmp -s -- "$CONFIG" "$BACKUP" || {
    echo "ERROR: Backup verification failed."
    exit 1
}

#--- Update the existing bind-mounted file in place ---
sed "s/server $ACTIVE:8000;/server $TARGET:8000;/" "$CONFIG" > "$CONFIG.next"
cat "$CONFIG.next" > "$CONFIG"
rm -f "$CONFIG.next"

#--- Validate configuration before reloading ---
if ! docker exec "$NGINX" nginx -t; then
    recover
    exit 1
fi

if ! docker exec "$NGINX" nginx -s reload; then
    recover
    exit 1
fi

#--- Confirm production now serves the promoted application ---
SUCCESS=false
for attempt in {1..10}; do
    if check_live "$TARGET"; then
        SUCCESS=true
        break
    fi
    sleep 1
done

if [[ "$SUCCESS" != "true" ]]; then
    recover
    exit 1
fi

echo "SUCCESS: Production promoted from $ACTIVE to $TARGET."
echo "Previous environment remains available for rollback."

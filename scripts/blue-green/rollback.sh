#!/usr/bin/env bash
#--- Mini Project 2.3: Blue/Green Production Rollback ---
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG="$ROOT/infrastructure/blue-green/nginx/nginx.conf"
BACKUP="$ROOT/infrastructure/blue-green/nginx/nginx.conf.backup"

[[ -f "$BACKUP" ]] || {
    echo "ERROR: No backup configuration available."
    exit 1
}

echo "Restoring the previous production routing configuration..."
read -r -p "Type ROLLBACK to confirm: " APPROVAL

if [[ "$APPROVAL" != "ROLLBACK" ]]; then
    echo "Rollback cancelled."
    exit 1
fi

cp -- "$BACKUP" "$CONFIG"
docker exec itsd4350-nginx nginx -t
docker exec itsd4350-nginx nginx -s reload

EXPECTED="$(grep -E '^[[:space:]]*server[[:space:]]+(blue|green):8000;' "$CONFIG" | head -1 | sed -E 's/.*server (blue|green):8000;.*/production-\1/')"

for attempt in {1..10}; do
    if curl -fsS --max-time 5 http://localhost:8080/health |
        python3 -c '
import json, sys
data = json.load(sys.stdin)
if data.get("status") != "healthy" or data.get("environment") != sys.argv[1]:
    sys.exit(1)
print("Rollback verified:", data)
' "$EXPECTED"; then
        echo "SUCCESS: Production rollback completed."
        exit 0
    fi
    sleep 1
done

echo "ERROR: Rollback health validation failed."
exit 1

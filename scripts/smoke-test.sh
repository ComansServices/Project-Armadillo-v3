#!/usr/bin/env bash
set -euo pipefail

echo "[1/3] API health"
for i in {1..30}; do
  if curl -fsS http://localhost:4000/health > /tmp/armadillo_health.json; then
    cat /tmp/armadillo_health.json
    break
  fi
  sleep 1
  if [ "$i" -eq 30 ]; then
    echo "API did not become healthy in time" >&2
    exit 1
  fi
done

echo "[2/3] Queue scan"
RESP=$(curl -fsS -X POST http://localhost:4000/api/v1/scans \
  -H 'content-type: application/json' \
  -d '{
    "projectId":"proj-001",
    "requestedBy":"local-smoke",
    "targets":[{"value":"127.0.0.1","type":"ip"}],
    "config":{"profile":"safe-default"}
  }')

echo "$RESP" | tee /tmp/armadillo_scan_create.json
SCAN_ID=$(python3 - <<'PY' "$RESP"
import json,sys
print(json.loads(sys.argv[1])["scanId"])
PY
)

echo "[3/3] Fetch status for ${SCAN_ID}"
for i in {1..15}; do
  curl -fsS "http://localhost:4000/api/v1/scans/${SCAN_ID}" | tee /tmp/armadillo_scan_status.json
  status=$(python3 - <<'PY' /tmp/armadillo_scan_status.json
import json,sys
with open(sys.argv[1]) as f:
    print(json.load(f).get('status',''))
PY
)
  if [ "$status" = "running" ] || [ "$status" = "completed" ] || [ "$status" = "failed" ]; then
    break
  fi
  sleep 1
done

echo

echo "Worker tail:"
docker logs --tail 20 project-armadillo-v3-worker-1 || true

echo
echo "Smoke test completed."

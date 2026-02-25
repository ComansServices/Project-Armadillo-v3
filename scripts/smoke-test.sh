#!/usr/bin/env bash
set -euo pipefail

echo "[1/3] API health"
curl -fsS http://localhost:4000/health | tee /tmp/armadillo_health.json

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
sleep 1
curl -fsS "http://localhost:4000/api/v1/scans/${SCAN_ID}" | tee /tmp/armadillo_scan_status.json

echo

echo "Worker tail:"
docker logs --tail 20 project-armadillo-v3-worker-1 || true

echo
echo "Smoke test completed."

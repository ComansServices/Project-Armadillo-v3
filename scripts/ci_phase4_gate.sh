#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "[phase4-gate] starting stack"
make up >/tmp/armadillo-phase4-ci-makeup.log

echo "[phase4-gate] waiting for api health"
python3 - <<'PY'
import time,requests,sys
for i in range(60):
    try:
        r=requests.get('http://localhost:4000/health',timeout=3)
        if r.status_code==200:
            print('api healthy')
            sys.exit(0)
    except Exception:
        pass
    time.sleep(1)
print('api did not become healthy in time')
sys.exit(2)
PY

echo "[phase4-gate] running integration smoke"
./scripts/integration_smoke_phase4.py

echo "[phase4-gate] success"

# 🛡️ Project Armadillo v3

Modern, queue-driven network discovery and security visibility platform.

## Current platform includes
- Next.js web app (`apps/web`)
- Fastify API (`apps/api`)
- BullMQ worker pipeline (`apps/worker`)
- Shared pipeline contracts (`packages/types`)
- PostgreSQL + Prisma migrations (`apps/api/prisma`)

## Progress snapshot (as of 2026-02-25, end of day)
Implemented through **Step 20**:
- ✅ Scan queue + status + event timeline (`/api/v1/scans`, `/api/v1/scans/:scanId/events`)
- ✅ XML import pipeline (`POST /api/v1/imports/xml`) with strict/lenient quality modes
- ✅ Import analytics:
  - `GET /api/v1/imports`
  - `GET /api/v1/imports/:importId`
  - `GET /api/v1/imports.csv`
  - `GET /api/v1/imports/quality-trend`
  - `GET /api/v1/imports/quality-digest`
  - `GET /api/v1/imports/:importId/reject-artifact`
- ✅ Asset normalization + dedup by deterministic `identityKey`
- ✅ Identity backfill + preflight enforcement (`POST /api/v1/assets/backfill-identity`)
- ✅ Migration-hardening startup flow (`migrate deploy`, no `db push`)
- ✅ Source policy governance:
  - `GET /api/v1/import-policies`
  - `POST /api/v1/import-policies` (admin+)
  - source-required ingest enforcement + strict-source lenient bypass guard
- ✅ Imports UI upgrades:
  - quality panels/trend/CSV export
  - policy visibility + admin editor
  - role-aware read-only mode + save success/error feedback

### Current stop point
- Next planned dev pickup: **Step 21 / Phase 1**
  - asset/import annotations (labels + notes)
  - import/scan diff endpoint + UI
- Dev stack has been intentionally brought down for overnight break (`make down`).

## Pipeline (v1 practical combo)
`naabu -> nmap -> httpx -> nuclei`

## Quick Start (one command)
```bash
make up
```

### Local URLs
- Web: <http://localhost:3000>
- API health: <http://localhost:4000/health>

### Helpers
```bash
make ps      # containers status
make logs    # tail logs
make test    # health + queue smoke test
make down    # stop stack
make clean   # down + volumes + dangling image prune
```

### First-time bootstrap (macOS)
```bash
make bootstrap
colima start
```

### Database setup (API)
```bash
pnpm --filter @armadillo/api prisma:generate
pnpm --filter @armadillo/api prisma:migrate -- --name init_scans
```

## API sample
Role headers (auth scaffold):
- `x-armadillo-user: <actor>`
- `x-armadillo-role: owner|admin|staff|viewer`

Queue a scan (staff+):
```bash
curl -X POST http://localhost:4000/api/v1/scans \
  -H 'content-type: application/json' \
  -H 'x-armadillo-user: jason' \
  -H 'x-armadillo-role: staff' \
  -d '{
    "projectId": "proj-001",
    "requestedBy": "jason",
    "targets": [{"value": "192.168.1.0/24", "type": "cidr"}],
    "config": {"profile": "safe-default"}
  }'
```

Check status (viewer+):
```bash
curl http://localhost:4000/api/v1/scans/<scanId> \
  -H 'x-armadillo-user: jason' \
  -H 'x-armadillo-role: viewer'
```

Import XML and read normalized assets:
```bash
curl -X POST http://localhost:4000/api/v1/imports/xml \
  -H 'content-type: application/json' \
  -H 'x-armadillo-user: jason' \
  -H 'x-armadillo-role: staff' \
  -d '{"source":"manual","qualityMode":"strict","xml":"<assets><asset><ip>10.0.0.1</ip><hostname>srv-1</hostname></asset></assets>"}'

curl http://localhost:4000/api/v1/assets?limit=20 \
  -H 'x-armadillo-user: jason' \
  -H 'x-armadillo-role: viewer'

curl "http://localhost:4000/api/v1/assets?tag=web&source=xml&ip=10.0.0" \
  -H 'x-armadillo-user: jason' \
  -H 'x-armadillo-role: viewer'
```

Source policy admin API:
```bash
# list policies
curl http://localhost:4000/api/v1/import-policies \
  -H 'x-armadillo-user: jason' \
  -H 'x-armadillo-role: viewer'

# upsert policy (admin+)
curl -X POST http://localhost:4000/api/v1/import-policies \
  -H 'content-type: application/json' \
  -H 'x-armadillo-user: jason' \
  -H 'x-armadillo-role: admin' \
  -d '{"source":"manual","defaultQualityMode":"strict","allowBypassToLenient":false,"enabled":true}'
```

Backfill legacy assets missing identity keys (admin+):
```bash
curl -X POST http://localhost:4000/api/v1/assets/backfill-identity \
  -H 'x-armadillo-user: jason' \
  -H 'x-armadillo-role: admin'
```

Step-11/12 startup hardening:
- API startup runs `assets:enforce-identity` preflight before migrations.
- Preflight writes an audit report to `apps/api/prisma/reports/asset-identity-enforcement.json` in the API runtime.
- Startup now uses `prisma migrate deploy` (via `prisma:migrate:startup`) instead of `prisma db push`.
- Baseline migration path added for existing non-empty dev DBs (`20260225_step12_baseline`).

## Docs
- `docs/armadillo-v3-architecture.md`
- `docs/armadillo-v3-roadmap-90d.md`
- `docs/armadillo-v3-tooling-matrix.md`

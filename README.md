# 🛡️ Project Armadillo v3

Modern, queue-driven network discovery and security visibility platform.

## Current scaffold includes
- Next.js web shell (`apps/web`)
- NestJS API with scan enqueue/status endpoints (`apps/api`)
- BullMQ worker with staged pipeline stubs (`apps/worker`)
- Shared pipeline contracts (`packages/types`)

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
  -d '{"source":"manual","xml":"<assets><asset><ip>10.0.0.1</ip><hostname>srv-1</hostname></asset></assets>"}'

curl http://localhost:4000/api/v1/assets?limit=20 \
  -H 'x-armadillo-user: jason' \
  -H 'x-armadillo-role: viewer'

curl "http://localhost:4000/api/v1/assets?tag=web&source=xml&ip=10.0.0" \
  -H 'x-armadillo-user: jason' \
  -H 'x-armadillo-role: viewer'
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

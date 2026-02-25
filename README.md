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

## API sample
Queue a scan:
```bash
curl -X POST http://localhost:4000/api/v1/scans \
  -H 'content-type: application/json' \
  -d '{
    "projectId": "proj-001",
    "requestedBy": "jason",
    "targets": [{"value": "192.168.1.0/24", "type": "cidr"}],
    "config": {"profile": "safe-default"}
  }'
```

Check status:
```bash
curl http://localhost:4000/api/v1/scans/<scanId>
```

## Docs
- `docs/armadillo-v3-architecture.md`
- `docs/armadillo-v3-roadmap-90d.md`
- `docs/armadillo-v3-tooling-matrix.md`

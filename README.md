# 🛡️ Project Armadillo v3

Modern, queue-driven network discovery and security visibility platform.

## Current platform includes
- Next.js web app (`apps/web`)
- Fastify API (`apps/api`)
- BullMQ worker pipeline (`apps/worker`)
- Shared pipeline contracts (`packages/types`)
- PostgreSQL + Prisma migrations (`apps/api/prisma`)

---

## 🎯 Current Status (as of 2026-02-27)

| Phase | Status | Notes |
|-------|--------|-------|
| Phase 4 — Beta Hardening | ✅ **Complete** | Performance indexes, CI gates, threat model, rollback runbook |
| Phase 5 — Legacy Parity | ✅ **Complete** | Self-service submissions, notifications, private credentials, schedules |
| Phase 6 — Usability Modernization | 🔄 **U1 & U2 Complete** | Modern UI shell, mobile polish, demo dataset (480 assets, 720 vulns) |
| Phase 7 — Operator Confidence | 🔄 **Sprint 2 In Progress** | Triage velocity + risk prioritization intelligence |

### Phase 7 Sprint Breakdown

#### ✅ Sprint 1 — Remediation Focus (COMPLETE)
| Item | Feature | Deliverables |
|------|---------|--------------|
| 1 | **Vuln remediation tracking** | `assignedTo`, `dueDate`, `remediationStatus` + PATCH/POST endpoints + inline edit UI |
| 2 | **Global Cmd+K search** | `/api/v1/search` + modal UI with keyboard navigation |
| 3 | **Attention banner for failed scans** | `/api/v1/scans/attention` with 7-day trend + sparkline banner + retry |
| 4 | **Asset change badges** | `deltaSinceLast` column + badge UI (new/new_this_week/changed) |

#### 🔄 Sprint 2 — Risk Prioritization Intelligence (In Progress)
| Item | Feature | Status |
|------|---------|--------|
| 1 | **Exploitability-first grouping** | ✅ Filter tabs (All/🔥 Exploitable/📋 Theoretical), API stats + blast radius |
| 2 | **Blast radius chips** | ✅ Live API integration with hover tooltips |
| 3 | **Attack path simulation** | ✅ POST `/network/attack-path` — entry → target with hops + vulns |
| 4 | **Exposure scoring** | 🔲 Internet-facing detection + risk scoring |

---

## 🗺️ Future Roadmap

### Phase 7 Sprint 3 — Operator Usability (Planned)
- Incident runbooks UI with step-by-step guidance
- Evidence collection for findings (screenshots, logs, notes)
- Team skill matrix + assignment routing
- Bulk remediation actions
- Time-to-remediate dashboards

### Phase 8 — MSP Integration & Scale (Proposed)
- **Quality alert routing** — Auto-Teams ping when import quality = fail
- **Scan failure escalation** — 3x consecutive failures → admin notification
- **Schedule conflict warnings** — Calendar heatmap + overlap detection
- **Reports delivery tracking** — "Sent/Pending/Acknowledged" workflow
- **Customer portal stub** — Read-only tenant view with separate auth scope
- **Kubernetes production** — EKS+Fargate, KEDA auto-scaling, Aurora Global

---

## Quick Start (one command)
```bash
make up
```

### Local URLs
- Web: <http://localhost:3000>
- API health: <http://localhost:4000/health>

### API Auth Headers
- `x-armadillo-user: <actor>`
- `x-armadillo-role: owner|admin|staff|viewer`

### Key API Endpoints

**Vulnerability Management (Phase 7)**
```bash
# Exploitability filtering
curl 'http://localhost:4000/api/v1/vulns?hasExploit=true'
curl 'http://localhost:4000/api/v1/vulns/stats/exploitability'

# Blast radius for a CVE
curl 'http://localhost:4000/api/v1/vulns/CVE-2024-6387/blast-radius'

# Attack path simulation
curl -X POST 'http://localhost:4000/api/v1/network/attack-path' \
  -H 'content-type: application/json' \
  -d '{"entryAssetId":"...","targetAssetId":"..."}'

# Update remediation
curl -X PATCH 'http://localhost:4000/api/v1/vulns/123' \
  -H 'content-type: application/json' \
  -H 'x-armadillo-role: staff' \
  -d '{"assignedTo":"jason","dueDate":"2026-03-15","remediationStatus":"in_progress"}'

# Bulk update
curl -X POST 'http://localhost:4000/api/v1/vulns/bulk-update' \
  -H 'content-type: application/json' \
  -H 'x-armadillo-role: staff' \
  -d '{"ids":[1,2,3],"remediationStatus":"resolved"}'
```

**Global Search**
```bash
curl 'http://localhost:4000/api/v1/search?q=CVE-2024'
```

**Scan Management**
```bash
# Queue scan
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

# Failed scans attention
curl 'http://localhost:4000/api/v1/scans/attention'

# Retry failed scan
curl -X POST 'http://localhost:4000/api/v1/scans/<scanId>/retry'
```

**Asset Management**
```bash
# List assets with change badges
curl 'http://localhost:4000/api/v1/assets?badges=true'

# Import XML
curl -X POST http://localhost:4000/api/v1/imports/xml \
  -H 'content-type: application/json' \
  -H 'x-armadillo-user: jason' \
  -H 'x-armadillo-role: staff' \
  -d '{"source":"manual","qualityMode":"strict","xml":"<assets>...</assets>"}'
```

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

---

## 📚 Docs
- `docs/armadillo-v3-architecture.md`
- `docs/armadillo-v3-roadmap-90d.md`
- `docs/armadillo-v3-tooling-matrix.md`
- `docs/phase7-improvements-roadmap.md` — Operator confidence features
- `docs/sprint-phase7-1.md` — Sprint 1 completion (remediation tracking)
- `docs/sprint-phase7-2.md` — Sprint 2 progress (risk prioritization)
- `docs/ops-register.md` — Current operational status & decisions
- `k8s/` — Kubernetes deployment specs
- `docs/infrastructure/ARMADILLO-SCALE-PLAN.md` — Scale infrastructure blueprint

---

## 🔒 Operational Security Posture
- Signed session auth enabled for API
- Legacy header trust disabled in production
- Project scope enforcement active for scan/schedule paths
- Auth audit and lockout controls active
- Dev mode alert suppression available (`ARMADILLO_DEV_MODE=1`)

---

*Built with ❤️ by Comans Services — from reactive IT to proactive security.*

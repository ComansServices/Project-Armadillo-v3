# 🛡️ Project Armadillo v3

Modern, queue-driven network discovery and security visibility platform.

Built to replace the legacy Armadillo/WebMap stack with a secure, scalable architecture focused on practical operations.

## Why v3
Project Armadillo v3 is a full modernization effort:
- TypeScript-first monorepo
- Decoupled web, API, and worker services
- Redis queue orchestration for scan pipelines
- PostgreSQL-backed normalized findings model
- Security-first deployment posture for real-world use

---

## Architecture (Option A)
- **Web:** Next.js (App Router)
- **API:** NestJS (Fastify)
- **Workers:** BullMQ + Redis
- **Database:** PostgreSQL + Prisma (planned)
- **Observability:** OpenTelemetry + Grafana/Prometheus + Sentry (planned)
- **Auth:** OIDC/SAML + RBAC (planned)

### Practical scan combo (v1)
1. **naabu** → fast port discovery  
2. **nmap** → deep service/version enumeration  
3. **httpx** → web probing/fingerprinting  
4. **nuclei** → scoped template-based checks

---

## Repo Structure
```text
apps/
  web/        # Next.js frontend
  api/        # NestJS API
  worker/     # Queue workers (BullMQ)
packages/
  config/     # Shared config
  types/      # Shared types/contracts
  ui/         # Shared UI components
docs/
  armadillo-v3-architecture.md
  armadillo-v3-roadmap-90d.md
  armadillo-v3-tooling-matrix.md
```

---

## Quick Start
```bash
pnpm install
pnpm dev
```

### Local Services
- Web: <http://localhost:3000>
- API health: <http://localhost:4000/health>

---

## Documentation
- Architecture diagram: `docs/armadillo-v3-architecture.md`
- 90-day roadmap: `docs/armadillo-v3-roadmap-90d.md`
- Tooling matrix + safe defaults: `docs/armadillo-v3-tooling-matrix.md`

---

## Current Status
🚧 **Scaffold phase** — base services and planning docs are in place.

Next implementation targets:
- Queue contracts for multi-stage scan jobs
- XML import + normalization pipeline
- Findings API + dashboard views
- Docker Compose runtime profile

---

## Legacy Notice
Legacy implementation remains in `ComansServices/Project-Armadillo` and is treated as archive/reference.

Active development is in this repository.

# Project Armadillo v3 — Option A Architecture (TypeScript-first)

## Stack
- **Frontend:** Next.js (App Router) + Tailwind + Cytoscape/ECharts
- **API:** NestJS (Fastify adapter) + OpenAPI
- **Workers:** BullMQ + Redis (pipeline stages: naabu -> nmap -> httpx -> nuclei)
- **DB:** PostgreSQL + Prisma
- **Auth:** OIDC/SAML via Auth0 or Keycloak (RBAC + MFA)
- **Infra:** Docker + Terraform + managed Postgres/Redis
- **Observability:** OpenTelemetry + Prometheus/Grafana + Sentry

## System Diagram

```mermaid
flowchart LR
  U[User / Analyst] --> W[Next.js Web App]
  W -->|JWT/OIDC| A[NestJS API]
  W -->|SSE/WebSocket status| A

  A --> P[(PostgreSQL)]
  A --> R[(Redis)]
  A --> Q[BullMQ Queue]

  Q --> N1[naabu stage]
  N1 --> N2[nmap stage]
  N2 --> N3[httpx stage]
  N3 --> N4[nuclei stage]

  N4 --> X[Normalized Findings + Artifacts]
  X --> P

  A --> C[CVE/Enrichment Service]
  C --> E[External Feeds / NVD / CPE]
  C --> P

  A --> O[OTel Collector]
  N1 --> O
  N2 --> O
  N3 --> O
  N4 --> O
  W --> O
  O --> G[Grafana/Prometheus]
  O --> S[Sentry]
```

## Runtime Boundaries
- **Web app:** UI only, no direct scanner execution.
- **API:** AuthZ, tenancy, CRUD, orchestration, reporting endpoints.
- **Worker:** Executes scans/import parsing with constrained capability profile.
- **Scanner container:** Runs `nmap` under restricted network/file policies.

## Security Baseline
- No debug mode in prod, strict CORS/CSRF policies.
- Secrets from runtime secret manager (no repo secrets).
- RBAC by org/project/asset group.
- Immutable audit log for scan launches, edits, exports.
- Signed job payloads and worker allowlist execution profiles.

## Core Domain Objects
- `users`, `orgs`, `projects`
- `scan_jobs`, `scan_runs`, `scan_artifacts`
- `hosts`, `services`, `ports`, `cpe`, `cve_findings`
- `labels`, `notes`, `diff_reports`, `pdf_reports`
- `api_clients`, `audit_events`


## Practical Scan Pipeline (v1)
- Stage 1: `naabu` for fast port discovery
- Stage 2: `nmap` for deep service/version/NSE enumeration
- Stage 3: `httpx` for web endpoint probing/fingerprinting
- Stage 4: `nuclei` for scoped template-based checks

Each stage writes structured outputs to Redis queue + PostgreSQL persistence for full traceability.

# Armadillo v3 — Phase 4 Threat Model (Beta)

## Scope
- API (`apps/api`)
- Worker pipeline (`apps/worker`)
- Web UI (`apps/web`)
- Queue + DB (Redis/Postgres)
- Report generation + archive

## Assets to protect
- Scan requests + target definitions
- Scan artifacts/events
- Import payloads and normalized assets
- Vulnerability findings and reports
- Auth/role boundaries and audit trail integrity

## Trust boundaries
1. User/UI -> API
2. API -> Redis/Worker
3. Worker -> scan tools/runtime
4. API -> report archive filesystem
5. Internal notifications -> Teams

## Primary threats and controls

### T1: Scan execution abuse (unsafe targets/tool misuse)
- Risk: attacker triggers broad/internal scans or dangerous flags
- Controls:
  - safe-default profile contract
  - role checks (`staff+` for launch)
  - queue mediation + bounded worker concurrency
  - status/event audit trail for all runs

### T2: Privilege escalation / RBAC bypass
- Risk: viewer executes admin/staff mutations
- Controls:
  - centralized role gate checks in API
  - smoke tests include viewer-forbidden admin endpoint
  - explicit role headers in internal automation paths

### T3: Queue flooding / backlog denial
- Risk: high submit rate causes worker starvation
- Controls:
  - bounded queue worker concurrency
  - stage-based queue pipeline
  - failure handling + status transitions

### T4: Data leakage via reports
- Risk: over-broad report exposure and uncontrolled sharing
- Controls:
  - viewer role required for report fetch
  - internal confidentiality labels in PDFs
  - archived metadata index for operational traceability

### T5: Vulnerability enrichment noise / drift
- Risk: noisy findings reduce signal quality
- Controls:
  - deterministic enrichment seed rules
  - daily digest summaries + failure-only immediate alerts
  - archive-based historical review

### T6: Supply-chain/config drift in beta
- Risk: inconsistent runtime or migration state
- Controls:
  - migration files versioned in repo
  - phase4 smoke gate script + CI workflow
  - beta readiness checklist + rollback planning

## Residual risks (beta)
- Header-based role model is still scaffold-level (not final auth provider hardening)
- Report archive persistence is local filesystem (no object-store durability policy yet)
- Full load/perf profiling not completed yet for production traffic envelopes

## Phase 4 close conditions
- CI gate consistently green on PRs
- pen-test prep checklist complete
- rollback runbook rehearsed once
- known residual risks accepted by stakeholder sign-off

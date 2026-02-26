# Armadillo v3 — Beta Sign-off Sweep (2026-02-26)

## Summary verdict
**GO (conditional)** for controlled beta.

Rationale:
- Critical technical and operational flows pass in current environment.
- Remaining items are governance/sign-off completion tasks, not blocking engineering defects.

## Evidence captured
- Phase4 gate script: `scripts/ci_phase4_gate.sh` -> PASS
- Integration smoke: `scripts/integration_smoke_phase4.py` -> PASS (3/3)
- Endpoint perf sample (local):
  - `/api/v1/reports`: p95 ~6.56ms
  - `/api/v1/vulns?limit=200`: p95 ~4.16ms
- Index presence verified in Postgres:
  - `scans_createdAt_idx`, `scans_updatedAt_idx`
  - `xml_imports_source_createdAt_idx`
  - vuln detected/severity indexes

## Checklist status (high-level)

### 1) Performance hardening
- ✅ New indexes applied in current environment
- ✅ `/api/v1/reports` target met in local benchmark
- ✅ `/api/v1/vulns?limit=200` target met in local benchmark
- ⚠️ Cross-environment confirmation still required (staging/beta prod target env)

### 2) Integration tests (critical flows)
- ✅ Scan lifecycle
- ✅ Report archive + index
- ✅ RBAC viewer denial
- ✅ Import enrichment + auto-archive flow validated in prior phase runs

### 3) Security hardening
- ✅ Threat model doc present
- ✅ Pen-test prep checklist present
- ⚠️ Formal pen-test prep sign-off pending

### 4) Beta operations readiness
- ✅ Report automation + digest + failure alerting documented and active
- ✅ Rollback runbook documented
- ✅ Migration runbook + beta release notes documented
- ✅ Known limitations captured in beta release notes

## Required follow-ups before wider rollout
1. Execute same performance and smoke checks in target beta environment (not only local)
2. Complete formal pen-test prep sign-off record
3. Record owner approval against rollback/migration runbooks

## Recommendation
Proceed with **controlled beta rollout** while tracking the three follow-ups above as day-0 acceptance tasks.

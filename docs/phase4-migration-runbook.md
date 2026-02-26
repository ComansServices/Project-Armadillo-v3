# Armadillo v3 — Migration Runbook (Beta)

## Objective
Migrate from previous build state to Phase 4 beta safely with rollback confidence.

## Pre-migration
- [ ] Confirm backups are healthy and current
- [ ] Confirm target commit/tag approved
- [ ] Confirm maintenance window and owner on-call
- [ ] Capture baseline metrics (health, queue depth, error rate)

## Deployment sequence
1. Pull target commit
2. Start services with rebuild:
   - `make up`
3. Apply migrations (if not auto-applied by startup flow)
4. Verify migration file applied:
   - `20260226_step24_phase4_perf_indexes`

## Validation sequence
1. API health:
   - `GET /health` -> `{ok:true}`
2. Run phase4 gate:
   - `scripts/ci_phase4_gate.sh`
3. Manual spot checks:
   - `/vulns` sort/group/export
   - `/reports` archive visibility
   - import + scan PDF links

## Post-migration monitoring (first 60 min)
- API 5xx count
- Worker failure count
- Queue depth/backlog trend
- Report archive write success
- Teams alert/digest behavior

## Rollback decision threshold
Rollback if any critical flow remains broken >15 min after remediation attempts:
- scan launch/completion
- import/enrichment
- report generation/archive

## Rollback pointer
Use: `docs/phase4-rollback-runbook.md`

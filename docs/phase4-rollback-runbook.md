# Armadillo v3 — Phase 4 Rollback Runbook

## Purpose
Fast, controlled rollback procedure for beta incidents affecting API, web, worker, queue, or migrations.

## Trigger conditions
- Repeated 5xx on critical endpoints (`/api/v1/scans`, `/api/v1/imports`, `/api/v1/reports`)
- Worker stuck/backlog growth with failed recoveries
- Data integrity concerns after deployment/migration
- Security incident requiring immediate containment

## Rollback levels

### Level 1 — Service rollback (no DB rollback)
Use when code release is faulty but DB schema remains compatible.

1. Identify previous stable commit/tag.
2. Checkout stable commit.
3. Rebuild + restart stack:
   - `make up`
4. Validate:
   - `/health` = ok
   - `scripts/integration_smoke_phase4.py` passes
5. Announce incident resolved + monitoring window.

### Level 2 — Service + migration rollback
Use when migration introduced breaking behavior.

1. Freeze write operations (pause scan/enrichment triggers).
2. Backup DB immediately (`pg_dump` snapshot).
3. Revert services to previous stable release.
4. Apply compensating SQL migration (preferred) rather than destructive down migration.
5. Re-run smoke checks.
6. Resume write operations gradually.

### Level 3 — Full operational fallback
Use for major instability.

1. Disable non-critical cron automations (digests, optional checks).
2. Keep only core backup + failure alert jobs active.
3. Route to read-only/report-only mode where possible.
4. Start incident timeline and handoff.

## Post-rollback validation checklist
- [ ] API health stable for 15+ min
- [ ] Scan lifecycle completes end-to-end
- [ ] Report generation/archive works
- [ ] No runaway queue growth
- [ ] Teams failure alerts functional
- [ ] Daily digests still scheduled or intentionally paused

## Evidence capture
- git commit/tag rolled back to
- relevant logs (api/worker)
- DB snapshot reference
- impacted time window
- customer-visible impact summary

## Recovery follow-up
- Open corrective action task
- Add regression test before re-release
- Update threat model/checklists if new class of failure found

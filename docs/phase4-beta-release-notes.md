# Armadillo v3 — Phase 4 Beta Release Notes

## Release scope
This beta bundles roadmap phases through late Phase 4 hardening, including report automation and operational controls.

## Highlights
- Core scan pipeline (`naabu -> nmap -> httpx -> nuclei`) with queue orchestration
- XML import + normalization + quality controls
- CVE/CPE enrichment + vulnerability views
- RBAC role gating for critical actions
- Branded PDF reporting (ops/exec variants)
- Report archive API + UI (`/api/v1/reports`, `/reports`)
- Auto-report generation on enrichment + completed scans
- Failure-only immediate alerts + daily Teams digest
- Phase 4 CI smoke gate + threat model + pen-test prep docs

## Operational changes
- New cron: Armadillo reports daily digest (Teams)
- Worker now auto-archives scan reports on completion
- Enrichment endpoint auto-archives import reports

## Migration notes
- Apply migration: `20260226_step24_phase4_perf_indexes`
- No destructive schema changes in this release
- Validate index presence post-deploy

## Known beta limitations
- Header-based role model remains scaffold auth (final provider hardening pending)
- Report archive currently local filesystem-backed
- Full-scale load testing still pending

## Recommended go-live checks
1. Run `scripts/ci_phase4_gate.sh`
2. Verify `/api/v1/reports` returns recent archive entries
3. Trigger one enrichment and one scan, confirm auto-archive
4. Confirm Teams failure alert path in controlled test

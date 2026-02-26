# Armadillo v3 — Phase 4 Beta Readiness Checklist

## 1) Performance hardening
- [ ] Validate new DB indexes are applied in all environments
- [ ] Confirm `/api/v1/vulns` p95 latency at limit=200 under expected load
- [ ] Confirm `/api/v1/reports` remains <500ms for first 200 records
- [ ] Verify pagination limits enforced on high-cardinality endpoints

## 2) Integration tests (critical flows)
- [ ] Scan lifecycle: queue -> running -> completed/failed
- [ ] Import enrichment: import -> vuln enrich -> findings list
- [ ] Reporting: generate ops/exec PDFs -> archive -> list in `/api/v1/reports`
- [ ] RBAC smoke: viewer forbidden on staff/admin-only mutations

## 3) Security hardening
- [ ] Validate safe scan profile policy enforcement
- [ ] Validate queue bounded concurrency and worker fail behavior
- [ ] Threat model review completed (abuse, data leak, queue DOS)
- [ ] Pen-test prep checklist completed and signed off

## 4) Beta operations readiness
- [ ] Runbook updated for report automation + digest + failure alerts
- [ ] Rollback plan documented (API/web/worker + DB migration strategy)
- [ ] Legacy migration notes updated in project docs
- [ ] Known limitations + support boundaries documented

## Exit target
Production-ready beta candidate with recovery runbook + rollback confidence.

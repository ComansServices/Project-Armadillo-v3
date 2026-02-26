# Armadillo v3 — Pen-Test Prep Checklist (Phase 4)

## A) Environment readiness
- [ ] Dedicated beta target environment prepared
- [ ] Test accounts with viewer/staff/admin roles provisioned
- [ ] Non-production data set loaded (sanitized)
- [ ] Scan tools and queue stack running with stable baseline

## B) Access and auth checks
- [ ] Verify viewer cannot call admin/staff endpoints
- [ ] Verify staff can run scan/import actions only
- [ ] Verify role headers are logged in audit/event context where expected
- [ ] Confirm no debug bypass endpoints exposed

## C) API surface checks
- [ ] Validate input bounds (`limit`, filters, IDs)
- [ ] Validate 4xx behavior for malformed payloads
- [ ] Validate no stack traces returned in API responses
- [ ] Validate report endpoints require role and cannot enumerate arbitrary IDs beyond role scope assumptions

## D) Queue and execution safety
- [ ] Concurrency caps verified under burst load
- [ ] Worker failure path confirms scan status -> failed and alert is emitted
- [ ] Stage execution contract enforces approved tool chain only
- [ ] No direct unsandboxed command injection paths exposed in request payload

## E) Data and reporting controls
- [ ] Report archive write path permissions reviewed
- [ ] Archived metadata does not include secrets/tokens
- [ ] PDF outputs include confidentiality label
- [ ] Daily digest contains summary-level content only

## F) Observability and incident response
- [ ] Health endpoint monitored
- [ ] Failure alerts route confirmed (Teams)
- [ ] Runbook includes triage for failed scans, queue backlog, and report generation failures
- [ ] Rollback steps documented for API/web/worker images + migration considerations

## G) Deliverables for assessor
- [ ] API endpoint map (current)
- [ ] Architecture diagram and tooling matrix
- [ ] Threat model document
- [ ] Latest phase4 smoke test output
- [ ] Known limitations and accepted beta risks

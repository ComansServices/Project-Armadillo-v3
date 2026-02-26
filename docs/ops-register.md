# Armadillo v3 — Ops Register

Last updated: 2026-02-26 20:29 AEDT
Owner: Comans / Leo

## Current Program Status
- Phase 4 Beta Hardening: Complete (GO)
- Phase 5 Legacy Parity: Complete (Items 1–6 done)
- Phase 6 Usability Modernization:
  - U1 Foundations: Complete
  - U2 Core Workflow + Triage Pass: Complete
  - U3 Analysis-page enhancement: Next
- **Phase 7 Operator Confidence: Sprint 1 COMPLETE** (2026-02-27)

## Completed Milestones (latest)
1. Item 2 Network parity complete + desktop/mobile usability fixes
2. Item 3 Dashboard parity complete + filter/export + trend + mobile polish
3. Item 4 Host action shortcuts complete (safe templates + copy controls)
4. Item 5 Exploit enrichment parity complete (UI + CSV + report surfacing)
5. Item 6 Auth hardening complete (signed session path + scope + lockout/audit)
6. Prod hardening pass complete in stack config (`AUTH_ALLOW_LEGACY_HEADERS=false`)
7. Usability Phase U1 complete (shared app shell/nav, button-first actions, helper text framework across core pages)
8. Usability Phase U2 complete (overview/imports/assets + vulns/network/schedules interaction passes, mobile card fallbacks)
9. U2 consolidation complete (global control styling normalization)
10. U2 final polish complete (mobile topology readability, import policy layout density, overview row-count control)
11. Demo-scale synthetic data pack loaded for UX validation (120 scans, 480 assets, 720 vulns)
12. Full-page QA sweep executed across all routes including detail pages (`/imports/[id]`, `/assets/[id]`, `/scans/[id]`)
13. Detail pages upgraded to AppShell/helper-text pattern for full UI consistency
14. Imports hydration warning fixed (`input[name=source]` selector normalization in inline style block)

## Operational Security Posture (current)
- Signed session auth enabled for API
- Legacy header trust disabled in stack runtime
- Project scope enforcement active for key scan/schedule paths
- Auth audit and lockout controls active

## Active Risks / Watch Items
- Service token currently static in compose (dev convenience)
  - Action: move token issuance/rotation to secure secret management
- OIDC/SAML interactive login UI not yet implemented
  - Action: phase after parity (provider integration + session UX)

## Next Actions (approved)
1. Observe user trial feedback on seeded large-network dataset and log UX friction points
2. Execute Phase 6 U3 analysis-page enhancement backlog (network affordances + vuln triage density + reports UX cleanup)
3. Prepare Phase 6 release sign-off pack (before/after summary + decisions + residual polish items)
4. Plan auth next increment discovery (interactive OIDC/SAML UX + token/secret rotation strategy)

## Change Log (today)
- Added `docs/phase6-usability-modern-ui-plan.md`
- Updated parity and auth-hardening completion status
- Registered transition from feature parity to usability modernization
- Marked Phase 6 U2 complete and logged regression + polish evidence (`1a50ef4`, `ef6d61e`, `bd9791d`, `32c1db5`)
- Seeded demo-scale synthetic dataset for realistic usage rehearsal (scan/import/asset/vuln volume)
- Ran full page QA sweep and aligned detail pages with shared AppShell modern UI pattern
- Fixed imports-page hydration warning caused by style selector escaping mismatch
- **Dev Mode: Armadillo quality spike alerts suppressed** — `ARMADILLO_DEV_MODE=1` set via `launchctl` and shell profiles; all 3 alert scripts updated to exit early when dev mode active
- **Phase 7 Sprint 1 launched** — `docs/sprint-phase7-1.md` created; 4 items prioritized: vuln remediation tracking, global Cmd+K search, overview attention banner, asset new/changed badges
- **Phase 7 Sprint 1 COMPLETE** — All 4 items (backend + frontend + tested):
  - ✅ Item 1: Vuln remediation tracking (DB columns, PATCH /vulns/:id, POST /vulns/bulk-update, inline edit UI, Status/Assignee/Due columns)
  - ✅ Item 2: Global Cmd+K search (API endpoint + modal UI with keyboard nav)
  - ✅ Item 3: Attention banner (API with 7-day trend + UI banner with sparkline + retry)
  - ✅ Item 4: Asset change badges (deltaSinceLast column + badge UI with new/new_this_week/changed)
  - ✅ All APIs verified via automated testing (search, attention, vuln updates, asset badges)
- **Phase 7 Sprint 2 IN PROGRESS** — Items 1-3 backend complete:
  - ✅ Item 1: Exploitability-first grouping (stats API, blast radius, 🔥/📋 badges, filter tabs)
  - ✅ Item 2: Blast radius chips with live API data
  - ✅ Item 3: Attack path simulation API (entry → target path with vulns)
  - 🔲 Item 4: Exposure scoring (internet-facing detection)

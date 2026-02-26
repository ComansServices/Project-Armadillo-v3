# Armadillo v3 — Ops Register

Last updated: 2026-02-26 19:19 AEDT
Owner: Comans / Leo

## Current Program Status
- Phase 4 Beta Hardening: Complete (GO)
- Phase 5 Legacy Parity: Complete (Items 1–6 done)
- Current Focus: Post-parity usability modernization (Phase 6 planning)

## Completed Milestones (latest)
1. Item 2 Network parity complete + desktop/mobile usability fixes
2. Item 3 Dashboard parity complete + filter/export + trend + mobile polish
3. Item 4 Host action shortcuts complete (safe templates + copy controls)
4. Item 5 Exploit enrichment parity complete (UI + CSV + report surfacing)
5. Item 6 Auth hardening complete (signed session path + scope + lockout/audit)
6. Prod hardening pass complete in stack config (`AUTH_ALLOW_LEGACY_HEADERS=false`)
7. Usability Phase U1 complete (shared app shell/nav, button-first actions, helper text framework across core pages)

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
1. Execute Usability + Modern UI Phase U2 (core workflow refinements)
2. Redesign Scans + Imports + Assets interactions for faster triage
3. Add mobile table/card fallbacks on core workflow pages
4. Run breakpoint QA and present before/after pack

## Change Log (today)
- Added `docs/phase6-usability-modern-ui-plan.md`
- Updated parity and auth-hardening completion status
- Registered transition from feature parity to usability modernization

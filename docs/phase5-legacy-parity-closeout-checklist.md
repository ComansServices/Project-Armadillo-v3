# Armadillo v3 — Phase 5 Legacy Parity Closeout Checklist

Goal: close remaining legacy-era feature gaps in a controlled, one-by-one sequence.

## Work order (do in sequence)

### 1) Scan scheduling UI parity
- [x] Add scan schedule model (recurring + one-off)
- [x] Add UI to create/edit/disable schedules
- [x] Show next-run + last-run status in UI
- [x] Wire schedule execution to existing queue pipeline *(due-run processor + auto 60s poller)*
- [x] Add RBAC constraints (viewer read-only; staff/admin manage)
- [x] Acceptance: user can schedule scans from UI and see execution lifecycle

### 2) Network view / topology page
- [x] Define network graph data endpoint (nodes, links, metadata)
- [x] Implement `/network` page with host/service relationships
- [x] Add filters (import, subnet, service tag, open ports)
- [x] Add click-through to host/asset detail
- [x] Acceptance: parity-level network map usable for triage and discovery *(table + mini-map + grouping view)*

### 3) Stats & charts dashboard parity
- [x] Build dashboard cards (hosts, open ports, high-risk findings)
- [x] Add charts for top services, ports, OS families, severity trends
- [x] Add date range/import filters
- [x] Add export snapshot capability (CSV/JSON)
- [x] Acceptance: legacy-equivalent chart visibility on core metrics

### 4) Host action shortcuts parity
- [ ] Add UI actions to generate quick commands (curl/nikto/telnet-style)
- [ ] Add copy-to-clipboard buttons with clean formatting
- [ ] Add safeguards for unsafe command templates
- [ ] Acceptance: operator can copy practical host commands from asset/host page

### 5) Exploit enrichment parity
- [ ] Add optional exploit-source enrichment adapter(s)
- [ ] Store exploit references linked to CVE findings
- [ ] Display exploit references in `/vulns` and report outputs
- [ ] Add cache/retry/timeout controls to reduce noise
- [ ] Acceptance: findings can show exploit context when available

### 6) Production auth hardening completion
- [ ] Finalize auth provider implementation (OIDC/SAML path)
- [ ] Replace header-scaffold role trust with signed identity/session flow
- [ ] Add org/project scoping enforcement at auth boundary
- [ ] Add auth failure audit events and lockout policy
- [ ] Acceptance: scaffold auth removed from production path

## Delivery mechanics (for each item)
- [ ] Design note (scope + API/UI changes)
- [ ] Implementation in small phases
- [ ] Smoke/integration test updates
- [ ] Docs + runbook update
- [ ] Commit and release note entry

## Definition of done (Phase 5)
- All six parity tracks accepted
- Legacy feature gaps closed or intentionally deferred with owner sign-off
- Updated roadmap published with post-parity innovation priorities

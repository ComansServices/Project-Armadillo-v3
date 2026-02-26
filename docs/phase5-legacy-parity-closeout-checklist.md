# Armadillo v3 — Phase 5 Legacy Parity Closeout Checklist

Goal: close remaining legacy-era feature gaps in a controlled, one-by-one sequence.

## Work order (do in sequence)

### 1) Scan scheduling UI parity
- [x] Add scan schedule model (recurring + one-off) *(Phase 1 foundation landed)*
- [x] Add UI to create/edit/disable schedules *(create + toggle landed)*
- [ ] Show next-run + last-run status in UI
- [ ] Wire schedule execution to existing queue pipeline
- [x] Add RBAC constraints (viewer read-only; staff/admin manage)
- [ ] Acceptance: user can schedule scans from UI and see execution lifecycle

### 2) Network view / topology page
- [ ] Define network graph data endpoint (nodes, links, metadata)
- [ ] Implement `/network` page with host/service relationships
- [ ] Add filters (import, subnet, service tag, open ports)
- [ ] Add click-through to host/asset detail
- [ ] Acceptance: parity-level network map usable for triage and discovery

### 3) Stats & charts dashboard parity
- [ ] Build dashboard cards (hosts, open ports, high-risk findings)
- [ ] Add charts for top services, ports, OS families, severity trends
- [ ] Add date range/import filters
- [ ] Add export snapshot capability (CSV/JSON)
- [ ] Acceptance: legacy-equivalent chart visibility on core metrics

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

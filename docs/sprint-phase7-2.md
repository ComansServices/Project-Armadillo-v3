# Armadillo v3 — Phase 7 Sprint 2
**Date:** 2026-02-27  
**Status:** In Progress  
**Sprint Goal:** Risk prioritization intelligence — exploitability focus + attack path visualization

---

## Sprint Backlog (Priority Order)

### 🎯 Sprint 2 Scope (4 items)

| Priority | Item | Location | Effort | Status |
|----------|------|----------|--------|--------|
| P1 | **Exploitability-first grouping** — "Has Public Exploit" vs "Theoretical Risk" split view | `/vulns` | Medium | 🔲 TODO |
| P1 | **Blast radius chips** — Show "affects 12 hosts" directly in vuln list | `/vulns` | Low | 🔲 TODO |
| P2 | **Attack path simulation** — "If entry point X, can reach Y?" query mode | `/network` | High | 🔲 TODO |
| P2 | **Exposure scoring** — Internet-adjacent assets with Critical vulns auto-surface | `/assets` + `/network` | Medium | 🔲 TODO |

---

## Item 1: Exploitability-First Grouping

### Requirements
- [ ] Add filter toggle: "All" | "Has Exploit" | "Theoretical Only"
- [ ] Group vulns by exploitability in list view
- [ ] Visual badge: 🔥 "Public Exploit Available" vs 📋 "Theoretical Risk"
- [ ] Sort exploitables first by default when filter is "All"

### API Changes
- [ ] Add `hasExploit` computed field to vuln response (check exploitRefs array)
- [ ] Add `?hasExploit=true|false` filter param to GET /vulns
- [ ] Add blast radius count (affected assets count) to vuln response

### UI Changes
- [ ] Exploitability filter buttons/tabs
- [ ] Group headers in table: "🔥 Exploitable (n)" / "📋 Theoretical (n)"
- [ ] Exploit badge component

---

## Item 2: Blast Radius Chips

### Requirements
- [ ] Calculate and display how many unique assets affected by each CVE
- [ ] Show chip in vuln row: "Affects 12 hosts"
- [ ] Tooltip showing breakdown by severity/asset type

### API Changes
- [ ] Add `affectedAssetCount` to vuln response
- [ ] New endpoint: GET `/api/v1/vulns/:cve/blast-radius` for detailed breakdown

### UI Changes
- [ ] Blast radius chip component
- [ ] Hover tooltip with asset breakdown

---

## Item 3: Attack Path Simulation

### Requirements
- [ ] Query mode: "Simulate attack from [entry asset] to [target asset]"
- [ ] Visualize hops through network topology
- [ ] Show path with vulnerability context per hop

### API Changes
- [ ] POST `/api/v1/network/attack-path` with `{entryAssetId, targetAssetId}`
- [ ] Return path as array of hops with:
  - Asset at each hop
  - Open ports/services
  - Vulnerabilities that could enable lateral movement

### UI Changes
- [ ] Attack path query panel (entry selector → target selector → Simulate)
- [ ] Path visualization overlay on network graph
- [ ] Path list view (alternative to graph)

---

## Item 4: Exposure Scoring

### Requirements
- [ ] Auto-identify internet-adjacent assets (public IPs, DMZ tags)
- [ ] Calculate exposure score: (critical vulns × internet accessibility)
- [ ] Surface high-exposure assets in overview banner

### API Changes
- [ ] Add `isInternetFacing` computed field to assets
- [ ] Add `exposureScore` (0-100) based on vuln severity + network position
- [ ] GET `/api/v1/assets?highExposure=true` filter
- [ ] Add high exposure count to `/api/v1/scans/attention` response

### UI Changes
- [ ] Exposure badge: 🔴 Critical / 🟠 High / 🟡 Medium / 🟢 Low
- [ ] High exposure section in overview attention banner
- [ ] Filter in assets page: "High Exposure Only"

---

## Progress Log

| Date | Item | Action | Commit |
|------|------|--------|--------|
| 2026-02-27 | — | Sprint 2 created | — |
| 2026-02-27 | Item 1 | Exploitability stats API + blast radius endpoints | API rebuild |
| 2026-02-27 | Item 1 | Exploitability filter tabs + 🔥/📋 badges + grouped view | Frontend |
| 2026-02-27 | Item 2 | Blast radius chip component with API integration + tooltip | Frontend |
| 2026-02-27 | Item 3 | Attack path simulation API endpoint | API rebuild |
| 2026-02-27 | Item 3 | Attack path returns path with hops, vulnerabilities, lateral movement risk | PASS |
| 2026-02-27 | **Status** | **Items 1-3 Backend Complete** — Frontend UI for attack path remaining | — |

---

## Dependencies

- Requires Phase 7 Sprint 1 (vuln remediation + search) to be complete ✅
- Network topology data already available via `/api/v1/network`
- Asset port/service data available

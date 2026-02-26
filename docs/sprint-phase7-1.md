# Armadillo v3 — Phase 7 Sprint 1
**Date:** 2026-02-27  
**Status:** In Progress  
**Sprint Goal:** Operator-confidence-10x via triage velocity + command centre

---

## Sprint Backlog (Priority Order)

### 🎯 Sprint 1 Scope (4 items)

| Priority | Item | Location | Effort | Status |
|----------|------|----------|--------|--------|
| P1 | **Vuln remediation tracking** — Assignee / Due Date / Status columns | `/vulns` | Medium | 🔲 TODO |
| P1 | **Global Cmd+K search** — Jump to CVE, IP, scan ID | Global | Medium | 🔲 TODO |
| P1 | **Overview attention banner** — Failed scans 24h + retry | `/` | Low | 🔲 TODO |
| P2 | **Asset "new today/week" badges** — Delta indicators | `/assets` | Low | 🔲 TODO |

---

## Item 1: Vulnerability Remediation Tracking

### Requirements
- [ ] Add `assigned_to` (string) column to vulns table
- [ ] Add `due_date` (date, nullable) column to vulns table  
- [ ] Add `remediation_status` (enum: open/in_progress/on_hold/resolved) column
- [ ] Expose fields in `/vulns` table view
- [ ] Inline edit for assignee and status
- [ ] Date picker for due date

### API Changes
- [ ] PATCH `/api/v1/vulns/:id` — update remediation fields
- [ ] Filter by `assigned_to`, `remediation_status`, `due_date`

### UI Changes
- [ ] New columns in vulns table
- [ ] Bulk assign action
- [ ] Status badge colors (open=red, in_progress=yellow, resolved=green)

---

## Item 2: Global Cmd+K Search

### Requirements
- [ ] `Cmd+K` / `Ctrl+K` hotkey opens search modal
- [ ] Search across: CVEs, IPs, hostnames, scan IDs, import IDs
- [ ] Instant results with keyboard navigation
- [ ] Enter to navigate to detail page

### Search Index
- [ ] CVE: `/vulns?cve={query}`
- [ ] IP: `/assets?ip={query}`
- [ ] Hostname: `/assets?hostname={query}`
- [ ] Scan ID: `/scans?id={query}`
- [ ] Import ID: `/imports?id={query}`

### UI Changes
- [ ] Global search component in AppShell
- [ ] Modal with result type icons
- [ ] Highlight matching text

---

## Item 3: Overview Attention Banner

### Requirements
- [ ] Query scans failed in last 24h
- [ ] Banner appears at top of `/` when count > 0
- [ ] Shows: "3 scans failed in last 24h" + [View] [Retry All]
- [ ] One-click retry opens confirmation modal
- [ ] 7-day sparkline micro-chart (bonus)

### API Changes
- [ ] GET `/api/v1/scans?status=failed&since=24h` (exists, may need since filter)
- [ ] POST `/api/v1/scans/:id/retry` (retry failed scan)

### UI Changes
- [ ] AttentionBanner component
- [ ] Sticky at top of overview page
- [ ] Severity coloring (red if >5 fails, orange if 1-5)

---

## Item 4: Asset "New Today/Week" Badges

### Requirements
- [ ] Add `first_seen_at` (timestamp) to assets table
- [ ] Add `last_scan_delta` (JSON) — port/service changes vs previous scan
- [ ] Badge on asset row: "New today", "New this week", "Changed"
- [ ] Tooltip showing delta details

### API Changes
- [ ] Include `first_seen_at` in asset response
- [ ] Calculate delta on scan completion (background job)

### UI Changes
- [ ] Badge component in asset table
- [ ] Delta tooltip on hover
- [ ] Filter by "New assets"

---

## Progress Log

| Date | Item | Action | Commit |
|------|------|--------|--------|
| 2026-02-27 | — | Sprint 1 created | — |
| 2026-02-27 | Item 1 | Database migration + Prisma schema updated (`step28_remediation_tracking`) | Migration applied |
| 2026-02-27 | Item 1 | API endpoints added: PATCH /vulns/:id, POST /vulns/bulk-update, updated GET /vulns with filters | — |
| 2026-02-27 | Item 1 | CSV export updated with new columns (assignedTo, dueDate, remediationStatus) | — |
| 2026-02-27 | Item 2 | Global search API endpoint added: GET /api/v1/search (CVEs, IPs, hostnames, scan IDs, import IDs) | — |
| 2026-02-27 | Item 3 | Attention banner API added: GET /scans/attention (failed scans 24h + 7-day trend) + POST /scans/:id/retry | — |
| 2026-02-27 | Item 4 | Asset delta tracking migration + `deltaSinceLast` JSON column added | — |
| 2026-02-27 | Item 4 | Asset badge logic implemented: `new` / `new_this_week` / `changed` with tooltip | — |
| 2026-02-27 | Item 4 | GET /assets endpoint enhanced with `?badges=true` parameter | — |
| 2026-02-27 | **Sprint 1** | **All 4 backend items complete** — Frontend implementation ready to start | — |
| 2026-02-27 | Item 1 (FE) | Vuln remediation UI: inline edit component + table columns (Status/Assignee/Due) + filters | — |
| 2026-02-27 | Item 2 (FE) | Global Cmd+K search modal with keyboard navigation (Cmd+K hotkey, ↑↓ navigate, ↵ select) | — |
| 2026-02-27 | Item 3 (FE) | Attention banner component with sparkline trend + retry functionality | — |
| 2026-02-27 | Item 4 (FE) | Asset badge component (new/new_this_week/changed) with tooltips | — |
| 2026-02-27 | **Sprint 1** | **FRONTEND COMPLETE** — All 4 UI components built and integrated | — |
| 2026-02-27 | Testing | API endpoints verified: GET /search, GET /scans/attention, PATCH /vulns/:id, GET /assets?badges=true | API rebuild |
| 2026-02-27 | Testing | Search API returns CVEs with asset context | PASS |
| 2026-02-27 | Testing | Attention API returns 7-day trend with completed/failed counts | PASS |
| 2026-02-27 | Testing | Vuln API includes assignedTo, dueDate, remediationStatus fields | PASS |
| 2026-02-27 | Testing | Assets API with ?badges=true returns new/new_this_week/changed badges | PASS |
| 2026-02-27 | **Status** | **PHASE 7 SPRINT 1 COMPLETE** — Backend, Frontend, and API integration verified | — |

---

## Next Sprint Candidates (Sprint 2)

1. Exploitability-first grouping in vulns
2. Attack path simulation in network
3. Schedule conflict warnings
4. Reports delivery status

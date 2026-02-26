# Armadillo v3 — Usability & Modern UI Plan

Date: 2026-02-26
Owner: Comans / Leo
Status: U1 delivered; U2 delivered (core workflows + triage pages complete); U3 queued

## Objective
Improve operator speed, comprehension, and confidence by modernizing page structure, action hierarchy, and helper guidance across desktop + mobile.

## UX Targets
- Reduce click-paths for common actions (scan → triage → report)
- Replace scattered text links with clear CTA buttons
- Add consistent page purpose + helper text
- Improve mobile readability and reduce table-overload friction

## Information Architecture (proposed)

Primary navigation:
1. Overview
2. Scans
3. Imports
4. Assets
5. Vulnerabilities
6. Network
7. Schedules
8. Reports
9. Settings

Grouping:
- Operate: Scans, Schedules
- Investigate: Imports, Assets, Vulns, Network
- Communicate: Reports
- Control: Settings

## Global UI Pattern Changes
- Introduce reusable components:
  - `PageHeader`
  - `ActionBar`
  - `FilterBar`
  - `StatCard`
  - `DataTable`
  - `EmptyState`
  - `HelpCallout`
- Button-first hierarchy:
  - Primary button: key action (e.g. Run Scan)
  - Secondary button: related actions (e.g. Export)
  - Tertiary text/icon actions for low-priority links
- Standard helper content on every page:
  1. What this page is for
  2. When to use it
  3. Recommended first action
  4. Empty-state guidance

## Page-Level Improvement Plan

### Overview
- KPI strip + active risk summary
- "What needs attention now" panel
- Quick-action buttons (Run Scan / Import XML / Open Vulns / Generate Report)

### Scans
- Strong status chips + stage summary
- Sticky filters
- Row action buttons: View / Compare / Report
- Better timeline readability + failure summary

### Imports
- Quality banner (pass/warn/fail) with explanation
- Policy helper text (strict vs lenient)
- Action buttons: Enrich / Report / View Assets

### Assets
- Card/table toggle
- Better filter chips
- Quick action buttons per row
- Cleaner at-a-glance block in asset detail

### Vulnerabilities
- Triage summary at top
- Severity-group view with accordion option
- Per-row quick actions + exploit confidence hints
- Mobile card mode for findings

### Network
- Segmented mode control (Service / Subnet)
- Legend and interaction hinting
- Stronger panel guidance for node selection

### Schedules
- Next-run countdown + clearer on/off toggle
- Cron presets
- Safer confirmation for risky actions

### Reports
- Report cards by audience (Ops / Exec)
- One-click download/open-source context actions
- Better context/helper text for report purpose

## U1 Delivery Notes (completed)
- Added shared app shell component with consistent top navigation across core pages.
- Implemented button-first quick action bar on overview/import pages.
- Added standard helper callout block (Purpose / When to use / Start here) across core UIs.
- Applied foundation pattern to Overview, Dashboard, Imports, Assets, Vulnerabilities, Network, Schedules, and Reports.

## Delivery Phases

### U1 — Foundations (2–3 days)
- App shell/nav and shared component library
- Button hierarchy normalization
- Standard page headers + helper text pattern

### U2 — Core Workflow Pages (3–4 days) ✅ Complete
- Overview, Imports, Assets UX refactor completed
- Vulnerabilities, Network, Schedules interaction pass completed
- Mobile responsiveness + table/card fallbacks completed across heavy-data pages
- Consolidation pass completed (shared control styling in app shell)
- Full desktop/mobile regression pack executed and captured

### U3 — Analysis Pages (2–3 days)
- Vulnerability triage UX
- Network UX polish + legend + mode controls
- Reports UX cleanup

### U4 — Validation & Release (1–2 days)
- Breakpoint QA (desktop/mobile)
- Accessibility and keyboard flow sanity pass
- Copy clarity pass
- Before/after screenshot pack and sign-off

## Success Metrics
- Time-to-first-action decreases
- Scan-to-triage workflow clicks decrease
- Mobile overflow/usability defects near zero
- Fewer operator clarification questions
- Positive owner/operator qualitative feedback

## U2 Closure Evidence (2026-02-26)
- Commits:
  - `1a50ef4` — U2 slice 1 (Overview/Imports/Assets)
  - `ef6d61e` — U2 continuation (Vulns/Schedules/Network)
  - `bd9791d` — consolidation pass (shared control styling)
  - `32c1db5` — final polish (mobile topology readability, imports policy density, overview row-density control)
- Visual regression coverage:
  - Desktop: `/`, `/imports`, `/assets`, `/vulns`, `/network`, `/schedules`, `/reports`, `/dashboard`
  - Mobile: `/`, `/imports`, `/assets`, `/vulns`, `/network`, `/schedules`
- Captured screenshots are stored under `.openclaw/media/browser/*` during QA runs.

## Immediate Next Step
Proceed to U3 analysis-page enhancement backlog (legend/mode affordances on network, vuln triage density controls, reports UX cleanup).

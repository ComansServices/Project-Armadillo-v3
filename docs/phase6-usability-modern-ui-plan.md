# Armadillo v3 — Usability & Modern UI Plan

Date: 2026-02-26
Owner: Comans / Leo
Status: U1 delivered (foundations complete); U2 queued

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

### U2 — Core Workflow Pages (3–4 days)
- Overview, Scans, Imports, Assets UX refactor
- Mobile responsiveness + table/card fallbacks

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

## Immediate Next Step
Kick off U1 with component scaffold and redesign of Overview + Scans as first review milestone.

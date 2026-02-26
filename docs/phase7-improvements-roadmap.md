# Armadillo v3 — Phase 7 Improvements Roadmap

**Date:** 2026-02-26  
**Status:** Proposed / Backlog Ready  
**Owner:** Comans / Leo

---

## Executive Summary

Based on full UX sweep across all pages with operator workflow intent in mind, the following improvements are proposed to move Armadillo from "functional" to "operator-confidence-10x".

---

## Strategic Improvements by Priority

### P1 — Command Centre Enhancement

#### 1) Overview (/) — True Command Centre
**Current:** Lists scans chronologically  
**Gap:** No "what needs my attention NOW" signal

**Proposed:**
- **🔥 Attention banner**: Auto-surface failed scans from last 24h with one-click retry
- **📊 Trend micro-chart**: "Scans completed vs failed" mini-sparkline last 7 days
- **⚡ Quick actions**: "Run ad-hoc scan" button (opens minimal target dialog without leaving page)
- **🎯 Scan health indicators**: Avg duration trend (flag if today's scans taking 2x longer)

---

### P1 — Triage Velocity

#### 2) Vulnerabilities (/vulns) — Prioritised Action
**Current:** Flat table of CVEs  
**Gap:** Still requires manual mental prioritisation

**Proposed:**
- **Exploitability-first grouping**: Split view "Has Public Exploit" vs "Theoretical Risk"
- **Blast radius chips**: Show "affects 12 hosts" directly in list, not just after click
- **Remediation tracking**: Add "Assigned To" + "Due Date" + "Status" columns to track fix workflow
- **Ticket integration stub**: "Create Jira ticket" action per vuln (even if stubbed for now)

---

### P2 — Change Intelligence

#### 3) Assets (/assets) — Change Awareness
**Current:** Static host inventory  
**Gap:** No visibility into "what's new/changed"

**Proposed:**
- **First-seen highlighting**: Badge "New today" / "New this week" on IP/hostname
- **Delta since last import**: Show "(+3 ports, -1 service)" if asset changed vs previous scan
- **Risk heatmap per asset**: Aggregate vuln score (critical count × exposure) as color chip

---

### P2 — Risk Visualisation

#### 4) Network (/network) — Attack Path Focus
**Current:** Topology visualisation  
**Gap:** Hard to read; no actionable "dangerous path" insight

**Proposed:**
- **Attack path simulation**: "If entry point is X, what can reach Y?" query mode
- **Exposure scoring**: Auto-surface internet-adjacent assets with Critical vulns
- **Service dependency map**: "Web tier → DB tier → Backend" logical grouping beyond raw nodes
- **Topology legend + zoom controls** for larger networks

---

### P3 — Operational Reliability

#### 5) Schedules (/schedules) — Conflict Awareness
**Current:** Cron text management  
**Gap:** No conflict awareness or calendar view

**Proposed:**
- **Calendar heatmap**: Visual scan windows so you don't overlap heavy jobs
- **Conflict warnings**: Alert if two schedules hit same CIDR at same time
- **Pause with reason**: "Paused: Customer maintenance window" annotation

---

### P3 — Navigation Speed

#### 6) Cross-App Search — Find Anything Fast
**Current:** Per-page filters only  
**Gap:** Can't jump from vuln to asset to scan quickly

**Proposed:**
- **Global Cmd+K search**: 
  - "CVE-2024-6387" → direct vuln
  - "10.0.0.5" → asset detail
  - "scan-0012" → scan detail
- **Breadcrumb persistence**: Remember path: Vuln → Asset → Import → (back to Vuln)

---

### P3 — Delivery Tracking

#### 7) Reports (/reports) — Distribution Readiness
**Current:** Archive list  
**Gap:** No customer delivery tracking

**Proposed:**
- **Delivery status**: "Sent to client" / "Pending review" / "Client acknowledged" workflow
- **Scheduled report preview**: Show what *will* be in next Monday exec report before it runs
- **Distribution log**: Tracked sends (Teams webhook confirmation, email receipt)

---

### P4 — MSP Integration

#### 8) Integration Readiness — Comans Operations
**What's missing for real MSP use:**

**Proposed:**
- **Quality alert routing**: Auto-Teams ping when import quality = fail (not just UI badge)
- **Scan failure escalation**: If scan fails 3x consecutively → escalate to admin notification
- **Customer portal stub**: Read-only view of their assets/vulns (separate auth scope)

---

## Quick Wins (Implement First)

| Rank | Improvement | Effort | Impact |
|------|-------------|--------|--------|
| 1 | Vuln remediation tracking (Assignee/Due/Status) | Medium | High |
| 2 | Global Cmd+K search | Medium | High |
| 3 | Overview attention banner | Low | High |
| 4 | Asset "new today" badges | Low | Medium |
| 5 | Schedule conflict warnings | Low | Medium |

---

## Notes
- Improvements derived from desktop/mobile QA sweep with synthetic dataset (480 assets, 720 vulns, 128 scans)
- All pages currently functional; these are maturity enhancements
- Database schema may need extension for remediation tracking and delivery status fields

---

**Next Step:** Review priorities with Jason → select top 2-3 for Phase 7 implementation sprint.

import { useState, useMemo } from "react";

// ── Story Data with Dependencies, Effort & Baseline Status ──
// status: "done" = already in codebase, "partial" = foundation exists but needs extension, "new" = not started
const STORIES = [
  // Foundation (Sprint 0) — infra upgrades to existing stack
  { id: "INFRA-01", title: "User & RBAC Models (Prisma Migration)", section: "Foundation", priority: "P0", effort: 3, sprint: 0, deps: [], type: "infra", theme: "foundation", status: "new", note: "Existing auth uses signed sessions + header trust. Need formal User/ProjectMembership/Role models." },
  { id: "INFRA-02", title: "RLS Policies on All Tenant Tables", section: "Foundation", priority: "P0", effort: 3, sprint: 0, deps: ["INFRA-01"], type: "infra", theme: "foundation", status: "new", note: "No RLS exists. Assets scope via importId, not projectId." },
  { id: "INFRA-03", title: "Prisma Middleware (projectId auto-inject)", section: "Foundation", priority: "P0", effort: 2, sprint: 0, deps: ["INFRA-01"], type: "infra", theme: "foundation", status: "new", note: "No Prisma middleware. Routes manually filter. Need auto-inject." },
  { id: "INFRA-04", title: "Zod Validation Layer (Fastify + Env)", section: "Foundation", priority: "P0", effort: 2, sprint: 0, deps: [], type: "infra", theme: "foundation", status: "new", note: "No Zod yet. API uses manual validation. Need schema-first." },
  { id: "INFRA-05", title: "EPSS + KEV Sync Workers (BullMQ cron)", section: "Foundation", priority: "P0", effort: 3, sprint: 0, deps: [], type: "infra", theme: "foundation", status: "new", note: "BullMQ worker exists but no EPSS/KEV jobs. Add cron sync." },
  { id: "INFRA-06", title: "packages/scoring (Composite Score Engine)", section: "Foundation", priority: "P0", effort: 2, sprint: 0, deps: ["INFRA-05"], type: "infra", theme: "foundation", status: "new", note: "Only packages/types exists. Need new scoring package." },
  { id: "INFRA-07", title: "MinIO (Open Source) + Evidence Storage Setup", section: "Foundation", priority: "P0", effort: 1, sprint: 0, deps: [], type: "infra", theme: "foundation", status: "new", note: "No MinIO in docker-compose. Add container + S3 client." },
  { id: "INFRA-08", title: "ScanCredential Model + AES-256 Vault", section: "Foundation", priority: "P1", effort: 2, sprint: 0, deps: ["INFRA-01"], type: "infra", theme: "foundation", status: "new", note: "No credential vault. Scan configs stored as plain JSON." },
  { id: "INFRA-09", title: "Notification Router (SMTP + Webhooks)", section: "Foundation", priority: "P1", effort: 3, sprint: 0, deps: [], type: "infra", theme: "foundation", status: "new", note: "No notification system exists. Build packages/notifications." },
  { id: "INFRA-10", title: "UI Stack Upgrade (Tailwind + shadcn + RHF)", section: "Foundation", priority: "P0", effort: 2, sprint: 0, deps: [], type: "infra", theme: "foundation", status: "new", note: "Web uses plain inline styles. Need Tailwind + shadcn + react-hook-form." },
  { id: "INFRA-11", title: "Ollama Docker + LLM Gateway (OpenAI-compat)", section: "Foundation", priority: "P0", effort: 2, sprint: 0, deps: [], type: "infra", theme: "foundation", status: "new", note: "No AI/LLM infra. Add Ollama container + openai SDK gateway." },

  // Sprint 1: Core Intelligence + P0 Operator Features
  { id: "US-INT.01", title: "EPSS Score Integration", section: "Intelligence", priority: "P0", effort: 3, sprint: 1, deps: ["INFRA-05", "INFRA-06"], type: "feature", theme: "intelligence", status: "new" },
  { id: "US-INT.02", title: "CISA KEV Flagging", section: "Intelligence", priority: "P0", effort: 2, sprint: 1, deps: ["INFRA-05"], type: "feature", theme: "intelligence", status: "new" },
  { id: "US-INT.03", title: "Composite Risk Score", section: "Intelligence", priority: "P0", effort: 5, sprint: 1, deps: ["US-INT.01", "US-INT.02", "INFRA-06"], type: "feature", theme: "intelligence", status: "new" },
  { id: "US-7.3.04", title: "Bulk Remediation Actions", section: "Sprint 7.3", priority: "P0", effort: 3, sprint: 1, deps: ["INFRA-04"], type: "feature", theme: "operator", status: "partial", note: "POST /vulns/bulk-update exists (status only). Extend: add bulk assign, due date, notes." },
  { id: "US-7.3.08", title: "Vulnerability Age Tracking + SLA Warnings", section: "Sprint 7.3", priority: "P0", effort: 3, sprint: 1, deps: ["INFRA-04"], type: "feature", theme: "operator", status: "new", note: "detectedAt exists on vulns. Need age calc, SLA config, colour badges, breach warnings." },
  { id: "US-OPS.01", title: "Saved Views & Filters", section: "Ops Excellence", priority: "P0", effort: 3, sprint: 1, deps: ["INFRA-10"], type: "feature", theme: "ops", status: "new", note: "URL-based filters exist. Need named saved views with persistence + sharing." },

  // Sprint 2: Auth, API Keys, PSA + AI Foundation
  { id: "US-8.08", title: "API Key Authentication", section: "Phase 8", priority: "P0", effort: 5, sprint: 2, deps: ["INFRA-01", "INFRA-04"], type: "feature", theme: "platform", status: "new", note: "Auth is header/session based. Need API key model, hashing, rate limiting." },
  { id: "US-ECO.01", title: "PSA/Ticketing Integration (CW + Halo)", section: "Integrations", priority: "P0", effort: 8, sprint: 2, deps: ["US-8.08", "INFRA-04"], type: "feature", theme: "integrations", status: "new" },
  { id: "US-AI.01", title: "AI Remediation Guidance (Ollama)", section: "AI & Auto", priority: "P0", effort: 5, sprint: 2, deps: ["INFRA-06", "INFRA-11"], type: "feature", theme: "ai", status: "new" },
  { id: "US-8.07", title: "Multi-Tenant Dashboard Aggregation", section: "Phase 8", priority: "P0", effort: 5, sprint: 2, deps: ["INFRA-01", "INFRA-02", "US-INT.03"], type: "feature", theme: "platform", status: "partial", note: "/dashboard/summary exists but single-project. Need cross-project aggregation + RLS." },

  // Sprint 3: Compliance + Revenue + Reporting
  { id: "US-COMP.01", title: "Essential Eight Mapping", section: "Compliance", priority: "P0", effort: 8, sprint: 3, deps: ["US-INT.03"], type: "feature", theme: "compliance", status: "new" },
  { id: "US-REV.02", title: "Security Posture Score (Client-Facing)", section: "Revenue", priority: "P0", effort: 5, sprint: 3, deps: ["US-INT.03", "INFRA-06"], type: "feature", theme: "revenue", status: "new" },
  { id: "US-REV.01", title: "Pre-Sales Risk Assessment Report (PDF)", section: "Revenue", priority: "P0", effort: 5, sprint: 3, deps: ["US-REV.02", "INFRA-07"], type: "feature", theme: "revenue", status: "partial", note: "PDF reports exist (pdfkit for imports/scans). Need @react-pdf upgrade + posture report template." },
  { id: "US-7.3.01", title: "Incident Runbook Library", section: "Sprint 7.3", priority: "P1", effort: 3, sprint: 3, deps: [], type: "feature", theme: "operator", status: "new" },
  { id: "US-7.3.02", title: "Evidence Attachment for Findings", section: "Sprint 7.3", priority: "P1", effort: 3, sprint: 3, deps: ["INFRA-07"], type: "feature", theme: "operator", status: "new", note: "Annotations exist (text). Need file attachments via MinIO." },

  // Sprint 4: Notifications, Digests, Webhook System
  { id: "US-8.09", title: "Webhook Event System", section: "Phase 8", priority: "P1", effort: 5, sprint: 4, deps: ["US-8.08", "INFRA-09"], type: "feature", theme: "platform", status: "new" },
  { id: "US-ECO.02", title: "Microsoft Teams / Slack Bot", section: "Integrations", priority: "P1", effort: 5, sprint: 4, deps: ["INFRA-09"], type: "feature", theme: "integrations", status: "new" },
  { id: "US-7.3.09", title: "Operator Daily Digest", section: "Sprint 7.3", priority: "P1", effort: 3, sprint: 4, deps: ["INFRA-09", "US-ECO.02"], type: "feature", theme: "operator", status: "new" },
  { id: "US-8.01", title: "Customer Portal (Read-Only Tenant View)", section: "Phase 8", priority: "P1", effort: 5, sprint: 4, deps: ["INFRA-01", "INFRA-02"], type: "feature", theme: "platform", status: "new" },
  { id: "US-8.02", title: "Quality Alert Auto-Routing", section: "Phase 8", priority: "P1", effort: 2, sprint: 4, deps: ["INFRA-09"], type: "feature", theme: "platform", status: "partial", note: "alertTriggered field exists on XmlImport. Need notification routing." },
  { id: "US-8.03", title: "Scan Failure Escalation", section: "Phase 8", priority: "P1", effort: 2, sprint: 4, deps: ["INFRA-09"], type: "feature", theme: "platform", status: "partial", note: "/scans/attention + attention banner exist. Need 3x-failure auto-escalation." },

  // Sprint 5: Advanced Intelligence, Compliance, Runbooks
  { id: "US-INT.05", title: "CVE Trend Alerting (EPSS Spikes)", section: "Intelligence", priority: "P1", effort: 3, sprint: 5, deps: ["US-INT.01", "INFRA-09"], type: "feature", theme: "intelligence", status: "new" },
  { id: "US-COMP.02", title: "Multi-Framework Compliance Dashboard", section: "Compliance", priority: "P1", effort: 5, sprint: 5, deps: ["US-COMP.01"], type: "feature", theme: "compliance", status: "new" },
  { id: "US-COMP.03", title: "Compliance Gap Remediation Roadmap", section: "Compliance", priority: "P1", effort: 5, sprint: 5, deps: ["US-COMP.02"], type: "feature", theme: "compliance", status: "new" },
  { id: "US-COMP.04", title: "Audit Trail Export", section: "Compliance", priority: "P1", effort: 3, sprint: 5, deps: ["INFRA-07"], type: "feature", theme: "compliance", status: "new" },
  { id: "US-7.3.05", title: "Time-to-Remediate Dashboard", section: "Sprint 7.3", priority: "P1", effort: 3, sprint: 5, deps: ["US-7.3.08"], type: "feature", theme: "operator", status: "new", note: "Remediation fields exist (assignedTo, dueDate, status). Need TTR calc + dashboard." },
  { id: "US-7.3.06", title: "Runbook Execution Tracking", section: "Sprint 7.3", priority: "P1", effort: 3, sprint: 5, deps: ["US-7.3.01"], type: "feature", theme: "operator", status: "new" },

  // Sprint 6: AI Features, RMM, Revenue Packs
  { id: "US-AI.02", title: "Natural Language Search", section: "AI & Auto", priority: "P1", effort: 5, sprint: 6, deps: ["US-AI.01"], type: "feature", theme: "ai", status: "new", note: "Global search exists (/search). Need LLM NL → structured query parsing." },
  { id: "US-AI.03", title: "AI Scan Summary Digest", section: "AI & Auto", priority: "P1", effort: 3, sprint: 6, deps: ["US-AI.01", "INFRA-09"], type: "feature", theme: "ai", status: "new" },
  { id: "US-AI.04", title: "Anomaly Detection on Asset Changes", section: "AI & Auto", priority: "P1", effort: 5, sprint: 6, deps: ["US-AI.01"], type: "feature", theme: "ai", status: "new", note: "deltaSinceLast exists on Asset. Need statistical anomaly flagging via LLM." },
  { id: "US-AI.05", title: "Auto-Categorisation of Assets", section: "AI & Auto", priority: "P1", effort: 3, sprint: 6, deps: ["US-AI.01"], type: "feature", theme: "ai", status: "new" },
  { id: "US-ECO.03", title: "RMM Asset Sync (NinjaOne)", section: "Integrations", priority: "P1", effort: 5, sprint: 6, deps: ["US-8.08"], type: "feature", theme: "integrations", status: "new" },
  { id: "US-REV.03", title: "Posture Score Trend Widget", section: "Revenue", priority: "P1", effort: 3, sprint: 6, deps: ["US-REV.02"], type: "feature", theme: "revenue", status: "new" },
  { id: "US-REV.04", title: "Cyber Insurance Evidence Pack", section: "Revenue", priority: "P1", effort: 5, sprint: 6, deps: ["US-COMP.04", "US-REV.02"], type: "feature", theme: "revenue", status: "new" },

  // Sprint 7: Reports, Dashboards, Ops Polish
  { id: "US-REV.05", title: "ROI Calculator Dashboard", section: "Revenue", priority: "P1", effort: 3, sprint: 7, deps: ["US-7.3.05"], type: "feature", theme: "revenue", status: "new" },
  { id: "US-7.3.10", title: "Export Evidence Pack (PDF)", section: "Sprint 7.3", priority: "P1", effort: 5, sprint: 7, deps: ["US-7.3.02", "US-COMP.04", "INFRA-07"], type: "feature", theme: "operator", status: "new" },
  { id: "US-8.05", title: "Report Delivery Tracking", section: "Phase 8", priority: "P1", effort: 3, sprint: 7, deps: ["US-7.3.10"], type: "feature", theme: "platform", status: "new", note: "Reports list exists. Need sent/pending/acknowledged workflow." },
  { id: "US-OPS.02", title: "Dashboard Customisation", section: "Ops Excellence", priority: "P1", effort: 5, sprint: 7, deps: ["US-8.07"], type: "feature", theme: "ops", status: "new" },
  { id: "US-OPS.03", title: "Notification Preferences", section: "Ops Excellence", priority: "P1", effort: 3, sprint: 7, deps: ["INFRA-09"], type: "feature", theme: "ops", status: "new" },
  { id: "US-OPS.06", title: "Multi-Scan Comparison (Diff View)", section: "Ops Excellence", priority: "P1", effort: 5, sprint: 7, deps: [], type: "feature", theme: "ops", status: "done", note: "GET /scans/:id/diff and /imports/:id/diff already implemented with full diff logic." },

  // Sprint 8: P2 Polish + Deferred Features
  { id: "US-7.3.03", title: "Team Skill Matrix & Smart Assignment", section: "Sprint 7.3", priority: "P2", effort: 3, sprint: 8, deps: ["INFRA-01"], type: "feature", theme: "operator", status: "new" },
  { id: "US-7.3.07", title: "Custom Runbook Creation", section: "Sprint 7.3", priority: "P2", effort: 3, sprint: 8, deps: ["US-7.3.01"], type: "feature", theme: "operator", status: "new" },
  { id: "US-8.04", title: "Schedule Calendar Heatmap", section: "Phase 8", priority: "P2", effort: 3, sprint: 8, deps: [], type: "feature", theme: "platform", status: "partial", note: "ScanSchedule model + CRUD exists. Need calendar heatmap UI + overlap viz." },
  { id: "US-8.10", title: "White-Label Branding", section: "Phase 8", priority: "P2", effort: 5, sprint: 8, deps: [], type: "feature", theme: "platform", status: "new" },
  { id: "US-INT.04", title: "Threat Intelligence Feed (STIX/TAXII)", section: "Intelligence", priority: "P2", effort: 5, sprint: 8, deps: ["US-INT.01"], type: "feature", theme: "intelligence", status: "new" },
  { id: "US-COMP.05", title: "Automated Evidence Screenshots", section: "Compliance", priority: "P2", effort: 3, sprint: 8, deps: ["US-7.3.02"], type: "feature", theme: "compliance", status: "new" },
  { id: "US-OPS.04", title: "Dark Mode", section: "Ops Excellence", priority: "P2", effort: 2, sprint: 8, deps: ["INFRA-10"], type: "feature", theme: "ops", status: "new" },
  { id: "US-OPS.05", title: "Keyboard Shortcuts", section: "Ops Excellence", priority: "P2", effort: 2, sprint: 8, deps: [], type: "feature", theme: "ops", status: "partial", note: "Cmd+K search + some keyboard nav exists. Need full j/k/a/s/d/e shortcut system." },
  { id: "US-ECO.04", title: "SIEM Log Forwarding", section: "Integrations", priority: "P2", effort: 3, sprint: 8, deps: [], type: "feature", theme: "integrations", status: "new" },
  { id: "US-ECO.05", title: "Terraform / IaC Export", section: "Integrations", priority: "P2", effort: 3, sprint: 8, deps: [], type: "feature", theme: "integrations", status: "new" },
  { id: "US-8.06", title: "Kubernetes Deployment (Tier 3)", section: "Phase 8", priority: "P2", effort: 8, sprint: 8, deps: [], type: "feature", theme: "platform", status: "new" },

  // Sprint 9–10: Phase 9 (Host Telemetry) — separate track
  { id: "US-9.01", title: "Linux Agent Deployment (Go)", section: "Phase 9", priority: "P1", effort: 8, sprint: 9, deps: [], type: "feature", theme: "agents", status: "new" },
  { id: "US-9.02", title: "Real-Time Process Monitoring (eBPF)", section: "Phase 9", priority: "P1", effort: 8, sprint: 9, deps: ["US-9.01"], type: "feature", theme: "agents", status: "new" },
  { id: "US-9.03", title: "Windows Agent with ETW Events", section: "Phase 9", priority: "P1", effort: 8, sprint: 10, deps: ["US-9.01"], type: "feature", theme: "agents", status: "new" },
  { id: "US-9.04", title: "Cross-Platform Software Inventory", section: "Phase 9", priority: "P1", effort: 5, sprint: 10, deps: ["US-9.01", "US-9.03"], type: "feature", theme: "agents", status: "new" },
  { id: "US-9.05", title: "File Integrity Monitoring (FIM)", section: "Phase 9", priority: "P1", effort: 5, sprint: 10, deps: ["US-9.01"], type: "feature", theme: "agents", status: "new" },
  { id: "US-9.06", title: "Remote Response Actions", section: "Phase 9", priority: "P2", effort: 5, sprint: 10, deps: ["US-9.01"], type: "feature", theme: "agents", status: "new" },
  { id: "US-9.07", title: "CIS Benchmark Compliance", section: "Phase 9", priority: "P1", effort: 5, sprint: 10, deps: ["US-9.01"], type: "feature", theme: "agents", status: "new" },
];

const SPRINTS = [
  { num: 0, name: "Sprint 0: Foundation & Infra", weeks: 2, focus: "Database models, RLS, Zod, scoring engine, MinIO, Ollama LLM, notification router, UI bootstrap. No user-visible features — pure plumbing. 100% open source.", milestone: "make up works, all models migrated, EPSS/KEV syncing, Ollama responding to test prompts" },
  { num: 1, name: "Sprint 1: Intelligence + Core UX", weeks: 2, focus: "Composite risk scoring live in the UI. Bulk actions. Age tracking. Saved views. The vulnerability list becomes genuinely useful.", milestone: "Vulns sorted by composite score, EPSS/KEV badges visible, bulk assign works" },
  { num: 2, name: "Sprint 2: Auth + PSA + AI", weeks: 2, focus: "API key auth unlocks integrations. PSA ticket creation (ConnectWise + Halo). AI remediation guidance via Ollama. Multi-tenant dashboard.", milestone: "PSA tickets auto-created on vuln assignment, AI 'How do I fix this?' working via Ollama" },
  { num: 3, name: "Sprint 3: Compliance + Revenue", weeks: 2, focus: "Essential Eight mapping. Posture score (A–F). Pre-sales PDF report. Runbook library + evidence attachments.", milestone: "Client portal shows posture grade, E8 compliance dashboard, PDF report generates" },
  { num: 4, name: "Sprint 4: Notifications + Portal", weeks: 2, focus: "Webhook system. Teams/Slack bot. Daily digests. Customer portal (read-only). Alert routing.", milestone: "Teams alerts firing, customer portal login working, daily digest emails sending" },
  { num: 5, name: "Sprint 5: Advanced Intel + Compliance", weeks: 2, focus: "EPSS spike alerting. Multi-framework compliance. Remediation roadmap. Audit trail. TTR dashboard. Runbook tracking.", milestone: "CIS Controls + NIST mapped, EPSS spike alerts live, TTR dashboard populated" },
  { num: 6, name: "Sprint 6: AI Suite + RMM + Revenue", weeks: 2, focus: "NL search. Scan digests. Anomaly detection. Asset auto-classification. NinjaOne sync. Insurance pack. Trend widgets.", milestone: "NL search working, NinjaOne devices syncing, insurance pack generating" },
  { num: 7, name: "Sprint 7: Reports + Ops Polish", weeks: 2, focus: "Evidence pack PDF. Report delivery tracking. Dashboard customisation. Notification prefs. Scan diff view. ROI calculator.", milestone: "Evidence pack exports, custom dashboards saved, scan diff working" },
  { num: 8, name: "Sprint 8: P2 Polish + Ecosystem", weeks: 2, focus: "Smart assignment, custom runbooks, white-label, dark mode, keyboard shortcuts, SIEM forwarding, Terraform, K8s Helm charts.", milestone: "White-label branding applied, dark mode toggles, SIEM events forwarding" },
  { num: 9, name: "Sprint 9: Phase 9a — Linux Agent", weeks: 3, focus: "Go agent binary for linux/amd64 + linux/arm64. mTLS registration. eBPF process monitoring. Telemetry ingestion endpoint.", milestone: "Agent installs via curl, process events visible in UI" },
  { num: 10, name: "Sprint 10: Phase 9b — Cross-Platform", weeks: 3, focus: "Windows agent (ETW). Software inventory. FIM. Remote response. CIS benchmarks.", milestone: "Windows + Linux agents reporting, CIS benchmark dashboard" },
];

const THEME_COLORS = {
  foundation: { bg: "#1B365D", text: "#fff" },
  intelligence: { bg: "#1A8A7D", text: "#fff" },
  operator: { bg: "#3B82F6", text: "#fff" },
  platform: { bg: "#8B5CF6", text: "#fff" },
  ai: { bg: "#6C3FA0", text: "#fff" },
  compliance: { bg: "#1B365D", text: "#fff" },
  revenue: { bg: "#2563EB", text: "#fff" },
  integrations: { bg: "#E67E22", text: "#fff" },
  ops: { bg: "#2D8B46", text: "#fff" },
  agents: { bg: "#DC2626", text: "#fff" },
};

const PRIORITY_COLORS = { P0: "#DC2626", P1: "#E67E22", P2: "#6B7280" };

const Badge = ({ children, bg, color = "#fff", style = {} }) => (
  <span style={{ display: "inline-block", padding: "1px 7px", borderRadius: 4, fontSize: 10, fontWeight: 700, background: bg, color, letterSpacing: 0.3, ...style }}>{children}</span>
);

const STATUS_COLORS = { done: "#16A34A", partial: "#D97706", new: "#6B7280" };
const STATUS_LABELS = { done: "✅ DONE", partial: "🔶 PARTIAL", new: "🆕 NEW" };

const StoryRow = ({ s, allStories }) => {
  const [showDeps, setShowDeps] = useState(false);
  const tc = THEME_COLORS[s.theme] || THEME_COLORS.foundation;
  const st = s.status || "new";
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 6, padding: "5px 8px", borderBottom: "1px solid #F0F0F0", fontSize: 12, cursor: "pointer", background: st === "done" ? "#F0FFF4" : st === "partial" ? "#FFFBEB" : showDeps ? "#FAFBFF" : "transparent", opacity: st === "done" ? 0.7 : 1 }} onClick={() => setShowDeps(!showDeps)}>
      <span style={{ fontFamily: "'JetBrains Mono', monospace", fontSize: 10, fontWeight: 700, color: tc.bg, minWidth: 76 }}>{s.id}</span>
      <Badge bg={PRIORITY_COLORS[s.priority]}>{s.priority}</Badge>
      <Badge bg={STATUS_COLORS[st]} style={{ fontSize: 8 }}>{STATUS_LABELS[st]}</Badge>
      <span style={{ flex: 1, fontWeight: 500, color: "#1B365D", textDecoration: st === "done" ? "line-through" : "none" }}>{s.title}</span>
      <Badge bg="#E8EEF4" color="#555" style={{ fontSize: 9 }}>{s.effort}d</Badge>
      {s.deps.length > 0 && <span style={{ fontSize: 9, color: "#999" }}>⤺ {s.deps.length}</span>}
      {(showDeps && (s.deps.length > 0 || s.note)) && (
        <div style={{ position: "absolute", right: 40, background: "#fff", border: "1px solid #ddd", borderRadius: 6, padding: 8, boxShadow: "0 2px 8px rgba(0,0,0,0.1)", zIndex: 10, maxWidth: 320 }} onClick={e => e.stopPropagation()}>
          {s.note && <div style={{ fontSize: 10, color: "#555", marginBottom: s.deps.length > 0 ? 6 : 0, fontStyle: "italic", padding: "4px 0", borderBottom: s.deps.length > 0 ? "1px solid #eee" : "none" }}>📝 {s.note}</div>}
          {s.deps.length > 0 && <><div style={{ fontSize: 10, fontWeight: 700, color: "#888", marginBottom: 4 }}>DEPENDS ON:</div>
          {s.deps.map(d => {
            const dep = allStories.find(x => x.id === d);
            return <div key={d} style={{ fontSize: 10, color: "#333", marginBottom: 2 }}>{d}: {dep?.title || "?"}</div>;
          })}</>}
        </div>
      )}
    </div>
  );
};

const SprintCard = ({ sprint, stories, expanded, onToggle }) => {
  const p0 = stories.filter(s => s.priority === "P0").length;
  const p1 = stories.filter(s => s.priority === "P1").length;
  const p2 = stories.filter(s => s.priority === "P2").length;
  const totalEffort = stories.reduce((a, s) => a + s.effort, 0);
  const infra = stories.filter(s => s.type === "infra").length;
  const features = stories.filter(s => s.type === "feature").length;
  const themes = [...new Set(stories.map(s => s.theme))];
  const doneCount = stories.filter(s => s.status === "done").length;
  const partialCount = stories.filter(s => s.status === "partial").length;
  const newCount = stories.filter(s => s.status === "new" || !s.status).length;

  return (
    <div style={{ border: "1px solid #E0E4EA", borderRadius: 10, marginBottom: 12, background: "#fff", overflow: "hidden", boxShadow: expanded ? "0 2px 12px rgba(0,0,0,0.06)" : "none" }}>
      <div onClick={onToggle} style={{ padding: "14px 16px", cursor: "pointer", display: "flex", justifyContent: "space-between", alignItems: "center", background: expanded ? "#F8F9FB" : "#fff" }}>
        <div>
          <div style={{ fontWeight: 800, fontSize: 14, color: "#1B365D", marginBottom: 4 }}>{sprint.name}</div>
          <div style={{ fontSize: 11, color: "#666" }}>{sprint.focus}</div>
        </div>
        <div style={{ display: "flex", gap: 6, alignItems: "center", flexShrink: 0 }}>
          <Badge bg="#F0F4F8" color="#1B365D" style={{ fontSize: 11 }}>{sprint.weeks}w</Badge>
          <Badge bg="#F0F4F8" color="#1B365D" style={{ fontSize: 11 }}>{totalEffort}d effort</Badge>
          <Badge bg="#F0F4F8" color="#1B365D" style={{ fontSize: 11 }}>{stories.length} items</Badge>
          {p0 > 0 && <Badge bg={PRIORITY_COLORS.P0}>{p0} P0</Badge>}
          {p1 > 0 && <Badge bg={PRIORITY_COLORS.P1}>{p1} P1</Badge>}
          {p2 > 0 && <Badge bg={PRIORITY_COLORS.P2}>{p2} P2</Badge>}
          {doneCount > 0 && <Badge bg="#16A34A">✅{doneCount}</Badge>}
          {partialCount > 0 && <Badge bg="#D97706">🔶{partialCount}</Badge>}
          <span style={{ fontSize: 16, color: "#999", transform: expanded ? "rotate(180deg)" : "rotate(0)", transition: "transform 0.2s" }}>▾</span>
        </div>
      </div>
      {expanded && (
        <div>
          <div style={{ padding: "8px 16px", background: "#F0F7EE", borderTop: "1px solid #E0E4EA", borderBottom: "1px solid #E0E4EA" }}>
            <span style={{ fontSize: 11, fontWeight: 700, color: "#2D8B46" }}>🎯 MILESTONE: </span>
            <span style={{ fontSize: 11, color: "#333" }}>{sprint.milestone}</span>
          </div>
          <div style={{ padding: "4px 8px", display: "flex", gap: 4, flexWrap: "wrap", borderBottom: "1px solid #F0F0F0" }}>
            {themes.map(t => <Badge key={t} bg={THEME_COLORS[t]?.bg || "#888"}>{t}</Badge>)}
            {infra > 0 && <Badge bg="#555">🔧 {infra} infra</Badge>}
            <Badge bg="#2563EB">⚡ {features} features</Badge>
          </div>
          <div style={{ position: "relative" }}>
            {stories.map(s => <StoryRow key={s.id} s={s} allStories={STORIES} />)}
          </div>
        </div>
      )}
    </div>
  );
};

const Timeline = () => {
  const maxWeek = SPRINTS.reduce((a, s) => a + s.weeks, 0);
  let cumWeek = 0;
  return (
    <div style={{ padding: 16, background: "#F8F9FB", borderRadius: 10, border: "1px solid #E0E4EA", overflowX: "auto" }}>
      <div style={{ fontWeight: 700, fontSize: 13, color: "#1B365D", marginBottom: 12 }}>TIMELINE — {maxWeek} weeks total ({Math.ceil(maxWeek/4.3)} months)</div>
      <div style={{ display: "flex", gap: 0, minWidth: 900 }}>
        {SPRINTS.map(sprint => {
          const width = `${(sprint.weeks / maxWeek) * 100}%`;
          const stories = STORIES.filter(s => s.sprint === sprint.num);
          const p0count = stories.filter(s => s.priority === "P0").length;
          cumWeek += sprint.weeks;
          const isPhase9 = sprint.num >= 9;
          return (
            <div key={sprint.num} style={{ width, padding: "0 2px", boxSizing: "border-box" }}>
              <div style={{
                height: 36, borderRadius: 4,
                background: isPhase9 ? "#DC2626" : p0count > 0 ? "#1B365D" : "#6B7280",
                display: "flex", alignItems: "center", justifyContent: "center",
                fontSize: 10, fontWeight: 700, color: "#fff", padding: "0 4px", textAlign: "center",
              }}>S{sprint.num}</div>
              <div style={{ fontSize: 9, color: "#888", textAlign: "center", marginTop: 2 }}>w{cumWeek}</div>
            </div>
          );
        })}
      </div>
      <div style={{ display: "flex", gap: 12, marginTop: 12, fontSize: 10, color: "#666" }}>
        <span>◼️ Navy = P0 stories</span>
        <span style={{ color: "#6B7280" }}>◼️ Grey = P1/P2</span>
        <span style={{ color: "#DC2626" }}>◼️ Red = Phase 9 (agents)</span>
        <span style={{ marginLeft: "auto", fontWeight: 700, color: "#1B365D" }}>MVP (Sprint 0–3): 8 weeks · Full platform (0–8): 18 weeks · With agents (0–10): 24 weeks</span>
      </div>
    </div>
  );
};

const Stats = () => {
  const totalEffort = STORIES.reduce((a, s) => a + s.effort, 0);
  const p0Stories = STORIES.filter(s => s.priority === "P0");
  const p0Effort = p0Stories.reduce((a, s) => a + s.effort, 0);
  const infraStories = STORIES.filter(s => s.type === "infra");
  const doneCount = STORIES.filter(s => s.status === "done").length;
  const partialCount = STORIES.filter(s => s.status === "partial").length;
  const newCount = STORIES.filter(s => s.status === "new" || !s.status).length;
  const newEffort = STORIES.filter(s => s.status === "new" || !s.status).reduce((a, s) => a + s.effort, 0);

  return (
    <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(140px, 1fr))", gap: 8, marginBottom: 20 }}>
      {[
        { label: "Total Items", val: STORIES.length, sub: `${infraStories.length} infra + ${STORIES.length - infraStories.length} features` },
        { label: "🆕 New Work", val: newCount, sub: `${newEffort}d effort remaining` },
        { label: "🔶 Partial", val: partialCount, sub: "Foundation exists, extend" },
        { label: "✅ Done", val: doneCount, sub: "Already in codebase" },
        { label: "P0 (Must-Have)", val: p0Stories.length, sub: `${p0Effort}d effort` },
        { label: "Monthly Cost", val: "$0", sub: "100% open source stack" },
      ].map(s => (
        <div key={s.label} style={{ background: "#F8F9FB", borderRadius: 8, padding: "10px 12px", border: "1px solid #E8ECF0" }}>
          <div style={{ fontSize: 10, fontWeight: 700, color: "#888", textTransform: "uppercase", letterSpacing: 0.5 }}>{s.label}</div>
          <div style={{ fontSize: 20, fontWeight: 800, color: "#1B365D", marginTop: 2 }}>{s.val}</div>
          <div style={{ fontSize: 10, color: "#999" }}>{s.sub}</div>
        </div>
      ))}
    </div>
  );
};

const CriticalPath = () => {
  const path = [
    { id: "INFRA-05", sprint: 0, label: "EPSS/KEV Workers" },
    { id: "INFRA-06", sprint: 0, label: "Scoring Engine" },
    { id: "INFRA-11", sprint: 0, label: "Ollama + LLM Gateway" },
    { id: "US-INT.01", sprint: 1, label: "EPSS Integration" },
    { id: "US-INT.03", sprint: 1, label: "Composite Score" },
    { id: "US-8.08", sprint: 2, label: "API Key Auth" },
    { id: "US-AI.01", sprint: 2, label: "AI Remediation (Ollama)" },
    { id: "US-COMP.01", sprint: 3, label: "Essential Eight" },
    { id: "US-REV.02", sprint: 3, label: "Posture Score" },
  ];
  return (
    <div style={{ padding: 16, background: "#FFF8F0", borderRadius: 10, border: "1px solid #F5DEB3", marginBottom: 20 }}>
      <div style={{ fontWeight: 700, fontSize: 13, color: "#B45309", marginBottom: 10 }}>🔥 CRITICAL PATH (longest dependency chain to MVP)</div>
      <div style={{ display: "flex", gap: 4, flexWrap: "wrap", alignItems: "center" }}>
        {path.map((p, i) => (
          <div key={p.id} style={{ display: "flex", alignItems: "center", gap: 4 }}>
            <div style={{ background: "#1B365D", color: "#fff", padding: "4px 10px", borderRadius: 4, fontSize: 10, fontWeight: 700 }}>
              S{p.sprint}: {p.label}
            </div>
            {i < path.length - 1 && <span style={{ color: "#B45309", fontWeight: 700, fontSize: 14 }}>→</span>}
          </div>
        ))}
      </div>
      <div style={{ fontSize: 11, color: "#92400E", marginTop: 8 }}>If any item on this chain slips, the MVP delivery date moves. Protect these tasks.</div>
    </div>
  );
};

export default function SprintPlanner() {
  const [expandedSprint, setExpandedSprint] = useState(0);
  const [view, setView] = useState("sprints");

  return (
    <div style={{ fontFamily: "'Inter', -apple-system, sans-serif", maxWidth: 1000, margin: "0 auto", padding: 24, background: "#FAFBFC" }}>
      <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;600;700&display=swap" rel="stylesheet" />
      <div style={{ marginBottom: 24 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 4 }}>
          <span style={{ fontSize: 28 }}>🗓️</span>
          <div>
            <h1 style={{ margin: 0, fontSize: 22, fontWeight: 800, color: "#1B365D", letterSpacing: -0.5 }}>Project Armadillo v3 — Sprint Plan & Sequencing</h1>
            <p style={{ margin: 0, fontSize: 13, color: "#666" }}>74 items (11 infra + 63 user stories) across 11 sprints • 24 weeks total • Dependency-mapped • 100% open source stack</p>
          </div>
        </div>
        <div style={{ display: "flex", gap: 6, marginTop: 12 }}>
          {[["sprints", "📋 Sprint Board"], ["timeline", "📊 Timeline"], ["critical", "🔥 Critical Path"]].map(([k, l]) => (
            <button key={k} onClick={() => setView(k)} style={{
              padding: "6px 14px", borderRadius: 6, border: "1px solid #D0D5DD",
              background: view === k ? "#1B365D" : "#fff", color: view === k ? "#fff" : "#555",
              fontWeight: 600, fontSize: 12, cursor: "pointer",
            }}>{l}</button>
          ))}
        </div>
      </div>

      <Stats />

      {view === "critical" && <CriticalPath />}
      {view === "timeline" && <Timeline />}

      {view === "sprints" && SPRINTS.map(sprint => {
        const stories = STORIES.filter(s => s.sprint === sprint.num);
        return (
          <SprintCard
            key={sprint.num} sprint={sprint} stories={stories}
            expanded={expandedSprint === sprint.num}
            onToggle={() => setExpandedSprint(expandedSprint === sprint.num ? -1 : sprint.num)}
          />
        );
      })}

      {view !== "sprints" && (
        <div style={{ marginTop: 20 }}>
          {SPRINTS.map(sprint => {
            const stories = STORIES.filter(s => s.sprint === sprint.num);
            return <SprintCard key={sprint.num} sprint={sprint} stories={stories} expanded={false} onToggle={() => { setView("sprints"); setExpandedSprint(sprint.num); }} />;
          })}
        </div>
      )}
    </div>
  );
}

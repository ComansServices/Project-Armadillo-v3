import { useState } from "react";

const CATEGORIES = [
  {
    id: "intel",
    label: "Intelligence Feeds",
    icon: "🧠",
    color: "#1A8A7D",
    desc: "Free public APIs — no auth, no cost. The foundation of smart prioritisation.",
    items: [
      {
        name: "FIRST.org EPSS API",
        stories: ["US-INT.01", "US-INT.03", "US-INT.05"],
        priority: "P0",
        endpoints: [
          { method: "GET", url: "https://api.first.org/data/v1/epss?cve=CVE-XXXX", note: "Single/batch CVE lookup" },
          { method: "GET", url: "https://epss.empiricalsecurity.com/epss_scores-YYYY-MM-DD.csv.gz", note: "Full daily CSV (~200K CVEs, ~8MB gzipped)" },
        ],
        auth: "None — fully public",
        rateLimit: "No documented limits. Use daily CSV bulk to avoid per-CVE calls.",
        dataFormat: "JSON: { cve, epss (0–1), percentile (0–1), date }  •  CSV: cve,epss,percentile",
        refreshSchedule: "Daily cron 02:00 UTC → download CSV → upsert EpssCache → trigger enrich-vulnerabilities",
        failureMode: "Retain previous day cache. Flag epssStale=true. Alert via Teams.",
        dbTarget: "EpssCache table → Vulnerability.epssScore, .epssPercentile, .epssScorePrev",
        npm: "undici (built-in Node 18+), zlib (built-in), csv-parse",
        cost: "Free",
      },
      {
        name: "CISA KEV Catalog",
        stories: ["US-INT.02", "US-INT.03"],
        priority: "P0",
        endpoints: [
          { method: "GET", url: "https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json", note: "Full JSON catalog" },
          { method: "GET", url: "https://www.cisa.gov/sites/default/files/csv/known_exploited_vulnerabilities.csv", note: "CSV alternative" },
        ],
        auth: "None — fully public",
        rateLimit: "None. Single file download.",
        dataFormat: "JSON: { catalogVersion, dateReleased, count, vulnerabilities: [{ cveID, vendorProject, product, vulnerabilityName, dateAdded, dueDate, knownRansomwareCampaignUse, notes }] }",
        refreshSchedule: "Daily cron 02:30 UTC → download JSON → upsert CisaKevEntry → trigger enrich-vulnerabilities",
        failureMode: "Retain existing cache. KEV is additive-only (entries never removed).",
        dbTarget: "CisaKevEntry table → Vulnerability.isInCisaKev, .kevDateAdded, .kevDueDate",
        npm: "undici (built-in)",
        cost: "Free",
        extra: "GitHub mirror: github.com/cisagov/kev-data (synced within minutes). ~1,200 CVEs, grows 5–10/week.",
      },
      {
        name: "NVD / CVE API 2.0",
        stories: ["US-INT.03"],
        priority: "P1",
        endpoints: [
          { method: "GET", url: "https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-XXXX", note: "CVSS score lookup when missing from OpenVAS/Nessus scan data" },
        ],
        auth: "API key recommended (free registration at nvd.nist.gov). Without key: 5 req/30s. With key: 50 req/30s.",
        rateLimit: "5 req/30s (no key) or 50 req/30s (with key)",
        dataFormat: "JSON: { vulnerabilities: [{ cve: { id, metrics: { cvssMetricV31: [{ cvssData: { baseScore } }] } } }] }",
        refreshSchedule: "On-demand when CVE first imported and CVSS missing. Cache in Vulnerability record.",
        failureMode: "If NVD unavailable, use CVSS from scanner data. Flag cvssSource='scanner'.",
        dbTarget: "Vulnerability.cvssScore (backfill only)",
        npm: "undici (built-in)",
        cost: "Free",
      },
    ],
  },
  {
    id: "ai",
    label: "AI / LLM",
    icon: "🤖",
    color: "#6C3FA0",
    desc: "AI-powered features via OpenAI-compatible API. Default: Ollama (self-hosted, FREE). Optional: Claude, OpenRouter.",
    items: [
      {
        name: "Ollama (Self-Hosted LLM — DEFAULT)",
        stories: ["US-AI.01", "US-AI.02", "US-AI.03", "US-AI.04", "US-AI.05"],
        priority: "P0–P1",
        endpoints: [
          { method: "POST", url: "http://ollama:11434/v1/chat/completions", note: "OpenAI-compatible endpoint — all AI features route here" },
          { method: "GET", url: "http://ollama:11434/v1/models", note: "List available models" },
        ],
        auth: "None — local service, no API key needed.",
        rateLimit: "Hardware-limited. Mac Mini M1 16GB: ~10-20 tok/s with 8B model. Rate limiter still enforced (50/hr/project).",
        dataFormat: "OpenAI-compatible JSON: { model, max_tokens, messages: [{ role, content }] }",
        refreshSchedule: "Event-driven (not scheduled). Called when user triggers AI features.",
        failureMode: "Return fallback: link to NVD advisory + generic guidance. AI features degrade; core unaffected.",
        dbTarget: "Redis cache: ai:guidance:{cveId}:{osHash} (TTL 7d), ai:classify:{portsHash} (TTL 30d)",
        npm: "openai (npm package — works with Ollama, Claude, OpenRouter, vLLM, LocalAI via baseURL config)",
        cost: "$0 — runs locally. Models: llama3.2 (3B, fast), qwen3:8b (quality), deepseek-r1:8b (reasoning).",
        extra: "Docker: ollama/ollama:latest (multi-arch: amd64 + arm64). Pull models: docker exec ollama ollama pull qwen3:8b. LLM_BASE_URL env var switches providers without code changes. For cloud: set LLM_BASE_URL=https://api.anthropic.com/v1 + LLM_API_KEY.",
        license: "MIT (Ollama). Models: Meta Community License (Llama), Apache-2.0 (Qwen), MIT (DeepSeek).",
      },
    ],
  },
  {
    id: "psa",
    label: "PSA Integrations",
    icon: "🎫",
    color: "#E67E22",
    desc: "Ticketing system integrations — bidirectional sync eliminates double-entry.",
    items: [
      {
        name: "ConnectWise Manage (PSA)",
        stories: ["US-ECO.01"],
        priority: "P0",
        endpoints: [
          { method: "POST", url: "https://{company}.connectwise.com/v4_6_release/apis/3.0/service/tickets", note: "Create ticket" },
          { method: "PATCH", url: "https://{company}.connectwise.com/v4_6_release/apis/3.0/service/tickets/{id}", note: "Update ticket status" },
          { method: "GET", url: "https://{company}.connectwise.com/v4_6_release/apis/3.0/service/tickets/{id}", note: "Read ticket for sync" },
        ],
        auth: "Basic Auth: {companyId}+{publicKey}:{privateKey}. Requires clientId header. API Member account.",
        rateLimit: "Page size max 1,000 records. No documented req/s limit (be respectful).",
        dataFormat: "JSON: { summary, board: {id}, company: {id}, priority: {id}, status: {id}, ... }",
        refreshSchedule: "Event-driven: create ticket on vuln assignment. Webhook callback for status sync.",
        failureMode: "Queue failed ticket creates for retry. Log in AuditEvent. Surface in attention banner.",
        dbTarget: "Vulnerability.externalTicketId, .externalTicketUrl (new fields). WebhookSubscription for callbacks.",
        npm: "connectwise-rest (npm package with TypeScript types)",
        cost: "Included with ConnectWise subscription. API access requires ConnectWise Developer Network registration.",
      },
      {
        name: "HaloPSA",
        stories: ["US-ECO.01"],
        priority: "P0",
        endpoints: [
          { method: "POST", url: "https://{tenant}.halopsa.com/api/tickets", note: "Create ticket" },
          { method: "POST", url: "https://{tenant}.halopsa.com/api/tickets/{id}", note: "Update ticket" },
          { method: "GET", url: "https://{tenant}.halopsa.com/api/tickets/{id}", note: "Read for sync" },
        ],
        auth: "OAuth2 Client Credentials. Auth endpoint: /auth/token. Requires Client ID + Secret from API application.",
        rateLimit: "Documented throttling. Use reasonable request spacing.",
        dataFormat: "JSON: [{ summary, details, tickettype_id, client_id, priority_id, ... }]",
        refreshSchedule: "Event-driven: create on vuln assignment. Webhook via Actions for status sync back.",
        failureMode: "Same as ConnectWise — queue, retry, log.",
        dbTarget: "Same fields as ConnectWise — polymorphic PSA connector.",
        npm: "undici (custom client — no official npm package)",
        cost: "Included with HaloPSA subscription. Requires API application setup.",
        extra: "Permissions needed: read:tickets, edit:tickets, read:customers. Agent login required.",
      },
    ],
  },
  {
    id: "rmm",
    label: "RMM Integration",
    icon: "🖥️",
    color: "#2E75B6",
    desc: "Endpoint management data enrichment — match scan assets to managed devices.",
    items: [
      {
        name: "NinjaOne RMM",
        stories: ["US-ECO.03"],
        priority: "P1",
        endpoints: [
          { method: "GET", url: "https://{region}.ninjarmm.com/api/v2/devices", note: "List all devices" },
          { method: "GET", url: "https://{region}.ninjarmm.com/api/v2/device/{id}", note: "Device detail" },
          { method: "GET", url: "https://{region}.ninjarmm.com/api/v2/device/{id}/os-patches", note: "Patch status" },
        ],
        auth: "OAuth2 (Authorization Code or Client Credentials). Admin → Apps → API → Client App IDs.",
        rateLimit: "Documented but unspecified. Use hourly sync, not real-time.",
        dataFormat: "JSON: { id, systemName, dnsName, lastContact, os: { name, version }, nodeClass, ... }",
        refreshSchedule: "Hourly cron (sync-rmmData job). Match by IP/hostname to Armadillo assets.",
        failureMode: "Skip sync cycle. Retain previous metadata. Log warning.",
        dbTarget: "Asset.rmmSource, .rmmDeviceId, .rmmMetadata ({lastPatchDate, loggedInUser, deviceGroup})",
        npm: "undici (custom client — NinjaOne has no official Node SDK)",
        cost: "Included with NinjaOne subscription. API access included.",
        extra: "Region-specific base URLs: app.ninjarmm.com (US), eu.ninjarmm.com (EU), oc.ninjarmm.com (Oceania/AU).",
      },
    ],
  },
  {
    id: "notify",
    label: "Notification Channels",
    icon: "🔔",
    color: "#C62828",
    desc: "Alert delivery — route to the right person on the right channel.",
    items: [
      {
        name: "Microsoft Teams (Incoming Webhooks)",
        stories: ["US-ECO.02", "US-8.02", "US-8.03", "US-7.3.09"],
        priority: "P1",
        endpoints: [
          { method: "POST", url: "https://{tenant}.webhook.office.com/webhookb2/{id}", note: "Incoming Webhook (simple)" },
        ],
        auth: "Webhook URL is the auth (contains embedded token). No OAuth needed for simple webhooks.",
        rateLimit: "4 messages/second per webhook.",
        dataFormat: "Adaptive Card JSON (MessageCard format being deprecated → use Adaptive Cards).",
        refreshSchedule: "Event-driven: critical alerts immediate, digests at 07:00 local.",
        failureMode: "Queue for retry. If persistent failure, fall back to email.",
        dbTarget: "NotificationPreference.channels.teams, project-level webhook URL config.",
        npm: "undici (POST to webhook URL — no SDK needed for simple webhooks)",
        cost: "Free (included with M365).",
        extra: "For interactive buttons (acknowledge/assign/snooze), need Bot Framework registration. Start with simple webhooks.",
      },
      {
        name: "Slack (Incoming Webhooks + Block Kit)",
        stories: ["US-ECO.02"],
        priority: "P1",
        endpoints: [
          { method: "POST", url: "https://hooks.slack.com/services/{id}/{id}/{token}", note: "Incoming Webhook" },
          { method: "POST", url: "https://slack.com/api/chat.postMessage", note: "Bot API (richer)" },
        ],
        auth: "Webhook URL (simple) or Bot Token + OAuth2 (interactive).",
        rateLimit: "1 message/second per webhook.",
        dataFormat: "Block Kit JSON for rich messages with interactive elements.",
        refreshSchedule: "Event-driven.",
        failureMode: "Same as Teams — queue, retry, fallback.",
        dbTarget: "NotificationPreference.channels.slack, project-level config.",
        npm: "@slack/web-api (for bot). undici for simple webhooks.",
        cost: "Free tier sufficient for alerts. Paid Slack not required.",
      },
      {
        name: "Email (SMTP — Open Standard)",
        stories: ["US-7.3.09", "US-OPS.03"],
        priority: "P1",
        endpoints: [
          { method: "SMTP", url: "smtp://{host}:587 (any SMTP server)", note: "Transactional email via open SMTP standard" },
        ],
        auth: "SMTP credentials (SMTP_HOST, SMTP_USER, SMTP_PASS env vars).",
        rateLimit: "Depends on SMTP server. Self-hosted Postfix: unlimited. Mailcow: configurable.",
        dataFormat: "HTML email templates (Handlebars or React Email).",
        refreshSchedule: "Event-driven + daily digest cron at 07:00.",
        failureMode: "Queue for retry. Store in outbox table.",
        dbTarget: "NotificationPreference.channels.email",
        npm: "nodemailer (MIT license)",
        cost: "$0 — self-hosted SMTP (Postfix, Mailcow). Optional paid: SendGrid, SES.",
        license: "nodemailer: MIT. SMTP: open standard (RFC 5321).",
      },
      {
        name: "WebSocket (In-App Real-Time)",
        stories: ["US-OPS.03"],
        priority: "P2",
        endpoints: [
          { method: "WS", url: "wss://armadillo.local/ws", note: "Real-time push to browser" },
        ],
        auth: "Session token on connection upgrade.",
        rateLimit: "N/A (internal).",
        dataFormat: "JSON: { event, payload, timestamp }",
        refreshSchedule: "Real-time — fires on every relevant event.",
        failureMode: "If WS disconnected, client polls /api/v1/notifications on reconnect.",
        dbTarget: "In-memory (no persistence needed — notifications also stored in DB).",
        npm: "ws or socket.io",
        cost: "Free (self-hosted).",
      },
    ],
  },
  {
    id: "storage",
    label: "Object Storage",
    icon: "📦",
    color: "#2D8B46",
    desc: "Evidence files, report PDFs, export artifacts — MinIO (open source, self-hosted, S3-compatible).",
    items: [
      {
        name: "MinIO (Self-Hosted — DEFAULT)",
        stories: ["US-7.3.02", "US-7.3.10", "US-COMP.04", "US-COMP.05", "US-REV.01"],
        priority: "P1",
        endpoints: [
          { method: "PUT", url: "s3://armadillo-evidence/{projectId}/{vulnId}/{filename}", note: "Upload evidence" },
          { method: "GET", url: "s3://armadillo-reports/{projectId}/{reportId}.pdf", note: "Download report" },
        ],
        auth: "MINIO_ROOT_USER / MINIO_ROOT_PASSWORD env vars. S3-compatible credentials.",
        rateLimit: "Hardware-limited. Typical MSP volumes are trivial.",
        dataFormat: "Binary files (PNG, PDF, JSON snapshots).",
        refreshSchedule: "Event-driven: on evidence upload, report generation, auto-screenshot.",
        failureMode: "Return error to user. Retry upload. Never lose evidence.",
        dbTarget: "EvidenceAttachment.s3Key, Report.s3Key",
        npm: "@aws-sdk/client-s3 (Apache-2.0 — works with MinIO, no AWS required)",
        cost: "$0 — MinIO is free, open source (AGPL-3.0). Optional: AWS S3, Cloudflare R2, Backblaze B2.",
        extra: "Docker: minio/minio:latest (multi-arch: amd64 + arm64). Ports 9000/9001. Buckets: armadillo-evidence, armadillo-reports.",
        license: "MinIO: AGPL-3.0. @aws-sdk/client-s3: Apache-2.0.",
      },
    ],
  },
  {
    id: "siem",
    label: "SIEM Forwarding",
    icon: "📡",
    color: "#333333",
    desc: "Log forwarding to security platforms — Armadillo events alongside other security data.",
    items: [
      {
        name: "Syslog / CEF (Sentinel, Splunk, Elastic)",
        stories: ["US-ECO.04"],
        priority: "P2",
        endpoints: [
          { method: "UDP/TCP", url: "syslog://{siem_host}:{port}", note: "Standard syslog (514/udp or custom)" },
        ],
        auth: "Network-level (IP allowlisting). TLS for TCP syslog.",
        rateLimit: "N/A (fire-and-forget for UDP, backpressure for TCP).",
        dataFormat: "CEF: CEF:0|Armadillo|VulnMgmt|1.0|vuln.new|New Critical Vulnerability|9|src={assetIP} cs1={cveId} cs2={compositeScore}",
        refreshSchedule: "Event-driven: on vuln discovery, status change, scan complete, auth event.",
        failureMode: "UDP: silent drop (acceptable for syslog). TCP: queue and retry.",
        dbTarget: "Project-level SIEM config (host, port, protocol, format).",
        npm: "pino-syslog or winston-syslog",
        cost: "Free (protocol-level, no vendor dependency).",
      },
    ],
  },
];

const PriorityBadge = ({ p }) => {
  const colors = { P0: "#C62828", P1: "#E67E22", P2: "#666666" };
  return (
    <span style={{
      display: "inline-block", padding: "1px 8px", borderRadius: 4,
      fontSize: 11, fontWeight: 700, letterSpacing: 0.5,
      background: colors[p] || "#999", color: "#fff",
    }}>{p}</span>
  );
};

const StoryTag = ({ id }) => (
  <span style={{
    display: "inline-block", padding: "1px 6px", borderRadius: 3,
    fontSize: 10, fontWeight: 600, background: "#E8EEF4", color: "#1B365D",
    marginRight: 4, marginBottom: 2,
  }}>{id}</span>
);

const EndpointRow = ({ ep }) => (
  <div style={{ display: "flex", gap: 8, alignItems: "baseline", marginBottom: 4, fontSize: 12 }}>
    <span style={{
      fontFamily: "'JetBrains Mono', monospace", fontWeight: 700,
      color: ep.method === "POST" ? "#2D8B46" : ep.method === "PATCH" ? "#E67E22" : ep.method === "WS" ? "#6C3FA0" : "#2E75B6",
      minWidth: 48, fontSize: 11,
    }}>{ep.method}</span>
    <code style={{
      fontFamily: "'JetBrains Mono', monospace", fontSize: 11, color: "#1B365D",
      background: "#F5F7FA", padding: "2px 6px", borderRadius: 3, wordBreak: "break-all",
    }}>{ep.url}</code>
    <span style={{ color: "#888", fontSize: 11, flexShrink: 0 }}>— {ep.note}</span>
  </div>
);

const DetailRow = ({ label, value, mono }) => (
  <div style={{ display: "flex", gap: 8, marginBottom: 6, fontSize: 12, lineHeight: 1.5 }}>
    <span style={{ fontWeight: 700, color: "#555", minWidth: 110, flexShrink: 0 }}>{label}</span>
    <span style={{ color: "#333", fontFamily: mono ? "'JetBrains Mono', monospace" : "inherit", fontSize: mono ? 11 : 12 }}>{value}</span>
  </div>
);

const ItemCard = ({ item, color }) => {
  const [open, setOpen] = useState(false);
  return (
    <div style={{
      border: "1px solid #E0E0E0", borderRadius: 8, marginBottom: 10,
      borderLeft: `4px solid ${color}`, background: "#fff",
      transition: "box-shadow 0.15s", cursor: "pointer",
      boxShadow: open ? "0 2px 12px rgba(0,0,0,0.08)" : "none",
    }} onClick={() => setOpen(!open)}>
      <div style={{ padding: "12px 16px", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div>
          <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 4 }}>
            <span style={{ fontWeight: 700, fontSize: 14, color: "#1B365D" }}>{item.name}</span>
            <PriorityBadge p={item.priority} />
            <span style={{ fontSize: 11, color: "#888" }}>{item.cost}</span>
          </div>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 0 }}>
            {item.stories.map(s => <StoryTag key={s} id={s} />)}
          </div>
        </div>
        <span style={{ fontSize: 18, color: "#999", transform: open ? "rotate(180deg)" : "rotate(0)", transition: "transform 0.2s" }}>▾</span>
      </div>
      {open && (
        <div style={{ padding: "0 16px 16px", borderTop: "1px solid #F0F0F0" }} onClick={e => e.stopPropagation()}>
          <div style={{ marginTop: 12, marginBottom: 12 }}>
            <div style={{ fontWeight: 700, fontSize: 12, color: "#555", marginBottom: 6 }}>ENDPOINTS</div>
            {item.endpoints.map((ep, i) => <EndpointRow key={i} ep={ep} />)}
          </div>
          <DetailRow label="Auth" value={item.auth} />
          <DetailRow label="Rate Limits" value={item.rateLimit} />
          <DetailRow label="Data Format" value={item.dataFormat} mono />
          <DetailRow label="Refresh" value={item.refreshSchedule} />
          <DetailRow label="Failure Mode" value={item.failureMode} />
          <DetailRow label="DB Target" value={item.dbTarget} mono />
          <DetailRow label="npm Package" value={item.npm} mono />
          {item.extra && <DetailRow label="Notes" value={item.extra} />}
        </div>
      )}
    </div>
  );
};

const SummaryTable = () => {
  const allItems = CATEGORIES.flatMap(c => c.items.map(i => ({ ...i, category: c.label, color: c.color })));
  return (
    <div style={{ overflowX: "auto" }}>
      <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 12 }}>
        <thead>
          <tr style={{ background: "#1B365D", color: "#fff" }}>
            {["Tool / API", "Auth", "Cost", "Priority", "Cron / Trigger", "DB Target"].map(h => (
              <th key={h} style={{ padding: "8px 10px", textAlign: "left", fontWeight: 700, fontSize: 11 }}>{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {allItems.map((item, i) => (
            <tr key={i} style={{ background: i % 2 ? "#F8F9FA" : "#fff", borderBottom: "1px solid #E8E8E8" }}>
              <td style={{ padding: "6px 10px", fontWeight: 600, color: item.color }}>{item.name}</td>
              <td style={{ padding: "6px 10px", fontSize: 11 }}>{item.auth.split('.')[0]}</td>
              <td style={{ padding: "6px 10px", fontSize: 11 }}>{item.cost}</td>
              <td style={{ padding: "6px 10px" }}><PriorityBadge p={item.priority.split('–')[0]} /></td>
              <td style={{ padding: "6px 10px", fontSize: 11 }}>{item.refreshSchedule.split('→')[0].split(':')[0].trim()}</td>
              <td style={{ padding: "6px 10px", fontFamily: "'JetBrains Mono', monospace", fontSize: 10 }}>{item.dbTarget.split('→')[0].trim()}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

const DataFlowDiagram = () => {
  const flows = [
    { from: "FIRST.org EPSS", to: "EpssCache", via: "sync-epss-scores (02:00 UTC)", arrow: "→" },
    { from: "CISA KEV", to: "CisaKevEntry", via: "sync-cisa-kev (02:30 UTC)", arrow: "→" },
    { from: "EpssCache + CisaKevEntry", to: "Vulnerability (enriched)", via: "enrich-vulnerabilities", arrow: "→" },
    { from: "Vulnerability (enriched)", to: "compositeScore", via: "packages/scoring", arrow: "→" },
    { from: "compositeScore + vulns", to: "PostureSnapshot", via: "compute-posture-scores (03:00 UTC)", arrow: "→" },
    { from: "PostureSnapshot", to: "ComplianceMapping", via: "compute-compliance-maps (03:30 UTC)", arrow: "→" },
    { from: "Vulnerability (assigned)", to: "ConnectWise/Halo ticket", via: "create-psa-ticket (event)", arrow: "→" },
    { from: "PSA ticket status change", to: "Vulnerability.remediationStatus", via: "webhook callback", arrow: "←" },
    { from: "NinjaOne devices", to: "Asset.rmmMetadata", via: "sync-rmmData (hourly)", arrow: "→" },
    { from: "Scan complete event", to: "AI scan digest", via: "generate-scan-digest (event)", arrow: "→" },
    { from: "User clicks 'Fix this'", to: "AI guidance (cached)", via: "generate-ai-guidance (event)", arrow: "→" },
    { from: "Asset created/updated", to: "assetType + assetRole", via: "auto-classify-asset (event)", arrow: "→" },
  ];
  return (
    <div style={{ background: "#F8F9FB", borderRadius: 8, padding: 16, border: "1px solid #E0E4EA" }}>
      <div style={{ fontWeight: 700, fontSize: 13, color: "#1B365D", marginBottom: 12 }}>DATA PIPELINE — Daily Enrichment Chain</div>
      {flows.map((f, i) => (
        <div key={i} style={{
          display: "flex", alignItems: "center", gap: 6, marginBottom: 6, fontSize: 11, lineHeight: 1.6,
          padding: "4px 8px", background: i < 6 ? "#E8F5E9" : i < 9 ? "#FFF3E0" : "#EDE7F6",
          borderRadius: 4, fontFamily: "'JetBrains Mono', monospace",
        }}>
          <span style={{ fontWeight: 600, color: "#333", minWidth: 200 }}>{f.from}</span>
          <span style={{ color: "#888" }}>{f.arrow}</span>
          <span style={{ color: "#6C3FA0", fontWeight: 600 }}>[{f.via}]</span>
          <span style={{ color: "#888" }}>{f.arrow}</span>
          <span style={{ fontWeight: 600, color: "#1B365D" }}>{f.to}</span>
        </div>
      ))}
      <div style={{ marginTop: 12, fontSize: 11, color: "#666", display: "flex", gap: 16 }}>
        <span>🟢 Daily enrichment chain</span>
        <span>🟠 Integration sync</span>
        <span>🟣 AI event-driven</span>
      </div>
    </div>
  );
};

export default function ArmadilloToolsMap() {
  const [tab, setTab] = useState("detail");
  const [filter, setFilter] = useState("all");
  const totalItems = CATEGORIES.reduce((acc, c) => acc + c.items.length, 0);
  const totalStories = [...new Set(CATEGORIES.flatMap(c => c.items.flatMap(i => i.stories)))].length;

  return (
    <div style={{ fontFamily: "'Inter', -apple-system, sans-serif", maxWidth: 960, margin: "0 auto", padding: 24, background: "#FAFBFC" }}>
      <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;800&family=JetBrains+Mono:wght@400;600;700&display=swap" rel="stylesheet" />

      <div style={{ marginBottom: 32 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 8 }}>
          <span style={{ fontSize: 28 }}>🛡️</span>
          <div>
            <h1 style={{ margin: 0, fontSize: 22, fontWeight: 800, color: "#1B365D", letterSpacing: -0.5 }}>
              Project Armadillo v3 — Tools & Data Acquisition Map
            </h1>
            <p style={{ margin: 0, fontSize: 13, color: "#666" }}>
              {totalItems} external tools/APIs  •  {totalStories} user stories covered  •  Every endpoint, auth method, and data flow
            </p>
          </div>
        </div>

        <div style={{ display: "flex", gap: 8, marginTop: 16, flexWrap: "wrap" }}>
          {["detail", "summary", "dataflow"].map(t => (
            <button key={t} onClick={() => setTab(t)} style={{
              padding: "6px 16px", borderRadius: 6, border: "1px solid #D0D5DD",
              background: tab === t ? "#1B365D" : "#fff", color: tab === t ? "#fff" : "#555",
              fontWeight: 600, fontSize: 12, cursor: "pointer", transition: "all 0.15s",
            }}>
              {t === "detail" ? "📋 Full Detail" : t === "summary" ? "📊 Summary Table" : "🔄 Data Pipeline"}
            </button>
          ))}
        </div>
      </div>

      {tab === "summary" && <SummaryTable />}
      {tab === "dataflow" && <DataFlowDiagram />}
      {tab === "detail" && (
        <>
          <div style={{ display: "flex", gap: 6, marginBottom: 20, flexWrap: "wrap" }}>
            <button onClick={() => setFilter("all")} style={{
              padding: "4px 12px", borderRadius: 4, border: "none", fontSize: 11, fontWeight: 600,
              background: filter === "all" ? "#1B365D" : "#E8EEF4", color: filter === "all" ? "#fff" : "#1B365D", cursor: "pointer",
            }}>All ({totalItems})</button>
            {CATEGORIES.map(c => (
              <button key={c.id} onClick={() => setFilter(c.id)} style={{
                padding: "4px 12px", borderRadius: 4, border: "none", fontSize: 11, fontWeight: 600,
                background: filter === c.id ? c.color : "#F0F0F0", color: filter === c.id ? "#fff" : "#555", cursor: "pointer",
              }}>{c.icon} {c.label} ({c.items.length})</button>
            ))}
          </div>

          {CATEGORIES.filter(c => filter === "all" || filter === c.id).map(cat => (
            <div key={cat.id} style={{ marginBottom: 28 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 4 }}>
                <span style={{ fontSize: 20 }}>{cat.icon}</span>
                <h2 style={{ margin: 0, fontSize: 16, fontWeight: 800, color: cat.color }}>{cat.label}</h2>
              </div>
              <p style={{ margin: "0 0 12px", fontSize: 12, color: "#666" }}>{cat.desc}</p>
              {cat.items.map(item => <ItemCard key={item.name} item={item} color={cat.color} />)}
            </div>
          ))}
        </>
      )}

      <div style={{ marginTop: 32, padding: 16, background: "#E8F5E9", borderRadius: 8, border: "1px solid #C8E6C9" }}>
        <div style={{ fontWeight: 700, fontSize: 13, color: "#2D8B46", marginBottom: 8 }}>💰 TOTAL COST ESTIMATE — Self-Hosted (Monthly)</div>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))", gap: 8, fontSize: 12 }}>
          <div><strong>Intelligence feeds:</strong> $0 (all free public APIs)</div>
          <div><strong>AI/LLM (Ollama):</strong> $0 (self-hosted, open source)</div>
          <div><strong>Object storage (MinIO):</strong> $0 (self-hosted, open source)</div>
          <div><strong>Email (SMTP):</strong> $0 (self-hosted Postfix/Mailcow)</div>
          <div><strong>PSA/RMM:</strong> $0 (included with existing subs)</div>
          <div><strong style={{ color: "#2D8B46" }}>TOTAL: $0/mo (fully self-hosted on open source)</strong></div>
        </div>
        <div style={{ fontSize: 11, color: "#666", marginTop: 8, borderTop: "1px solid #C8E6C9", paddingTop: 8 }}>
          Optional cloud upgrades: Claude API (~$50-100/mo), AWS S3 (~$5/mo), SendGrid ($15/mo). These are <em>optional</em> — not required.
        </div>
      </div>
    </div>
  );
}

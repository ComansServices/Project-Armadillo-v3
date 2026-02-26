# Armadillo v3 — Phase 9: Host Telemetry & Endpoint Awareness

**Date:** 2026-02-27  
**Status:** Proposed / Architecture Ready  
**Owner:** Comans / Leo  
**Strategic Goal:** Extend Armadillo from network visibility to endpoint reality — close the gap between "what the scanner sees" and "what's actually running on the host"

---

## Executive Summary

Armadillo currently sees the network layer — open ports, service banners, CVE matches. But the real story lives on the endpoint: processes, users, configuration drift, privilege escalation paths, and insider threats.

**Phase 9 deploys lightweight agents** (Linux, Windows, macOS) that feed local telemetry into Armadillo's central brain, giving operators:
- Real-time process and user activity
- Configuration compliance posture
- Lateral movement detection from the inside
- File integrity monitoring for critical paths
- Log aggregation without expensive SIEM overhead

---

## Strategic Value

| Current State | With Host Agents |
|---------------|------------------|
| Scan-based point-in-time visibility | Continuous telemetry stream |
| Network-level vuln detection | Process-level exploit detection |
| "Port 445 is open" | "SMB is running + 3 active sessions + lateral auth attempts" |
| Asset inventory from imports | Live software inventory + version drift |
| External threat focus | Insider threat + configuration drift detection |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Armadillo Control Plane                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │  API Server │  │  Ingestion  │  │  Host Telemetry Service │  │
│  │             │  │   Pipeline  │  │  (new component)        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
│           │                │                    │                │
│           └────────────────┴────────────────────┘                │
│                          │                                       │
│                   ┌────────────┐                                 │
│                   │ PostgreSQL │                                 │
│                   │ + Redis    │                                 │
│                   └────────────┘                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ mTLS + JWT
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Host Agents (daemon/service)                │
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │ Linux Agent │  │ Win Agent   │  │ macOS Agent             │  │
│  │ (systemd)   │  │ (service)   │  │ (launchd)               │  │
│  │ Go binary   │  │ Go binary   │  │ Go binary               │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
│                                                                  │
│  Capabilities (all platforms):                                   │
│  • Process events (exec, fork, network connect)                  │
│  • User session tracking (logon/logoff, privilege escalation)    │
│  • File integrity monitoring (FIM) for critical paths            │
│  • Software inventory (installed apps, versions, auto-drift)     │
│  • Configuration compliance (CIS benchmarks subset)              │
│  • Log shipping (auth, sudo, Windows Event Log)                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Phase 9 Sprint Breakdown

### 🎯 Sprint 1 — Agent Core & Linux Support
**Goal:** Bootstrap agent architecture, Linux agent MVP, telemetry ingestion

| Item | Feature | Deliverables |
|------|---------|--------------|
| 1 | **Agent SDK / shared core** | Go module: config, crypto, heartbeat, retry logic |
| 2 | **Linux agent (systemd)** | eBPF for process events, FIM with inotify, log tailing |
| 3 | **Host Telemetry Service API** | `POST /api/v1/telemetry/batch`, agent registration, JWT auth |
| 4 | **Agent management UI** | `/agents` page: enrolled hosts, status, last seen, version |
| 5 | **Process event stream** | Real-time process exec tracking → Armadillo DB |

**Key Decisions:**
- Go for agent (single static binary, no runtime deps)
- eBPF for Linux process events (no LD_PRELOAD, kernel-native)
- mTLS mandatory for agent↔server comms
- SQLite local cache for offline resilience

---

### 🎯 Sprint 2 — Windows & macOS Agents
**Goal:** Cross-platform parity, OS-specific telemetry

| Item | Feature | Deliverables |
|------|---------|--------------|
| 1 | **Windows agent (service)** | ETW for process events, FIM with ReadDirectoryChangesW |
| 2 | **Windows Event Log shipping** | Auth events, PowerShell, Defender alerts |
| 3 | **macOS agent (launchd)** | Endpoint Security API (ESF), FSEvents for FIM |
| 4 | **Software inventory** | Cross-platform package detection (dpkg, rpm, MSI, Homebrew, etc) |
| 5 | **Version drift detection** | Alert when installed software != expected version |

**Key Decisions:**
- Windows: ETW (Event Tracing for Windows) for minimal overhead
- macOS: ESF (Endpoint Security Framework) — Apple-approved path
- Software inventory: Normalize to CPE format for CVE matching

---

### 🎯 Sprint 3 — Threat Detection & Response
**Goal:** Turn telemetry into actionable security signals

| Item | Feature | Deliverables |
|------|---------|--------------|
| 1 | **Lateral movement detection** | Alert on SMB/RDP/SSH to new hosts from monitored endpoint |
| 2 | **Privilege escalation alerts** | sudo/su/RunAs escalation to admin → immediate alert |
| 3 | **File integrity monitoring rules** | Critical paths: `/etc/passwd`, `C:\Windows\System32`, etc |
| 4 | **IOC matching** | Process name, hash, IP match → auto-alert |
| 5 | **Response actions** | Remote kill process, isolate host (quarantine network) |

**Detection Rules Engine:**
```yaml
rule:
  name: suspicious_powershell
  condition: process.name == "powershell.exe" AND parent.name != "explorer.exe"
  severity: high
  action: alert

rule:
  name: privilege_escalation
  condition: event.type == "privilege_escalation" AND target.user == "root"
  severity: critical
  action: alert + notify
```

---

### 🎯 Sprint 4 — Compliance & Reporting
**Goal:** CIS benchmarks, compliance dashboards, audit trails

| Item | Feature | Deliverables |
|------|---------|--------------|
| 1 | **CIS benchmark subset** | 20-30 critical checks per OS (password policy, UAC, SSH config) |
| 2 | **Compliance dashboard** | Pass/fail per host, trend over time, drill-down to failures |
| 3 | **Configuration drift** | Alert when security settings change (e.g., UAC disabled) |
| 4 | **User activity audit** | "What did this user do on these hosts?" timeline view |
| 5 | **Agent health monitoring** | Offline agents, version mismatch, stale telemetry alerts |

---

## Technical Specifications

### Agent Binary Design
```
armadillo-agent/
├── cmd/agent/          # Entry point
├── pkg/
│   ├── telemetry/      # Event collection
│   ├── fim/            # File integrity monitoring
│   ├── inventory/      # Software inventory
│   ├── compliance/     # CIS checks
│   ├── transport/      # mTLS + retry
│   └── platform/
│       ├── linux/      # eBPF, inotify
│       ├── windows/    # ETW, WinAPI
│       └── darwin/     # ESF, FSEvents
└── packaging/
    ├── deb/            # .deb for Debian/Ubuntu
    ├── rpm/            # .rpm for RHEL/CentOS
    ├── msi/            # Windows installer
    └── pkg/            # macOS installer
```

### API Endpoints (Host Telemetry Service)

```bash
# Agent registration (one-time bootstrap)
POST /api/v1/agents/register
{
  "hostname": "web-01",
  "os": "linux",
  "version": "9.1.0",
  "public_key": "..."
}

# Telemetry batch upload
POST /api/v1/telemetry/batch
Authorization: Bearer <agent-jwt>
[
  {"type": "process_exec", "pid": 1234, "name": "curl", "cmdline": "curl https://evil.com", "timestamp": "..."},
  {"type": "user_logon", "username": "admin", "source_ip": "10.0.0.5", "timestamp": "..."}
]

# Get agent config (polling)
GET /api/v1/agents/config
Authorization: Bearer <agent-jwt>
{
  "collection_interval": 30,
  "fim_paths": ["/etc", "/var/www"],
  "ioc_rules": [...],
  "compliance_checks": [...]
}

# List enrolled agents
GET /api/v1/agents

# Get agent details + recent events
GET /api/v1/agents/:agentId

# Response actions
POST /api/v1/agents/:agentId/actions/quarantine
POST /api/v1/agents/:agentId/actions/kill-process
{"pid": 1234}
```

### Database Schema Additions

```sql
-- Agents table
CREATE TABLE agents (
  id UUID PRIMARY KEY,
  hostname TEXT NOT NULL,
  os TEXT NOT NULL, -- linux, windows, darwin
  version TEXT NOT NULL,
  public_key TEXT NOT NULL,
  last_seen TIMESTAMP,
  status TEXT DEFAULT 'active', -- active, offline, quarantined
  registered_at TIMESTAMP DEFAULT NOW()
);

-- Telemetry events table
CREATE TABLE telemetry_events (
  id UUID PRIMARY KEY,
  agent_id UUID REFERENCES agents(id),
  type TEXT NOT NULL, -- process_exec, user_logon, file_change, etc
  data JSONB NOT NULL,
  severity TEXT DEFAULT 'info',
  timestamp TIMESTAMP NOT NULL
);

-- File integrity monitoring
CREATE TABLE fim_baseline (
  id UUID PRIMARY KEY,
  agent_id UUID REFERENCES agents(id),
  path TEXT NOT NULL,
  hash_sha256 TEXT NOT NULL,
  last_modified TIMESTAMP
);

-- Software inventory
CREATE TABLE software_inventory (
  id UUID PRIMARY KEY,
  agent_id UUID REFERENCES agents(id),
  name TEXT NOT NULL,
  version TEXT NOT NULL,
  cpe TEXT,
  installed_at TIMESTAMP,
  source TEXT -- dpkg, rpm, msi, etc
);

-- Compliance checks
CREATE TABLE compliance_results (
  id UUID PRIMARY KEY,
  agent_id UUID REFERENCES agents(id),
  benchmark TEXT NOT NULL, -- cis-linux-2.0
  check_id TEXT NOT NULL,
  status TEXT NOT NULL, -- pass, fail, error
  details JSONB,
  checked_at TIMESTAMP DEFAULT NOW()
);
```

---

## Security & Privacy Considerations

| Concern | Mitigation |
|---------|------------|
| Agent as attack surface | mTLS only, no inbound ports, principle of least privilege |
| Data exfiltration risk | PII redaction rules, retention limits (30 days default) |
| Privileged access | Agent runs as unprivileged user, uses OS APIs for privileged events |
| Key management | Agent keys generated on-device, never leave host |
| Audit trail | All agent actions logged centrally, tamper-resistant |

---

## Quick Wins for MVP

1. **Linux agent first** — eBPF is mature, easiest to iterate
2. **Process exec only** — most bang-for-buck telemetry
3. **Manual enrollment** — script-based install, auto-registration
4. **24-hour retention** — start small, expand based on storage
5. **Alert on sudo** — single rule, immediate security value

---

## Dependencies

- Requires Phase 7 (operator confidence) for alert/response UI
- Builds on Phase 8 (MSP integration) for multi-tenant agent isolation
- eBPF requires Linux kernel 4.18+ (RHEL 8, Ubuntu 20.04+)
- ESF requires macOS 10.15+ with User Approved MDM

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Agent coverage | 80% of managed endpoints within 30 days |
| Telemetry latency | < 5 seconds from event to Armadillo |
| False positive rate | < 5% on detection rules |
| Compliance score | Baseline → 90% CIS pass rate in 60 days |
| Mean time to detect | < 1 minute for critical events (privilege escalation) |

---

**Next Step:** Architecture review → Sprint 1 kickoff → Linux agent prototype

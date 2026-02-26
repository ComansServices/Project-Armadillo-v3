import Link from 'next/link';
import { AppShell } from '../_components/app-shell';
import { BulkVulnEdit } from '../_components/vuln-remediation-edit';
import { RemediationCell } from '../_components/remediation-cell';
import { BlastRadiusChip } from '../_components/blast-radius-chip';

type Finding = {
  id: number;
  cve: string;
  cpe: string | null;
  severity: string;
  cvss: number | null;
  title: string | null;
  description: string | null;
  detectedAt: string;
  importId: string;
  assignedTo: string | null;
  dueDate: string | null;
  remediationStatus: string;
  hasExploit?: boolean;
  exploitRefs?: Array<{ source: string; id: string; url: string; confidence: 'high' | 'medium' | 'low' }>;
  asset: {
    id: string;
    identityKey: string;
    ip: string | null;
    hostname: string | null;
  };
};

const baseUrl = process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';
const publicApiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';
const authHeaders = {
  'x-armadillo-user': process.env.WEB_ACTOR_ID ?? 'web-ui',
  'x-armadillo-role': process.env.WEB_ACTOR_ROLE ?? 'viewer',
  ...(process.env.ARMADILLO_AUTH_TOKEN ? { 'x-armadillo-auth': process.env.ARMADILLO_AUTH_TOKEN } : {})
};

const sevRank: Record<string, number> = { critical: 4, high: 3, medium: 2, low: 1 };

function sevStyle(sev: string) {
  const s = sev.toLowerCase();
  if (s === 'critical') return { background: '#7f1d1d', color: '#fee2e2', border: '1px solid #ef4444' };
  if (s === 'high') return { background: '#991b1b', color: '#fecaca', border: '1px solid #f87171' };
  if (s === 'medium') return { background: '#78350f', color: '#fde68a', border: '1px solid #f59e0b' };
  return { background: '#1f2937', color: '#d1d5db', border: '1px solid #4b5563' };
}

async function getFindings(filters: { 
  importId?: string; 
  severity?: string; 
  hasExploit?: string;
  assignedTo?: string;
  remediationStatus?: string;
}) {
  const qs = new URLSearchParams();
  if (filters.importId) qs.set('importId', filters.importId);
  if (filters.severity) qs.set('severity', filters.severity);
  if (filters.hasExploit) qs.set('hasExploit', filters.hasExploit);
  if (filters.assignedTo) qs.set('assignedTo', filters.assignedTo);
  if (filters.remediationStatus) qs.set('remediationStatus', filters.remediationStatus);
  qs.set('limit', '200');

  const res = await fetch(`${baseUrl}/api/v1/vulns?${qs.toString()}`, {
    cache: 'no-store',
    headers: authHeaders
  });
  if (!res.ok) throw new Error(`Failed to fetch vulnerabilities (${res.status})`);
  const data = (await res.json()) as { findings: Finding[] };
  return data.findings ?? [];
}

async function getExploitabilityStats(importId?: string) {
  const qs = new URLSearchParams();
  if (importId) qs.set('importId', importId);
  const res = await fetch(`${baseUrl}/api/v1/vulns/stats/exploitability?${qs.toString()}`, {
    cache: 'no-store',
    headers: authHeaders
  });
  if (!res.ok) return null;
  return res.json() as Promise<{
    total: number;
    withExploit: number;
    withoutExploit: number;
    bySeverity: { exploitable: Record<string, number>; theoretical: Record<string, number> };
  }>;
}

function ExploitBadge({ finding }: { finding: Finding }) {
  const hasExploit = finding.hasExploit || (finding.exploitRefs && finding.exploitRefs.length > 0);
  if (!hasExploit) return (
    <span style={{
      display: 'inline-flex',
      alignItems: 'center',
      gap: 4,
      padding: '2px 8px',
      borderRadius: 999,
      background: '#f3f4f6',
      color: '#6b7280',
      border: '1px solid #d1d5db',
      fontSize: 11,
      fontWeight: 600
    }} title="No known public exploit available">
      📋 Theoretical
    </span>
  );
  
  return (
    <span style={{
      display: 'inline-flex',
      alignItems: 'center',
      gap: 4,
      padding: '2px 8px',
      borderRadius: 999,
      background: '#fef2f2',
      color: '#dc2626',
      border: '1px solid #fecaca',
      fontSize: 11,
      fontWeight: 600
    }} title="Public exploit available - prioritize remediation">
      🔥 Exploitable
    </span>
  );
}

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default async function VulnsPage({
  searchParams
}: {
  searchParams: { 
    importId?: string; 
    severity?: string; 
    hasExploit?: string;
    assignedTo?: string; 
    remediationStatus?: string; 
    sort?: string; 
    group?: string;
    view?: string;
  };
}) {
  const filters = {
    importId: searchParams.importId?.trim() || undefined,
    severity: searchParams.severity?.trim() || undefined,
    hasExploit: searchParams.hasExploit?.trim() || undefined,
    assignedTo: searchParams.assignedTo?.trim() || undefined,
    remediationStatus: searchParams.remediationStatus?.trim() || undefined
  };
  const sort = (searchParams.sort ?? 'severity').toLowerCase();
  const group = (searchParams.group ?? 'none').toLowerCase();
  const view = (searchParams.view ?? 'all').toLowerCase();

  const [findings, stats] = await Promise.all([
    getFindings(filters),
    getExploitabilityStats(filters.importId)
  ]);

  const sorted = [...findings].sort((a, b) => {
    if (sort === 'detected') return +new Date(b.detectedAt) - +new Date(a.detectedAt);
    if (sort === 'cvss') return (b.cvss ?? 0) - (a.cvss ?? 0);
    return (sevRank[b.severity.toLowerCase()] ?? 0) - (sevRank[a.severity.toLowerCase()] ?? 0);
  });

  const sevCounts = sorted.reduce<Record<string, number>>((acc, f) => {
    const k = f.severity.toLowerCase();
    acc[k] = (acc[k] ?? 0) + 1;
    return acc;
  }, {});

  // Group by exploitability for display
  const exploitable = sorted.filter(f => f.hasExploit || (f.exploitRefs && f.exploitRefs.length > 0));
  const theoretical = sorted.filter(f => !f.hasExploit && (!f.exploitRefs || f.exploitRefs.length === 0));

  const exportQs = new URLSearchParams();
  if (filters.importId) exportQs.set('importId', filters.importId);
  if (filters.severity) exportQs.set('severity', filters.severity);
  exportQs.set('limit', '500');
  exportQs.set('format', 'csv');

  const grouped = sorted.reduce<Record<string, Finding[]>>((acc, f) => {
    const key = group === 'severity' ? f.severity.toLowerCase() : 'all';
    (acc[key] ||= []).push(f);
    return acc;
  }, {});

  const groupOrder = Object.keys(grouped).sort((a, b) => (sevRank[b] ?? 0) - (sevRank[a] ?? 0));

  return (
    <AppShell
      title="Vulnerability Findings"
      purpose="Triage CVE risk by severity, exploit context, and affected assets."
      whenToUse="Use this page when prioritising remediation or preparing stakeholder updates."
      firstAction="Filter by exploitability to focus on actionable risks first."
    >
      <p style={{ marginTop: 0 }}>
        <strong>💡 Tip:</strong> Prioritize vulnerabilities with 🔥 <strong>Exploitable</strong> badges — these have known public exploits available and pose immediate risk.
      </p>

      {/* Exploitability Filter Tabs */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 14, flexWrap: 'wrap' }}>
        <Link 
          href={`/vulns?${new URLSearchParams({...filters, view: 'all'}).toString()}`}
          style={{
            padding: '8px 16px',
            borderRadius: 8,
            textDecoration: 'none',
            fontWeight: 600,
            background: view === 'all' ? '#0f172a' : '#fff',
            color: view === 'all' ? '#fff' : '#0f172a',
            border: '1px solid #cbd5e1'
          }}
        >
          All ({stats?.total ?? sorted.length})
        </Link>
        <Link 
          href={`/vulns?${new URLSearchParams({...filters, hasExploit: 'true', view: 'exploitable'}).toString()}`}
          style={{
            padding: '8px 16px',
            borderRadius: 8,
            textDecoration: 'none',
            fontWeight: 600,
            background: view === 'exploitable' ? '#dc2626' : '#fef2f2',
            color: view === 'exploitable' ? '#fff' : '#dc2626',
            border: '1px solid #fecaca'
          }}
        >
          🔥 Exploitable ({stats?.withExploit ?? exploitable.length})
        </Link>
        <Link 
          href={`/vulns?${new URLSearchParams({...filters, hasExploit: 'false', view: 'theoretical'}).toString()}`}
          style={{
            padding: '8px 16px',
            borderRadius: 8,
            textDecoration: 'none',
            fontWeight: 600,
            background: view === 'theoretical' ? '#6b7280' : '#f3f4f6',
            color: view === 'theoretical' ? '#fff' : '#6b7280',
            border: '1px solid #d1d5db'
          }}
        >
          📋 Theoretical ({stats?.withoutExploit ?? theoretical.length})
        </Link>
      </div>

      <form method="get" style={{ display: 'flex', gap: 8, marginBottom: 14, flexWrap: 'wrap', alignItems: 'center' }}>
        <input name="importId" placeholder="Filter import ID" defaultValue={filters.importId ?? ''} style={{ minWidth: 180, width: 'min(100%, 260px)' }} />
        <select name="severity" defaultValue={filters.severity ?? ''}>
          <option value="">All severities</option>
          <option value="critical">critical</option>
          <option value="high">high</option>
          <option value="medium">medium</option>
          <option value="low">low</option>
        </select>
        <input name="assignedTo" placeholder="Assignee" defaultValue={filters.assignedTo ?? ''} style={{ width: 120 }} />
        <select name="remediationStatus" defaultValue={filters.remediationStatus ?? ''}>
          <option value="">All statuses</option>
          <option value="open">Open</option>
          <option value="in_progress">In Progress</option>
          <option value="on_hold">On Hold</option>
          <option value="resolved">Resolved</option>
        </select>
        <select name="sort" defaultValue={sort}>
          <option value="severity">Sort: severity</option>
          <option value="cvss">Sort: cvss</option>
          <option value="detected">Sort: detected time</option>
        </select>
        <select name="group" defaultValue={group}>
          <option value="none">Group: none</option>
          <option value="severity">Group: severity</option>
        </select>
        <button type="submit">Apply filters</button>
        <Link href="/vulns">Reset</Link>
        <a href={`${publicApiBaseUrl}/api/v1/vulns?${exportQs.toString()}`}>Export CSV</a>
      </form>

      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 14 }}>
        <div style={{ border: '1px solid #ddd', borderRadius: 8, padding: 10, minWidth: 110 }}><strong>Critical</strong><div>{sevCounts.critical ?? 0}</div></div>
        <div style={{ border: '1px solid #ddd', borderRadius: 8, padding: 10, minWidth: 110 }}><strong>High</strong><div>{sevCounts.high ?? 0}</div></div>
        <div style={{ border: '1px solid #ddd', borderRadius: 8, padding: 10, minWidth: 110 }}><strong>Medium</strong><div>{sevCounts.medium ?? 0}</div></div>
        <div style={{ border: '1px solid #ddd', borderRadius: 8, padding: 10, minWidth: 110 }}><strong>Low</strong><div>{sevCounts.low ?? 0}</div></div>
      </div>

      {/* Exploitable Section */}
      {(view === 'all' || view === 'exploitable') && exploitable.length > 0 && (
        <section style={{ marginBottom: 24 }}>
          <h3 style={{ 
            marginBottom: 12, 
            padding: '8px 12px', 
            background: '#fef2f2', 
            borderRadius: 8,
            border: '1px solid #fecaca',
            color: '#991b1b',
            display: 'flex',
            alignItems: 'center',
            gap: 8
          }}>
            🔥 Exploitable — {exploitable.length} finding{exploitable.length !== 1 ? 's' : ''} with public exploits
          </h3>
          <VulnTable findings={exploitable} />
        </section>
      )}

      {/* Theoretical Section */}
      {(view === 'all' || view === 'theoretical') && theoretical.length > 0 && (
        <section style={{ marginBottom: 24 }}>
          <h3 style={{ 
            marginBottom: 12, 
            padding: '8px 12px', 
            background: '#f3f4f6', 
            borderRadius: 8,
            border: '1px solid #d1d5db',
            color: '#374151',
            display: 'flex',
            alignItems: 'center',
            gap: 8
          }}>
            📋 Theoretical — {theoretical.length} finding{theoretical.length !== 1 ? 's' : ''} without known exploits
          </h3>
          <VulnTable findings={theoretical} />
        </section>
      )}

      {view === 'all' && group !== 'none' && groupOrder.map((g) => (
        <section key={g} style={{ marginBottom: 18 }}>
          <h3 style={{ marginBottom: 8, textTransform: 'uppercase' }}>
            {g} ({grouped[g].length})
          </h3>
          <VulnTable findings={grouped[g]} />
        </section>
      ))}

      <style>{`
        @media (max-width: 1100px) {
          .desktop-table { display: none; }
          .mobile-cards { display: grid !important; }
        }
      `}</style>
    </AppShell>
  );
}

function VulnTable({ findings }: { findings: Finding[] }) {
  return (
    <>
      <div className="desktop-table" style={{ overflowX: 'auto' }}>
        <table style={{ borderCollapse: 'collapse', minWidth: 1200, width: '100%' }}>
          <thead>
            <tr>
              {['Detected', 'Severity', 'Exploit', 'CVE', 'CVSS', 'Blast Radius', 'Asset', 'Import', 'Title', 'Status'].map((h) => (
                <th key={h} style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: '8px 10px' }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {findings.length === 0 ? (
              <tr><td colSpan={10} style={{ padding: '12px 10px', color: '#666' }}>No findings for current filters.</td></tr>
            ) : (
              findings.map((f) => (
                <tr key={f.id}>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{new Date(f.detectedAt).toLocaleString()}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>
                    <span style={{ ...sevStyle(f.severity), padding: '2px 10px', borderRadius: 999, textTransform: 'uppercase', fontSize: 12, fontWeight: 700, display: 'inline-flex', alignItems: 'center', gap: 6 }}>
                      <span aria-hidden="true">●</span>{f.severity}
                    </span>
                  </td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>
                    <ExploitBadge finding={f} />
                  </td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', fontFamily: 'monospace' }}>{f.cve}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{f.cvss ?? '-'}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>
                    <BlastRadiusChip cve={f.cve} />
                  </td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}><Link href={`/assets/${f.asset.id}`}>{f.asset.identityKey}</Link></td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}><Link href={`/imports/${f.importId}`}>{f.importId}</Link></td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{f.title ?? '-'}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>
                    <RemediationCell 
                      vulnId={f.id} 
                      assignedTo={f.assignedTo} 
                      dueDate={f.dueDate} 
                      remediationStatus={f.remediationStatus} 
                    />
                  </td>
                </tr>
              )))
            }
          </tbody>
        </table>
      </div>

      <div className="mobile-cards" style={{ display: 'none', gap: 8 }}>
        {findings.map((f) => (
          <article key={`m-${f.id}`} style={{ border: '1px solid #ddd', borderRadius: 10, padding: 10, background: '#fff' }}>
            <div style={{ display: 'flex', gap: 8, marginBottom: 8 }}>
              <span style={{ ...sevStyle(f.severity), padding: '2px 9px', borderRadius: 999, textTransform: 'uppercase', fontSize: 11, fontWeight: 700 }}>{f.severity}</span>
              <ExploitBadge finding={f} />
            </div>
            <p style={{ margin: '0 0 4px 0', fontFamily: 'monospace' }}>{f.cve}</p>
            <p style={{ margin: '0 0 4px 0', color: '#475569', fontSize: 12 }}>{new Date(f.detectedAt).toLocaleString()}</p>
            <p style={{ margin: '0 0 4px 0' }}><strong>Asset:</strong> {f.asset.identityKey}</p>
            <p style={{ margin: '0 0 8px 0' }}><strong>Title:</strong> {f.title ?? '-'}</p>
            <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
              <Link href={`/assets/${f.asset.id}`}>Open asset</Link>
              <Link href={`/imports/${f.importId}`}>Open import</Link>
            </div>
          </article>
        ))}
      </div>
    </>
  );
}

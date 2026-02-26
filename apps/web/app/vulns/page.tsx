import Link from 'next/link';
import { AppShell } from '../_components/app-shell';

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

async function getFindings(filters: { importId?: string; severity?: string }) {
  const qs = new URLSearchParams();
  if (filters.importId) qs.set('importId', filters.importId);
  if (filters.severity) qs.set('severity', filters.severity);
  qs.set('limit', '200');

  const res = await fetch(`${baseUrl}/api/v1/vulns?${qs.toString()}`, {
    cache: 'no-store',
    headers: authHeaders
  });
  if (!res.ok) throw new Error(`Failed to fetch vulnerabilities (${res.status})`);
  const data = (await res.json()) as { findings: Finding[] };
  return data.findings ?? [];
}

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default async function VulnsPage({
  searchParams
}: {
  searchParams: { importId?: string; severity?: string; sort?: string; group?: string };
}) {
  const filters = {
    importId: searchParams.importId?.trim() || undefined,
    severity: searchParams.severity?.trim() || undefined
  };
  const sort = (searchParams.sort ?? 'severity').toLowerCase();
  const group = (searchParams.group ?? 'none').toLowerCase();

  const findings = await getFindings(filters);
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
      firstAction="Filter by import/severity, then review high and critical findings first."
    >
      <p style={{ marginTop: 0 }}>CVE/CPE enrichment results from import assets. CSV export includes source and description fields for analyst handoff.</p>

      <form method="get" style={{ display: 'flex', gap: 8, marginBottom: 14, flexWrap: 'wrap', alignItems: 'center' }}>
        <input name="importId" placeholder="Filter import ID" defaultValue={filters.importId ?? ''} style={{ minWidth: 220, width: 'min(100%, 360px)' }} />
        <select name="severity" defaultValue={filters.severity ?? ''}>
          <option value="">All severities</option>
          <option value="critical">critical</option>
          <option value="high">high</option>
          <option value="medium">medium</option>
          <option value="low">low</option>
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

      {groupOrder.map((g) => (
        <section key={g} style={{ marginBottom: 18 }}>
          {group === 'severity' ? (
            <h3 style={{ marginBottom: 8, textTransform: 'uppercase' }}>
              {g} ({grouped[g].length})
            </h3>
          ) : null}

          <div className="desktop-table" style={{ overflowX: 'auto' }}>
            <table style={{ borderCollapse: 'collapse', minWidth: 1200, width: '100%' }}>
              <thead>
                <tr>
                  {['Detected', 'Severity', 'CVE', 'CVSS', 'CPE', 'Exploits', 'Asset', 'Import', 'Title'].map((h) => (
                    <th key={h} style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: '8px 10px' }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {grouped[g].length === 0 ? (
                  <tr><td colSpan={9} style={{ padding: '12px 10px', color: '#666' }}>No findings for current filters.</td></tr>
                ) : (
                  grouped[g].map((f) => (
                    <tr key={f.id}>
                      <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{new Date(f.detectedAt).toLocaleString()}</td>
                      <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>
                        <span style={{ ...sevStyle(f.severity), padding: '2px 10px', borderRadius: 999, textTransform: 'uppercase', fontSize: 12, fontWeight: 700, display: 'inline-flex', alignItems: 'center', gap: 6 }}>
                          <span aria-hidden="true">●</span>{f.severity}
                        </span>
                      </td>
                      <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', fontFamily: 'monospace' }}>{f.cve}</td>
                      <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{f.cvss ?? '-'}</td>
                      <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', fontFamily: 'monospace' }}>{f.cpe ?? '-'}</td>
                      <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', fontSize: 12 }}>
                        {f.exploitRefs && f.exploitRefs.length > 0 ? (
                          <div style={{ display: 'grid', gap: 4 }}>
                            {f.exploitRefs.slice(0, 2).map((r) => (
                              <a key={`${f.id}-${r.source}-${r.id}`} href={r.url} target="_blank" rel="noreferrer">{r.source}:{r.id}</a>
                            ))}
                          </div>
                        ) : '-'}
                      </td>
                      <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}><Link href={`/assets/${f.asset.id}`}>{f.asset.identityKey}</Link></td>
                      <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}><Link href={`/imports/${f.importId}`}>{f.importId}</Link></td>
                      <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{f.title ?? '-'}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          <div className="mobile-cards" style={{ display: 'none', gap: 8 }}>
            {grouped[g].map((f) => (
              <article key={`m-${f.id}`} style={{ border: '1px solid #ddd', borderRadius: 10, padding: 10, background: '#fff' }}>
                <p style={{ margin: '0 0 6px 0' }}>
                  <span style={{ ...sevStyle(f.severity), padding: '2px 9px', borderRadius: 999, textTransform: 'uppercase', fontSize: 11, fontWeight: 700 }}>{f.severity}</span>
                </p>
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

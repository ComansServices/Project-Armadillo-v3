import Link from 'next/link';

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
  asset: {
    id: string;
    identityKey: string;
    ip: string | null;
    hostname: string | null;
  };
};

const baseUrl = process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';
const authHeaders = {
  'x-armadillo-user': process.env.WEB_ACTOR_ID ?? 'web-ui',
  'x-armadillo-role': process.env.WEB_ACTOR_ROLE ?? 'viewer'
};

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
  searchParams: { importId?: string; severity?: string };
}) {
  const findings = await getFindings({
    importId: searchParams.importId?.trim() || undefined,
    severity: searchParams.severity?.trim() || undefined
  });

  return (
    <main style={{ padding: 24, fontFamily: 'system-ui' }}>
      <p style={{ marginBottom: 12 }}>
        <Link href="/">← Back to scans</Link>
      </p>
      <h1 style={{ marginBottom: 8 }}>Vulnerability Findings</h1>
      <p style={{ marginTop: 0 }}>CVE/CPE enrichment results from import assets.</p>

      <form method="get" style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
        <input name="importId" placeholder="Filter import ID" defaultValue={searchParams.importId ?? ''} style={{ minWidth: 360 }} />
        <select name="severity" defaultValue={searchParams.severity ?? ''}>
          <option value="">All severities</option>
          <option value="critical">critical</option>
          <option value="high">high</option>
          <option value="medium">medium</option>
          <option value="low">low</option>
        </select>
        <button type="submit">Apply filters</button>
        <Link href="/vulns">Reset</Link>
      </form>

      <div style={{ overflowX: 'auto' }}>
        <table style={{ borderCollapse: 'collapse', minWidth: 1200, width: '100%' }}>
          <thead>
            <tr>
              {['Detected', 'Severity', 'CVE', 'CVSS', 'CPE', 'Asset', 'Import', 'Title'].map((h) => (
                <th key={h} style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: '8px 10px' }}>
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {findings.length === 0 ? (
              <tr>
                <td colSpan={8} style={{ padding: '12px 10px', color: '#666' }}>No findings for current filters.</td>
              </tr>
            ) : (
              findings.map((f) => (
                <tr key={f.id}>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{new Date(f.detectedAt).toLocaleString()}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', textTransform: 'uppercase' }}>{f.severity}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', fontFamily: 'monospace' }}>{f.cve}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{f.cvss ?? '-'}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', fontFamily: 'monospace' }}>{f.cpe ?? '-'}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>
                    <Link href={`/assets/${f.asset.id}`}>{f.asset.identityKey}</Link>
                  </td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>
                    <Link href={`/imports/${f.importId}`}>{f.importId}</Link>
                  </td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{f.title ?? '-'}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </main>
  );
}

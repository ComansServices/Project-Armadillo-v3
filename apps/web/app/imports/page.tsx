import Link from 'next/link';

type XmlImportRecord = {
  id: string;
  source: string | null;
  requestedBy: string;
  rootNode: string | null;
  itemCount: number;
  normalizedAssetCount: number;
  skippedAssetCount: number;
  invalidAssetCount: number;
  createdAt: string;
};

type ImportTrendPoint = {
  id: string;
  createdAt: string;
  normalizedAssetCount: number;
  skippedAssetCount: number;
  invalidAssetCount: number;
};

const baseUrl =
  process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';
const publicApiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';

const authHeaders = {
  'x-armadillo-user': process.env.WEB_ACTOR_ID ?? 'web-ui',
  'x-armadillo-role': process.env.WEB_ACTOR_ROLE ?? 'viewer'
};

async function getImports(): Promise<XmlImportRecord[]> {
  const res = await fetch(`${baseUrl}/api/v1/imports?limit=50`, {
    cache: 'no-store',
    headers: authHeaders
  });

  if (!res.ok) {
    throw new Error(`Failed to fetch imports (${res.status})`);
  }

  const data = (await res.json()) as { imports: XmlImportRecord[] };
  return data.imports ?? [];
}

async function getTrend(): Promise<ImportTrendPoint[]> {
  const res = await fetch(`${baseUrl}/api/v1/imports/quality-trend?limit=10`, {
    cache: 'no-store',
    headers: authHeaders
  });

  if (!res.ok) {
    throw new Error(`Failed to fetch trend (${res.status})`);
  }

  const data = (await res.json()) as { trend: ImportTrendPoint[] };
  return data.trend ?? [];
}

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default async function ImportsPage() {
  const [imports, trend] = await Promise.all([getImports(), getTrend()]);

  return (
    <main style={{ padding: 24, fontFamily: 'system-ui' }}>
      <p style={{ marginBottom: 12 }}>
        <Link href="/">← Back to scans</Link>
      </p>
      <h1 style={{ marginBottom: 8 }}>XML Imports</h1>
      <p style={{ marginTop: 0 }}>Latest imported XML payloads (auto-refresh every 5s).</p>
      <p style={{ marginTop: 0 }}>
        <Link href="/assets">View normalized assets →</Link>
      </p>
      <p style={{ marginTop: 0 }}>
        <a href={`${publicApiBaseUrl}/api/v1/imports.csv?limit=500`} target="_blank" rel="noreferrer">
          Export imports CSV →
        </a>
      </p>

      <meta httpEquiv="refresh" content="5" />

      <h2 style={{ marginTop: 20, marginBottom: 8 }}>Quality Trend (last 10 imports)</h2>
      <div style={{ overflowX: 'auto', marginBottom: 18 }}>
        <table style={{ borderCollapse: 'collapse', minWidth: 700, width: '100%' }}>
          <thead>
            <tr>
              {['When', 'Normalized', 'Skipped', 'Invalid'].map((h) => (
                <th key={h} style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: '8px 10px' }}>
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {trend.length === 0 ? (
              <tr>
                <td colSpan={4} style={{ padding: '12px 10px', color: '#666' }}>
                  No trend points yet.
                </td>
              </tr>
            ) : (
              trend.map((t) => (
                <tr key={t.id}>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>
                    {new Date(t.createdAt).toLocaleString()}
                  </td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{t.normalizedAssetCount}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{t.skippedAssetCount}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{t.invalidAssetCount}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <div style={{ overflowX: 'auto', marginTop: 16 }}>
        <table style={{ borderCollapse: 'collapse', minWidth: 1100, width: '100%' }}>
          <thead>
            <tr>
              {['Import ID', 'Source', 'Requested By', 'Root Node', 'Items', 'Normalized', 'Skipped', 'Invalid', 'Created'].map((h) => (
                <th
                  key={h}
                  style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: '8px 10px' }}
                >
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {imports.length === 0 ? (
              <tr>
                <td colSpan={9} style={{ padding: '12px 10px', color: '#666' }}>
                  No imports yet.
                </td>
              </tr>
            ) : (
              imports.map((i) => (
                <tr key={i.id}>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', fontFamily: 'monospace' }}>
                    <Link href={`/imports/${i.id}`}>{i.id}</Link>
                  </td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{i.source ?? '-'}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{i.requestedBy}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{i.rootNode ?? '-'}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{i.itemCount}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{i.normalizedAssetCount}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{i.skippedAssetCount}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{i.invalidAssetCount}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>
                    {new Date(i.createdAt).toLocaleString()}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </main>
  );
}

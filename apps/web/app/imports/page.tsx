import Link from 'next/link';

type XmlImportRecord = {
  id: string;
  source: string | null;
  requestedBy: string;
  rootNode: string | null;
  itemCount: number;
  createdAt: string;
};

const baseUrl =
  process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';

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

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default async function ImportsPage() {
  const imports = await getImports();

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

      <meta httpEquiv="refresh" content="5" />

      <div style={{ overflowX: 'auto', marginTop: 16 }}>
        <table style={{ borderCollapse: 'collapse', minWidth: 900, width: '100%' }}>
          <thead>
            <tr>
              {['Import ID', 'Source', 'Requested By', 'Root Node', 'Items', 'Created'].map((h) => (
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
                <td colSpan={6} style={{ padding: '12px 10px', color: '#666' }}>
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
